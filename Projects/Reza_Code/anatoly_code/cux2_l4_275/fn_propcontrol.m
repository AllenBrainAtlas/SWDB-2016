classdef fn_propcontrol < hgsetget
% function fn_propcontrol(obj,prop,spec,graphic object options...)
%---
% Create a control that will be synchronized to an object property value.
% 
% Input:
% - obj     the object whose property is observed
% - prop    the name of the observed property THIS PROPERTY MUST BE SET AS 
%           OBSERVABLE, AND ITS SET ACCESS MUST BE PUBLIC
% - spec    specification of both the value type and the control style:
%           . for logical values: 'checkbox', 'radiobutton' or 'menu'
%           . for numerical and char values: 'char', 'double', 'uint8', etc
%           . for list of values: {'listbox|checkbox|menu|menugroup' value1 value2 ...}
%             or {'listbox|checkbox|menu|menugroup' {values...} {labels...}}
%             'menu' will create one entry with sub-entries while
%             'menugroup' will create multiple entries at the first level
% - options options for the graphic object that will be created
%           If spec is 'menu' or 'menugroup', it is mandatory that options
%           will contain the pair ('parent',parentmenu).
%           For better visibility, options can be nested inside a cell
%           array.
%
% See also: fn_menugroup, fn_control

properties
    hu
    obj
    prop
    type
    style
    valuelist
    hl
end

methods
    function M = fn_propcontrol(obj,prop,spec,varargin)
        M.obj = obj;
        M.prop = prop;
        if isscalar(varargin) && iscell(varargin{1})
            varargin = varargin{1};
        end
            
        
        % if several objects, only the first one will be watched
        obj = obj(1);
        
        % list of values
        labellist = [];
        if iscell(spec)
            if length(spec)==1
                error 'missing list of values'
            elseif iscell(spec{2})
                M.valuelist = spec{2};
                if length(spec)>=3, labellist = spec{3}; end
            else
                M.valuelist = spec(2:end);
            end
            spec = spec{1};
        elseif ismember(spec,{'listbox' 'popupmenu'})
            kstring = strcmpi(varargin(1:2:end),'string');
            if isempty(kstring), error 'missing list of values', end
            M.valuelist = cellstr(varargin{kstring});
        end
        
        % special: color
        docolor = false;
        if ~isempty(regexpi('color',prop)) && ~isempty(M.valuelist) && any(fn_map(@ischar,M.valuelist))
            % try converting color names to colors
            try
                colorlist = M.valuelist;
                deflinecol = get(0,'defaultlinecolor');
                for i=1:length(colorlist)
                    set(0,'defaultlinecolor',M.valuelist{i})
                    colorlist{i} = get(0,'defaultlinecolor');
                end
                set(0,'defaultlinecolor',deflinecol)
                M.valuelist = colorlist;
                if isempty(labellist), labellist = repmat({'X'},1,length(colorlist)); end
                docolor = true;
            catch
                set(0,'defaultlinecolor',deflinecolor)
            end
        end
        if ~isempty(M.valuelist) && isempty(labellist), labellist = M.valuelist; end
        
        % set type and style
        switch spec
            case {'checkbox' 'radiobutton'}
                M.type = 'logical';
                M.style = spec;
            case {'char' 'double' 'single' 'uint8' 'uint16' 'uint32' 'uint64' 'int8' 'int16' 'int32' 'int64'}
                M.type = spec;
                M.style = 'edit';
            case {'listbox' 'popupmenu' 'menugroup'}
                M.type = 'list';
                M.style = spec;
                dotopmenu = false;
            case 'menu'
                if isempty(M.valuelist)
                    M.type = 'logical';
                    M.style = 'menu';
                else
                    M.type = 'list';
                    M.style = 'menugroup';
                    dotopmenu = true;
                end
        end
        
        % create control
        switch M.style
            case 'menu'
                M.hu = uimenu(varargin{:});
            case 'menugroup'
                if dotopmenu
                    mparent = uimenu(varargin{:});
                    varargin = {};
                else
                    kparent = find(strcmpi(varargin(1:2:end),'parent'));
                    mparent = varargin{2*kparent};
                    varargin(2*(kparent-1)+(1:2)) = [];
                end
                n = length(M.valuelist);
                M.hu = gobjects(1,n);
                dosep = ~isempty(get(mparent,'children'));
                for i=1:n
                    M.hu(i) = uimenu(mparent,'label',labellist{i});
                    if docolor, set(M.hu(i),'foregroundcolor',colorlist{i}), end
                    if ~isempty(varargin), set(M.hu(i),varargin{:}); end
                    if i==1 && dosep, set(M.hu(i),'separator','on'), end
                end
            case {'listbox' 'popupmenu'}
                M.hu = uicontrol('style',M.style,'string',labellist,varargin{:});
            otherwise
                M.hu = uicontrol('style',M.style,varargin{:});
        end
        
        % set callback
        switch M.style
            case 'menugroup'
                for i=1:n
                    set(M.hu(i),'callback',@(u,e)setvalue(M,i))
                end
            otherwise
                set(M.hu,'callback',@(u,e)setvalue(M))
        end
        
        % display value
        updatevalue(M)
        
        % watch object property
        M.hl = addlistener(obj,prop,'PostSet',@(u,e)updatevalue(M));
        
        % delete everything upon object deletion or control deletion
        if ishandle(obj)
            fn_deletefcn(obj,@(u,e)delete(M))
        else
            addlistener(obj,'Delete',@(u,e)delete(M));
        end
        set(M.hu,'deletefcn',@(u,e)delete(M))
        
        % no output?
        if nargout==0
            clear M
        end
    end
    function delete(M)
        delete(M.hl)
        delete(M.hu(ishandle(M.hu)))
    end
    function updatevalue(M)
        curval = get(M.obj(1),M.prop);
        switch M.style
            % type logical
            case 'menu'
                set(M.hu,'checked',fn_switch(curval))
            case {'checkbox' 'radiobutton'}
                set(M.hu,'value',curval)
            % edit
            case 'char'
                set(M.hu,'string',curval)
            case 'edit'
                set(M.hu,'string',fn_chardisplay(curval))
            % list of values
            case 'menugroup'
                set(M.hu,'checked','off')
                for i=1:length(M.valuelist)
                    if isequal(curval,M.valuelist{i})
                        set(M.hu(i),'checked','on')
                        break
                    end
                end
            case {'listbox' 'popupmenu'}
                n = length(M.valuelist);
                check = false(1,n);
                if get(M.hu,'max')-get(M.hu,'min')<=1
                    curval = {curval};
                end
                for i=1:length(curval)
                    for j=1:n
                        if isequal(curval{i},M.valuelist{j})
                            check(j) = true;
                            break;
                        end
                    end
                end
                set(M.hu,'value',find(check))
        end
    end
    function setvalue(M,i)
        switch M.style
            % type logical
            case 'menu'
                set(M.obj,M.prop,~fn_switch(get(M.hu,'checked')));
            case {'checkbox' 'radiobutton'}
                set(M.obj,M.prop,logical(get(M.hu,'value')));
            % edit
            case 'char'
                set(M.obj,M.prop,get(M.hu,'value'));
            case 'edit'
                set(M.obj,M.prop,fn_chardisplay(get(M.hu,'value'),M.type));
            % list of values
            case 'menugroup'
                set(M.obj,M.prop,M.valuelist{i});
            case {'listbox' 'popupmenu'}
                idx = get(M.hu,'value');
                if get(M.hu,'max')-get(M.hu,'min')>1
                    set(M.obj,M.prop,M.valuelist(idx));
                else
                    set(M.obj,M.prop,M.valuelist{idx});
                end
        end
    end
end

end
