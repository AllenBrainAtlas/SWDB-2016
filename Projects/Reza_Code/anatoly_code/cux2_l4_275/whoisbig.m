function whoisbig(varargin)
% function whoisbig([var][,minsize])
%---
% Input:
% - var     a variable or a structure [default: all variables in caller
%           workspace]
% - minsize e.g.: 10M [default], G, 100k, 0

% Input
var = []; minsize = [];
for k=1:length(varargin)
    a = varargin{k};
    if isequal(a,0) || ischar(a)
        minsize = a;
    else
        var = a;
        varname = inputname(k);
        if isempty(minsize)
            w = whos('var');
            totsize = w.bytes;
            minsize = min(10*2^20,totsize/1000);
        end
    end
end
if isempty(minsize), minsize = '10M'; end

%% call 'whos'
if isempty(var)
    % check caller workspace
    w = evalin('caller','whos');
else
    if isstruct(var)
        % check fields of structure
        F = fieldnames(var);
        for i=1:length(F)
            f = F{i};
            eval([f ' = var.' f ';'])
        end
        w = whos(F{:});
    else
        % check variable
        if isempty(varname)
            varname = 'var';
        else
            eval([varname ' = var;'])
        end
        w = whos(varname);
    end
end

%% sort
[bytes ord] = sort([w.bytes]);
w = w(ord);

%% min size
if ischar(minsize)
    tokens = regexpi(minsize,'^([\d.]*)([KMG]{0,1})$','tokens');
    if isempty(tokens), error argument, end
    [n u] = deal(tokens{1}{:});
    minsize = fn_switch(isempty(n),1,str2double(n)) * 2^fn_switch(lower(u),'',0,'k',10,'m',20,'g',30);
end

%% subselect
matlabclasses = {'logical' 'char' 'single' 'double' 'uint8' 'uint16' 'uint32' 'uint64' 'int8' 'int16' 'int32' 'int64' 'struct' 'cell'};
ok = ([w.bytes]>=minsize) | ~ismember({w.class},matlabclasses);
if ~any(ok)
    fprintf('no variable is big (total: %iKB)\n',round(sum([w.bytes])/2^10))
    return
end
w = w(ok);
n = length(w);

%% name
names = char('Name','',w.name);

%% size
s1 = fn_map(@(s)num2str(s(1)),{w.size},'cell');
format = ['%' num2str(max(fn_map(@length,s1))) 'i'];
s1 = char(fn_map(@(s)sprintf('%5i',s(1)),{w.size},'cell'));
s2 = char(fn_map(@(s)fn_strcat(s(2:end),'x','x',''),{w.size},'cell'));
sizes = char('Size','',[s1 s2]);

%% class
classes = char('Class','',w.class);

%% bytes
bytes = [w.bytes];
bk = min(floor(log(bytes)/log(1024)),3);
bs = bytes./(1024.^bk);
mem = cell(1,n);
for i=1:n
    switch bk(i)
        case 0
            mem{i} = num2str(bs(i));
        case 1
            mem{i} = [num2str(round(bs(i))) 'k'];
        case 2
            mem{i} = [num2str(round(bs(i))) 'M'];
        case 3
            mem{i} = [num2str(bs(i),'%.1f') 'G'];
    end
end
ll = fn_map(@length,mem);
L = max(ll);
for i=1:n, mem{i} = [repmat(' ',1,L-ll(i)) mem{i}]; end
mem = char('Memory','',mem{:});

%% space
sp = repmat(' ',2+n,2);

%% display
disp([sp names sp mem sp sizes sp classes])
fprintf('\n')

