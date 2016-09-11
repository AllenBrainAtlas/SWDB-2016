function lisse = fn_smooth(t,sigma)
% function lisse = fn_smooth(t,sigma)
% lissage isotropique (par une gaussienne) 1D ou 2D
% - sigma   param�tre de la gaussienne

% Thomas Deneux
% Copyright 2005-2012

s = size(t);

if (length(s)>2), error('dimension>2 not handled'); end

l = ceil(4*sigma);
ll = 2*l+1;

if (s(1)==1) % vecteur ligne
    g = fspecial('gaussian',[1 ll],sigma);
    u = ones(s);
    tt = conv(t,g);
    uu = conv(u,g);
    tt = tt ./ uu;
    lisse = tt(1,(1+l):(end-l));
elseif (s(2)==1) %vecteur colonne
    g = fspecial('gaussian',[ll 1],sigma);
    u = ones(s);
    tt = conv(t,g);
    uu = conv(u,g);
    tt = tt ./ uu;
    lisse = tt((1+l):(end-l));
else %matrice
    g = fspecial('gaussian',[ll ll],sigma);
    u = ones(s);
    tt = conv2(t,g);
    uu = conv2(u,g);
    tt = tt ./ uu;
    lisse = tt((1+l):(end-l),(1+l):(end-l));
end
 





    
    
    