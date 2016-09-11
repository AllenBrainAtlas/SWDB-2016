function b = fn_interprows(a,subrate,method,extrap)
% function b = fn_interprows(a,subrate[,method[,extrap]])
%---
% interpolate to account for delays between different rows 
% demultiply frames according to subrate [default=1]
% method and extrap arguments are as for interp1 function

% Thomas Deneux
% Copyright 2006-2012

if nargin<2, subrate = 1; end
if nargin<3, method = 'linear'; end
if nargin<4, extrap = 'extrap'; end
[nx ny nt] = size(a);

rowtime = fn_add(1:nt,(0:ny-1)'/ny);

b = zeros(nx,ny,subrate,nt);
for k = 1:subrate
    for i = 1:ny
        tmp = permute(a(:,i,:),[3 1 2]);
        tmp = interp1(rowtime(i,:),tmp,(1:nt)+(k-1)/subrate,method,extrap);
        b(:,i,k,:) = permute(tmp,[2 3 4 1]);
    end
end
b = reshape(b,[nx ny subrate*nt]);
        
