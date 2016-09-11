function m = fn_nanmean(x,varargin)
% function m = fn_nanmean(x[,dim])

nans = isnan(x);
if any(nans)
    x(nans) = 0;
    % Count up non-NaNs.
    n = sum(~nans,varargin{:});
    n(n==0) = NaN; % prevent divideByZero warnings
    % Sum up non-NaNs, and divide by the number of non-NaNs.
    m = sum(x,varargin{:}) ./ n;
else
    m = mean(x,varargin{:});
end