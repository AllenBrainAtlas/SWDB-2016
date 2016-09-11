function [hl geom] = fn_arraydisplay(varargin)
% function [hl geom] = fn_arraydisplay([x,y,][t,]data[,clip][,'dispatch',b][,'xbin',n][,'tbin',n][,line properties...])
%---
% Input (except for data, order of inputs can be changed):
% - x,y     x and y values
% - t       time values
% - data    3D or 4D data; NOT using Matlab image convention (i.e. first
%           dim is x and second dim is y) 
% - clip    clipping range or flag as in fn_clip
% - xbin    spatial binning
% - tbin    temporal binning
% - dispatch    logical [default: true]
%
% Output:
% - hl      set of drawn lines
% - geom    a structure describing the geometric transformation between
%           original (x,y,t) and the display (x,y)
%
% See also fn_framedisplay

% Thomas Deneux
% Copyright 2011-2012

if nargin==0, help fn_framedisplay, return, end

% Input
% (scan varargin)
x = []; y = []; t = [];
data = []; clip = []; xbin = 1; tbin = 1;
dodispatch = true; lineoptions = {};
karg = 0;
while karg<length(varargin)
    karg = karg+1;
    a = varargin{karg};
    if ischar(a)
        switch a
            case 'xbin'
                karg = karg+1;
                xbin = varargin{karg};
            case 'tbin'
                karg = karg+1;
                tbin = varargin{karg};
            case 'dispatch'
                karg = karg+1;
                dodispatch = varargin{karg};
            otherwise
                if ~mod(length(varargin)-karg,2)
                    % remaining part has an even number of arguments
                    clip = a;
                else
                    % remaining part is line properties
                    lineoptions = varargin(karg:end);
                    karg = length(varargin);
                end
        end
    elseif ~isvector(a)
        data = a;
        if ~isempty(x) && isempty(y), t = x; x = []; end
    elseif ~isempty(data)
        clip = a;
    elseif isempty(x)
        x = a;
    elseif isempty(y)
        y = a;
    elseif isempty(t)
        t = a;
    else 
        error argument
    end
end
% (sizes)
[nx ny nt nc] = size(data);
% (x,y,t)
if isempty(y), x = 1:nx; y = 1:ny; end
if isempty(t), t = 1:nt; end

% Data
% (some constants)
dx = diff(x(1:2));
dy = diff(y(1:2));
dt = diff(t(1:2));
xsides = [x(1)-dx/2 x(end)+dx/2];
ysides = [y(1)-dy/2 y(end)+dy/2];
% (binning)
if xbin>1
    data = fn_bin(data,[xbin xbin],'smart'); 
    nx = size(data,1); ny = size(data,2);
    dx = diff(xsides)/nx; dy = diff(ysides)/ny;
    x = xsides(1) + (.5:nx)*dx;
    y = ysides(1) + (.5:ny)*dy;
end
if tbin>1
    data = fn_bin(data,[1 1 tbin]); 
    nt = size(data,3);
    t = fn_bin(t,tbin);
end
% (clipping)
data = fn_clip(data,clip,'scaleonly'); % now data is clipped between 0 and 1

% Display
% (x/time) t -> (t-t(1))/(t(end)-t(1)) -> .05+.9*t -> xoffset+dx*t
xscale = 1 / (t(end)-t(1)) * .9 * dx;
xoffset = -t(1)*xscale + x(1) - .45*dx + (0:nx-1)*dx;
% (y/amplitude)
data = 1-data; % because y axis will be reversed!
if dodispatch
    dataoffset = .5*(0:nc-1);
    datarange = .5*(1+nc);
    data = fn_add(data,shiftdim(dataoffset,-2))/datarange;
end

yoffset = y(1) - .5*dy + (0:ny-1)*dy;
data = fn_add(yoffset,data*dy);
% (prepare display)
cla
axis([xsides ysides])
set(gca,'ydir','reverse')
% (loop on spatial locations)
hl = zeros(nx,ny,nc);
for i=1:nx
    ti = t*xscale+xoffset(i);
    for j=1:ny
        hl(i,j,:) = line(ti,squeeze(data(i,j,:,:)),lineoptions{:});
    end
end

% output 
if nargout==0
    clear hl
elseif nargout>=2
    geom = struct('nx',nx,'ny',ny,'x0',xsides(1),'y0',ysides(1), ...
        'dx',dx,'dy',dy,'t2x_scale',xscale','t2x_offset',xoffset);
end
