function y = fn_coerce(x,m,M)
% function y = fn_coerce(x,m,M)
%---
% y = min(max(x,m),M);

% Thomas deneux
% Copyright 2002-2012

if nargin==2,
    M = m(2);
    m = m(1);
end
y = min(max(x,m),M);
