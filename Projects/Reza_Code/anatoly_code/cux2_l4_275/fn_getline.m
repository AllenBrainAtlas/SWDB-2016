function varargout = fn_getline(varargin)
% function varargout = fn_getline([ha])

% modifications de getline
% - on suppose qu'on a d�j� cliqu� une fois dans la fenetre
% - si la s�lection ne commence pas par un d�placement bouton enfonc�, on
%   retourne seulement un point

%   Callback syntaxes:
%        fn_getline('KeyPress')
%        fn_getline('FirstButtonDown')
%        fn_getline('NextButtonDown')
%        fn_getline('ButtonMotion')

%   Grandfathered syntaxes:
%   XY = FN_GETLINE(...) returns output as M-by-2 array; first
%   column is X; second column is Y.

% Copyright 1993-2012 The MathWorks, Inc.
% $Revision: 1.1 $  $Date: 2005/09/19 09:45:06 $
% Thomas Deneux
% Copyright 2006-2012

global FN_GETLINE_FIG FN_GETLINE_AX FN_GETLINE_H1 FN_GETLINE_H2
global FN_GETLINE_X FN_GETLINE_Y
global FN_GETLINE_ISCLOSED

if ((nargin >= 1) & (isstr(varargin{end})))
    str = varargin{end};
    if (str(1) == 'c')
        % fn_getline(..., 'closed')
        FN_GETLINE_ISCLOSED = 1;
        varargin = varargin(1:end-1);
    end
else
    FN_GETLINE_ISCLOSED = 0;
end

if ((length(varargin) >= 1) & isstr(varargin{1}))
    % Callback invocation: 'KeyPress', 'FirstButtonDown',
    % 'NextButtonDown', or 'ButtonMotion'.
    feval(varargin{:});
    return;
end

FN_GETLINE_X = [];
FN_GETLINE_Y = [];

if (length(varargin) < 1)
    FN_GETLINE_AX = gca;
    FN_GETLINE_FIG = get(FN_GETLINE_AX, 'Parent');
else
    if (~ishandle(varargin{1}))
        CleanUp(xlimorigmode,ylimorigmode);
        error('First argument is not a valid handle');
    end
    
    switch get(varargin{1}, 'Type')
    case 'figure'
        FN_GETLINE_FIG = varargin{1};
        FN_GETLINE_AX = get(FN_GETLINE_FIG, 'CurrentAxes');
        if (isempty(FN_GETLINE_AX))
            FN_GETLINE_AX = axes('Parent', FN_GETLINE_FIG);
        end

    case 'axes'
        FN_GETLINE_AX = varargin{1};
        FN_GETLINE_FIG = get(FN_GETLINE_AX, 'Parent');

    otherwise
        CleanUp(xlimorigmode,ylimorigmode);
        error('First argument should be a figure or axes handle');
    end
end

% Remember initial figure state
xlimorigmode = xlim(FN_GETLINE_AX,'mode');
ylimorigmode = ylim(FN_GETLINE_AX,'mode');
xlim(FN_GETLINE_AX,'manual');
ylim(FN_GETLINE_AX,'manual');

old_db = get(FN_GETLINE_FIG, 'DoubleBuffer');
state= guisuspend(FN_GETLINE_FIG);

% Set up initial callbacks for initial stage
set(FN_GETLINE_FIG, ...
    'Pointer', 'crosshair', ...
    'WindowButtonDownFcn', 'fn_getline(''FirstButtonDown'');',...
    'KeyPressFcn', 'fn_getline(''KeyPress'');', ...
    'DoubleBuffer', 'on');

% Bring target figure forward
figure(FN_GETLINE_FIG);

% Initialize the lines to be used for the drag
FN_GETLINE_H1 = line('Parent', FN_GETLINE_AX, ...
                  'XData', FN_GETLINE_X, ...
                  'YData', FN_GETLINE_Y, ...
                  'Visible', 'off', ...
                  'Clipping', 'off', ...
                  'Color', 'k', ...
                  'LineStyle', '-');

FN_GETLINE_H2 = line('Parent', FN_GETLINE_AX, ...
                  'XData', FN_GETLINE_X, ...
                  'YData', FN_GETLINE_Y, ...
                  'Visible', 'off', ...
                  'Clipping', 'off', ...
                  'Color', 'w', ...
                  'LineStyle', ':');

% We're ready; wait for the user to do the drag
% Wrap the call to waitfor in try-catch so we'll
% have a chance to clean up after ourselves.
errCatch = 0;

% AJOUT
FirstButtonDown
% fin AJOUT

try
    waitfor(FN_GETLINE_H1, 'UserData', 'Completed');
catch
    errCatch = 1;
end

% After the waitfor, if FN_GETLINE_H1 is still valid
% and its UserData is 'Completed', then the user
% completed the drag.  If not, the user interrupted
% the action somehow, perhaps by a Ctrl-C in the
% command window or by closing the figure.

if (errCatch == 1)
    errStatus = 'trap';
    
elseif (~ishandle(FN_GETLINE_H1) | ...
            ~strcmp(get(FN_GETLINE_H1, 'UserData'), 'Completed'))
    errStatus = 'unknown';
    
else
    errStatus = 'ok';
    x = FN_GETLINE_X(:);
    y = FN_GETLINE_Y(:);
    % If no points were selected, return rectangular empties.
    % This makes it easier to handle degenerate cases in
    % functions that call fn_getline.
    if (isempty(x))
        x = zeros(0,1);
    end
    if (isempty(y))
        y = zeros(0,1);
    end
end

% Delete the animation objects
if (ishandle(FN_GETLINE_H1))
    delete(FN_GETLINE_H1);
end
if (ishandle(FN_GETLINE_H2))
    delete(FN_GETLINE_H2);
end

% Restore the figure's initial state
if (ishandle(FN_GETLINE_FIG))
   guirestore(state);
   set(FN_GETLINE_FIG, 'DoubleBuffer', old_db);
end

CleanUp(xlimorigmode,ylimorigmode);

% Depending on the error status, return the answer or generate
% an error message.
switch errStatus
case 'ok'
    % Return the answer
    if (nargout >= 2)
        varargout{1} = x;
        varargout{2} = y;
    else
        % Grandfathered output syntax
        varargout{1} = [x(:) y(:)];
    end
    
case 'trap'
    % An error was trapped during the waitfor
    error('Interruption during mouse selection.');
    
case 'unknown'
    % User did something to cause the polyline selection to
    % terminate abnormally.  For example, we would get here
    % if the user closed the figure in the middle of the selection.
    error('Interruption during mouse selection.');
end

%--------------------------------------------------
% Subfunction KeyPress
%--------------------------------------------------
function KeyPress

global FN_GETLINE_FIG FN_GETLINE_AX FN_GETLINE_H1 FN_GETLINE_H2
global FN_GETLINE_PT1 
global FN_GETLINE_ISCLOSED
global FN_GETLINE_X FN_GETLINE_Y

key = get(FN_GETLINE_FIG, 'CurrentCharacter');
switch key
case {char(8), char(127)}  % delete and backspace keys
    % remove the previously selected point
    switch length(FN_GETLINE_X)
    case 0
        % nothing to do
    case 1
        FN_GETLINE_X = [];
        FN_GETLINE_Y = [];
        % remove point and start over
        set([FN_GETLINE_H1 FN_GETLINE_H2], ...
                'XData', FN_GETLINE_X, ...
                'YData', FN_GETLINE_Y);
        set(FN_GETLINE_FIG, 'WindowButtonDownFcn', ...
                'fn_getline(''FirstButtonDown'');', ...
                'WindowButtonMotionFcn', '');
    otherwise
        % remove last point
        if (FN_GETLINE_ISCLOSED)
            FN_GETLINE_X(end-1) = [];
            FN_GETLINE_Y(end-1) = [];
        else
            FN_GETLINE_X(end) = [];
            FN_GETLINE_Y(end) = [];
        end
        set([FN_GETLINE_H1 FN_GETLINE_H2], ...
                'XData', FN_GETLINE_X, ...
                'YData', FN_GETLINE_Y);
    end
    
case {char(13), char(3)}   % enter and return keys
    % return control to line after waitfor
    set(FN_GETLINE_H1, 'UserData', 'Completed');     

end

%--------------------------------------------------
% Subfunction FirstButtonDown
%--------------------------------------------------
function FirstButtonDown

global FN_GETLINE_FIG FN_GETLINE_AX FN_GETLINE_H1 FN_GETLINE_H2
global FN_GETLINE_ISCLOSED
global FN_GETLINE_X FN_GETLINE_Y

[x,y] = getcurpt(FN_GETLINE_AX);

% check if FN_GETLINE_X,FN_GETLINE_Y is inside of axis
xlim = get(FN_GETLINE_AX,'xlim');
ylim = get(FN_GETLINE_AX,'ylim');
if (x>=xlim(1)) & (x<=xlim(2)) & (y>=ylim(1)) & (y<=ylim(2))
    % inside axis limits
    FN_GETLINE_X = x;
    FN_GETLINE_Y = y;
else
    % outside axis limits, ignore this FirstButtonDown
    return
end

if (FN_GETLINE_ISCLOSED)
    FN_GETLINE_X = [FN_GETLINE_X FN_GETLINE_X];
    FN_GETLINE_Y = [FN_GETLINE_Y FN_GETLINE_Y];
end

set([FN_GETLINE_H1 FN_GETLINE_H2], ...
        'XData', FN_GETLINE_X, ...
        'YData', FN_GETLINE_Y, ...
        'Visible', 'on');

if (strcmp(get(FN_GETLINE_FIG, 'SelectionType'), 'open'))
    % We're done!
    set(FN_GETLINE_H1, 'UserData', 'Completed');
else
    % Let the motion functions take over.
    set(FN_GETLINE_FIG, 'WindowButtonMotionFcn', 'fn_getline(''ButtonMotion'');', ...
            'WindowButtonUpFcn', 'fn_getline(''LastButtonDown'');', ...
            'WindowButtonDownFcn', 'fn_getline(''NextButtonDown'');');
end

%--------------------------------------------------
% Subfunction LastButtonDown
%--------------------------------------------------
function LastButtonDown

global FN_GETLINE_H1

set(FN_GETLINE_H1, 'UserData', 'Completed')

%--------------------------------------------------
% Subfunction NextButtonDown
%--------------------------------------------------
function NextButtonDown

global FN_GETLINE_FIG FN_GETLINE_AX FN_GETLINE_H1 FN_GETLINE_H2
global FN_GETLINE_ISCLOSED
global FN_GETLINE_X FN_GETLINE_Y

selectionType = get(FN_GETLINE_FIG, 'SelectionType');
set(FN_GETLINE_FIG, 'WindowButtonUpFcn','')
if (~strcmp(selectionType, 'open'))
    % We don't want to add a point on the second click
    % of a double-click

    [x,y] = getcurpt(FN_GETLINE_AX);
    if (FN_GETLINE_ISCLOSED)
        FN_GETLINE_X = [FN_GETLINE_X(1:end-1) x FN_GETLINE_X(end)];
        FN_GETLINE_Y = [FN_GETLINE_Y(1:end-1) y FN_GETLINE_Y(end)];
    else
        FN_GETLINE_X = [FN_GETLINE_X x];
        FN_GETLINE_Y = [FN_GETLINE_Y y];
    end
    
    set([FN_GETLINE_H1 FN_GETLINE_H2], 'XData', FN_GETLINE_X, ...
            'YData', FN_GETLINE_Y);
    
end

if (strcmp(get(FN_GETLINE_FIG, 'SelectionType'), 'open'))
    % We're done!
    set(FN_GETLINE_H1, 'UserData', 'Completed');
end

%-------------------------------------------------
% Subfunction ButtonMotion
%-------------------------------------------------
function ButtonMotion

global FN_GETLINE_FIG FN_GETLINE_AX FN_GETLINE_H1 FN_GETLINE_H2
global FN_GETLINE_ISCLOSED
global FN_GETLINE_X FN_GETLINE_Y

[newx, newy] = getcurpt(FN_GETLINE_AX);
if (FN_GETLINE_ISCLOSED & (length(FN_GETLINE_X) >= 3))
    x = [FN_GETLINE_X(1:end-1) newx FN_GETLINE_X(end)];
    y = [FN_GETLINE_Y(1:end-1) newy FN_GETLINE_Y(end)];
else
    x = [FN_GETLINE_X newx];
    y = [FN_GETLINE_Y newy];
end

set([FN_GETLINE_H1 FN_GETLINE_H2], 'XData', x, 'YData', y);
set(FN_GETLINE_FIG, 'WindowButtonUpFcn','fn_getline(''NextButtonDown'');')

%---------------------------------------------------
% Subfunction CleanUp
%--------------------------------------------------
function CleanUp(xlimmode,ylimmode)

global FN_GETLINE_AX

xlim(FN_GETLINE_AX,xlimmode);
ylim(FN_GETLINE_AX,ylimmode);
% Clean up the global workspace
clear global FN_GETLINE_FIG FN_GETLINE_AX FN_GETLINE_H1 FN_GETLINE_H2
clear global FN_GETLINE_X FN_GETLINE_Y
clear global FN_GETLINE_ISCLOSED

%---------------------------------------------------
% Subfunction getcurpt
%--------------------------------------------------
function [x,y] = getcurpt(axHandle)
%GETCURPT Get current point.
%   [X,Y] = GETCURPT(AXHANDLE) gets the x- and y-coordinates of
%   the current point of AXHANDLE.  GETCURPT compensates these
%   coordinates for the fact that get(gca,'CurrentPoint') returns
%   the data-space coordinates of the idealized left edge of the
%   screen pixel that the user clicked on.  For IPT functions, we
%   want the coordinates of the idealized center of the screen
%   pixel that the user clicked on.

%   Copyright 1993-2002 The MathWorks, Inc.  
%   $Revision: 1.1 $  $Date: 2005/09/19 09:45:06 $

pt = get(axHandle, 'CurrentPoint');
x = pt(1,1);
y = pt(1,2);

%-- start Thomas Deneux ---
function state = guisuspend(hf)

state.hf        = hf;
state.obj       = findobj(hf);
state.hittest   = get(state.obj,'hittest');
state.buttonmotionfcn   = get(hf,'windowbuttonmotionfcn');
state.buttondownfcn     = get(hf,'windowbuttondownfcn');
state.buttonupfcn       = get(hf,'windowbuttonupfcn');
state.keydownfcn        = get(hf,'keypressfcn');
try, state.keyupfcn = get(hf,'keyreleasefcn'); end
state.pointer          = get(hf,'pointer');

set(state.obj,'hittest','off')
set(hf,'hittest','on','windowbuttonmotionfcn','', ...
    'windowbuttondownfcn','','windowbuttonupfcn','', ...
    'keypressfcn','')
try set(hf,'keyreleasefcn',''), end

%---
function guirestore(state)

for k=1:length(state.obj)
    set(state.obj(k),'hittest',state.hittest{k});
end
hf = state.hf;
set(hf,'windowbuttonmotionfcn',state.buttonmotionfcn);
set(hf,'windowbuttondownfcn',state.buttondownfcn);
set(hf,'windowbuttonupfcn',state.buttonupfcn);
set(hf,'keypressfcn',state.keydownfcn);
try, set(hf,'keyreleasefcn',state.keyupfcn); end
set(hf,'pointer',state.pointer);

%---  end Thomas Deneux ---