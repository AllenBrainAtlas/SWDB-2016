function x = fn_readxmllabview(fname)
% function x = fn_readxmllabview(fname)

% Thomas Deneux
% Copyright 2008-2012

if nargin==0
    fname = fn_getfile('*.xml');
end

Pref = struct('Str2Num',false);
s = fn_readxml(fname,Pref);
if isfield(s,'Version')     % this is the normal case
    s = rmfield(s,{'Version','ATTRIBUTE'});
    F = fieldnames(s);
    if length(s)~=1 || length(F)~=1, error programming; end
    type = F{1};
    x = xml2mat(type,s.(type));
else                        % when called from tps_readacqsettingsxml
    type = 'Cluster';
    x = xml2mat(type,s);
end    
    
%---
function x = xml2mat(type,s)

switch type
    case 'String'
        x = s.Val;
    case 'Boolean'
        x = (s.Val=='1');
    case {'DBL','I32'}
        x = str2double(s.Val);
    case 'Cluster'
        x = struct;
        s = rmfield(s,{'Name','NumElts'});  % structure with fields = type names
        F = fieldnames(s);
        for i=1:length(F)
            type1 = F{i};
            s1 = s.(type1);                 % structure array with elements of the same type
            for j=1:length(s1)
                name = s1(j).Name;
                idx = ismember(name,' ().');
                name(idx) = [];
                x.(name) = xml2mat(type1,s1(j));
            end
        end
    case 'Array'
        n = s.Dimsize;
        s = rmfield(s,{'Name','Dimsize'});
        F = fieldnames(s);
        if length(s)~=1 || length(F)~=1, error programming; end
        type1 = F{1};
        s1 = s.(type1);
        for j=1:length(s1)
            x(j) = xml2mat(type1,s1(j));
        end
    otherwise
        error(['unknown labview type ''' type ''', please edit code'])
end
            
        




