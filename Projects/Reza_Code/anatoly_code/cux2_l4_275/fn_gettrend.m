function [trend, X, beta] = fn_gettrend(y,varargin)
% function [trend X beta] = fn_gettrend(y[,ind][,order][,options])
%---
% Estimates a slow trend for y
% it is possible to estimate it based on given indices only
% 
% Inputs:
% - y       signal
% - ind     indices where there is supposed to be equal to baseline
% - order   number of low-frequency regressors
% - 'otherbase',indbis      indices where the signal is supposed to be on a
%                           plateau value
%
% Exemple:
%
% signal = [zeros(1,200) -[1:100]/100.*sin([1:100]/100*(3*pi/2)) ...
%     ones(1,300)  1+[1:100]/100.*sin([1:100]/100*(3*pi/2)) zeros(1,300)]';
% noise = fn_filt(1/2-rand(1000,1),200,'lm')*100;
% y = signal + noise;
% figure(1), plot([signal noise y])
% legend('signal','noise','noisy signal')
% % estimation of trend; we assume that the signal is equal to baseline for
% % indices 1:150 and 750:1000
% trend = fn_gettrend(y,[1:150 750:1000],6,'otherbase',350:550);
% figure(2), plot([trend noise y-trend signal])
% legend('estimated noise','noise','estimated signal','signal')% signal = [zeros(1,200) -[1:100]/100.*sin([1:100]/100*(3*pi/2)) ...

% Thomas Deneux
% Copyright 2004-2012

if nargin==0, help fn_gettrend, return, end

if size(y,1)==1, tflag=true; y=y'; else tflag=false; end
ny = size(y,1);
oflag = false;
k=1;
while k<=nargin-1
    a = varargin{k};
    if ischar(a)                % option 
        switch a
            case 'otherbase'    % 'otherbase' -> indices � utiliser
                k = k+1;
                oflag = true;
                indbis = varargin{k};
            otherwise
                error('unknown option')
        end
    elseif length(a)==1         % scalaire -> ordre du filtrage
        order=a; 
    else                        % indices � utiliser
        ind=a;
    end
    k = k+1;
end
if ~exist('ind','var'), ind=1:ny; end
if ~exist('order','var'), order=2; end
if oflag, ind = union(ind, indbis); end

% regressor
X = ones(ny,order);                     % premier r�gresseur = constante
if order>1                              % second = drift lin�aire
    X(:,2) = (.5-ny/2:ny-ny/2-.5)'/(ny/2);
end         
for k=3:order                           % suivants = base trigonom�trique
    X(:,k) = cos(pi*(2*(0:ny-1)'+1)*(k-1)/(2*ny));
end
if oflag, X(indbis,order+1) = 1; end    % r�gresseur sp�cial = un cr�neau

% regression
beta = pinv(X(ind,:))*y(ind,:);
trend = X(:,1:order)*beta(1:order,:);

% Output
if tflag, trend=trend'; end

