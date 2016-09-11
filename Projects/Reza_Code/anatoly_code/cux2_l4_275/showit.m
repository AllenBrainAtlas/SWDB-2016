function x = showit(x)
% function x = showit(x)
%---
% this function returns its input, but also displays it before

if isnumeric(x) && isscalar(x)
    fprintf('%s = %g\n',inputname(1),x)
else
    disp(x)
end