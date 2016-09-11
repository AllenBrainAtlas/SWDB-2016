function x = third(x)
%---
% reshape x to a third-dimension vector
%
% See also column, row, matrix

x = shiftdim(x(:),-2);