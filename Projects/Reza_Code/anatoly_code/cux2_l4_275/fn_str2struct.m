function par = fn_str2struct(str)
% function par = fn_str2struct(str)
%---
% evaluates cell array of strings or characer array to get a structure
% str can be of the form {'par.x=a', 'par.y=b', ...}, or {'x=a', 'y=b',
% ...}
% 
% See also fn_struct2str, fn_structedit

% Thomas Deneux
% Copyright 2007-2012

% Input
if isempty(str), par = []; return, end
str = cellstr(str);

% Evaluate strings
for HID=1:length(str)
    eval(str{HID})
end

% Make a structure from the result
clear HID str
parname = who;

if length(parname)==1 && isstruct(eval(parname{1}))
    % first form, see help above
    par = eval(parname{1});
else
    % second form
    par = struct;
    for k=1:length(parname)
        par.(parname{k}) = eval(parname{k});
    end
end