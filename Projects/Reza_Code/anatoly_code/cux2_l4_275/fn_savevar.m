function fn_savevar(fname,varargin)
% function fn_save(fname,var1,var2,var3...)
%---
% save variables in a MAT file
%
% See also fn_loadvar

ext = fn_fileparts(fname,'ext');
if isempty(ext), fname = [fname '.mat']; end
nvar = length(varargin);
varnames = cell(1,nvar);
for k=1:nvar
    str = inputname(k+1);
    if isempty(str), str = ['var' num2str(k)]; end
    varnames{k} = str;
    if iscell(varargin{k}), varargin{k} = {varargin{k}}; end %#ok<CCAT1>
end
tmp = [varnames; varargin];
s = struct(tmp{:}); %#ok<NASGU>
save(fname,'-STRUCT','s','-MAT')
