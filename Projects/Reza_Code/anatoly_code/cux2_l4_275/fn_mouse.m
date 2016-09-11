function varargout = fn_mouse(varargin)
% function poly = fn_mouse([axes handle],'point|cross|poly|free|ellipse'[,msg])
% function [x y] = fn_mouse([axes handle],'point|cross'[,msg])
% function rect = fn_mouse([axes handle],'rect'[,msg])
% function [center axis e] = fn_mouse([axes handle],'ellipse'[,msg])
% function [center axis e relradius] = fn_mouse([axes handle],'ring'[,msg])
%---
% multi-functions function using mouse events
% mode defines action:
% 'point'       [default] get coordinates on mouse click
% 'cross'       get coordinates on mouse click - use cross pointer
% 'rect'        get a rectangle selection (format [xstart ystart xsize ysize])
% 'rectax'      get a rectangle selection (format [xstart xend ystart yend])
% 'rectangle'   get a rectangle selection (format [x1 x2 x3 x4; y1 y2 y3 y4])
% 'poly'        polygone selection
% 'line' or 'segment'       single line segment
% 'xsegment', 'ysegment'    a segment in x or y (formag [start end]) 
% 'free'        free-form drawing
% 'ellipse'     circle or ellipse
% 'ring'        circular or elliptic ring 
% options: (ex: 'rect+', 'poly-@:.25:')
% +     selection is drawn (all modes)
% -     use as first point the current point in axes (rect, poly, free, ellipse)
% @     plots open line instead of closed polygon (poly, free)
% ^     enable escape: cancel current selection if a second key is pressed
% :num: interpolates line with one point every 'num' pixel (poly, free, ellipse)
%       for 'ellipse' mode, if :num; is not specified, output is a cell
%       array {center axis e} event in the case of only one outpout argument
% 
% See also fn_maskselect

% Thomas Deneux
% Copyright 2005-2012

% Input
i=1;
ha=[];
mode='';
msg = '';
while i<=nargin
    arg = varargin{i};
    if ishandle(arg), ha=arg;
    elseif ischar(arg)
        if isempty(mode), mode=arg; else msg=arg; end
    else error('bad argument')
    end
    i=i+1;
end
if isempty(mode), mode='point'; end
if isempty(ha), ha=gca; end
hf = fn_parentfigure(ha);
figure(hf)

% Extract parameters from mode definition
type = regexp(mode,'^(\w)+','match'); type = type{1};
buttonalreadypressed = any(mode=='-');
showselection = any(mode=='+');
openline = any(mode=='@');
dointerp = any(mode==':');
doescape = any(mode=='^');

switch type
    case {'point' 'cross'}
        if doescape, error 'escape option is not valid for type ''point'' or ''cross''', end
        curpointer = get(hf,'pointer');
        if strcmp(type,'cross'), set(hf,'pointer','fullcrosshair'), end
        SuspendCallbacks(ha)
        waitforbuttonpressmsg(ha,msg)
        RestoreCallbacks(ha)
        point = get(ha,'CurrentPoint');    % button down detected
        if strcmp(type,'cross'), set(hf,'pointer',curpointer), end
        if showselection
            oldnextplot=get(ha,'NextPlot'); set(ha,'NextPlot','add')
            plot(point(1,1),point(1,2),'+','parent',ha),
            set(ha,'NextPlot',oldnextplot)
        end
        switch nargout
            case {0 1}
                varargout={point(1,:)'};
            case 2
                varargout=num2cell(point(1,1:2));
            case 3
                varargout=num2cell(point(1,1:3));
            otherwise
                error 'too many output arguments'
        end
    case {'line' 'segment'}
        if doescape, warning 'escape option is not valid for type ''line''', end
        if ~buttonalreadypressed, waitforbuttonpressmsg(ha,msg), end
        p1 = get(ha,'CurrentPoint'); p1 = p1(1,1:2);
        hl(1) = line('xdata',p1([1 1]),'ydata',p1([2 2]),'parent',ha,'color','k');
        hl(2) = line('xdata',p1([1 1]),'ydata',p1([2 2]),'parent',ha,'color','b','linestyle','--');
        data = fn_buttonmotion({@drawline,ha,hl,p1},hf);
        delete(hl(2))
        if showselection
            set(hl(1),'color','y')
        else
            delete(hl(1))
        end
        switch nargout
            case {0 1}
                varargout = {data};
            case 2
                varargout = {data(:,1) data(:,2)};
            otherwise
                error 'too many output arguments'
        end
    case {'rect' 'rectax' 'rectangle' 'xsegment' 'ysegment'}
        % if button has already been pressed, no more button will be
        % pressed, so it is not necessary to suspend callbacks
        SuspendCallbacks(ha)
        if ~buttonalreadypressed, waitforbuttonpressmsg(ha,msg), end
        selectiontype = get(hf,'selectionType');
        p0 = get(ha,'currentpoint'); p0 = p0(1,1:2);
        hl(1) = line(p0(1),p0(2),'color','k','linestyle','-','parent',ha);
        hl(2) = line(p0(1),p0(2),'color','w','linestyle',':','parent',ha);
        mode = fn_switch(type,'xsegment','x','ysegment','y','');
        rect = fn_buttonmotion({@drawrectangle,ha,hl,p0,mode},hf);
        delete(hl)
        RestoreCallbacks(ha)
        if doescape && ~strcmp(get(hf,'selectionType'),selectiontype)
            % another key was pressed -> escape
            waitforbuttonup(hf)
            varargout = {[]};
            return
        end
        if showselection,
            line(rect(1,[1:4 1]),rect(2,[1:4 1]),'color','k','parent',ha)
            line(rect(1,[1:4 1]),rect(2,[1:4 1]),'color','w','linestyle',':','parent',ha),
        end
        if strcmp(type,'rectangle')
            varargout={rect};
        else % type is 'rect'
            cornera = [min(rect(1,:)); min(rect(2,:))];
            cornerb = [max(rect(1,:)); max(rect(2,:))];
            switch type
                case 'rect'
                    rect = [cornera' cornerb'-cornera'];
                case 'rectax'
                    rect = [cornera(1) cornerb(1) cornera(2) cornerb(2)];
                case 'xsegment'
                    rect = [cornera(1) cornerb(1)];
                case 'ysegment'
                    rect = [cornera(2) cornerb(2)];
            end
            varargout = {rect};
        end
    case 'poly'
        SuspendCallbacks(ha)
        if ~buttonalreadypressed, waitforbuttonpressmsg(ha,msg), end
        selectiontype = get(hf,'selectionType');
        [xi,yi] = fn_getline(ha);                   % return figure units
        RestoreCallbacks(ha)
        if doescape && ~strcmp(get(hf,'selectionType'),selectiontype)
            % another key was pressed -> escape
            waitforbuttonup(hf)
            varargout = {[]};
            return
        end
        x = [xi yi];
        if showselection,
            if openline, back=[]; else back=1; end
            oldnextplot=get(ha,'NextPlot'); set(ha,'NextPlot','add')
            plot(x([1:end back],1),x([1:end back],2),'k-'),
            plot(x([1:end back],1),x([1:end back],2),'w:'),
            set(ha,'NextPlot',oldnextplot)
        end
        if dointerp
            f = find(mode==':'); f = [f length(mode)+1];
            ds = str2num(mode(f(1)+1:f(2)-1));
            if ~openline, x(end+1,:)=x(1,:); end
            ni = size(x,1);
            L = zeros(ni-1,1);
            for i=2:ni, L(i) = L(i-1)+norm(x(i,:)-x(i-1,:)); end
            if ~isempty(L), x = interp1(L,x,0:ds:L(end)); end
        end
        varargout={x'};
    case 'free'
        SuspendCallbacks(ha)
        if ~buttonalreadypressed, waitforbuttonpressmsg(ha,msg), end
        selectiontype = get(hf,'selectionType');
        p = get(ha,'currentpoint');
        hl(1) = line(p(1,1),p(1,2),'color','k','linestyle','-','parent',ha);
        hl(2) = line(p(1,1),p(1,2),'color','w','linestyle',':','parent',ha);
        fn_buttonmotion({@freeform,ha,hl},hf)
        RestoreCallbacks(ha)    
        x = [get(hl(1),'xdata')' get(hl(2),'ydata')'];
        delete(hl)
        if doescape && ~strcmp(get(hf,'selectionType'),selectiontype)
            % another key was pressed -> escape
            waitforbuttonup(hf)
            varargout = {[]};
            return
        end
        if showselection,
            if openline, back=[]; else back=1; end
            oldnextplot=get(ha,'NextPlot'); set(ha,'NextPlot','add')
            plot(x([1:end back],1),x([1:end back],2),'k-','parent',ha),
            plot(x([1:end back],1),x([1:end back],2),'w:','parent',ha),
            set(ha,'NextPlot',oldnextplot)
        end
        if dointerp
            f = find(mode==':'); f = [f length(mode)+1];
            ds = str2double(mode(f(1)+1:f(2)-1));
            if ~openline, x(end+1,:)=x(1,:); end
            ni = size(x,1);
            L = zeros(ni-1,1);
            for i=2:ni, L(i) = L(i-1)+norm(x(i,:)-x(i-1,:)); end
            if ~isempty(L), x = interp1(L,x,0:ds:L(end)); end
        end
        varargout={x'};
    case {'ellipse' 'ring'}
        if doescape, warning 'escape option is not valid for types ''ellipse'' and ''ring''', end
        SuspendCallbacks(ha)
        if ~buttonalreadypressed, waitforbuttonpressmsg(ha,msg), end
        p = get(ha,'currentpoint');
        hl(1) = line(p(1,1),p(1,2),'color','k','linestyle','-','parent',ha);
        hl(2) = line(p(1,1),p(1,2),'color','w','linestyle',':','parent',ha);
        info = fn_pointer('flag','init');
        % circle
        fn_buttonmotion({@drawellipse,ha,hl,info},hf,'doup')
        % make it an ellipse
        if strcmp(info.flag,'width')
            % change eccentricity -> ellipse
            fn_buttonmotion({@drawellipse,ha,hl,info},hf)
        end
        % ring -> set the diameter of the internal circle
        if strcmp(type,'ring')
            info.flag = 'ring';
            fn_buttonmotion({@drawellipse,ha,hl,info},hf)
        end
        RestoreCallbacks(ha)   
        x = [get(hl(1),'xdata')' get(hl(1),'ydata')'];
        ax = info.axis;
        u = (ax(:,2)-ax(:,1))/2;
        center = mean(ax,2);
        value = {center u info.eccentricity};
        if strcmp(type,'ring'), value{4} = info.relradius; end
        delete(hl)
        if showselection,
            oldnextplot=get(ha,'NextPlot'); set(ha,'NextPlot','add')
            plot(x(1:end,1),x(1:end,2),'k-','parent',ha),
            plot(x(1:end,1),x(1:end,2),'w:','parent',ha),
            set(ha,'NextPlot',oldnextplot)
        end
        if dointerp
            f = find(mode==':'); f = [f length(mode)+1];
            ds = str2double(mode(f(1)+1:f(2)-1));
            ni = size(x,1);
            L = zeros(ni-1,1);
            for i=2:ni, L(i) = L(i-1)+norm(x(i,:)-x(i-1,:)); end
            if ~isempty(L), x = interp1(L,x,0:ds:L(end)); end
        end
        switch nargout
            case {0 1}
                if dointerp
                    varargout = {x'};
                else
                    varargout = {value};
                end
            case {3 4}
                varargout = value;
        end
    otherwise
        error('unknown type ''%s''',type)
end


%-------------------------------------------------
function SuspendCallbacks(ha)
% se pr�munir des callbacks divers et vari�s

hf = get(ha,'parent'); while ~strcmp(get(hf,'type'),'figure'), hf = get(hf,'parent'); end
setappdata(ha,'uistate',guisuspend(hf))
setappdata(ha,'oldtag',get(ha,'Tag'))
set(ha,'Tag','fn_mouse') % pour bloquer fn_imvalue !

%-------------------------------------------------
function RestoreCallbacks(ha)
% r�tablissement des callbacks avant les affichages

set(ha,'Tag',getappdata(ha,'oldtag'))
rmappdata(ha,'oldtag')
guirestore(getappdata(ha,'uistate'))

%-------------------------------------------------
function state = guisuspend(hf)

state.hf        = hf;
state.obj       = findobj(hf);
state.hittest   = get(state.obj,'hittest');
state.buttonmotionfcn   = get(hf,'windowbuttonmotionfcn');
state.buttondownfcn     = get(hf,'windowbuttondownfcn');
state.buttonupfcn       = get(hf,'windowbuttonupfcn');
state.keydownfcn        = get(hf,'keypressfcn');
try state.keyupfcn = get(hf,'keyreleasefcn'); end

set(state.obj,'hittest','off')
set(hf,'hittest','on','windowbuttonmotionfcn','', ...
    'windowbuttondownfcn','','windowbuttonupfcn','', ...
    'keypressfcn','')
try set(hf,'keyreleasefcn',''), end

%-------------------------------------------------
function guirestore(state)

for k=1:length(state.obj)
    set(state.obj(k),'hittest',state.hittest{k});
end
hf = state.hf;
set(hf,'windowbuttonmotionfcn',state.buttonmotionfcn);
set(hf,'windowbuttondownfcn',state.buttondownfcn);
set(hf,'windowbuttonupfcn',state.buttonupfcn);
set(hf,'keypressfcn',state.keydownfcn);
try set(hf,'keyreleasefcn',state.keyupfcn); end

%-------------------------------------------------
function data=drawline(ha,hl,p1)

p2 = get(ha,'currentpoint');
data = [p1(:) p2(1,1:2)'];
set(hl,'xdata',data(1,:),'ydata',data(2,:))
drawnow update

%-------------------------------------------------
function freeform(ha,hl)

p = get(ha,'currentpoint');
xdata = get(hl(1),'xdata'); xdata(end+1) = p(1,1);
ydata = get(hl(1),'ydata'); ydata(end+1) = p(1,2);
set(hl,'xdata',xdata,'ydata',ydata)
drawnow update

%-------------------------------------------------
function rect = drawrectangle(ha,hl,p0,mode)

p = get(ha,'currentpoint'); 
pp = [p0(:) p(1,1:2)'];
if strcmp(mode,'x')
    pp(2,:) = get(ha,'ylim');
elseif strcmp(mode,'y')
    pp(1,:) = get(ha,'xlim');
end
xdata = pp(1,[1 1 2 2 1]);
ydata = pp(2,[1 2 2 1 1]);
rect = [xdata(1:4); ydata(1:4)];
set(hl,'xdata',xdata,'ydata',ydata)
drawnow update

%-------------------------------------------------
function drawellipse(ha,hl,info)

p = get(ha,'currentpoint');
p = p(1,1:2)';

% special cases: initialization
flag = info.flag;
switch flag
    case 'init'
        xdata = get(hl(1),'xdata');
        ydata = get(hl(1),'ydata');
        info.start = [xdata; ydata];
        info.axis = [xdata xdata; ydata ydata];
        info.eccentricity = .999;
        info.relradius = [];
        info.flag = 'axis';
        set(get(ha,'parent'),'windowbuttondownfcn',@(hf,evnt)set(info,'flag','click'))
        drawellipse(ha,hl,info)
        return
    case 'click'
        ax = info.axis;
        u = (ax(:,2)-ax(:,1))/2;
        v = [u(2); -u(1)];
        p = ax(:,1) + u + v;
        p0 = fn_coordinates(ha,'a2s',p,'position');
        set(0,'pointerlocation',p0);
        info.flag = 'width';
        return
end

% main axis
switch flag
    case 'axis'
        ax = [info.start p];
        info.axis = ax;
    otherwise
        ax = info.axis;
end
u = (ax(:,2)-ax(:,1))/2;

% some constants
normu2 = sum(u.^2);
v = [u(2); -u(1)];
o = mean(ax,2);
x = p-o;

% eccentricity
switch flag
    case 'width'
        uc = sum(x.*u)/normu2;
        vc = sum(x.*v)/normu2;
        e = abs(vc / (sin(acos(uc))));
        info.eccentricity = e;
    otherwise
        e  = info.eccentricity;
end

% second radius for ring
switch flag
    case 'ring'
        center = mean(ax,2);
        x = (p-center);
        u = (ax(:,2)-ax(:,1))/2;
        v = [u(2); -u(1)];
        relradius = sqrt((x'*u)^2 + (x'*v/e)^2) / norm(u)^2;
        info.relradius = relradius;
    otherwise
        relradius = info.relradius;
end

% update display
t = 0:.05:1;
udata = cos(2*pi*t);
vdata = e*sin(2*pi*t);
if ~isempty(relradius)
        udata = [udata NaN relradius*udata];
        vdata = [vdata NaN relradius*vdata];
end
xdata = o(1) + u(1)*udata + v(1)*vdata;
ydata = o(2) + u(2)*udata + v(2)*vdata;
set(hl,'xdata',xdata,'ydata',ydata)
drawnow update

%---
function waitforbuttonpressmsg(ha,msg)

hf = get(ha,'parent');

%if isempty(msg), waitfor(hf,'windowbuttondownfcn',''), return, end

p = get(ha,'currentpoint'); p=p(1,1:2);
dd = fn_coordinates(ha,'b2a',[9 9; 3 -12],'vector');
if isempty(msg)
    t = [];
else
    for i=1:2
        t(i) = text('parent',ha,'string',msg, ...
            'fontsize',8,'position',p(1:2)'+dd(:,i), ...
            'color',fn_switch(i,1,'k',2,'w')); %#ok<AGROW>
    end
end
set(hf,'windowbuttonmotionfcn',@(f,evnt)movesub(ha,t,dd), ...
    'windowbuttondownfcn', ...
    @(f,evnt)set(hf,'windowbuttonmotionfcn','','windowbuttondownfcn',''))
waitfor(hf,'windowbuttondownfcn','')
if ishandle(t), delete(t), end

%---
function waitforbuttonup(hf)

set(hf,'windowbuttonupfcn',@(h,e)set(hf,'windowbuttonupfcn',''))
waitfor(hf,'windowbuttonupfcn','')

%---
function movesub(ha,t,dd)

p = get(ha,'currentpoint'); p=p(1,1:2);
for i=1:length(t), set(t(i),'position',p(1:2)'+dd(:,i)), end
drawnow update

