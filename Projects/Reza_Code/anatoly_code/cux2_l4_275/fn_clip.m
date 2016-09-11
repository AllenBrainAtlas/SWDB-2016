function [x clip] = fn_clip(x,varargin)
% function [x clip] = fn_clip(x[,clipflag][,outflag][,nanvalue])
%---
% Rescale and restrict to a specific range ("clip") the data in an array.
% Make a color image if requested.  
%
% Input:
% - x           array (any dimension)
% - clipflag    clipping mode:
%               [a b]                   define manually min and max value
%               'fit','mM' or 'minmax'  use minimum and maximum [default]
%               'fitz'                  use minimum and maximum, and make the center of the range zero
%               'Xstd'                  use mean and X times standard deviation
%               'prcA-B'                use percentiles (if B is omitted,
%                                       use B = 100-A)
% - outflag     output format
%               [a b]       define minimum and maximum value [default, with
%                           a=0 and b=1]
%               n           integer values between 1 and n
%               'uint8', 'uint16', ..   integer values between 0 and max
%               nx3 array   returns a (n+1)-dimensional array using this
%                           colormap 
%               char array  use this colormap (for example 'jet' -> use
%                           jet(256))
%               'scaleonly' rescale data but do not coerce within the range
%               'getrange'  output not the cliped data, but the calculated
%                           clipping range (can be useful for 'std' and
%                           'prc' clipping calculations)
%
% - nanvalue    value to give to NaNs
%
% Output:
% - x           the clipped image (or the clipping range if outflag is
%               'getrange') 
% - clip        the clipping range 

% Thomas Deneux
% Copyright 2007-2012

if nargin==0, help fn_clip, return, end

% Input
x = fn_float(x);
clipflag = []; outflag = []; nanvalue = [];
for k=1:length(varargin)
    a = varargin{k};
    if ischar(a)
        if fn_ismemberstr(a,{'fit','mM','minmax','fitz'}) || any(regexpi(a,'(^prc)|((st|sd|std)$)'))
            clipflag = a;
        elseif length(str2num(a))==2 %#ok<ST2NM>
            clipflag = str2num(a); %#ok<ST2NM>
        else
            outflag = a;
        end
    else
        if isvector(a) && length(a)==2 && isempty(clipflag)
            clipflag = a;
        elseif isempty(outflag)
            outflag = a;
        else
            nanvalue = a;
        end
    end
end
if isempty(clipflag), clipflag='mM'; end
if isempty(outflag), outflag=[0 1]; end

% clipping mode
if isnumeric(clipflag)
    if ~isvector(clipflag) || length(clipflag)~=2, error('clipping vector must have 2 elements'), end
    clip = clipflag;
else
    xstd = regexpi(clipflag,'^([\d.]*)(st|sd|std)$','tokens');
    xprc = regexpi(clipflag,'^prc([\d.]*)[-_]*([\d.]*)$','tokens');
    if fn_ismemberstr(clipflag,{'fit' 'mM' 'minmax'})
        clip = [min(x(:)) max(x(:))];
    elseif strcmp(clipflag,'fitz')
        clip = [-1 1]*max(abs(x(:)));
    elseif ~isempty(xstd)
        xstd = xstd{1}{1};
        if isempty(xstd), xstd=1; else xstd=str2double(xstd); end
        m = mean(x(~isnan(x) & ~isinf(x)));
        st = std(x(~isnan(x) & ~isinf(x)));
        clip = m + [-1 1]*xstd*st;
    elseif ~isempty(xprc)
        low = str2double(xprc{1}{1});
        high = str2double(xprc{1}{2});
        if isnan(high), high=100-low; end
        if high<30, high=100-high; end
        clip = [prctile(x(:),low) prctile(x(:),high)];
    else
        error('erroneous clipping option')
    end
end

% output mode
doclip = true; nbit = [];
if strcmp(outflag,'getrange')
    x = clip;
    return
elseif strcmp(outflag,'scaleonly')
    doclip = false;
elseif ischar(outflag) && any(strfind(outflag,'uint'))
    docolor = false;
    nbit = sscanf(outflag,'uint%i');
    n = 2^nbit;
elseif ischar(outflag)
    docolor = true;
    fname = outflag;
    if strfind(fname,'.LUT')
        cm = fn_readasciimatrix(fname);
    else
        cm = feval(fname,256);
    end
    n = size(cm,1);
elseif ~isvector(outflag)
    if size(outflag,2)~=3, error('colormap must have 3 columns'), end
    docolor = true;
    cm = outflag;
    n = size(cm,1);
elseif isscalar(outflag)
    docolor = false;
    n = outflag;
    if mod(n,1) || n<=0, error('scalar for output format must be a positive integer'), end
else
    docolor = false;
    if length(outflag)~=2, error('vector for output format must have 2 elements'), end
    n = 0;
    a = outflag(1);
    b = outflag(2);
end

% clip
x = (x-clip(1))/diff(clip);
if ~doclip, return, end
if ~isempty(nanvalue)
    xnan = isnan(x);
end
x = min(1-eps(single(1)),max(0,x)); % it is convenient that 1 cannot be reached

% scaling
if n
    if isempty(nbit)
        x = floor(n*x)+1; % values between 1 and n
    else
        x = cast(n*x,outflag); % values between 0 and 2^nbit-1
    end
else
    x = a + x*(b-a); % b cannot be reached
end

% color and value for NaNs
if docolor
    s = size(x); %if s(2)==1, s(2)=[]; end
    if ~isempty(nanvalue)
        x(xnan) = n+1;
        cm(n+1,:) = nanvalue;
    end
    x = reshape(cm(x,:),[s 3]);
    if length(s)>2, x = permute(x,[1 2 length(s)+1 3:length(s)]); end
else
    if ~isempty(nanvalue)
        x(xnan) = nanvalue;
    end
end




        