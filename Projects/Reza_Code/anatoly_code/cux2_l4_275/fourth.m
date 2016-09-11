function x = fourth(x)
%---
% reshape x to a fourth-dimension vector
%
% See also column, row, third, matrix

x = shiftdim(x(:),-3);