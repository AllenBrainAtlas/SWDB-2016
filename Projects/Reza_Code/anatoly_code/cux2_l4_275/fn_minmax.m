function x = fn_minmax(varargin)
% function fn_minmax(action,x1,x2,..)
%
% utility to easily compute best axes positions...
% 'action' determines what to do :
% - 'minmax'    -> [min(xi(1)) max(xi(2))]
% - 'maxmin'    -> [max(xi(1)) min(xi(2))]
% - 'axi'       -> [max min max min] (i.e. intersection of 2 ranges)
% - 'axu'       -> [min max min max] (i.e. union of 2 ranges)
% - logical vector -> ok

% Thomas Deneux
% Copyright 2006-2012

if nargin==0, help fn_minmax, return, end

action = varargin{1};
if strcmp(action,'axis'), warning('''axis'' flag has been replaced by ''axi'''), action='axi'; end
if ischar(action)
    x = varargin{2};
    switch action
        case 'minmax'
            action = [0 1];
        case 'maxmin'
            action = [1 0];
        case 'axi'
            action = repmat([1 0],1,length(x)/2);
        case 'axu'
            action = repmat([0 1],1,length(x)/2);
    end
end
if ~all(action==0 | action==1), error('bad action argument'); end

if isvector(action)
    imax = find(action);
    imin = find(~action);
    if isvector(varargin{2})
        x = varargin{2};
        for i=2:nargin-1 % vectors
            xi = varargin{i+1};
            %             if ~any(size(xi)==1) || length(xi)~=length(action)
            %                 error('arguments are not the same length')
            %             end
            x(imin) = min(x(imin),xi(imin));
            x(imax) = max(x(imax),xi(imax));
        end
    else % one matrix
        x1 = varargin{2};
        x = zeros(size(x1,1),1);
        if nargin>2, error('too many arguments'); end
        x(imin) = min(x1(:,imin));
        x(imax) = max(x1(:,imax));
    end
else % matrices
    x = zeros(size(action))*nan;
    imax = find(action);
    imin = find(~action);
    for i=1:nargin-1
        xi = varargin{i+1};
        if size(xi)~=size(action)
            error('arguments are not the size')
        end
        x(imin) = min(x(imin),xi(imin));
        x(imax) = max(x(imax),xi(imax));
    end
end
