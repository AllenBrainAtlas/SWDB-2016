classdef fn_colorbar < hgsetget
    % function C = fn_colorbar([ha][,cmap][,clip])
    properties (Access='private')
        ha
        hi
        vertical = true;
    end
    properties
        clip
        cmap
    end
       
    % Initialization
    methods
        function C = fn_colorbar(varargin)
            % Input
            in = []; cmap0 = jet(256); clip0 = [];
            for k=1:nargin
                a = varargin{k};
                if all(ishandle(a(:))) && (isscalar(a) || strcmp(get(a(1),'type'),'axes')) 
                    in = a;
                elseif ischar(a) || size(a,2)==3
                    cmap0 = a;
                elseif isvector(a) && length(a)==2
                    clip0 = a;
                else
                    error argument
                end
            end
            defclip = ~isempty(clip0);
            if ~defclip, clip0 = [0 1]; end
            
            % Parent axes
            if isempty(in), in = figure; end
            switch get(in,'type')
                case 'figure'
                    clf(in)
                    fn_setfigsize(in,90,450);
                    set(in,'color','w','menubar','none')
                    C.ha = axes('parent',in,'pos',[.4 .05 .4 .9]);
                case 'uipanel'
                    C.ha = axes('parent',in);
                case 'axes'
                    C.ha = in;
                otherwise
                    error argument 
            end
            hf = get(C.ha,'parent'); 
            while ~strcmp(get(hf,'type'),'figure'), hf = get(hf,'parent'); end
            if isempty(get(hf,'tag')), set(hf,'tag','fn_colorbar'), end % forbid access to fn_imvalue
            su = get(C.ha,'units'); set(C.ha,'units','pixel')
            pos = get(C.ha,'pos');  set(C.ha,'units',su)
            C.vertical = (pos(4)>pos(3));
            
            % Display
            colormap(C.ha,cmap0)
            if C.vertical
                C.hi = imagesc([0 1],clip0,(1:256)','parent',C.ha,[1 256]);
                set(C.ha,'ydir','normal','xtick',[])
                if ~defclip, set(C.ha,'ytick',[]), end
            else
                imagesc(clip0,[0 1],1:256,'parent',C.ha,[1 256])
                set(C.ha,'ytick',[])
                if ~defclip, set(C.ha,'xtick',[]), end
            end
            set(C.ha,'deletefcn',@(u,e)delete(C))
            
            % Set clip and color map: automatic display update
            C.clip = clip0;
            C.cmap = cmap0;
        end
    end
    
    % Get/Set
    methods
        function set.clip(C,clip)
            C.clip = clip;
            if C.vertical %#ok<*MCSUP>
                set(C.hi,'ydata',clip)
                set(C.ha,'ytickmode','auto')
            else
                set(C.hi,'xdata',clip)
                set(C.ha,'xtickmode','auto')
            end
            axis(C.ha,'tight')
        end
        function set.cmap(C,cmap)
            if ischar(cmap)
                C.cmap = feval(cmap,256);
            else
                C.cmap = cmap;
            end
            colormap(C.ha,C.cmap)
        end
    end

    
end