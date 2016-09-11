function fn_setpropertyandmark(obj,propertyname,hu,value) 
% function fn_setpropertyandmark(obj,propertyname,hu[,value])
%---
% This function is useful for setting the callback of a boolean uibutton,
% or of a menu with a checkmark which reflects the boolean value of a
% specific property of a given object (or the 'on/off' value of another
% graphich object).
% Once invoked, it set both the property value of the object, and the
% control display.
% 
% Input:
% - obj             object or graphic object handle
% - propertyname    property name or cell array of property names
%                   can be of the form 'prop.subfield1.etc'
% - hu              control or uimenu handle
% - value           boolean, or 'toggle' to inverse the value [default]

% Thomas Deneux
% Copyright 2007-2012

% Input
if ~isobject(obj) && ~ishandle(obj), error 'invalid object or handle', end
if ~iscell(propertyname), propertyname = {propertyname}; end
if nargin<4, value = 'toggle'; end
if ischar(value) 
    if strcmp(value,'switch'), value = 'toggle'; warning 'please use ''toggle'' instead of ''switch''', end %#ok<WNTAG>
    if ~strcmp(value,'toggle'), error argument, end
    if ishandle(obj)
        b = ~fn_switch(get(obj,propertyname{1}));
    else
        b = ~eval(['obj.' propertyname{1}]);
    end
else
    b = value;
end

% object property
valstr = fn_switch(b,'true','false');
onoff = fn_switch(b,'on','off');
for k=1:length(propertyname)
    if ishandle(obj)
        set(obj,propertyname{k},onoff)
    else
        eval(['obj.' propertyname{1} '=' valstr ';']) % need the 'eval' form incase propertyname is something like 'a.b'
    end
end

% control display
switch get(hu,'type')
    case 'uimenu'
        set(hu,'checked',onoff)
    case 'uicontrol'
        set(hu,'value',b)
    otherwise
        error('wrong handle')
end
