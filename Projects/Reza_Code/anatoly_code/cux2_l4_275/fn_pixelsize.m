function [out1 out2] = fn_pixelsize(hobj)
% function siz = fn_pixelsize(hobj)
% function [w h] = fn_pixelsize(hobj)
%---
% returns the width and height in pixels of any object without needing to
% change any units values
%
% In R2014b and later, wraps function getpixelposition
%
% See also fn_pixelpos

% Thomas Deneux
% Copyright 2011-2012

if fn_matlabversion('newgraphics')
    pos = getpixelposition(hobj);
    siz = pos(3:4);
else
    W = pixelposwatcher(hobj);
    siz = W.pixelsize;
end

if nargout==2
    out1 = siz(1);
    out2 = siz(2);
else
    out1 = siz;
end