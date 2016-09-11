function y=fn_mult(u,v,varargin)
% function y=fn_mult(u,v,...)
%----
% tool to multiply a matrix row- or column-wise
% ex: y = fn_mult(rand(3,4),(1:3)')
%     y = fn_mult(rand(5,2,5),shiftdim(ones(5,1),-2))
%
% See also fn_add, fn_subtract, fn_div

% Thomas Deneux
% Copyright 2002-2012

y = bsxfun(@times,u,v);
for i=1:length(varargin), y = bsxfun(@times,y,varargin{i}); end

    