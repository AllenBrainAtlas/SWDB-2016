function s = fn_structinit(varargin)
% function s = fn_structinit(siz)
% function s = fn_structinit(n1,n2,...)
%---
% Initializes a structure with no fields and of size siz.
% If size is a scalar n, the structure will be a row vector of length n.

% input
if nargin==1
    siz = varargin{1};
else
    siz = [varargin{:}];
end
if isscalar(siz), siz = [1 siz]; end

% initialize structure using a dum trick
s = cell2struct(cell([0 siz]),{});
