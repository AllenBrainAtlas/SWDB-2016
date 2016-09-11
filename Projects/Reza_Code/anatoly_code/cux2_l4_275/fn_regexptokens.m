function tokens = fn_regexptokens(a,expr)
% function tokens = fn_regexptokens(a,expr)
%---
% a wrapper of regexp that returns the tokens in a string where expression
% 'expr' is assumed to occur only zero or one time
% returns the unique token if there is only one, or a cell array of tokens
% if there are several

tokens = regexp(a,expr,'tokens');
tokens = tokens{1};
if isscalar(tokens), tokens = tokens{1}; end