function fn_labels(x_label,y_label,legend_,title_,name_)
% function fn_labels(x_label,y_label[,legend_[,title[,figure name]])
%---
% Shortcut for:
% xlabel(x_label)
% ylabel(y_label)
% fn_nicegraph
% if nargin>2, legend(legend_{:},'location','northwest'), end
% if nargin>3, title(title_), end
% if nargin>4, set(gcf,'name',name_), end
%
% See also fn_nicegraph, fn_scale, fn_plotscale

% Thomas Deneux
% Copyright 2005-2012

if nargin<1, help fn_labels, return, end
if nargin<2, y_label=''; end

fn_nicegraph
xlabel(x_label)
ylabel(y_label)
if nargin>2 && ~isempty(legend_), legend(legend_{:},'location','northwest'), end
if nargin>3, title(title_), end
if nargin>4, set(gcf,'name',name_), end


