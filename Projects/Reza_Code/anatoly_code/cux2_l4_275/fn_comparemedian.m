function fn_comparemedian(x,y,test,varargin)
% function fn_comparemedian(x,y[,test][,'tail','left|right|both'])
%---
% Perform any of 'ranksum', 'signrank' or 'signtest' test and display the
% data and p-value.
%
% Input
% - x,y     data points; for signrank or signtest, y can be a scalar
%           (the tested median value, typically 0)
% - test    'ranksum' (=default if y is nonscalar), 'signrank' or
%           'signtest' (=default if y is scalar)


% Input
if nargin<=3
    test = fn_switch(isscalar(y),'signtest','ranksum');
end

% p-value
switch test
    case 'ranksum'
        p = ranksum(x,y,varargin{:});
        flag = 'dual';
    case {'signrank' 'signtest'}
        p = feval(test,x-y,varargin{:});
        flag = fn_switch(isscalar(y),'single','dual');
    otherwise
        error('invalid test ''%s''',test)
end

% display
switch flag
    case 'dual'
        xlim = [0 3];
        xx = [ones(1,length(x)) 2*ones(1,length(y))];
        data = [row(x) row(y)];
        if strcmp(test,'ranksum')
            plot(xx,data,'o','color',[1 1 1]*.6) % no connecting lines
        else
            plot(1:2,[row(x); row(y)],'color',[1 1 1]*.6,'marker','o') % connecting lines
        end
        line(1:2,[nmean(x) nmean(y)],'color','k','linewidth',2)
        m = min(data); M = max(data);
        set(gca,'xlim',xlim,'ylim',m+[-.1 1.3]*(M-m))
        fn_markpvalue(1.5,M+.1*(M-m),p,'ns')
    case 'single'
        xlim = [0 2];
        plot(ones(1,length(x)),x,'o','color',[1 1 1]*.6)
        line([.5 1.5],mean(x)*[1 1],'color','k','linewidth',2)
        uistack(line(xlim,[y y],'color','k','linestyle','--'),'bottom')
        m = min(x); M = max(x);
        set(gca,'xlim',xlim,'ylim',m+[-.1 1.3]*(M-m))
        fn_markpvalue(1,M+.1*(M-m),p,'ns')
end

