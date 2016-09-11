function pos = fn_pixelpos(hobj,recursive)
% function pos = fn_pixelpos(hobj[,recursive])
%---
% returns the position in pixels of any object without needing to
% change any units values
%
% In R2014b and later, wraps function getpixelposition
%
% See also fn_pixelsize 

% Thomas Deneux
% Copyright 2011-2012

if nargin==0, help fn_pixelpos, return, end
if nargin<2, recursive = false; end

if fn_matlabversion('newgraphics')
    pos = getpixelposition(hobj,recursive);
else
    W = pixelposwatcher(hobj);
    pos = W.pixelpos;
end

% switch get(hobj,'type')
%     case 'figure'
%         pos = get(hobj,'position');
%     otherwise
%         units = get(hobj,'units');
%         switch units
%             case 'pixels'
%                 pos = get(hobj,'position');
%             case 'normalized'
%                 psiz = fn_pixelsize(get(hobj,'parent'));
%                 pos = get(hobj,'position').*psiz([1 2 1 2]);
%             otherwise
%                 error('units ''%s'' not handled',units)
%         end
% end
 