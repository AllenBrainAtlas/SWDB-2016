function fn_review_showres(x,info)
% function fn_review_showres(x,info)
%---
% this function is the default call by function fn_review
% it can be edited, but always have only one argument
% after finishing using it, please return the code to 'plot(x), axis tight'
%
% See also fn_review

% Thomas Deneux
% Copyright 2005-2012


plot(squeeze(x),'parent',info.ha), axis tight
        
