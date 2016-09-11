classdef montage < interface

    properties
        im = immodel('empty');
        X
        context
        showmarks = true;
    end
    
    methods
        function M = montage(fname)
            hf = figure('name','montage','integerhandle','off');
            M = M@interface(hf,'Montage');
            set(hf,'resize','on')
            init_context(M)
            init_grob(M)
            interface_end(M)
            init_control(M)
            %M.loadimages(evalin('base','a'))
            if nargin==1
                loaddata(M,fname)
            else
                load_example(M)
            end
        end
        function init_grob(M)
            M.grob.ha = axes( ...
                'buttondownfcn',@(u,e)moveaxis(M));
            fn_pixelsizelistener(M.grob.ha,@(u,e)M.show('reset'))
            colormap(M.grob.ha,gray(256))
            M.grob.x = uipanel; %('units','pixel','buttonDownFcn',@(u,e)fn_moveobject(u));
            fn_pixelsizelistener(M.grob.x,@(u,e)M.init_control)
            fn_scrollwheelregister(M.hf,@(n)scrollaxis(M,n))
            M.grob.list = uicontrol('style','listbox','max',2,'units','normalized', ...
                'callback',@(u,e)M.selectimages(get(u,'value')), ...
                'uicontextmenu',M.context);
        end
        function init_menus(M)
            init_menus@interface(M)
            % content
            m = M.menus.interface;
            uimenu(m,'label','add images from files','separator','on',...
                'callback',@(u,e)loadimages(M,'file'))
            uimenu(m,'label','add images from base workspace',...
                'callback',@(u,e)loadimages(M,'matlab'))
            uimenu(m,'label','erase',...
                'callback',@(u,e)erase(M))
            % load/save
            uimenu(m,'label','Open...','separator','on',...
                'callback',@(u,e)loaddata(M))
            uimenu(m,'label','Save as...',...
                'callback',@(u,e)savedata(M))
            % show marks
            uimenu(m,'label','Show marks','separator','on','Checked',fn_switch(M.showmarks), ...
                'callback',@(u,e)set(M,'showmarks',~M.showmarks))
        end
        function init_control(M)
            s = struct( ...
                'bin__images',  {1  'double'}, ...
                'alpha',    {.7     'slider 0 1'}, ...
                'white',    {0      'slider 0 1'}, ...
                'clip',     {'fit'  'char'});
            M.X = fn_control(s,@(s)action(M,'control'),M.grob.x);
        end
        function init_context(M)
            if isempty(M.context)
                m = uicontextmenu('parent',M.hf);
                M.context = m;
            else
                m = M.context;
                delete(get(m,'children'))
            end
            uimenu(m,'label','move to top','callback',@(u,e)action(M,'stacktop','context'))
            uimenu(m,'label','move to bottom','callback',@(u,e)action(M,'stackbottom','context'))
            uimenu(m,'label','set scale','callback',@(u,e)action(M,'setscale','context'))
            uimenu(m,'label','no rotation','callback',@(u,e)action(M,'norotation','context'))
            uimenu(m,'label','not transparent','callback',@(u,e)action(M,'noalpha','context'))
            uimenu(m,'label','active','callback',@(u,e)action(M,'active','context'))
            uimenu(m,'label','inactive','callback',@(u,e)action(M,'inactive','context'))
            uimenu(m,'label','discard','callback',@(u,e)action(M,'discard','context'))
        end
        function load_example(M)
            v = load('clown');
            s(1) = struct('name','clown','data',fn_clip(v.X',v.map),'xc',200,'yc',100,'scale',1,'rot',0);
            v = load('chess');
            s(2) = struct('name','chess','data',fn_clip(v.X',v.map),'xc',0,'yc',0,'scale',1,'rot',pi/6);
            M.im = fn_structmerge(immodel,s);
            show(M,'reset')
        end
        function loadimages(M,varargin)
            % loadimage(M,a[,names|structure])
            % loadimage(M,'file')
            % loadimage(M,'matlab')
            name = []; doconfirmnames = true; sim = [];
            if isnumeric(varargin{1}) || iscell(varargin{1})
                a = varargin{1};
                if ~iscell(a), a = {a}; end
                if nargin>=3
                    if nargin>3, b = struct(varargin{2:end}); else b = varargin{2}; end
                    if isstruct(b)
                        sim = b;
                        if isfield(sim,'name'), name = {sim.name}; doconfirmnames = false; end
                    else
                        name = varargin{2};
                        if ~iscell(name), name = {name}; doconfirmnames = false; end
                    end
                end
            else
                switch varargin{1}
                    case 'file'
                        f = cellstr(fn_getfile);
                        nim = length(f);
                        a = cell(1,nim);
                        for i=1:nim, a{i}=fn_readimg(f{i}); end
                        name = fn_fileparts(f,'base');
                    case 'matlab'
                        str = inputdlg('Enter cell array, or individual images separated by commas','Add images');
                        a = evalin('base',['{' str{1} '}']);
                        if isscalar(a) && iscell(a{1}), a = a{1}; end
                end
            end
            nim = length(a);
            if doconfirmnames
                if isempty(name), name = repmat({''},1,nim); end
                name = inputdlg(repmat({'name:'},1,nim),'Add images',1,name);
            end
            model = immodel;
            for i=1:nim
                simi = struct('name',name{i},'data',a{i},'xc',0,'yc',0,'scale',1,'rot',0);
                if ~isempty(sim), simi = fn_structmerge(simi,sim(i)); end
                M.im(end+1) = fn_structmerge(model,simi);
            end
            show(M,'reset')
        end
        function erase(M)
            M.im(:)=[];
            show(M)
        end
        function show(M,flag,idx)
            if nargin<2, flag=''; end
            ha = M.grob.ha;
            if isempty(M.im)
                cla(ha), delete(get(ha,'children'))
                set(ha,'xtick',[],'ytick',[],'box','on')
                set(M.grob.list,'string',{},'value',[])
                return
            end
            if strcmp(flag,'reset'), cla(ha), delete(get(ha,'children')), end
            if ~strcmp(flag,'move')
                idx = fliplr(1:length(M.im)); % flip it to have first image at the bottom
            end
            xbin = M.X.bin__images; if xbin==0, xbin=1; end
            hstackbottom = []; % images will be sent to bottom so that all handles remain visible
            for i=idx
                s = M.im(i);
                a = s.data;
                if ndims(a)<3
                    a = uint8(fn_clip(a,M.X.clip,[0 255]));
                elseif size(a,3)==4
                    % remove transparency channel
                    a(:,:,4) = [];
                end
                if xbin>1, a = uint8(fn_bin(a,xbin)); end
                [ni nj ncol] = size(a);
                ngrid = 2;
                [ii jj] = ndgrid(linspace(1,ni,ngrid),linspace(1,nj,ngrid));
                ij = [ones(1,ngrid*ngrid); row(ii); row(jj)];
                T1 = [1 0 0; [-(ni+1)/2; -(nj+1)/2] eye(2)]; % set central pixel to zero
                TSR = [[s.xc; s.yc] s.scale*xbin*[cos(s.rot) -sin(s.rot); sin(s.rot) cos(s.rot)]];
                xy = (TSR*T1)*ij;
                xx = reshape(xy(1,:),ngrid,ngrid); yy = reshape(xy(2,:),ngrid,ngrid);
                zz = zeros(ngrid);
                xyh = TSR*[1 1; [0; 0] [(ni+1)/2; 0]]; % handles: center, right side
                switch flag
                    case 'move'
                        if ~s.active, continue, end
                        set(M.im(i).h(1),'xdata',xx,'ydata',yy)
                        if M.showmarks
                            set(M.im(i).h(2),'xdata',xyh(1,1),'ydata',xyh(2,1))
                            set(M.im(i).h(3),'xdata',xyh(1,2),'ydata',xyh(2,2))
                            set(M.im(i).h(4),'pos',[xyh(1,1) xyh(2,1)])
                        end
                    otherwise
                        delete(s.h(ishandle(s.h)))
                        M.im(i).h = [];
                        if ~s.active, continue, end
                        M.im(i).h(1) = surface(xx,yy,zz,a,'parent',M.grob.ha, ...
                            'EdgeColor','none','FaceColor','texturemap','FaceAlpha',M.X.alpha, ...
                            'CDataMapping','direct', ...
                            'buttondownfcn',@(u,e)action(M,'middlebutton',i), ...
                            'uiContextMenu',M.context,'userdata',i);
                        if ~isempty(s.transparentcolor)
                            mask = false;
                            for k=1:size(s.transparentcolor,1)
                                col = third(s.transparentcolor(k,:));
                                mask = mask | all(bsxfun(@eq,s.data,col),3);
                            end
                            alpha = mask*M.X.white + ~mask*M.X.alpha;
                            set(M.im(i).h(1),'alphadata',alpha,'alphadatamapping','none','facealpha','texturemap')
                        end
                        hstackbottom(end+1) = M.im(i).h(1); %#ok<AGROW> % image will be sent to bottom
                        if M.showmarks
                            M.im(i).h(2) = line(xyh(1,1),xyh(2,1),'parent',M.grob.ha,'linestyle','none','marker','s', ...
                                'buttondownfcn',@(u,e)action(M,'movegroup',i), ...
                                'uiContextMenu',M.context,'userdata',i);
                            M.im(i).h(3) = line(xyh(1,2),xyh(2,2),'parent',M.grob.ha,'linestyle','none','marker','o', ...
                                'buttondownfcn',@(u,e)action(M,'rotate',i));
                            M.im(i).h(4) = text(xyh(1,1),xyh(2,1),s.name,'parent',M.grob.ha,'hittest','off', ...
                                'horizontalalignment','center','verticalalignment','middle','interpreter','none');
                        end
                        %set(M.im(i).h,'visible',fn_switch(s.active))
                end
                % send images to bottom
                uistack(hstackbottom,'bottom')
            end
            if strcmp(flag,'reset')
                fn_axis(ha,'tight',1.02)
                ax = axis(ha);
                pp = fn_pixelsize(ha);
                r = pp(2)/pp(1);
                rc = (ax(4)-ax(3))/(ax(2)-ax(1));
                if rc>r
                    % need to expand in x
                    ax(1:2) = mean(ax(1:2)) + [-.5 .5]*diff(ax(3:4))/r;
                else
                    % need to expand in y
                    ax(3:4) = mean(ax(3:4)) + [-.5 .5]*diff(ax(1:2))*r;
                end
                axis(ha,ax)
                set(ha,'xtick',[],'ytick',[],'box','on','ydir','reverse')
                allnames = fn_map(1:length(M.im),@(i)[num2str(i,'[%i] ') M.im(i).name],'cell');
                set(M.grob.list,'string',allnames,'value',[])
            end
        end
        function savedata(M,fname)
            if nargin<2, fname = fn_savefile('*.mat'); end
            fname = fn_fileparts(fname,'noext');
            if isempty(regexp(fname,'_montage$', 'once')), fname = [fname '_montage']; end
            fname = [fname '.mat'];
            fn_savevar(fname,M.im)
        end
        function loaddata(M,fname)
            if nargin<2, fname = fn_getfile('*.mat'); if ~fname, return, end, end
            M.im = fn_structmerge(immodel,fn_loadvar(fname));
            M.show('reset')
            set(M.grob.list,'string',{M.im.name},'value',[])
        end
        function set.showmarks(M,x)
            M.showmarks = x;
            M.show
        end
    end
    
    % Callbacks
    methods
        function selectimages(M,idx)
            if M.showmarks
                h = cat(1,M.im.h);
                if ~isempty(h), set(h(:,2:3),'color','b'), end
            end
            h = cat(1,M.im(idx).h); 
            if ~isempty(h)
                if M.showmarks, set(h(:,2:3),'color','r'), end
                action(M,'stacktop',idx)
            end
        end
        function moveaxis(M)
            if strcmp(get(M.hf,'selectiontype'),'extend')
                igroup = get(M.grob.list,'value');
                if ~isempty(igroup) && any([M.im(igroup).active])
                    action(M,'movegroup',igroup(1))
                    return
                end
            end
            ha = M.grob.ha;
            p0 = get(M.hf,'currentpoint');
            curpointer = get(M.hf,'pointer');
            set(M.hf,'pointer','hand')
            p0 = get(ha,'currentpoint'); p0 = p0(1,1:2);
            ax = axis(ha);
            fn_buttonmotion(@chgaxis,M.hf)
            function chgaxis
                p = get(ha,'currentpoint'); p = p(1,1:2);
                movax = p0-p;
                %                 sidedist = M.oldaxis - M.axis;
                %                 movax = max(sidedist(:,1),min(sidedist(:,2),movax));
                ax = ax + movax([1 1 2 2]);
                axis(ha,ax)
            end
            set(M.hf,'pointer',curpointer)
        end
        function scrollaxis(M,n)
            n=n/10;
            ha = M.grob.ha;
            p = get(ha,'currentpoint'); p = p(1,[1 1 2 2]);
            ax = axis(ha);
            ax = p + (ax-p)*(1.2^n);
            axis(ha,ax)
        end
        function action(M,flag,i)
            seltype = get(M.hf,'selectionType');
            dogroup = false;
            % special cases
            switch flag
                case 'middlebutton'
                    if strcmp(seltype,'normal'), flag='moveaxis'; else flag='move'; end
                case 'movegroup'
                    dogroup = any(get(M.grob.list,'value')==i);
                    flag = 'move';
            end
            if nargin>=3
                if dogroup
                    i = get(M.grob.list,'value');
                elseif strcmp(i,'context')
                    if gco==M.grob.list
                        i = get(M.grob.list,'value');
                        dogroup = true;
                    else
                        i = get(gco,'userdata');
                    end
                end
                if ~dogroup && ~isequal(get(M.grob.list,'value'),i)
                    set(M.grob.list,'value',i)
                    selectimages(M,i)
                end
            end
            switch flag
                case 'moveaxis'
                    if strcmp(seltype,'alt'), return, end
                    moveaxis(M)
                case {'move' 'rotate'}
                    if strcmp(seltype,'alt'), return, end
                    curpointer = get(M.hf,'pointer');
                    set(M.hf,'pointer','hand')
                    ha = M.grob.ha;
                    p0 = get(ha,'currentpoint'); p0 = p0(1,1:2);
                    s = M.im(i);
                    [xc0 yc0] = deal({s.xc},{s.yc});
                    fn_buttonmotion(@mov,M.hf)
                    set(M.hf,'pointer',curpointer)
                case 'norotation'
                    [M.im(i).rot] = deal(0);
                    M.show('move',i)
                case 'noalpha'
                    for s = M.im(i)
                        set(s.h(1),'facealpha',1)
                    end
                case 'setscale'
                    x = evalin('base',fn_input('scale',num2str(M.im(i(1)).scale)));
                    if ~(isscalar(x) && isnumeric(x)), return, end
                    [M.im(i).scale] = deal(x);
                    M.show('move',i)
                case 'stackbottom'
                    if fn_matlabversion('newgraphics')    
                        hh = cat(1,M.im(i).h);
                        uistack(hh(:,1),'bottom')
                    else
                        for k=i, uistack(M.im(k).h(1),'bottom'), end
                    end
                case 'stacktop'
                    % send the other images to bottom rather send the
                    % selected images to top: that way, all handles remain
                    % on top
                    j = setdiff(1:length(M.im),i);
                    if fn_matlabversion('newgraphics')    
                        hh = cat(1,M.im(j).h);
                        uistack(hh(:,1),'bottom')
                    else
                        for k=j, uistack(M.im(k).h(1),'bottom'), end
                    end
                case 'control'
                    if all(ismember(M.X.changedfields,{'alpha' 'white'}))
                        % no need to redisplay everything
                        for i=1:length(M.im)
                            s = M.im(i);
                            if ~s.active, continue, end
                            if isempty(s.transparentcolor)
                                set(s.h(1),'facealpha',M.X.alpha)
                            else
                                mask = false;
                                for k=1:size(s.transparentcolor,1)
                                    col = third(s.transparentcolor(k,:));
                                    mask = mask | all(bsxfun(@eq,s.data,col),3);
                                end
                                alpha = mask*M.X.white + ~mask*M.X.alpha;
                                set(s.h(1),'alphadata',alpha,'alphadatamapping','none','facealpha','texturemap')
                            end
                        end
                    else
                        M.show('')
                    end
                case 'discard'
                    M.im(i) = [];
                    M.show('reset')
                case 'active'
                    [M.im(i).active] = deal(true);
                    M.show()
                case 'inactive'
                    [M.im(i).active] = deal(false);
                    delete([M.im(i).h])
                    [M.im(i).h] = deal([]);
            end
            
            function mov
                p = get(ha,'currentpoint'); p = p(1,1:2); 
                if strcmp(flag,'move')
                    d = p-p0;
                    for ki=1:length(i)
                        M.im(i(ki)).xc = xc0{ki}+d(1);
                        M.im(i(ki)).yc = yc0{ki}+d(2);
                    end
                else
                    M.im(i).rot = atan2(p(2)-yc0{1},p(1)-xc0{1});
                end
                M.show('move',i)
            end
        end
    end
    
    % Output
    methods
        function a = getAlignedImages(M,dx)
            if nargin<2, dx=min([M.im.scale]); end
            n = length(M.im);
            a = {M.im.data};
            
            % smoothing
            for kim=1:n
            end
            % grid size
            range = NaN(1,4);
            for kim=1:n
                s = M.im(kim);
                [ni nj ~] = size(s.data);
                [ii jj] = ndgrid(linspace(1,ni,2),linspace(1,nj,2));
                ij = [ones(1,2*2); row(ii); row(jj)];
                T1 = [1 0 0; [-(ni+1)/2; -(nj+1)/2] eye(2)]; % set central pixel to zero
                TSR = [[s.xc; s.yc] s.scale*[cos(s.rot) -sin(s.rot); sin(s.rot) cos(s.rot)]];
                xy = (TSR*T1)*ij;
                range = fn_minmax('axu',[min(xy(1,:)) max(xy(1,:)) min(xy(2,:)) max(xy(2,:))]);
            end
            % interpolate
            [xx yy] = ndgrid(range(1):dx:range(2),range(3):dx:range(4));
            [nx ny] = size(xx);
            xy = [ones(1,numel(xx)); row(xx); row(yy)];
            fn_progress('interpolate',n)
            for kim=1:n
                fn_progress(kim)
                s = M.im(kim);
                [ni nj ncol] = size(s.data);
                [ii jj] = ndgrid(1:ni,1:nj);
                T1 = [1 0 0; [-(ni+1)/2; -(nj+1)/2] eye(2)]; % set central pixel to zero
                TSR = [1 0 0; [s.xc; s.yc] s.scale*[cos(s.rot) -sin(s.rot); sin(s.rot) cos(s.rot)]]*T1;
                TSR1 = TSR^-1; TSR1(1,:)=[];
                ijinterp = TSR1*xy;
                ak = cell(1,ncol);
                for k=1:ncol
                    ak{k} = interpn(ii,jj,double(a{kim}(:,:,k)),ijinterp(1,:),ijinterp(2,:));
                end
                ak = reshape(cat(3,ak{:}),[nx ny ncol]);
                a{kim} = uint8(ak);
            end
        end
    end
end

function im = immodel(emptyflag)

im=struct('name',[],'data',[],'xc',[],'yc',[],'scale',[],'rot',[],'h',[], ...
    'active',true,'transparentcolor',[]);
if nargin>=1 && strcmp(emptyflag,'empty'), im(1)=[]; end

end
