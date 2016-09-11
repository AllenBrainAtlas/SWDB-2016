function f = fn_fullfile(d,f)
% function f = fn_fullfile(d,f)

f = fn_map(@(x)fullfile(d,x),f);
