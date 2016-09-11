function fn_imdistline
% function fn_imdistline
%---
% enhanced version of Malab IMDISTLINE

% Copyright 2005-2012 The MathWorks, Inc.
% Copyright 2009-2012 Thomas Deneux

pointer = get(gcf,'pointer');
set(gcf,'pointer','hand')

h = imdistline;
api = iptgetapi(h);

setappdata(gcf,'fn_imdistline','first point')

% trick to force axes Currentpoint property to be updated at each mouse
% motion
set(gcf,'WindowButtonMotionFcn',' ');

% Set first point
% trick for stopping the loop: pressing a button will change a property
% which is inspected at each loop iteration
set(gcf,'WindowButtonDownFcn', ...
    'setappdata(gcf,''fn_imdistline'',''second point'')')
while strcmp(getappdata(gcf,'fn_imdistline'),'first point')
    pos1 = get(gca,'CurrentPoint');
    api.setPosition([pos1(1,1:2); pos1(2,1:2)])
    pause(.05)
end

% Set first point - same trick
set(gcf,'WindowButtonUpFcn', ...
    'setappdata(gcf,''fn_imdistline'','''')')
while strcmp(getappdata(gcf,'fn_imdistline'),'second point')
    pos2 = get(gca,'CurrentPoint');
    api.setPosition([pos1(1,1:2); pos2(2,1:2)])
    pause(.05)
end

% clean everything
%delete(h)
set(gcf,'pointer','arrow', ...
    'WindowButtonMotionFcn','','WindowButtonMotionFcn','')
a = 1;

