classdef pixelposwatcher < handle
    % A 'pixel position watcher' object
    %
    % This object becomes quite useless in R2014b, but we keep it for
    % compatibility reason.
    % See also: fn_pixelposlistener, fn_pixelsizelistener, fn_pixelpos, fn_pixelsize
   
    properties (SetAccess='private')
        pixelpos
        pixelposrecursive
    end
    properties (Access='private')
        newgraphics
        hobj
        isfig
        parent
        hlistparentsize
    end
    properties (Dependent, SetAccess='private')
        pixelsize
    end
    
    events
        changepos
        changesize
    end
    
    % Initialization
    methods
        function PP = pixelposwatcher(hobj)
            if isappdata(hobj,'pixelposwatcher')
                % a position watcher for this object already exists
                PP = getappdata(hobj,'pixelposwatcher');
                return
            end
            % check Matlab version 
            PP.newgraphics = fn_matlabversion('newgraphics');
            setappdata(hobj,'pixelposwatcher',PP)
            PP.hobj = hobj;
            PP.isfig = strcmp(get(hobj,'type'),'figure');
            if ~PP.isfig && isempty(PP.parent) && ~PP.newgraphics
                hp = get(PP.hobj,'parent');
                PP.parent = pixelposwatcher(hp);
                PP.hlistparentsize = addlistener(PP.parent,'changepos',@(u,e)updatepos(PP));
            end
            PP.pixelpos = zeros(1,4);
            updatepos(PP)
            if PP.newgraphics
                addlistener(hobj,'LocationChanged',@(hf,e)updatepos(PP));
            else
                addlistener(hobj,'Position','PostSet',@(hf,e)updatepos(PP));
            end
        end
        function delete(PP)
            % PP should be deleted only when it object hobj is deleted; at
            % this moment, the listeners to hobj are also deleted, but not
            % the listener to parent 
            delete(PP.hlistparentsize)
        end
    end
    
    % Get/Set
    methods
        function s = get.pixelsize(PP)
            s = PP.pixelpos(3:4);
        end
    end
    
    % Callbacks
    methods
        function updatepos(PP)
            %disp(['updatepos ' get(PP.hobj,'type')])
            if ~ishandle(PP.hobj), delete(PP), return, end
            if PP.newgraphics
                newpos = getpixelposition(PP.hobj);
                recpos = getpixelposition(PP.hobj,true);
            else
                if PP.isfig
                    parentpos = [0 0];
                else
                    parentpos = PP.parent.pixelpos;
                end
                switch get(PP.hobj,'units')
                    case 'pixels'
                        newpos = get(PP.hobj,'pos');
                    case 'normalized'
                        newpos = get(PP.hobj,'position').*parentpos([3 4 3 4]) + [1 1 0 0];
                    case {'points' 'inches'}
                        pos = get(PP.hobj,'pos');
                        inchpos = pos / fn_switch(get(PP.hobj,'units'),'inches',1,'points',72);
                        newpos = inchpos * get(0,'ScreenPixelsPerInch');
                        newpos(1:2) = newpos(1:2)+1;
                    otherwise
                        oldunit = get(PP.hobj,'units');
                        set(PP.hobj,'units','pixel')
                        newpos = get(PP.hobj,'pos');
                        set(PP.hobj,'units',oldunit)
                end
                recpos = newpos; recpos(1:2) = recpos(1:2)+parentpos(1:2);
            end
            if isequal(recpos,PP.pixelposrecursive)
                return
            end
            chgsize = any(newpos(3:4)~=PP.pixelpos(3:4));
            PP.pixelpos = newpos;
            PP.pixelposrecursive = recpos;
            if chgsize, notify(PP,'changesize'), end
            notify(PP,'changepos')
        end
    end
    
    
end



%---
function execResizeCallbacks(hf)

callbacklist = getappdata(hf,'resizecallbacks');
for i=1:length(callbacklist)
    feval(callbacklist{i},hf,[])
end

end
