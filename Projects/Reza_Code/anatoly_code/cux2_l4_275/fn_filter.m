function y=fn_filter(X0,y,highpassflag)
% function y=fn_filter(X0,y[,highpassflag])
%---
% remove confound subspace defined by the matrix X0 to y :
% y = y - X0*X0'*y
% if y is a vector, returns column or row vector according to input
% if y is a matrix, filter is applied to columns
% if highpassflag is set to false [default=true], only the confounds are kept

% Thomas Deneux
% Copyright 2005-2012

if ~isempty(X0)
    if size(y,1)==size(X0,1)
        c = X0*(X0'*y);
    else
        warning fn_filter(X0,y) applied along columns instead of rows
        c = (y*X0)*X0';
    end
    if nargin<3 || highpassflag, y=y-c; else y=c; end
else
    if nargin>=3 && ~highpassflag, y=zeros(size(y)); end
end
