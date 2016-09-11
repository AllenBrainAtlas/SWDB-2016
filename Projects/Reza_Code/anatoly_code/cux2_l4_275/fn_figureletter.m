function ha = fn_figureletter(varargin)
% function ha = fn_figureletter([ha,]letters)

if nargin==0, help fn_figureletter, return, end

% Input
ha = [];
for k=1:nargin
    a = varargin{k};
    if ischar(a)
        letters = a;
    else
        ha = a;
    end
end

% prepare
n = length(letters);
if isempty(ha)
    ha = zeros(1,n);
    istart = 1;
else
    istart = length(ha)+1;
    ha(end+1:n) = 0;
end

% create
for i=istart:n
    letter = letters(i);
    ha(i) = axes; %#ok<LAXES>
    ht = text(0,0,letter,'fontunits','pixel', ...
        'fontsize',18+2*(letter>='a'),'fontweight','bold', ...
        'horizontalalignment','left','verticalalignment','bottom');
    %     fn_pixelsizelistener(ha(i),@(h,e)settextsize(ha(i),ht))
    %     settextsize(ha(i),ht)
end
set(ha,'visible','off')

%---
function settextsize(ha,ht)

% p = fn_pixelsize(ha);
% h = min(50,p(2));
% set(ht,'fontUnits','pixel','fontsize',h);

disp 'function cancelled'