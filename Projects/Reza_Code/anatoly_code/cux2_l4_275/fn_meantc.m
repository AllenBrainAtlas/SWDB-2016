function y = fn_meantc(x,dosqueeze)
% function y = fn_meantc(x,dosqueeze)
%---
% returns the average time course of a movie
%
% Input:
% - x           array with 3 or dimensions (x*y*time*...) - the data
% - dosqueeze   boolean - if true [default], the average is squeeze so that
%               time becomes the first dimension; otherwise time remains
%               the 3rd dimension and first 2 dimensions are singletons
%
% Output:
% - y           spatial average of x

% Thomas Deneux
% Copyright 2006-2012

if nargin==0, help fn_meantc, return, end

% input
if nargin<2, dosqueeze = true; end

s = size(x);
x = reshape(x,[s(1)*s(2) s(3:end)]);
y = mean(x,1);
y = shiftdim(y,fn_switch(dosqueeze,1,-1));