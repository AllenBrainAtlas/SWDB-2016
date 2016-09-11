function hl = fn_eegplot(varargin)
% function hl = fn_eegplot([t,]data,usual plot arguments[,stepflag][,flag])
%---
% Like Matlab function 'plot', but separates line by a distance 'ystep'
%
% Input:
% - t       vector - x-values
% - data    2D or 3D array - y-values (if 3D, the spacing is done along the
%           3rd dimension)
% - usual plot arguments
% - stepflag    the way 'ystep' is calculated:
%   . x         use ystep = x
%   . 'STD'     use ystep = mean(std(data))
%   . 'xSTD'    use ystep = x*mean(std(data)) [default is 3*STD]
%   . 'fit' 	use ystep = max(max(data)-min(data))
%   . 'xfit'    use ystep = x * max(max(data)-min(data))
% - flag    'num'   rescale the data so that y-axis values correspond to
%                   data number
%           'numtop'    same, and put the first data top instead of bottom
%
% See also fn_gridplot

% Thomas Deneux
% Copyright 2005-2012

% Input
% (data at position 1 or 2)
if nargin>1 && isnumeric(varargin{2}) && ~isscalar(varargin{2})
    idata = 2;
else
    idata = 1;
end
data = varargin{idata};

% (flags at the end)
donum = ''; % '', 'bottom' or 'top'
ystep = [];
% ('num' flag?)
a = varargin{end};
if ischar(a)
    switch a
        case 'num'
            donum = 'bottom';
        case 'numtop'
            donum = 'top';
    end
    if ~isempty(donum), varargin(end) = []; end
end
% (step specification)
a = varargin{end};
if isnumeric(a) && isscalar(a) && ~(ishandle(a) && strcmp(get(a,'type'),'axes')) % TODO: not enough!!
    ystep = a;
    varargin(end) = [];
elseif ischar(a)
    x = regexpi(a,'^([0-9\.]*)STD$','tokens');
    if ~isempty(x)
        if isempty(x{1}{1}), fact=1; else fact=str2double(x{1}); end
        ystep = fact*mean(mean(std(data)));
        varargin(end) = [];
    else
        x = regexp(a,'^([0-9\.]*)fit$','tokens');
        if ~isempty(x)
            if isempty(x{1}), fact=1; else fact=str2double(x{1}); end
            ystep = fact*max(max(data(:))-min(data(:)));
            varargin(end) = [];
        end
    end
end

% more computation
if isempty(ystep)
    ystep = 3*mean(mean(std(data)));
end
if donum
    data = 1+(-1)^strcmp(donum,'top')*fn_normalize(data,1,'-')/ystep;
    ystep = 1;
end
is3d = (ndims(data)>2);
if is3d
    [nt nc nstep] = size(data);
    data = data(:,:);
else
    [nt nstep] = size(data);
    nc = 1;
end
varargin{idata} = data;

% display
hl = plot(varargin{:});
if isempty(hl), return, end
hl = reshape(hl,nc,nstep);
uistack(hl(:),'top')
ha = get(hl(1),'parent');
cols = get(ha,'colororder');
ncol = size(cols,1);
for k=1:nstep
    for i=1:nc, set(hl(i,k),'ydata',get(hl(i,k),'ydata')+(k-1)*ystep), end
    set(hl(:,k),'color',cols(fn_mod(k,ncol),:),varargin{idata+1:end})
end
axis(ha,'tight')
if strcmp(donum,'top'), set(ha,'yDir','reverse'), end

if nargout==0, clear hl, end

    
    
    
    