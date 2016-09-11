
load('ca_corr_expID_511510667.mat');


%% Loop over all cells

parfor j=2:1:size(A,2)

dt=0.0333;             % sampling rate in time steps    
    
% Calibration of parameters for a given Ca trace

calcium=A(2:length(A),j);
% length(A)

calcium = calcium/mean(calcium);

%% Auto-calibration only of parameter sigma

psig = spk_autosigma('par');
sigma = spk_autosigma(calcium,dt,psig)


% Estimation with MLspike with parameters set manually (except sigma)

% parameters
par = tps_mlspikes('par');

% (do not display graph summary)
par.dographsummary = false;

% time constant
par.dt = dt;

% physiological parameters
par.a = 0.034;
par.tau = 0.76;
par.pnonlin = [0.85 -0.006];

% noise and drift
par.finetune.sigma = sigma; % not that if you ommit this line, sigma would be estimated anyway by MLspike calling spk_autosigma
par.drift.parameter = .01;

% spike estimation
[spikest fit drift] = spk_est(calcium,par);

% save estimated spike times, ONLY!
parsave(sprintf('%d.mat',j-2),spikest, fit, drift,calcium,dt);


%spk_display(dt,{spikest},{calcium fit drift})
%set(gca,'Fontsize',20)
%title('ML spike')


end

%%