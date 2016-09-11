function fn_scatterbin(xvalues,yvalues,xbinsize,varargin)
% function fn_scatterbin(xvalues,yvalues,xbinsize[,'log'])
%---
% Display scatter plot, and averages per bin on top of it
%
% Input:
% - xvalues, yvalues    data
% - xbinsize            size of xbin
% - 'log'               use a logarithmic scale

% Input and sizes
xvalues = xvalues(:);
nx = length(xvalues);
yvalues = yvalues(:);
if length(yvalues)~=nx, error 'size of ydata does not match size of xdata', end

% Locarithmic scale?
dolog = nargin>=4 && strcmp(varargin{1},'log');
if dolog
    xbinsize = log10(xbinsize);
    xval = log10(xvalues);
else
    xval = xvalues;
end

% Create bins
x0 = min(xval);
ix = floor((xval-x0)/xbinsize)+1;
ix(isinf(ix)) = NaN;
nbin = max(ix);

% Fill-in the summary vector
yy = zeros(nbin,1);
if nbin<nx
    for i=1:nbin
        yy(i) = mean(yvalues(ix==i));
    end
else
    nn = zeros(nbin,1);
    for i=1:nx
        ixi = ix(i);
        nn(ixi) = nn(ixi)+1;
        yy(ixi) = yy(ixi)+yvalues(i);
    end
    yy = yy./nn;
end

% Display
plot(xvalues,yvalues,'.','color',[1 1 1]*.9)
xx = column(repmat(x0+(0:nbin)*xbinsize,2,1));
if dolog, xx = 10.^xx; end
yy = [NaN; column(repmat(yy',2,1)); NaN];
line(xx,yy)


