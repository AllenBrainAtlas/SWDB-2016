
% SCRIPTLOOP is a very tricky script that helps looping over a given script
% while changing some parameters.
%
% Example script calling SCRIPTLOOP (this example is provided in 
% [Brick toolbox dir]/examples/example_scriptloop.m):
%
% % define the sets of parameters
% parameters = struct( ...
%     'session',  {{'one' 'two'}}, ...
%     'speed',    [1 2 4]);
% 
% % special call to scriptloop
% % (setting loopstart is optional; it is useful whenever we want to
% % restart the loop when it has been interrupted; note that the variable
% % 'kloop' indicates at which iteration the interruption occured) 
% loopstart = 1;
% scriptloop
% 
% % The order in which parameters are set matters!! Indeed, it is assumed
% % that, if only 'speed' changes, then it is possible to avoid doing the
% % calculations associated to 'session' again.
% if sessionchanged
%     basename = [session '_'];
% end
% 
% fullname = [basename num2str(speed)];
% disp(fullname)

% caller
stack = dbstack;
if length(stack)==4, return, end % recursive call!
caller = stack(2).name;

% parameters
F = fieldnames(parameters);
npar = length(F);
nvalperpar = zeros(1,npar);
sets = struct;
nset = 1;
for kpar=npar:-1:1
    f = F{kpar};
    parsk = parameters.(f);
    nk = length(parsk);
    nvalperpar(kpar) = nk;
    sets = repmat(sets,1,nk);
    for i=1:nk
        if iscell(parsk), vali = parsk{i}; else vali = parsk(i); end
        [sets((i-1)*nset+(1:nset)).(f)] = deal(vali);
    end
    nset = nset*nk;
end

% parameter changes
for kpar=1:npar
    f = [F{kpar} 'changed'];
    period = prod(nvalperpar(kpar+1:end));
    [sets.(f)] = deal(false);
    [sets(1:period:end).(f)] = deal(true);
end

% now iteratively call the calling script
V = fieldnames(sets);
if ~exist('loopstart','var'), loopstart = 1; end
for kloop=loopstart:nset
    setk = sets(kloop);
    fprintf('\n[');
    for i=1:2*npar
        f = V{i};
        val = setk.(f);
        assignin('base',f,val)
    end
    for i=1:npar
        f = F{i};
        val = setk.(f);
        fprintf('%s=%s, ',f,fn_switch(ischar(val),val,num2str(val)));
    end
    fprintf('\b\b]\n\n');
    % call the calling script, except if kloop==nset, (in this case
    % scriptloop will return and the rest of the calling script will be
    % executed with the last parameters set)
    if kloop~=nset, eval(caller), end 
end

