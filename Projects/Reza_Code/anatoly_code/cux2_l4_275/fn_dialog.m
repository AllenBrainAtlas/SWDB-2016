% classdef fn_dialog
%     % this helps to create dialog windows very fast
%     
%     properties
%         % size parameters
%         hline = 30;
%         hcontrol = 2;
%         wunit = 10;
%         wtext = 20;
%         htext = 20;
%         % size control
%         wmax = 0;
%         hmax = 0;
%         xpos = 1;
%         ypos = 1;
%         % graphic elements
%         hf
%         controls
%     end
%     
%     % Constructor
%     methods
%         function G = fn_dialog
%             G.hf = figure;
%             
%         end
%     end
%     
%     % Generic
%     methods
%         function button(G,style,name,w,h,varargin)
%             hu = uicontrol( ...
%                 'style',        style, ...
%                 'position',     [
%                 end
%                 end
%                 
%                 % Specific controls
%                 methods
%             function text(G,label,w)
%             % function text(G,label[,w])
%             if nargin<2, wt = G.wtext; else wt = G.wunit * w; end
%             ht = G.htext;
%             button(G,'text','',wt,ht,'string',label)
%             end
%         end
%         
%     end

% Thomas Deneux
% Copyright 2012-2012
