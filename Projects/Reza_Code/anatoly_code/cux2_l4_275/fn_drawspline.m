function X = fn_drawspline(varargin)
% function X = fn_drawspline(tidx,X/[],command)

% Thomas Deneux
% Copyright 2004-2012

if nargin==0, varargin={1:10}; end

% Input
tidx = varargin{1};
nt = length(tidx);
tstart = tidx(1);
tlength = tidx(end)-tstart;
if nargin<2 || isempty(varargin{2});
    X = tidx;
    np = 2;
    timep = tidx([1 end]);
    x = tidx([1 end]);
else
    % find a spline parameterization of X which explains half of its
    % variance
    X = varargin{2};
    for k=1:log2(nt)
        np = 2^k;
        timep = tstart + tlength*(0:np-1)/(np-1);
        x = interp1(tidx,X,timep);
        Xtry = interp1(timep,x,tidx,'spline');
        if var(X(:)-Xtry(:))<var(X(:))/2; break, end
    end
    X = Xtry;
end
if nargin<3
    command = '';
else
    command = varargin{3};
end

% Init
hf = figure;
hl = plot(tidx,X,'b');
ax = axis; 
tmargin = (ax(2)-ax(1))/20; ymargin = (ax(4)-ax(3))/20;
axis([ax(1)-tmargin ax(2)+tmargin ax(3)-ymargin ax(4)+ymargin])
set(hl,'hittest','on','buttondownfcn',{@hitline})
hp = zeros(1,np);
for k=1:length(timep)
    hp(k) = line(timep(k),x(k),'color','b','marker','s', ...
        'hittest','on','buttondownfcn',{@hitpoint,timep(k)});
end
info = struct('tidx',tidx,'np',np,'timep',timep,'x',x, ...
    'hf',hf,'hl',hl,'hp',hp,'command',command);
setappdata(0,'fn_drawspline',info);
assignin('base','X',X)

updateX

% End
figure(hf), fn_okbutton wait
close(hf)
X = evalin('base','X');

%---
function hitline(varargin)

info = getappdata(0,'fn_drawspline');

mouse = get(gca,'currentpoint');
t = mouse(1,1);
xt = mouse(1,2);
[info.timep ord] = sort([info.timep t]);
info.x = [info.x xt]; info.x = info.x(ord);

k = find(info.timep==t);
hpk = line(t,xt,'color','b','marker','s', ...
    'hittest','on','buttondownfcn',{@hitpoint,t});
info.hp = [info.hp hpk]; info.hp = info.hp(ord);

updateX

set(info.hf,'windowButtonMotionFcn',{@movepoint,k}, ...
    'windowButtonUpFcn',{@movepointend,k})

setappdata(0,'fn_drawspline',info);

%---
function hitpoint(dum1,dum2,t)

info = getappdata(0,'fn_drawspline');

k = find(info.timep==t);

switch get(info.hf,'SelectionType')
    case 'normal'
        set(info.hf,'windowButtonMotionFcn',{@movepoint,k}, ...
            'windowButtonUpFcn',{@movepointend,k})
    case 'alt'
        info.timep(k) = [];
        info.x(k) = [];
        delete(info.hp(k))
        info.hp(k) = [];
        
        updateX
end



setappdata(0,'fn_drawspline',info);

%---
function movepoint(dum1,dum2,k)

info = getappdata(0,'fn_drawspline');

mouse = get(gca,'currentpoint');
t = mouse(1,1);
xt = mouse(1,2);

info.timep(k) = t;
info.x(k) = xt;

set(info.hp(k),'xdata',t,'ydata',xt)

updateX

setappdata(0,'fn_drawspline',info);

%---
function movepointend(dum1,dum2,k)

info = getappdata(0,'fn_drawspline');

set(info.hf,'windowButtonMotionFcn','', ...
    'windowButtonUpFcn','')

%---
function updateX

info = getappdata(0,'fn_drawspline');

X = interp1(info.timep,info.x,info.tidx,'cubic');
set(info.hl,'ydata',X)
assignin('base','X',X)

try
    evalin('base',info.command)
catch
    disp(lasterr)
end
figure(info.hf)


