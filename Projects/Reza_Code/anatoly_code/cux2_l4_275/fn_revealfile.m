function fn_revealfile(fname)
% function fn_revealfile(fname)
%---
% Reveal file in Windows Explorer

if ~ispc
    error 'fn_revealfile works only on Windows'
end
if ~exist(fname,'file')
    error('cannot locate file ''%s''',fname)
end

system(['explorer /select,"' which(fname) '"']);