function fn_eegdisplay(xidx,yrange,eeg)
% function fn_eegdisplay([xidx,yrange,]eeg)
%---
% (old) display of 2D data, with possibility to toggle between image or
% multi-curves displays
% 
% See also fn_eegplot

% Thomas Deneux
% Copyright 2005-2012

if nargin==0, help fn_eegdislay, end

if nargin<3
    eeg = xidx;
    xidx = 1:size(eeg,1);
    yrange = 1:size(eeg,2);
end
if length(xidx)==2
    % here tidx defines the two edges of the image, we need to find the
    % positions of each point now
    step = diff(xidx)/size(eeg,1);
    xidx = xidx(1) + step*(.5:size(eeg,1)-.5);
end
if length(yrange)>2
    % here yrange defines the position of each point, we need to find the
    % two edges of the image
    step = (yrange(end)-yrange(1))/(length(yrange)-1);
    yrange = [yrange(1)-step/2 yrange(end)+step/2];
end

hf = gcf; clf
m = fn_menu(hf,'v',[],30,20);
fn_menu(m,'add','String','gal','Style','text')
fn_menu(m,'add','String','T','Callback',{@eegdisp_toggle,m})
fn_menu(m,'add','String','res','Callback',{@eegdisp_reinit,m})
fn_menu(m,'add','String','img','Style','text')
fn_menu(m,'add','String','+','Callback',{@eegdisp_scale,m,'L+'})
fn_menu(m,'add','String','-','Callback',{@eegdisp_scale,m,'L-'})
fn_menu(m,'add','String','^','Callback',{@eegdisp_scale,m,'C+'})
fn_menu(m,'add','String','v','Callback',{@eegdisp_scale,m,'C-'})
fn_menu(m,'add','String','lines','Style','text')
fn_menu(m,'add','String','Cte','Callback',{@eegdisp_chgdata,m,'cte'})
fn_menu(m,'add','String','G','Callback',{@eegdisp_chgdata,m,'group'})
fn_menu(m,'add','String','U','Callback',{@eegdisp_chgdata,m,'ungroup'})
fn_menu(m,'add','String','^','Callback',{@eegdisp_scale,m,'^'})
fn_menu(m,'add','String','v','Callback',{@eegdisp_scale,m,'v'})
fn_menu(m,'add','String','thk','Callback',{@eegdisp_style,m,'thickness'})

info.xidx = xidx;
info.yrange = yrange;
info.eeg = eeg;
init(m,info);



%------
% utils
%------

function init(m,info)

eeg = info.eeg;
info.clim = [min(eeg(:)) max(eeg(:))];
detreeg = detrend(eeg);
info.ranges = [max(eeg(:))-min(eeg(:)) ...
    max(detreeg(:))-min(detreeg(:))];
info.group = 1;
info.detrend = true;
info.data = detrend(eeg,'constant');
info.mode = 'both';
info.ha = gca;
info.hi = [];
info.hp = [];
info.vi = 'on';
info.vp = 'on';
info.wp = 1;

setappdata(m,'fn_eegdisplay',info);

dispimage(m);       % sets info.hi
set(info.ha,'NextPlot','add');
disptimecourses(m); % sets info.hp


%---
function dispdata(m)

info = getappdata(m,'fn_eegdisplay');
switch info.mode
    case 'image'
        dispimage(m)
    case 'timecourses'
        disptimecourses(m)
    case 'both'
        dispimage(m)
        disptimecourses(m)        
end

%---
function dispimage(m)

info = getappdata(m,'fn_eegdisplay');
[nx ny] = size(info.eeg);
%nbin = size(info.data,2);
nbin = ny;

delete(info.hi)
info.hi = imagesc(info.xidx,info.yrange(1)+diff(info.yrange)/nbin*(.5:nbin-.5),info.eeg', ... %info.data', ...
    'parent',info.ha,'visible',info.vi,info.clim);
setappdata(m,'fn_eegdisplay',info);

%---
function disptimecourses(m)

info = getappdata(m,'fn_eegdisplay');
[nx ny] = size(info.eeg);
nbin = size(info.data,2);
decale = repmat(info.yrange(1)+diff(info.yrange)/nbin*(.5:nbin-.5),nx,1);
if info.detrend
    fact = 2/info.ranges(2)*(ny/nbin);
else
    fact = 2/info.ranges(1)*(ny/nbin);
end

delete(info.hp)
info.hp = plot(info.xidx,-info.data*fact+decale, ...
    'parent',info.ha,'visible',info.vp,'linewidth',info.wp);
%axis(info.ha,'tight')
setappdata(m,'fn_eegdisplay',info);


%----------
% callbacks
%----------

function eegdisp_reinit(dum1,dum2,m)

info = getappdata(m,'fn_eegdisplay');
delete([info.hi ; info.hp])
%init(m,info)
fn_eegdisplay(info.xidx,info.yrange,info.eeg)

%---
function eegdisp_toggle(dum1,dum2,m)

info = getappdata(m,'fn_eegdisplay');
switch info.mode
    case 'image'
        info.mode = 'timecourses';
        set(info.hi,'visible','off')
        info.vi = 'off';
        info.vp = 'on';
    case 'timecourses'
        info.mode = 'both';
        info.vi = 'on';
    case 'both'
        info.mode = 'image';
        set(info.hp,'visible','off')
        info.vp = 'off';
end

setappdata(m,'fn_eegdisplay',info);
dispdata(m)

%---
function eegdisp_scale(dum1,dum2,m,flag)

info = getappdata(m,'fn_eegdisplay');
coffset = mean(info.clim);
crange = diff(info.clim);
factcoffset = crange/10;
factrange = 2^(1/4);
switch flag
    case 'L+'
        coffset = coffset-factcoffset;
    case 'L-'
        coffset = coffset+factcoffset;
    case 'C+'
        crange = crange/factrange;
    case 'C-'
        crange = crange*factrange;
    case '^'
        info.ranges = info.ranges/factrange;
    case 'v'
        info.ranges = info.ranges*factrange;
end
info.clim = coffset+[-crange/2 crange/2];

setappdata(m,'fn_eegdisplay',info);
dispdata(m)

%---
function eegdisp_chgdata(dum1,dum2,m,flag)

info = getappdata(m,'fn_eegdisplay');
[nx ny] = size(info.eeg);
nbin = round(ny/info.group);

switch flag
    case {'group','ungroup'}
        if strcmp(flag,'group'), flag=1; else flag=-1; end
        if info.group>sqrt(ny)
            nbin = max(1,nbin-flag);
            info.group = round(ny/nbin);
        else
            info.group = max(1,info.group+flag);
            nbin = round(ny/info.group);
        end
    case 'cte'
        if info.detrend
            info.detrend=false; 
            %info.clim = info.clim+mean(info.eeg(:));
        else
            info.detrend=true; 
            %info.clim = info.clim-mean(info.eeg(:));
        end
end

info.data = zeros(nx,nbin);
for i=1:nbin
    bin = 1+floor((i-1)*ny/nbin):floor(i*ny/nbin);
    info.data(:,i) = mean(info.eeg(:,bin),2);
end
if info.detrend, info.data = detrend(info.data,'constant'); end

setappdata(m,'fn_eegdisplay',info);
dispdata(m)

%---
function eegdisp_style(dum1,dum2,m,flag)

info = getappdata(m,'fn_eegdisplay');
switch flag
    case 'thickness'
        info.wp = mod(info.wp,2)+1;
        set(info.hp,'linewidth',info.wp)
end
setappdata(m,'fn_eegdisplay',info);

