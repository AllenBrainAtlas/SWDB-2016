function fn_structexplore(X)
% function fn_structexplore(X)
% Explores recursively the content of a structure
% - X        structure or structure name

% Thomas Deneux
% Copyright 2004-2012

if ischar(X)
    Xname = X;
    X = evalin('caller',Xname);
else
    Xname = inputname(1);
end

% display name and value
Xoldnames = {};
disp([Xname ' :'])
disp(X)

% loop
while true
    str = ['[type fieldname, integer, ., .. or command] '];
    a = input(str,'s');
    
    % end
    if strcmp(a,'quit') || strcmp(a,'exit')
        return
    end
    
    % exit while
    if strcmp(a,'..'), 
        if isempty(Xoldnames), return, end
        Xname = Xoldnames{end};
        Xoldnames = {Xoldnames{1:end-1}};
        X = evalin('caller',Xname);
        disp([Xname ' :'])
        disp(X)
        continue
    end
    
    % display current structure
    if strcmp(a,'.'), 
        disp([Xname ' :'])
        disp(X)
        continue
    end
    
    % display one element of multiple structure (recursion)
    k=str2num(a);
    if ~isempty(k) && length(k)==1 && k>0 && k<=length(X)
        Xoldnames{end+1} = Xname;
        Xname = [Xname '(' num2str(k) ')'];
        X = evalin('caller',Xname);
        disp([Xname ' :'])
        disp(X)
        continue
    end
    
    % display one field of the structure (recursion)
    if isfield(X,a) && length(X)==1
        Xname2 = [Xname '.' a];
        X2 = evalin('caller',Xname2);
        if isstruct(X.(a)) || isobject(X.(a))
            Xoldnames{end+1} = Xname; 
            Xname = Xname2; X = X2;
        end
        disp([Xname2 ' :'])
        disp(X2)
        continue
    end
    
    % allow evaluation of user commands
    a = strrep(a,'this',Xname);
    a = strrep(a,'$',[Xname '.']);
    try
        evalin('caller',a)
        X = evalin('caller',Xname);
    catch
        disp(lasterr)
    end
end

