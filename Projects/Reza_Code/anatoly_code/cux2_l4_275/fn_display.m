function fn_display(varargin)
% function fn_display(x[,format])
% function fn_display(varname,x[,format])
%---
% Fast display of variable

if nargin==0, help fn_display, return, end

% Input
xname = []; x = []; format = [];
for i=1:nargin
    a = varargin{i};
    if isnumeric(a)
        x = a;
    elseif any(a=='%')
        format = a;
    elseif isempty(xname)
        xname = a;
    elseif isempty(x)
        x = evalin('caller',a);
    end
end
if isempty(xname)
    xname = inputname(1);
elseif isempty(x)
    x = evalin('caller',xname);
end

% Display
if isempty(format)
    disp([xname ': ' num2str(x)])
else
    disp([xname ': ' num2str(x,format)])
end

       