function ha = fn_subplot(varargin)
% function ha = fn_subplot(hf,nrow,ncol,k[,spacing])
% function ha = fn_subplot(abcd)
% function ha = fn_subplot(hf,ngraph,k)
% function ha = fn_subplot(abc)
%---
% if only 3 arguments, nrow and ncol are guessed from ngraphs

% Thomas Deneux
% Copyright 2008-2012

% input
if nargin==1
    abcd = str2num(num2str(varargin{1})'); %#ok<ST2NM>
    switch length(abcd)
        case 3
            varargin = num2cell(abcd);
        case 4
            varargin = num2cell(abcd);
        otherwise
            error argument
    end
end
spacing = 0;
if length(varargin)>=4
    [hf nrow ncol kk] = deal(varargin{1:4});
    if nargin>=5, spacing = varargin{5}; end
else
    [hf ngraph kk] = deal(varargin{:});
    ncol = ceil(sqrt(ngraph));
    nrow = ceil(ngraph/ncol);
end
if ~ishandle(hf), figure(hf), end

% delete annoying axes
info = getappdata(hf,'fn_subplot');
if isempty(info) || info.ncol~=ncol || info.nrow~=nrow
    delete(findobj(hf,'parent',hf,'type','axes')); 
    info = struct('ncol',ncol,'nrow',nrow,'axes',zeros(ncol,nrow));
end

% create new axis or find existing one
ha = zeros(1,length(kk));
for ik=1:length(kk)
    k = kk(ik);
    if info.axes(k) && ishandle(info.axes(k))
        ha(ik) = info.axes(k);
    else
        icol = 1+mod(k-1,ncol);
        irow = 1+floor((k-1)/ncol);
        pos = [(icol-1+spacing/2)/ncol (nrow-irow+spacing/2)/nrow (1-spacing)/ncol (1-spacing)/nrow];
        ha(ik) = axes('parent',hf,'units','normalized','pos',pos);
        info.axes(k) = ha(ik);
    end
end
setappdata(hf,'fn_subplot',info)

% output
if nargout==0
    axes(ha)
    clear ha
end
    