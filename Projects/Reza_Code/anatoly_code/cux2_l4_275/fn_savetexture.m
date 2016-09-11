function fn_savetexture(texture,filename)
% function fn_savetexture(texture,filename)
% -----
% save texture for anatomist in binary mode
% texture can be 1D (a vector) or 2D (a n x 2 or 2 x n matrice) or 
% or multi-temporal (a t x n matrice) 
% format : cf. http://brainvisa.info/doc/formats/tex.pdf
%
% See also fn_readtexture, fn_savemesh, fn_readmesh

% Thomas Deneux
% Copyright 2005-2012


if nargin<1, help fn_save_texture, return, end

if nargin<2, filename=fn_savefile('*.tex'); end
if isempty(findstr(filename,'.tex')), filename=[filename '.tex']; end

if size(texture,2)<=2, texture=texture'; end

if size(texture,1)==2, flag2D=true; else flag2D=false; end
nsommets = size(texture,2);
if flag2D
    ntemps = 1;
    texture = texture(:)'; 
else 
    ntemps = size(texture,1); 
end

fid = fopen(filename,'w');

% % ASCII mode
% fprintf(fid,'ascii\n'); % mode
% if flag2D, fprintf(fid,'POINT2DF\n'); else fprintf(fid,'FLOAT\n'); end % type
% fprintf(fid,'%i\n',ntemps); % nombre d'instants
% for i=1:ntemps
%     fprintf(fid,'%i\n',i-1);
%     fprintf(fid,'%i ',nsommets);
%     if flag2D
%         fprintf(fid,'(%f,%f)',texture(:));
%     else
%         fprintf(fid,'%f ',texture(i,:));
%     end
%     fprintf(fid,'\n');
% end

fprintf(fid,'binarDCBA'); % mode
if flag2D, type = 'POINT2DF'; else type = 'FLOAT'; end % type
fwrite(fid,length(type),'uint32');
fprintf(fid,type);
fwrite(fid,ntemps,'uint32'); % nombre d'instants

for i=1:ntemps
    fwrite(fid,i-1,'uint32');
    fwrite(fid,nsommets,'uint32');
    fwrite(fid,full(texture(i,:)),'float');
end

fclose(fid);
