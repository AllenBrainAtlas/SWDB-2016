function hf = fn_figure(name,varargin)
% function hf = fn_figure(name[,w,h][,options...])
%---
% returns a figure handle associated with a unique name: create the figure
% or return an existing figure handle depending on whether a figure with
% this name already exists

if isnumeric(name)
    if ishandle(name)
        hf = name;
    else
        hf = figure(name);
    end
else
    hf = findall(0,'type','figure','tag',name);
    if isempty(hf)
        hf = figure('name',name,'tag',name,'integerhandle','off','numbertitle','off');
    end
end
if ~isempty(varargin) && isnumeric(varargin{1})
    if length(varargin)>=2 && isnumeric(varargin{2})
        [w h] = deal(varargin{1:2});
        varargin(1:2)=[];
    else
        wh = varargin{1};
        varargin(1) = [];
        w = wh(1); h = wh(2);
    end
    fn_setfigsize(hf,w,h)
end
if ~isempty(varargin)
    set(hf,varargin{:})
end
clf(hf)
delete(get(hf,'children'))
if nargout==0
    figure(hf)
    clear hf
end
