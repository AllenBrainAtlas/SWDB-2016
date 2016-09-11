function varargout = fn_fit(x,y,fun,startpoint)
% function [par1 ... parN yfit] = fn_fit(x,y,@(x,par1,..,parN)fun,startpoint)
% function [a b yfit] = fn_fit(x,y,'affine')


% Thomas Deneux
% Copyright 2008-2012

if nargin==0, help fn_fit, return, end

if ~any(size(x)==1), error('x must be a vector'), end
x =  x(:);
nx = length(x);
if size(y,1)==1, y=y'; end

% Special cases
if ischar(fun)
    switch fun
        case 'affine'
            A = [x ones(nx,1)];
            ab = A\y;
            varargout = {ab(1) ab(2) A*ab};
            return
    end
end

% General case
opt = optimset('display','iter','algo','active-set');

proto = regexp(func2str(fun),'@\([^\)]*\)','match');
npar = sum(proto{1}==',');
if length(startpoint)~=npar, error 'starting point lengh does not match the number of parameters', end

% pars = fmincon(@(p)energy(x,y,fun,p),startpoint,[],[],[],[],[],[],[],opt);
pars = fminunc(@(p)energy(x,y,fun,p),startpoint,opt);
[e fit] = energy(x,y,fun,pars); %#ok<ASGLU>
varargout = [num2cell(pars) fit];

%---
function [e ypred] = energy(x,y,fun,p)

c = num2cell(p);
ypred = column(fun(x,c{:}));
d = y-ypred;
e = norm(d);

% % OLDER VERSION
% if ischar(m)
%     m = fittype(m);
% end
% 
% opt = fitoptions('method','NonlinearLeastSquares','startpoint',startpoint);
% 
% nk = size(y,2);
% fx = cell(1,nk);
% for k=1:nk
%     yk = y(:,k);
%     fx{k} = fit(x,yk,m,opt);
% end
% 
% if nk==1, fx = fx{1}; end