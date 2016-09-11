function varargout = fn_register(varargin)
% function [shift e xreg] = fn_register(x,par|ref)
% function par = fn_register('par')
%---
% Be careful with the sign: xreg is obtained as
% xreg = fn_translate(x,-shift);
%
% See also fn_translate, fn_xregister

% Thomas Deneux
% Copyright 2011-2012

if nargin==0, help fn_register, end

x = varargin{1};
if ischar(x)
    if ~strcmp(x,'par'), error argument, end
    varargout = {defaultpar(varargin{2:end})};
else
    if isstruct(varargin{2})
        par = defaultpar;
        if nargin>=2, par = fn_structmerge(par,varargin{2},'skip'); end
    else
        par = defaultpar;
        par.ref = varargin{2};
    end
    nout = max(nargout,1);
    varargout = cell(1,nout);
    [varargout{:}] = register(x,par);
end
%if nargout==0, varargout = {}; end

end

%---
function par = defaultpar(varargin)

par.maxshift = .5;      % shift cannot exceed half of the image size [TODO!]
par.ref = 10;           % reference frame: use average of first 10 frames as default
% par.repeat = false;     % repeat the estimation with the average resampled movie as new reference frame
par.dorotation = false;
par.doxreg = false;     % first do a global optimization
par.xlowpass = 0;       % spatial low-pass
par.xhighpass = 0;      % spatial high-pass
par.tsmoothing = 0;      % smoothing of the estimated drift!!
par.mask = [];          % use a mask
par.display = 'framenumber';    % possibilities: 'iter' (image display at each iteration), 'final' (image display of each aligned frame), 'framenumber' (frame number only), 'none'
par.maxerr = [];        % maximal error allowed: if not attained, try other initializations; [TODO!]
par.shift0 = [0 0];
par.useprev0 = true;
par.tolx = 1e-4;
par.tolfun = 1e-4;
par.FACT = 1;
par.dogradobj = false;
par.output = 'same';    % 'same' or 'valid'

% user input
for i = 1:2:length(varargin)
    f = varargin{i};
    val = varargin{i+1};
    par.(f) = val;
end

end

%---
function [shift e xreg] = register(x,par)

% Size
if any(isnan(x(:))), error 'cannot register images with NaN values', end
[ni nj nt] = size(x);
[par.ni par.nj par.nt] = size(x);

% Reference frame
if isscalar(par.ref)
    if par.ref==0
        ref = mean(x,3);
    else
        ref = mean(x(:,:,1:min(par.ref,nt)),3);
    end
else
    ref = double(par.ref);
    if any(size(ref)~=[ni nj])
        error('size mismatch between data (%i-%i) and reference frame (%i-%i)',ni,nj,size(ref,1),size(ref,2))
    end
end
ref = (ref-nmean(ref(:)))/nstd(ref(:)); % normalize image
% filtering
tau = [par.xlowpass par.xhighpass];
if any(tau)
    if ~isempty(par.mask)
        disp 'not using the mask for spatial smoothing'
    end
    ref = fn_filt(ref,tau,[1 2]);
end
docut = any(isnan(ref(:)));
if docut
    oki = ~all(any(isnan(ref),3),2);
    okj = ~all(any(isnan(ref),3),1);
    ref = ref(oki,okj,:);
    if ~isempty(par.mask), par.mask = par.mask(oki,okj); end
end

% Maximal move
if isscalar(par.maxshift)
    if par.maxshift>1
        xregminoverlap = 1-par.maxshift/min([ni nj]); % approximative...
        par.maxshift = par.maxshift*[1 1];
    else
        xregminoverlap = 1-par.maxshift; % approximative...
        par.maxshift = par.maxshift*[ni nj];
    end
end
if par.dorotation
    par.maxshift(3) = 2*pi;
end
par.maxshift = column(par.maxshift);

% Display
if fn_ismemberstr(par.display,{'iter' 'final'})
    hf = figure(678);
    set(hf,'numberTitle','off','name','fn_register')
    clf(hf)
    ha = axes('parent',hf);
    colormap(ha,gray(256))
    par.im = imagesc(par.ref','parent',ha);
end

% Register
opt = optimset('Algorithm','active-set','GradObj',fn_switch(par.dogradobj), ...
    'tolx',par.tolx,'tolfun',par.tolfun,'maxfunevals',1000, ...
    'display',fn_switch(par.display,'framenumber','none',par.display));
Q = column(par.FACT);
shift = zeros(2+par.dorotation,nt);
if nt>1 && ~strcmp(par.display,'none'), fn_progress('register frame',nt), end
d = par.shift0(:);
if par.dorotation && length(d)==2, d(3) = 0; end
if nargout>=2, e = zeros(1,nt); end

e0 = [];
    function [e de] = myfun(d)
        switch nargout
            case 1
                e = energy(d.*Q,xk,ref,par)/e0;
            case 2
                [e de] = energy(d.*Q,xk,ref,par);
                e = e/e0;
                de = de/e0;
        end
    end

for k=1:nt
    if nt>1 && ~strcmp(par.display,'none'), fn_progress(k), end
    xk = double(x(:,:,k));
    if docut, xk = xk(oki,okj,:); end
    xk = (xk-mean(xk(:)))/std(xk(:)); % normalize image
    % reset current shift?
    if ~par.useprev0, d = par.shift0(:); end
    % filtering
    if any(tau)
        xk = fn_filt(xk,tau,[1 2]);
    end
    e0 = energy(d,xk,ref,par); % energy with the default coregistration: use it for normalization
    if e0==0
        % perfect match between reference and frame, probably because this
        % frame was chosen as reference! keep the value for d
    else
        % global registration
        if par.doxreg
            d = fn_xregister(xk,ref,xregminoverlap);
        end
        % fine sub-pixel registration
        if par.dorotation
            disp 'warning: registration with a rotation might not work properly yet!'
        end
        d = fmincon(@myfun,d./Q, ...
            [],[],[],[],-par.maxshift./Q,par.maxshift./Q,[],opt).*Q;
        if par.dorotation
            d(3) = mod(d(3)+pi,2*pi)-pi;
        end
    end
    
    %     % test whether 'energy' is a nicely continuous/differentiable function
    %     dtest = 0:.01:11; nd = length(dtest);
    %     etest = zeros(1,nd);
    %     for ktest=1:nd
    %         etest(ktest) = energy(dtest(ktest)*[1 1],xk,ref,par)/e0;
    %     end
    %     figure(9), plot(dtest,etest)
    
    
    if strcmp(par.display,'final')
        error 'not implemented'
    end
    shift(:,k) = d;
    if nargout>=2, e(k) = energy(d,xk,ref,par); end
end

% Smooth estimated drift
if par.tsmoothing
    shift = [repmat(shift(:,1),1,nt) shift repmat(shift(:,nt),1,nt)];
    shift = fn_filt(shift,par.tsmoothing,2);
    shift = shift(:,nt+1:2*nt);
end
if nargout<3, return, end

% Resample
if nt>1 && ~strcmp(par.display,'none'), fn_progress('resample frames'), end
xreg = zeros(ni,nj,nt,class(x)); %#ok<*ZEROLIKE>
for k=1:nt
    xreg(:,:,k) = fn_translate(x(:,:,k),-shift(:,k),'full');
end

% Cut
if strcmp(par.output,'valid')
    okij = ~any(isnan(xreg),3);
    oki = okij(:,round(nj/2));
    okj = okij(round(ni/2),:);
    xreg = xreg(oki,okj,:);
end

end

%---
function [e de] = energy(d,x,ref,par)

DODEBUG = false;
if DODEBUG, fprintf('%f ',d), fprintf('\n'), end

doJ = (nargout==2);
% if doJ
%     if par.dorotation, error 'cannot compute gradient for rotation', end
%     [xpred weight J dweight] = fn_translate(ref,d,'valid');
% else
if par.dorotation
    [ni nj] = size(ref);
    center = [(1+ni)/2; (1+nj)/2];
    theta = -d(3); % inverse rotation
    M = [cos(theta) -sin(theta); sin(theta) cos(theta)];
    [ii jj] = ndgrid(1:ni,1:nj);
    p = fn_add( ...
        M*[row(ii); row(jj)], ...   % inverse rotation with center (0,0)
        center-M*center ...         % translation to have a rotation with center the center of the image
        -column(d(1:2)) ...         % inverse translation
        );
    xpred = interpn(ref,p(1,:),p(2,:));
    xpred = reshape(xpred,ni,nj);
    mask = ~isnan(xpred);
%     rotation = [cos(theta) -sin(theta); sin(theta) cos(theta)]; % inverse rotation with center (0,0)
%     translation = center-rotation*center ...    % translation to have a rotation with center the center of the image
%         -column(d(1:2));                        % inverse translation
%     M = [1 0 0; translation rotation];
%     [xpred weight] = fn_affinity(ref,M,'linear');
%     mask = logical(weight);
    xpred = xpred(mask);
    weight = mask / sum(mask(:));
else
    [xpred weight] = fn_translate(ref,d,'valid');
end
% end
mask = logical(weight);

if strcmp(par.display,'iter')
    showimages(x,xpred,mask,par)
end

if isempty(par.mask)
    xpred = xpred(:);
else
    xpred = xpred(par.mask(mask));
    mask = mask & par.mask;
end
N = length(xpred);
dif = xpred - x(mask);
dif = dif - mean(dif); % subtract the mean for not being influenced by global luminance changes - this is not taken into account in the calculation of the derivative!
dif2 = dif.^2;
weight = weight(mask);
% weight = weight/sum(weight(:));

e  = sum(dif2.*weight);
if DODEBUG, fprintf('\b -> e = %f\n',e), end
if doJ
    %     % TODO: still, something is not good with the derivative, in particular at integer values of shift
    %     J = reshape(J,[N 2]);
    %     dweight = reshape(dweight,[par.ni*par.nj 2]);
    %     dweight = dweight(mask,:);
    %
    %     de = 2*(dif.*weight)'*J + sum(repmat(dif2,1,2).*dweight);
    
    % compute derivative by hand, but with some smart choices
    de = zeros(1,length(d));
    for dim=1:length(d)
        switch dim
            case {1 2}
                dd = .1; % tenth of a pixel
            case 3
                dd = asin(.1/(max(ni,nj)/2)); % rotation that results in a motion of a tenth of a pixel in the most distant point from the center
        end
        d1 = d; d1(dim) = d(dim)+dd;
        e1 = energy(d1,x,ref,par);
        if e1<e
            de(dim) = (e1-e)/dd;
        else
            d2 = d; d2(dim) = d(dim)-dd; % test also the other direction!!
            e2 = energy(d2,x,ref,par);
            de(dim) = (e1-e2)/(2*dd);
            if e2>=e
                if DODEBUG, fprintf('local minimum in dimension %i, attenuating by 10000\n',dim), end
                de(dim) = de(dim)/10000;
            end
        end
    end
    % exagerating the derivative
    de = de*100;
    if DODEBUG, fprintf('-> de = '), fprintf('%f ',de), fprintf('\n'), end
end

end

%---
function showimages(x,xpred,mask,par)

a = x;
a(mask) = a(mask)-xpred(:);
if ~isempty(par.mask), a(~par.mask) = 0; end
set(par.im,'cdata',a')
drawnow

end


