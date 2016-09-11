classdef interface < hgsetget
    % Interface class provide utilities for designing a graphic interface,
    % such as allowing the user to resize the graphical elements, loading
    % and auto-saving program options, etc..
    %
    % Notes:
    % - to make a new interface, define a new class having interface as a
    %   parent
    % - constructor: 
    %     . in the new object constructor, first call the interface
    %       constructor (X = X@interface(hf,figtitle,defaultoptions)
    %     . then define the graphic objects that user can resize in the
    %       'grob' property
    %     . then call interface_end(X) to auto-position these objects
    % - methods:
    %     . if the child class defines menus additional to the one of
    %       interface, it should do it in a init_menus(X), which starts by
    %       calling init_menus@interface(X); menu handles can be stored in
    %       the structure X.menus
    %     . interface overwrites the default set method in order to easily 
    %       provide the user with a description of the value to enter; for
    %       such to happen, the child class should have a method x =
    %       setinfo(X) that returns a stucture with field names and
    %       description values (which can be a string or a cell with
    %       possible values)
    %
    % An example is provided in [Brick toolbox dir]/examples/example_interface
    
    % Thomas Deneux
    % Copyright 2007-2012
    
    properties (Access='private')
        figtitle
    end
    properties (SetAccess='protected')
        hf
        grob
        options = struct('positions',struct('name','base','value',[]));
        menus = struct('interface',[]);
        interfacepar
    end
    properties (Dependent, Access='private')
        settings
    end
    
    % Initialization
    methods
        function I = interface(hf,figtitle,defaultoptions)
            if nargin==0
                hf = 827;
                figtitle = 'INTERFACE';
            end
            
            % options
            interfaceoptions = I.options; % minimal default options
            loadoptions(I)                % load saved options
            if nargin>=3 && ~isempty(defaultoptions)
                % some new options might have been created (either in
                % 'interface' or in the child class), other might have been
                % removed -> update the saved options
                defaultoptions = fn_structmerge(interfaceoptions,defaultoptions); % default set
                I.options = fn_structmerge(defaultoptions,I.options,'skip');      % update
                saveoptions(I)
            end
            
            % internal parameters
            I.interfacepar = struct( ...
                'dosavesubframe',   false, ...
                'subframe',         [], ...
                'hsubframe',        [] ...
                );
                
            % figure
            I.hf = hf;
            I.figtitle = figtitle;
            if hf~=0 % use hf=0 for a command line interface only!
                figure(hf)
                set(hf,'numbertitle','off','name',figtitle)
                set(hf,'resize','off')
                if ~isempty(I.options.positions(1).value), set(hf,'pos',I.options.positions(1).value.hf), end
                clf(hf), delete(findall(hf,'parent',hf))
                I.grob.hf = hf;
            end
            
            % end of initialization
            if strcmp(class(I),'interface'), interface_end(I), end %#ok<STISA>
        end
        
        function interface_end(I)
            % end of initialization: call after additional object
            % initializations
            % these initializations should in particular define grob
            
            % graphic interface or command line only?
            if I.hf~=0
                
                % interface menu
                init_menus(I)
                
                % position frames
                chgframepositions(I,'set')
                drawnow
                
                % delete object when closing the window
                set(I.hf,'DeleteFcn',@(h,e)delete(I(isvalid(I))))
                
            end
            
            % make object available in base workspace
            assignin('base',inputname(1),I)
        end
    end
    
    % Methods
    methods
        function fname = get.settings(I)
            fname = fn_userconfig('configfolder',[class(I) '.mat']);
        end
        function init_menus(I)
            % delete existing menus
            F = fieldnames(I.menus);
            for k=1:length(F)
                f = F{k};
                m = I.menus.(f);
                if ishandle(m), delete(m), end
                V.menus.(f) = [];
            end
            
            % create main menu
            m = uimenu('parent',I.hf,'label',I.figtitle);
            I.menus.interface = m;
            items = struct;
            s = I.interfacepar;
            
            % positioning
            uimenu(m,'label','Change current display', ...
                'callback',@(u,evnt)chgframepositions(I,'reset'));
            pos = I.options.positions; npos = length(pos);
            m1 = uimenu(m,'label','Saved displays');
            for k=1:npos
                f = pos(k).name;
                uimenu(m1,'label',f, ...
                    'callback',@(u,evnt)chgframepositions(I,'load',f));
            end
            uimenu(m1,'label','Create new...','separator','on', ...
                'callback',@(u,evnt)chgframepositions(I,'new'));
            m2 = uimenu(m1,'label','Delete');
            for k=1:npos
                f = pos(k).name;
                uimenu(m2,'label',f, ...
                    'callback',@(u,evnt)chgframepositions(I,'delete',f));
            end
            
            % expert buttons
            varname = inputname(1);
            uimenu(m,'label','Object in base workspace','separator','on', ...
                'callback',@(u,evnt)assignin('base',varname,I))
            if fn_dodebug
                uimenu(m,'label','Edit code', ...
                    'callback',@(u,evnt)edit(which(class(I))))
                uimenu(m,'label','Reinit menus', ...
                    'callback',@(u,evnt)init_menus(I))
            end
            
            % save image
            uimenu(m,'label','Save PNG','separator','on','accelerator','P', ...
                'callback',@(u,evnt)saveimage(I,'autoname'))
            uimenu(m,'label','Copy sub-part...', ...
                'callback',@(u,evnt)fn_savefig(I.hf,'showonly','subframe'))
            m1 = uimenu(m,'label','More');
            items.savesub  = uimenu(m1,'label','Use sub-frame','checked',fn_switch(s.dosavesubframe), ...
                'callback',@(u,e)setsaveframe(I,'toggle'));
            items.savefull = uimenu(m1,'label','Define sub-frame...', ...
                'callback',@(u,e)setsaveframe(I,'def'));
            uimenu(m1,'label','Save image (select file)...', ...
                'callback',@(u,evnt)saveimage(I))
            uimenu(m1,'label','Save image (full options)...', ...
                'callback',@(u,evnt)fn_savefig(I.hf))
            uimenu(m1,'label','Copy figure', ...
                'callback',@(u,evnt)fn_savefig(I.hf,'showonly'))
            
            % save items
            I.interfacepar.menuitems = items;
        end
        function saveoptions(I)
            fn_savevar(I.settings,I.options)
        end
        function savedefaultoptions(I)
            codefile = which(class(I));
            fdefault = [fn_fileparts(codefile,'noext') '.mat'];
            fn_savevar(fdefault,I.options)
        end
        function loadoptions(I)
            % create default options if not any yet
            fname = I.settings;
            codefile = which(class(I));
            fdefault = [fn_fileparts(codefile,'noext') '.mat'];
            if ~exist(fdefault,'file')
                savedefaultoptions(I)
                saveoptions(I)
                return
            end
            % load options
            try
                I.options = fn_loadvar(fname);
            catch %#ok<CTCH>
                % if no user option file yet or problem with it, load
                % default options
                I.options = fn_loadvar(fdefault);
            end
            % handle previous options
            if isfield(I.options,'pos')
                pos = I.options.pos;
                I.options = rmfield(I.options,'pos');
                I.options.positions = struct('name','base','value',pos);
                %saveoptions(I)
            end
        end
        function chgframepositions(I,flag,varargin)
            pos = I.options.positions;
            npos = length(pos);
            curpos = pos(1).value;
            doreinitmenus = false;
            switch flag
                case 'reset'
                    pos(1).value = fn_framedesign(I.grob,curpos,true);
                    %                     obj = struct2cell(rmfield(I.grob,'hf'));
                    %                     obj = [obj{:}];
                    %                     set(obj,'units','pixel')
                case 'set'
                    pos(1).value = fn_framedesign(I.grob,curpos,[]);
                case 'load'
                    f = varargin{1};
                    idx = find(strcmp(f,{pos.name}));
                    pos = pos([idx setdiff(1:npos,idx)]);
                    pos(1).value = fn_framedesign(I.grob,pos(1).value,[]);
                    doreinitmenus = true;
                case 'new'
                    name = inputdlg('Name of new position configuration','Enter name',1);
                    if isempty(name) || fn_ismemberstr(name,{pos.name})
                        errordlg('Invalid name (empty or already exists)')
                        return
                    end
                    pos = [struct('name',name,'value',curpos) pos];
                    doreinitmenus = true;
                case 'delete'
                    f = varargin{1};
                    idx = find(strcmp(f,{pos.name}));
                    if idx==1
                        errordlg('Cannot delete current configuration')
                        return
                    end
                    pos(idx) = [];
                    doreinitmenus = true;
            end
            I.options.positions = pos;
            saveoptions(I)
            if doreinitmenus, init_menus(I), end
        end
        function saveimage(I,fname)
            if nargin>=2, fname = {fname}; else fname = {'askname'}; end
            if I.interfacepar.dosavesubframe
                set(I.interfacepar.hsubframe,'visible','off')
                fn_savefig(I.hf,fname{:},I.interfacepar.subframe);
                set(I.interfacepar.hsubframe,'visible','on')
            else
                fn_savefig(I.hf,fname{:})
            end
        end
        function setsaveframe(I,flag)
            switch flag
                case 'toggle'
                    dosubframe = ~I.interfacepar.dosavesubframe;
                    I.interfacepar.dosavesubframe = dosubframe;
                    items = I.interfacepar.menuitems;
                    set(items.savesub,'checked',fn_switch(dosubframe))
                    set(I.interfacepar.hsubframe,'visible',fn_switch(dosubframe))
                    dodef = dosubframe && isempty(I.interfacepar.subframe);
                case 'def'
                    dodef = true;
                otherwise
                    error 'unknown flag'
            end
            if dodef
                delete(I.interfacepar.hsubframe)
                [I.interfacepar.subframe I.interfacepar.hsubframe] = deal([]); % just in case selection will be interrupted
                [I.interfacepar.subframe I.interfacepar.hsubframe] = fn_figselection(I.hf);
                set(I.interfacepar.hsubframe,'visible',fn_switch(I.interfacepar.dosavesubframe))
            end
        end
        function set(I,f,x)
            if ~isvalid(I), return, end
            if nargin<3
                desc = setinfo(I);
                if nargin<2
                    M = metaclass(I);
                    M = [M.Properties{:}];
                    for k=1:length(M)
                        if ~strcmp(M(k).SetAccess,'public'), continue, end
                        f = M(k).Name;
                        if isfield(desc,f), str = makestr(desc.(f)); else str=[]; end
                        if isempty(str)
                            fprintf('\t%s\n',f)
                        else
                            fprintf('\t%s: %s\n',f,str)
                        end
                    end
                else
                    if isfield(desc,f), disp(makestr(desc.f)), end
                end
            else
                I.(f) = x;
            end
        end
        function x = setinfo(I) %#ok<MANU>
            x = struct;
        end
    end
    
    % Static methods
    methods (Static)
        function d = usercodepath
            d = fn_userconfig('codefolder');
            p = path;
            if isempty(strfind(p,d)), addpath(d), end
        end
    end
end

function desc = makestr(desc)

if isempty(desc)
    desc = '';
elseif iscell(desc)
    desc = [ '[' sprintf(' %s |',desc{:})];
    desc(end) = ']';
end

end







