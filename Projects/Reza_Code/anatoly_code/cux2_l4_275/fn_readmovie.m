function a = fn_readmovie(filename,frames)
% function a = fn_readmovie(filename,frames)
%---
% read an avi file and stores it into a 2D+time array 
% (2D+time+channel if color movie)
%
% See also fn_savemovie

% Thomas Deneux
% Copyright 2004-2012

if nargin<1
    filename = fn_getfile('*.avi');
end
if nargin<2, frames={}; end

disp 'reading'
try
    % recent Matlab version
    if ~isempty(frames), frames = {frames([1 end])}; end
    a = read(VideoReader(filename),frames{:});
catch
    if ~isempty(frames), frames = {frames}; end
    a = aviread(filename,frames{:});
    switch size(a(1).cdata,3)
        case 1
            a = cat(3,a.cdata);
        case 3
            s = size(a(1).cdata);
            nt = length(a);
            a = cat(2,a.cdata);
            a = reshape(a,[s(1) s(2) nt 3]);
        otherwise
            error('problem')
    end
end
disp 'transposing frames'
a = permute(a,[2 1 3 4]);
