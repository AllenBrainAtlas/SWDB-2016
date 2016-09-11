function B = fn_map(fun,A,varargin)
% function B = fn_map(fun,A[,'columns|rows'][,'array|cell'][,errorval])
% function B = fn_map(A,fun[,'columns|rows'][,'array|cell'][,errorval])
% 
% map function 'fun' 
% to elements [default] / columns / rows of A
%
% output an array or a cell array depending on the flag; if no flag is
% specified, output a vector if all returned values are scalar, a cell
% otherwise
%
% if errorval is specified, errors are caught and the value errorval is
% returned in case of an error
%
% See also fn_isemptyc, fn_itemlengths

% Thomas Deneux
% Copyright 2006-2012

if nargin==0, help fn_map, return, end

% Input
if ~isa(fun,'function_handle')
    [A fun] = deal(fun,A);
end
mode = ''; outtype = 'auto'; manageerror = false;
for k=1:length(varargin)
    a = varargin{k};
    if ischar(a)
        switch a
            case {'columns' 'rows'}
                mode = a;
            case {'array' 'cell'}
                outtype = a;
            otherwise
                manageerror = true;
                errorval = a;
        end
    else
        manageerror = true;
        errorval = a;
    end
end
if iscell(A) && ~isempty(mode)
    error 'the ''columns'' or ''rows'' flags are not applicable on a cell array input'
end

% Handle mode
if ~iscell(A)
    switch mode
        case ''
            A = num2cell(A);
        case 'columns'
            A = num2cell(A,1);
        case 'rows'
            A = num2cell(A,2);
    end
end
s = size(A);

% Any output?
if isempty(A)
    dooutput = (nargout==1);
else
    try
        b = feval(fun,A{1}); %#ok<NASGU>
        dooutput = true;
    catch ME
        if strcmp(ME.identifier,'MATLAB:maxlhs')
            dooutput = false;
        elseif manageerror
            dooutput = true;
        else
            rethrow(ME)
        end
    end
end
if dooutput, B = cell(s); end

% Perform operation
n = numel(A);
for i=1:n
    if manageerror
        if ~dooutput, error 'fn_map cannot manage errors if no output', end
        try
            B{i} = feval(fun,A{i});
        catch %#ok<CTCH>
            B{i} = errorval;
        end
    else
        if dooutput
            B{i} = feval(fun,A{i});
        else
            feval(fun,A{i});
        end
    end
end

% Output: try not to return a cell
switch outtype
    case 'array'
        doarray = true;
    case 'cell'
        doarray = false;
    case 'auto'
        doarray = true;
        for i=1:n
            if ~isscalar(B{i}), doarray = false; break; end
        end
end
if doarray
    try
        B = cell2mat(B);
    catch
        for i=2:n, B{i} = cast(B{i},'like',B{1}); end
        B = cell2mat(B);
    end
end