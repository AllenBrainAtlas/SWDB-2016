function y = fn_ls(varargin)
% function y = fn_ls(pattern)
%---
% List files inside directory

% Thomas Deneux
% Copyright 2009-2012


y = dir(varargin{:});
y = {y.name};