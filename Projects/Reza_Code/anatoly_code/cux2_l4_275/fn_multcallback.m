function fn_multcallback(hobj,evnt,varargin)
% function fn_multcallback(hobj,evnt,fun1,fun2,...)
%---
% this will evaluate fun1(hobj,evnt), fun2(hobj,evnt) ...

% Thomas Deneux
% Copyright 2005-2012

funs = varargin;
for k=1:length(funs)
    fun = funs{k};
    switch class(fun)
        case 'function_handle'
            fun(hobj,evnt);
        case 'cell'
            feval(fun{1},hobj,evnt,fun{2:end})
        case 'char'
            evalin('base',fun)
        otherwise
            error('callback must be a string, a function handle or a cell array')
    end
end

