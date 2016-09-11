function fn_watch(hf,flag)
% function fn_watch(hf[,'startnow|start|stop'])

% Thomas Deneux
% Copyright 2012-2012

if nargin<2, flag = 'startnow'; end

switch flag
    case {'startnow' 'on'}
        setappdata(hf,'fn_watch','busy')
        startwatch(hf)
    case 'start'
        if isappdata(hf,'fn_watch'), return, end
        setappdata(hf,'fn_watch','busy')
        % the timer object should not be stored in a local variable,
        % otherwise it would remain in memory forever...
        start(timer( ...
            'timerfcn',     @(u,e)startwatch(hf), ...
            'startdelay',   .5 ...
            )); 
    case {'stop' 'off'}
        if isappdata(hf,'fn_watch'), rmappdata(hf,'fn_watch'), end
        set(hf,'pointer','arrow')
end
    

%---
function startwatch(hf)

if isappdata(hf,'fn_watch')
    set(hf,'pointer','watch')
    drawnow
end
