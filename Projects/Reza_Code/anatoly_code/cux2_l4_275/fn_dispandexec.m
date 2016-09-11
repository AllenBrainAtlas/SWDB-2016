function fn_dispandexec(c)
% function fn_dispandexec(commands)
%--
% display and execute commands (a string or a cell array of strings)
% Note that all '$' signs are replaced by blanks ' '.

% Thomas Deneux
% Copyright 2011-2012

if ~iscell(c), c={c}; end
for k=1:length(c), c{k} = strrep(c{k},'$',' '); disp(c{k}), end
for k=1:length(c), evalin('base',c{k}), end