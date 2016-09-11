function pos = fn_getpos(hobj,unit)
% function pos = fn_getpos(hobj,unit)
%---
% get the position of specified object according to specific unit

sunit = get(hobj,'units');
set(hobj,'units',unit)
pos = get(hobj,'pos');
set(hobj,'units',sunit)