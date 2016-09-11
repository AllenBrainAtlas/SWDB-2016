function fn_playmovie(M,varargin)
% function fn_playmovie(M[,clip][,fps][,'once'][,'axisnormal'])
%---
% Simple display of movie.
% For color movie, time must be the 3rd dimension and color the 4th
% dimension.
% It is preferable to use fn_movie.
%
% See also fn_movie

% Thomas Deneux
% Copyright 2005-2012

% input
clip = {}; doloop = true; fps = 1000; doaxisimage = true;
for k=1:length(varargin)
    a = varargin{k};
    if ischar(a)
        switch a
            case 'once'
                doloop = false;
            case 'axisnormal'
                doaxisimage = false;
            otherwise
                error argument
        end
    elseif isscalar(a)
        fps = a;
    else
        clip = {a};
    end
end

colormap gray

clf
if ndims(M)==4 && size(M,3)==3
    n = size(M,4);
    im = imagesc(permute(M(:,:,:,1),[2 1 3]),clip{:});
else
    n = size(M,3);
    im = imagesc(permute(M(:,:,1,:),[2 1 4 3]),clip{:});
end
if doaxisimage, axis image, end
ha = axes('position',[.1 .05 .8 .01],'box','on','xlim',[1 n],'ylim',[-1 1],'ytick',[]);
pt = line('parent',ha,'xdata',1,'ydata',0,'marker','.','color','b','markersize',20, ...
    'buttondownfcn',@(u,e)fn_buttonmotion(@movepoint));
set(ha,'buttondownfcn',@(u,e)axeshit);
setappdata(pt,'mode','normal')
setappdata(pt,'play',true)
ok = uicontrol('style','toggle','pos',[10 17 35 15],'string','play','value',1,'callback',@(u,e)play());

% play
i = 1;
play()

    function play
        while ishandle(ok) && get(ok,'value')
            i = mod(i,n)+1;
            displayframe
            pause(1/fps)
            if ~doloop && i==n, set(ok,'value',0), end
        end
    end

    function displayframe
        set(pt,'xdata',i)
        if ndims(M)==4 && size(M,3)==3
            set(im,'CData',permute(M(:,:,:,i),[2 1 3]))
        else
            set(im,'CData',permute(M(:,:,i,:),[2 1 4 3]))
        end
    end

    function axeshit
        p = get(gca,'currentpoint'); x = p(1);
        if x<i, i=max(1,i-1); else i=min(n,i+1); end
        displayframe
    end

    function movepoint
        p = get(gca,'currentpoint'); 
        i = fn_coerce(round(p(1)),1,n);
        displayframe
    end

end
