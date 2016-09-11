function y = fn_decale(x,n,dt)
% function y = fn_decale(x,n[,dt])
%---
% decale le signal x de n*dt (vers la droite si n>0) 
% n peut etre un vecteur, auquel cas c'est la somme des signaux decales
% dt vaut 1 par defaut

% Thomas Deneux
% Copyright 2003-2012

% input
tflag = (size(x,1)==1);
if (tflag) x=x'; end
if exist('dt','var'), n = n/dt; end
n = round(n);

% decalages
y = zeros(size(x));
for k=n
    if k>0
        y(1+n:end,:)=y(1+n:end,:)+x(1:end-n,:);
    else
        y(1:end+n,:)=y(1:end+n,:)+x(1-n:end,:);
    end
end

% output
if (tflag) y=y'; end
