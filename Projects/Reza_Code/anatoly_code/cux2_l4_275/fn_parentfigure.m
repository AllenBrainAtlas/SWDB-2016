function hf = fn_parentfigure(obj)
% function hf = fn_parentfigure(obj)
%---
% returns the figure that contains object obj by recursively getting its
% parents

hf = obj;
while ~strcmp(get(hf,'type'),'figure'), hf = get(hf,'parent'); end
