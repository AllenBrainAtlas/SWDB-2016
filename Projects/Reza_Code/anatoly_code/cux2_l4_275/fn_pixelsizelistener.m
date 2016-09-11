function hl = fn_pixelsizelistener(hobj,callback)
% function hl = fn_pixelsizelistener(hobj,callback)
%---
% Add a listener that will execute whenever the pixel size of an object
% is changed.
% In Matlab version R2014b and later, this just adds a listener to the
% object 'SizeChanged' event. In earlier versions, this is a wrapper
% for pixelposwatcher class.
%
% See also pixelposwatcher, fn_pixelposlistener

if fn_matlabversion('newgraphics')
    hl = addlistener(hobj,'SizeChanged',callback);
else
    ppw = pixelposwatcher(hobj);
    hl = addlistener(ppw,'changesize',callback);
end

if nargout==0, clear hl, end