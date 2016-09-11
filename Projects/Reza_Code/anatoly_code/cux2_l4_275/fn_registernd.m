function [mov check] = fn_registernd(ref,test,sigma,hp)
% function [mov check] = fn_registernd(ref,test,sigma,hp)
%---
% register z-stack test to the z-stack ref and returns the distance to move
% in pixels
% 
% Input:
% - ref         ND array
% - test        ND array, sizes smaller than ref
% - sigma       nrep*ndim array: value of low-pass filter to apply first
%               [default: 1]
% - hp          parent for display: either figure or uipanel handle
%               [default: no display]
% 
% Output:
% - mov         estimated distance in pixels to go from the center of ref
%               to the place where the center of test has been register
% - check       interpolation of ref at the registered location, the same
%               size of test, allows to check that the alignment is correct
%
% the maximal distance is such that the portion of 'test' which is allowed to
% move out of 'ref' is less than 1/4 in each dimension

% Thomas Deneux
% Copyright 20011-2012

% convert to double
ref = double(ref);
test = double(test);

% sizes and maximal distance
sref = size(ref);
ndim = length(sref);
if ndim>3, error('coregistration not handled yet for arrays of dimension >=4'), end
s = size(test); s(end+1:ndim)=1;
if length(s)>ndim || any(s>sref)
    error('frame to be registered must be smaller in all dimensions than reference frame')
end
sid2sidmov = (sref-s)/2;
maxmov = sid2sidmov + floor(s/4) - .1; % -.1 is because the maximal move would require to access data beyond what is allowed although with a factor zero
if any(maxmov<0)
    error('motion not possible in some dimension')
end

% filtering
if nargin<3
    sigma = 1;
end
nrep = size(sigma,1);
if size(sigma,2)==1
    sigma = repmat(sigma,[1 ndim]);
elseif size(sigma,2)~=ndim
    error('number of column of the smoothing parameter must match the number of dimensions of the reference')
end

% prepare display
if nargin>=4
    [isfig isnewfig] = fn_isfigurehandle(hp);
    if isfig && isnewfig
        figure(hp)
    else
        delete(get(hp,'children'))
    end
    ha(1)=axes('parent',hp,'pos',[.02 .51 .96 .47]);
    ha(2)=axes('parent',hp,'pos',[.02 .02 .96 .47]);
    im(1)=imagesc(test(:,:),'parent',ha(1));
    im(2)=imagesc(test(:,:),'parent',ha(2));
    set(ha,'xtick',[],'ytick',[],'dataaspectratio',[1 1 1])
else
    im = [];
end
% optimization options
opt = optimset('Algorithm','active-set', ...
    'display','iter');
mov = zeros(1,ndim);
fact = 1e3;

% optimization: loop on smoothing pararmeter
for krep = 1:nrep
    
    % smoothing
    ref1 = ref; test1 = test;
    for k=1:ndim
        sig = sigma(krep,k);
        h = fspecial('gaussian',[ceil(5*sig) 1],sig);
        h = shiftdim(h,-(k-1));
        ref1  = convn(ref1,h,'same');
        test1 = convn(test1,h,'same');
    end
    
    % display
    if ~isempty(im)
        set(im(1),'cdata',test1(:,:))
    end
    
    % estimation
    fun = @(x)correlation(ref1,test1,x*fact,im);
    mov = fact * fmincon(fun,mov/fact,[],[],[],[],-maxmov/fact,maxmov/fact,[],opt);

end

% final interpolation
x = sref/2 + mov - s/2; % shift using image origin rather than center
indicesnew = cell(1,ndim);
for k=1:ndim
    indicesnew{k} = (1:s(k)) + x(k);
end
[indicesnew{:}] = ndgrid(indicesnew{:});
check = interpn(ref,indicesnew{:});

%---
function c = correlation(ref,test,mov,im)
% correlation between test (or part of it if the other part falls outside
% of ref), and the equivalent interpolation from test at position defined
% by mov

persistent t
if isempty(t), t=now; end

% sizes and number of dimensions
sref = size(ref);
ndim = length(sref);
s = size(test); s(ndim+1:length(sref))=1;

% mov initially describes how to move the center of test away from the
% center, change to how to move the origin of test away from the origin of
% ref
x = sref/2 + mov - s/2;

% find overlapping area:
% - integer part and remainder part
d = floor(x);
u = x-d;
% - all the indices in test that we want to visit 'a priori'
mintestidx = ones(1,ndim);
maxtestidx = s;
% - the indices to visit in ref -> correct to not exit from ref
minrefidx = max(mintestidx+d,1);
maxrefidx = min(maxtestidx+d+1,sref);
% - correct the 'a posteriori' indices in test to visit
mintestidx = minrefidx-d;
maxtestidx = maxrefidx-d-1;
% - check that we still have at least 3/4 of each size
if (maxtestidx-mintestidx+1)<(s-floor(s/4))
    error programming
end

% cut test accordingly, prepare for cutting ref
subsidx = cell(1,ndim);
subsidxref = cell(1,ndim);
for k=1:ndim
    subsidx{k} = mintestidx(k):maxtestidx(k);
    subsidxref{k} = minrefidx(k):maxrefidx(k)-1;
end
sub = substruct('()',subsidx);
%subref = substruct('()',subsidxref);
test2 = subsref(test,sub);

% and interpolate from the reference
switch ndim
    case 2
        ref2 = ...
            (1-u(1)) * (1-u(2)) * ref(subsidxref{1}  ,subsidxref{2}  ) + ...
            (1-u(1)) *    u(2)  * ref(subsidxref{1}  ,subsidxref{2}+1) + ...
               u(1)  * (1-u(2)) * ref(subsidxref{1}+1,subsidxref{2}  ) + ...
               u(1)  *    u(2)  * ref(subsidxref{1}+1,subsidxref{2}+1);
    case 3
        u1 = u(1); v1 = 1-u1;
        u2 = u(2); v2 = 1-u2;
        u3 = u(3); v3 = 1-u3;
        iv = subsidxref{1}; iu = iv+1;
        jv = subsidxref{2}; ju = jv+1;
        kv = subsidxref{3}; ku = kv+1;
        ref2 = ...
            v1*v2*v3 * ref(iv,jv,kv) + ...
            v1*v2*u3 * ref(iv,jv,ku) + ...
            v1*u2*v3 * ref(iv,ju,kv) + ...
            v1*u2*u3 * ref(iv,ju,ku) + ...
            u1*v2*v3 * ref(iu,jv,kv) + ...
            u1*v2*u3 * ref(iu,jv,ku) + ...
            u1*u2*v3 * ref(iu,ju,kv) + ...
            u1*u2*u3 * ref(iu,ju,ku);
    otherwise
        error('coregistration not handled yet for arrays of dimension >=4')
end

% display
if ~isempty(im) && now>t+datenum(0,0,0,0,0,1)
    z = zeros(s);
    test3 = subsasgn(z,sub,test2);
    ref3  = subsasgn(z,sub,ref2);
    set(im(1),'cdata',test3(:,:))
    set(im(2),'cdata',ref3(:,:))
    pause(.01)
    t = now;
end

% finally, the correlation!
c = mean((test2(:)-ref2(:)).^2);


