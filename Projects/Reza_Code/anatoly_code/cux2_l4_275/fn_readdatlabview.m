function a = fn_readdatlabview(fname)
% function a = fn_readdatlabview(fname)
%---
% read binary file saved in LabView:

% Thomas Deneux
% Copyright 2009-2012

fnamec = cellstr(fname);
nf = length(fnamec);
a = cell(1,nf);
oksize = true;
for i=1:nf
    fid = fopen(fnamec{i},'r','b');
    ny = fread(fid,1,'uint32');
    nx = fread(fid,1,'uint32');
    oksize = oksize && ((i==1) || all([nx ny]==prevsiz));
    prevsiz = [nx ny];
    a{i} = fread(fid,[nx ny],'double');
    fclose(fid);
end
if oksize
    if ny==1
        a = cat(2,a{:});
    elseif nx==1
        a = cat(1,a{:});
    else
        a = cat(3,a{:});
    end
end