classdef fn_buttongroup < hgsetget
    % function G = fn_buttongroup(style,str,callback,'prop1',value1,...)
    %---
    % Input:
    % - style       'radio' or 'toggle'
    % - str         list of string values
    % - callback    function with prototype @(x)fun(x), where x is the
    %               selected string value
    % - propn/valuen    additional properties to be set (possibilities are:
    %                   'parent', 'units', 'position', 'value')
    
    % Thomas Deneux
    % Copyright 2010-2012   
    
    properties
        callback
    end
    properties (Dependent)
        value       % string value
        valueidx    % index value
        unit
        units
        position
    end
    properties (SetAccess='private')
        style       % radio or toggle
        vertical    % true or false
        string
    end
    properties (Dependent, SetAccess='private')
        parent
    end
    properties % (Access='private')
        ugroup
        buttons
    end
    
    methods
        function G = fn_buttongroup(style,str,callback,varargin)
            % Input
            if nargin<1, style = 'radio'; end
            if nargin<2, str = {'a' 'b'}; end
            if nargin<3, callback = ''; end
            G.style = style;
            G.string = cellstr(str);
            G.callback = callback;
            args = reshape(varargin,2,length(varargin)/2);
            iscontrolprop = ismember(args(1,:),{'parent' 'unit' 'units' 'position'});
            
            % create button group
            u = uibuttongroup('SelectionChangeFcn',@(u,e)G.callback(G.value), ...
                args{:,iscontrolprop});
            G.ugroup = u;
            
            % vertical or horizontal
            sunit = get(u,'unit');
            set(u,'unit','pixel')
            pos = get(u,'pos');
            set(u,'unit',sunit);
            G.vertical = (pos(4)>pos(3)); 
            
            % place sub-buttons
            n = length(G.string);
            G.buttons = zeros(1,n);
            for i = 1:n
                if G.vertical
                    pos = [0 (i-1)/n 1 1/n];
                else
                    pos = [(i-1)/n 0 1/n 1];
                end
                G.buttons(i) = uicontrol('parent',u,'style',[style 'button'], ...
                    'units','normalized','position',pos, ...
                    'string',G.string{i});
            end
            
            % set additional properties
            if any(~iscontrolprop)
                set(G,args{:,~iscontrolprop})
            end
        end
    end

    % Get/Set directly on uicontrolgroup
    methods
        function unit = get.unit(G)
            unit = get(G.ugroup,'unit');
        end
        function set.unit(G,unit)
            set(G.ugroup,'unit',unit)
        end
        function unit = get.units(G)
            unit = get(G.ugroup,'unit');
        end
        function set.units(G,unit)
            set(G.ugroup,'unit',unit)
        end
        function pos = get.position(G)
            pos = get(G.ugroup,'pos');
        end
        function set.position(G,pos)
            set(G.ugroup,'pos',pos) %#ok<*MCSUP>
        end
        function h = get.parent(G)
            h = get(G.ugroup,'parent');
        end
    end
    
    % Get/Set
    methods
        function val = get.value(G)
            button = get(G.ugroup,'SelectedObject');
            val = get(button,'string');
        end
        function idx = get.valueidx(G)
            button = get(G.ugroup,'SelectedObject');
            idx = find(G.buttons==button);
        end
        function set.value(G,val)
            if ischar(val)
                idx = find(strcmp(val,G.string));
                if isempty(idx), error('incorrect value'), end
            else
                idx = val;
            end
            button = G.buttons(idx);
            set(button,'Value',1)
        end
        function set.valueidx(G,idx)
            set(G.buttons(idx),'Value',1)
        end
    end
    
end