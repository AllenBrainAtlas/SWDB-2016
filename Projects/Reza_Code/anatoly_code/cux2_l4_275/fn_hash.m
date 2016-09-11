function h = fn_hash(inp,varargin)
% function h = fn_hash(input[,meth][,'char|hexa|HEXA|num'][,n])
%---
% This function relies on function hash.m downloaded on Matlab File
% Exchange.
% It extends hash functionalities to structures and cell arrays
% default method 'MD2' is used, input 'n' outputs n letters
% 
% Input:
% - input   Matlab numerical array, cell array, or structure; subelements
%           of cell arrays and structures must themselves be numerical
%           arrays, cell arrays or structures
% - meth    methods, default is 'MD2', see function brick/private/hash.m
% - outtype 'char', 'hexa' or 'num' - indicates whether output will be a
%           number or a word [default='char']
% - n       number of digits of the hexadecimal hash number to return; if
%           n=0, the default value is used (depends on method)
%
% Output:
% - h       the hash key corresponding to input; its value, type and length
%           are controled by parameters meth, outtype and n
%   
% Note that structures with fields in different order give the same hash
% key.

% Michael Kleder (function hash.m)
% Copyright 2005-2012
% Thomas Deneux
% Copyright 2007-2012

if nargin==0, help fn_hash, return, end

meth = 'MD2'; n = 0; outtype = 'char';
for i=1:length(varargin)
    a = varargin{i};
    if ischar(a)
        if fn_ismemberstr(a,{'char' 'hexa' 'HEXA' 'num'})
            outtype = a;
        else
            meth = a;
        end
    else
        n = a;
    end
end

if isempty(inp), inp = class(inp); end
if isnumeric(inp) || islogical(inp) || ischar(inp)
    h = hash(inp,meth);
else
    % transform object into cell array with numeric / character type elements
    if isstruct(inp) || isobject(inp)
        inp = orderfields(struct(inp));
        F = fieldnames(inp);
        C = struct2cell(inp);
        C = [F(:); C(:)];
    elseif iscell(inp)
        C = inp(:);
    else
        error('cannot hash object of class ''%s''',class(inp))
    end
    C = cat(1,C,{class(inp); size(inp)});
    
    % hash each element of the cell array
    h = cell(1,numel(C));
    for i=1:numel(C)
        h{i} = fn_hash(C{i},meth);
    end
    
    % hash the concatenation of all hash results
    h = hash([h{:}],meth);
end

% crop to n digits
if n, h = h(1:n); end

% convert output
switch outtype
    case 'hexa'
        % nothing to do
    case 'HEXA'
        h = upper(h);
    case 'char'
        f = (h>='0' & h<='9');
        h(f) = h(f)-'0'+'A';
        h(~f) = h(~f)-'a'+'K';
    case 'num'
        h = hex2dec(h);
end

