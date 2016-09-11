function y1 = fn_interp1(x,y,x1)
% function y1 = fn_interp1(x,y,x1)
%---
% currently, x values need to be equally spaced, while x1 values do not
% even need to be monotonous; each y1(i) will be the average of y(k) values
% such that x(k) is closest to x1(i)

% Thomas Deneux
% Copyright 2012-2012

dx = x1(2)-x1(1);
x0 = x1(1);
nx = length(x1);

horiz = (size(y,1)==1);
if horiz, y=y'; end
s = size(y); if s(1)~=length(x), error('dimension mismatch'); end

ii = 1+round((x-x0)/dx);
discard = (ii<1 | ii>nx);
ii(discard) = [];
y(discard,:) = [];

y1 = NaN([nx s(2:end)]);
for i=1:nx
    y1(i,:) = mean(y(ii==i,:),1);
end
if horiz, y1=y1'; end