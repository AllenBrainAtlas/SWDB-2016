function str = fn_struct2str(par,parname,varargin)
% function str = fn_struct2str(par[,parname[,'cell'])
%---
% Input:
% - par             structure
% - parname         name (use inputname(1) or 'x' if not specified)
% - 'cell' flag     returns a cell array of srings instead of a character
%                   array
%
% Output:
% - str         character array which fills the structure with values
%
% ex: par = struct('a',2,'b','hello'); fn_struct2str(par,'x')
%   returns: 
%     x.a = 2;
%     x.b = hello
%
% See also fn_str2struct, fn_structedit

% Thomas Deneux
% Copyright 2007-2012

% Input
if isempty(par), str = ''; return, end
if ~isstruct(par) || ~isscalar(par), error('input should be a scalar structure'), end
if nargin<2, parname = inputname(1); end
if isempty(parname), parname = 'x'; end
docell = fn_flags('cell',varargin);

% Build character array
F = fieldnames(par);
str = cell(length(F),1);
for k=1:length(F)
    f = F{k};
    val = par.(f);
    switch class(val)
        case 'char'
            if size(val,1)>1, error('cannot display multiple-line string'), end
            st = ['''' val ''''];
        case {'double','logical'}
            if ndims(val)>2 || numel(val)>15
                error('cannot display array with more than 2 dimensions or 15 elements')
            end
            st = num2str(val);
            if ~isscalar(val)
                st(:,end+1) = ';'; st(:,end+1) = ' '; %#ok<AGROW>
                st = reshape(st',1,numel(st));
                st(end-1:end) = [];
                st = regexprep(st,' *',' ');
                st = ['[' st ']']; %#ok<AGROW>
            end
        case 'cell'
            if size(val,1)>1, error('cannot display cell array which are not row vector'), end
            st = '{ ';
            for i=1:length(val)
                val2 = val{i};
                switch class(val2)
                    case 'char'
                        if size(val2,1)>1, error('cannot display multiple-line string'), end
                        st2 = ['''' val2 ''''];
                    case {'double','logical'}
                        if ndims(val2)>2 || numel(val2)>15
                            error('cannot display array with more than 2 dimensions or 15 elements')
                        end
                        st2 = num2str(val2);
                        if ~isscalar(val2)
                            st2(:,end+1) = ';'; st2(:,end+1) = ' '; %#ok<AGROW>
                            st2 = reshape(st2',1,numel(st2));
                            st2(end-1:end) = [];
                            st2 = regexprep(st2,' *',' ');
                            st2 = ['[' st2 ']']; %#ok<AGROW>
                        end
                    otherwise
                        error('cannot display object of class ''%s''',type)
                end
                st = [st st2 ' ']; %#ok<AGROW>
            end
            st(end) = '}';
        otherwise
            error('cannot display object of class ''%s''',type)
    end
    str{k} = [parname '.' f ' = ' st ';'];
end
str = strvcat(str{:}); %#ok<VCAT>

if docell, str = cellstr(str); end

