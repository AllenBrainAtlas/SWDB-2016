function hl = fn_pixelposlistener(hobj,callback)
% function hl = fn_pixelposlistener(hobj,callback)
%---
% Add a listener that will execute whenever the pixel position of an object
% is changed. This is a wrapper for pixelposwatcher class.
%
% See also pixelposwatcher

ppw = pixelposwatcher(hobj);
hl = addlistener(ppw,'changepos',callback);
if nargout==0, clear hl, end