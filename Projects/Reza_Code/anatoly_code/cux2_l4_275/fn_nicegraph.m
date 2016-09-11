function fn_nicegraph(ha)
% function fn_nicegraph([ha])
%---
% see also fn_labels, fn_scale, fn_plotscale

% Thomas Deneux
% Copyright 2005-2012

if nargin==0, ha = gca; end

hl=findobj(ha,'type','line');
set(hl,'linewidth',2)

% % make some lines dash, etc..
% styles = {'-','--',':','-.'};
% nhl = length(hl);
% for k=0:(nhl-1)/7
%     set(hl(7*k+1:min(nhl,7*(k+1))),'linestyle',styles{k+1})
% end

set(ha,'fontsize',12)
set(get(ha,'ylabel'),'fontsize',14)
set(get(ha,'xlabel'),'fontsize',14)

set(ha,'xgrid','on','ygrid','on')

set(gcf,'paperposition',[.25 .5 4 3])

axis tight