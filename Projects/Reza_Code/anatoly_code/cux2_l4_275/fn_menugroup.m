classdef fn_menugroup < hgsetget
% function fn_menugroup(m,obj,prop,options,labels)
%---
% Set a list of menu items with labels the different possible possibilities
% for an object property. There will be an automatic synchronization
% between shich item is checked and the value of the object property.
% 
% Input:
% - m       the parent menu
% - obj     the object whose property is observed
% - prop    the name of the observed property THIS PROPERTY MUST BE SET AS 
%           OBSERVABLE, AND ITS SET ACCESS MUST BE PUBLIC
% - options cell array - possible values for the property (note that if the
%           object property is assigned a value that is not in the list,
%           all menu items will be unchecked, but no error will be
%           generated)
% - labels  labels for the menu items (optional if options is a cell array
%           of strings, in which case they will be used as labels per
%           default)
%
% See also: fn_propcontrol, fn_buttongroup

properties
    buttons
    options
    obj
    prop
    hl
end

methods
    function M = fn_menugroup(m,obj,prop,options,labels)
        if nargin<5, labels = options; end
        M.options = options;
        M.obj = obj;
        M.prop = prop;
        n = length(options);
        
        % create menus
        dosep = ~isempty(get(m,'children'));
        M.buttons = gobjects(1,n);
        for i=1:n
            M.buttons(i) = uimenu(m,'label',labels{i},'callback',@(u,e)set(obj,prop,options{i}),'deletefcn',@(u,e)delete(M(isvalid(M))));
            if i==1 && dosep, set(M.buttons(i),'separator','on'), end
        end
        updatecheck(M)
        
        % watch object property
        M.hl = addlistener(obj,prop,'PostSet',@(u,e)updatecheck(M));
        
        % no output?
        if nargout==0, clear M, end
    end
    function delete(M)
        delete(M.hl)
    end
    function updatecheck(M)
        set(M.buttons,'checked','off')
        curval = M.obj.(M.prop);
        for i=1:length(M.options)
            if isequal(curval,M.options{i})
                set(M.buttons(i),'checked','on')
                break
            end
        end
    end
end

end
