function fn_axispixel(ha)
% function fn_axispixel([ha])
%---
% set axes size such that there will be an integer ratio between the
% pixels in the image and on the screen display

% Thomas Deneux
% Copyright 2010-2012

% define axes handle, and possibly also image handle
if nargin==0
    ho = findobj('type','image');
    if isempty(ho)
        help fn_axispixel
        return
    elseif isscalar(ho)
        ha = get(ho,'parent');
    else
        ha = gca;
        ho = [];
    end
elseif strcmp(get(ha,'type'),'image')
    ho = ha;
    ha = get(ho,'parent');
else
    ho = [];
end
hf = get(ha,'parent');
if ~strcmp(get(hf,'type'),'figure')
    error('axes container must be a figure')
end

% define image handle
if isempty(ho)
    ho = findobj(ha,'type','image');
    if ~isscalar(ho)
        error('cannot determine which image to use')
    end
end
x = get(ho,'cdata');
[ni nj dum] = size(x);

% check and set callbacks
if isempty(getappdata(hf,'fn_axispixel'))
    % initialize function - first check 
    if ~isempty(get(hf,'resizefcn')) || ~isempty(get(ho,'deletefcn'))
        error('axes already has a resize function')
    end
    oldpos = {get(ha,'units'),get(ha,'position')};
    setappdata(hf,'fn_axispixel',oldpos)
    set(hf,'resizefcn',@(u,evnt)fn_axispixel(ho))
    set(ho,'deletefcn',@(u,evnt)cleanobject(ha,hf))
end

% set the axes size
curunits = get(ha,'units');
set(ha,'units','pixel')
pos = get(ha,'position');
ratio = min(pos(3)/nj,pos(4)/ni); % TODO: allow a ratio rather than 1:1
w = nj;
h = ni;
pos = [pos(1)-(w-pos(3))/2 pos(2)-(h-pos(4))/2 w h];
set(ha,'position',pos,'units',curunits)


%---
function cleanobject(ha,hf)

curunits = get(ha,'units');
oldpos = getappdata(hf,'fn_axispixel');
disp(oldpos{2})
set(ha,'units',oldpos{1},'pos',oldpos{2},'units',curunits)

rmappdata(hf,'fn_axispixel')
set(hf,'resizefcn','')



