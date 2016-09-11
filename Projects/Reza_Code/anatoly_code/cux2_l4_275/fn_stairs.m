function hl = fn_stairs(varargin)
% function hl = fn_stairs([x,]y,...)
%---
% a wrapper for Matlab stairs function that produces more intuitive display
% x can be of the same length as y (centers of time intervals), or have one
% additional element (edges of time intervals)

if nargin<2 || ischar(varargin{2})
    y = varargin{1};
    opt = varargin(2:end);
    if isvector(y), y = column(y); end
    x = (1:size(y,1))';
else
    [x y] = deal(varargin{1:2});
    opt = varargin(3:end);
    if isvector(y), y = column(y); end
    x = column(x);
end
ny = size(y,1);

% modify x and y for more intuitive display
y(end+1,:) = y(end,:);
if length(x)==ny
    x = [x(1); x(1:end-1)+diff(x)/2; x(end)];
elseif length(x)~=ny+1
    error 'x and y do not match'
end

% display
hl = stairs(x,y,opt{:});
if nargout==0, clear hl, end


