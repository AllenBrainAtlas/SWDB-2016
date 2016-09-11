%% Autocalibration demo
% This script demonstrates on simulated data how to use the MLspike and
% autocalibration algorithms. To see how to run the algorithms, go directly
% to section 'Spike estimation'. 


%% Random A and tau, and random level of noise
% We draw randomly the parameters governing the calcium dynamics A (DF/F
% amplitude for one spike) and tau (decay time constant), as well as the
% level of noise in the data, sigma.

amin = .04;
amax = .1;
a = amin * exp(rand(1)*log(amax/amin)) % log-uniform distribution 

taumin = .4;
taumax = 1.6;
tau = taumin * exp(rand(1)*log(taumax/taumin))

sigmamin = .005;
sigmamax = .05;
sigma = sigmamin * exp(rand(1)*log(sigmamax/sigmamin))

% SAMPLING RATE
dt = .0333; % 50Hz acquisition


%% Spike estimation (using naive parameters)
% We first apply the MLspike algorithm using some fixed parameters.
% To run the algorithm on other data, set variable 'calcium' as a vector
% time courses of the calcium signal if there is only one trial, or to a cell
% array of such time courses if there are many trials.

% parameters
% (get the default parameters)
par = tps_mlspikes('par');
% (indicate the frame duration of the data)
par.dt = dt;
% (set physiological parameters)
par.a = 0.07; % DF/F for one spike
par.tau = 1; % decay time constant (second)
par.saturation = 0.1; % OGB dye saturation
% (set noise parameters)
par.finetune.sigma = .02; % a priori level of noise (if par.finetune.sigma
                          % is left empty, MLspike has a low-level routine 
                          % to try estimating it from the data
par.drift.parameter = .01; % if par.drift parameter is not set, the 
                           % algorithm assumes that the baseline remains
                           % flat; it is also possible to tell the
                           % algorithm the value of the baseline by setting
                           % par.F0
% (do not display graph summary)
par.dographsummary = false;
%%



%% Auto-calibration
% Now we want to estimate the original spikes from the calcium signals
% rather than using fixed parameter.
% First we run the autocalibration algorithm to attempt estimating, from
% the calcium signals directly, the values of parameters A, tau and sigma.

% parameters
% (get default parameters and set frame duration)
pax = spk_autocalibration('par');
pax.dt = dt;
% (set limits for A and tau)
pax.amin = amin;
pax.amax = amax;
pax.taumin = taumin;
pax.taumax = taumax;
% (set saturation parameter)
pax.saturation = 0.1;
% (give real values to the algorithm for display purposes - they obviously won't be used in the estimation!)

%pax.realspikes = spikes;
%pax.reala = a;
%pax.realtau = tau;
% (when running MLspike from spk_autocalibratio, do not display graph summary)
pax.mlspikepar.dographsummary = false;

% perform auto-calibration
[tauest aest sigmaest] = spk_autocalibration(calcium,pax)

%%
% The above graphs illustrate some steps of the performed autocalibration.
% As can be seen, estimated values for A and tau are pretty close to the
% real values used for the simulation. 
% The estimated value for sigma is generally lower that the original sigma:
% this is normal, as the MLspike generally performs best when it uses a
% value for sigma slightly lower than the real one (using the real one
% tends to generate more misses).

%% Spike estimation (using autocalibrated parameters)
% After this autocalibration we can apply the MLspike algorithm by using
% the autocalibrated parameters. 

% parameters
par = tps_mlspikes('par');
par.dt = dt;
% (use autocalibrated parameters)
par.a = aest;
par.tau = tauest;
par.finetune.sigma = sigmaest;
% (the OGB saturation and drift parameters are fixed)
par.saturation = 0.1;
par.drift.parameter = .01;
% (do not display graph summary)
par.dographsummary = false;

% spike estimation
[spikest fit drift] = spk_est(calcium,par);

% display
figure(2)
spk_display(dt,{spikes spikest},{calcium fit drift})
set(2,'numbertitle','off','name','Auto-calibration + MLspike')

%% 
% Spikes estimated in such a way now match the original spikes with a lower
% error rate. 
