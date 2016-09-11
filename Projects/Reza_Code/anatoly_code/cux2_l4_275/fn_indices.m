function varargout = fn_indices(s,varargin)
% function globi = fn_indices(sizes|array,i,j,k,...)
% function globi = fn_indices(sizes|array,ijk)
% function [i j k...] = fn_indices(sizes|array,globi)
% function ijk = fn_indices(sizes|array,globi)
%---
% converts between global and per-coordinate indices
% 
% Input:
% - array   array - use conversion for array of this size (we note nd its
%           number of dimensions)
% - size    vector - sizes of the array
%
% Input/Output:
% - i,j,k   scalar or vectors of the same length N - per-coordinates indices
% - ijk     nd vector or nd x N array - per-coordinates indices
% - globi   scalar or vector of length N - global indices
% 
% Whenever the input indices are out of bound, the output indices are set
% to zero.
%
% See also fn_imvect, fn_subsref

% Thomas Deneux
% Copyright 2004-2012

if nargin<2, help fn_indices, return, end

% Input
% (size: if first argument is an array, take its size)
if ~isnumeric(s) || ndims(s)>2 || all(size(s)>1) 
    s = size(s);
end
nd = length(s);
%if nd==1, error('why do you need to convert per-coordinates indices to global indices for a vector!!??'), end
% (which case are we treating?)
x = varargin{1};
if nargin>2
    convtype = 'pc2g';
    if ~isvector(x), error 'first of several arguments should be a vector', end
    ijk = zeros(length(varargin),length(x));
    for i=1:length(varargin), ijk(i,:) = varargin{i}; end
elseif ~isvector(x) || length(x)==nd
    convtype = 'pc2g';
    if isvector(x)
        ijk = x(:);
    else
        if size(x,1)~=nd, error('wrong size: number of rows should be the number of dimensions'), end
        ijk = x;
    end
else
    convtype = 'g2pc';
    globi = x(:)';
end

switch convtype
    case 'pc2g'             % per-coordinates -> global
        % conversion
        cs = [1 cumprod(s(1:end-1))];
        globi = 1 + cs*(ijk-1);
        % indices out of range
        bad = any(ijk<1 | bsxfun(@gt,ijk,s'),1);
        globi(bad) = 0;
        % output
        varargout = {globi};
    case 'g2pc'             % global -> per-coordinates
        % conversion
        N = length(globi);
        ijk = zeros(nd,N);
        globi0 = globi-1;
        for k=1:nd
            ijk(k,:) = 1+mod(globi0,s(k));
            globi0   = floor(globi0/s(k));
        end
        % indices out of range
        bad = globi<1 | globi>prod(s);
        ijk(:,bad) = 0;
        % output
        if nargout<2
            varargout = {ijk};
        else
            if isempty(ijk)
                varargout = cell(1,nargout);
            else
                varargout = num2cell(ijk,2);
            end
        end
end


