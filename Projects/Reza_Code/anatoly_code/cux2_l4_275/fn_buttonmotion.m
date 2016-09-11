function varargout = fn_buttonmotion(fun,varargin)
% function varargout = fn_buttonmotion(fun[,hf][,'doup'][,'pointer',pointer])
% function fn_buttonmotion('demo')
%---
% utility for executing a task while mouse button is pressed
% 
% See also fn_moveobject

% Thomas Deneux
% Copyright 2007-2012

% Note on the implementation: unfortunately, it is not possible to simply
% use the figure 'BusyAction' and 'Interruptible' properties. Indeed, they
% act on all callbacks, whereas we would like to treat differently the
% motion callbacks (cancel if system is busy) and the button press
% callbacks (queue if system is busy).

if nargin==0, help fn_buttonmotion, return, end


disp_if_debug('entering fn_buttonmotion function')

% Input
if ischar(fun) && strcmp(fun,'demo')
    demo()
    return
end
hf = []; doup = (nargout>0); pointer = '';
k = 0;
while k<length(varargin)
    k = k+1;
    a = varargin{k};
    if ischar(a)
        switch a
            case 'doup'
                doup = true;
            case 'pointer'
                k = k+1;
                pointer = varargin{k};
            otherwise
                error 'unknown flag'
        end
    else
        hf = a;
    end
end
if isempty(hf), hf = gcf; end

% Already an existing callback!
if ~isempty(get(hf,'WindowButtonMotionFcn')) ...
        ||  ~isempty(get(hf,'WindowButtonUpFcn'))
    disp_if_debug('Problem! WindowButtonMotionFcn already set to: ',get(hf,'WindowButtonMotionFcn'))
    disp_if_debug('Problem! WindowButtonUpFcn already set to:     ',get(hf,'WindowButtonUpFcn'))
    terminate(hf)
    warning('a WindowButtonMotionFcn, DownFcn or UpFcn property is already set to figure') %#ok<WNTAG>
end
okdown = isempty(get(hf,'WindowButtonDownFcn'));

% Motion
disp_if_debug('current WindowButtonMotionFcn is: ',get(hf,'WindowButtonMotionFcn'),', setting now to @motionexec')
set(hf,'WindowButtonMotionFcn',{@motionexec 'move' fun}, ...
    'WindowButtonUpFcn',{@motionexec 'stop'})
if ~isempty(pointer)
    curpointer = get(hf,'pointer');
    set(hf,'pointer',pointer)
end
if okdown, set(hf,'WindowButtonDownFcn',{@motionexec 'stop2'}), end
setappdata(hf,'fn_buttonmotion_scrolling',true)
disp_if_debug('waiting for motion end')
waitfor(hf,'WindowButtonMotionFcn','')
if okdown, set(hf,'WindowButtonDownFcn',''), end

% Button release
if ~ishandle(hf), return, end % figure has been closed in the mean while
setappdata(hf,'fn_buttonmotion_scrolling',false)
if ~isempty(pointer), set(hf,'pointer',curpointer); end
if doup, [varargout{1:nargout}] = exec(fun); end
rmappdata(hf,'fn_buttonmotion_scrolling') 

%---
function motionexec(hf,evnt,actionflag,fun)

persistent kid
if isempty(kid), kid = 0; end
kid = fn_mod(kid+1,1000);

% start execution
debugstr = [actionflag ' ' num2str(kid)];
disp_if_debug(['start ' debugstr])
if strcmp(actionflag,'stop2'), actionflag = 'stop'; end

% custom queuing/canceling system
if getappdata(hf,'fn_buttonmotion_busy')
    switch actionflag
        case 'move' % cancel
            disp_if_debug(['rejct ' debugstr])
            return
        case 'stop' % queue
            setappdata(hf,'fn_buttonmotion_queue',debugstr)
            disp_if_debug(['queue ' debugstr])
            return
    end
end
setappdata(hf,'fn_buttonmotion_busy',true)


% stop (not queued)
if strcmp(actionflag,'stop')
    set(hf,'WindowButtonMotionFcn','', ...
        'WindowButtonUpFcn','')
    rmappdata(hf,'fn_buttonmotion_busy')
    disp_if_debug(['end   ' debugstr])
    return
end


% evaluate function
disp_if_debug(['exec  ' debugstr])
try 
    exec(fun); 
catch ME
    terminate(hf)
    rethrow(ME)
end


% end of current execution
disp_if_debug(['end   ' debugstr])
drawnow % allow queued events to be processed (and canceled, because of 'fn_buttonmotion_busy' flag)
setappdata(hf,'fn_buttonmotion_busy',false)

% stop (queued)
debugstr = getappdata(hf,'fn_buttonmotion_queue');
if ~isempty(debugstr)
    set(hf,'WindowButtonMotionFcn','', ...
        'WindowButtonUpFcn','')
    rmappdata(hf,'fn_buttonmotion_busy')
    rmappdata(hf,'fn_buttonmotion_queue')
    disp_if_debug(['exec  ' debugstr])
end

%---
function varargout = exec(fun)

if ischar(fun)
    evalin('base',fun);
elseif isa(fun,'function_handle')
    [varargout{1:nargout}] = feval(fun);
elseif iscell(fun)
    [varargout{1:nargout}] = feval(fun{:});
else
    error bad
end

%---
function terminate(hf)

set(hf,'WindowButtonMotionFcn','', ...
    'WindowButtonUpFcn','')
try rmappdata(hf,'fn_buttonmotion_busy'), end %#ok<*TRYNC>
try rmappdata(hf,'fn_buttonmotion_queue'), end

%---
function disp_if_debug(varargin)

% str = [];
% for k=1:nargin
%     x = varargin{k};
%     if iscell(x)
%         if isa(x{1},'function_handle')
%             x = func2str(x{1});
%         else
%             error('don''t know how to display cell array')
%         end
%     end
%     str = [str x]; %#ok<AGROW>
% end
% disp(str)

%---
function demo

C = {'figure(1), clf'
    'ht = uicontrol(''style'',''text'');'
    'fun = ''p=get(1,''''currentpoint''''); p=p(1,1:2); set(ht,''''pos'''',[p 60 20],''''string'''',num2str(p))'';'
    'set(1,''buttondownfcn'',@(u,evnt)fn_buttonmotion(fun))'};
fn_dispandexec(C)


