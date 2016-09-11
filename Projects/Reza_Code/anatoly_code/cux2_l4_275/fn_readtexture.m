function texture = fn_readtexture(filename)
% function texture = fn_readtexture(filename)
%---
% load textures saved in ascii mode (Anatomist format)
%
% See also fn_savetexture

% Thomas Deneux
% Copyright 2005-2012

if nargin==0, filename=fn_getfile; end

fid = fopen(filename,'r');

mode = char(fread(fid,5,'uchar'));
fseek(fid,0,-1);

switch mode(:)'
    case 'ascii'
        
        % skip header
        for i=1:4, tline = fgetl(fid); end
        
        nsommets = fscanf(fid,'%i',1);
        texture = zeros(4,nsommets);
        
        line = fgetl(fid);
        texture(1,:) = sscanf(line,'%f',[1 Inf]);
        
        fscanf(fid,'%i',2);
        texture(2,:) = sscanf(line,'%f',[1 Inf]);
        
        fscanf(fid,'%i',2);
        texture(3,:) = sscanf(line,'%f',[1 Inf]);
        
        fscanf(fid,'%i',2);
        texture(4,:) = sscanf(line,'%f',[1 Inf]);
        
        fclose(fid);
        
    case 'binar'
        
        %fprintf(fid,'binarDCBA');
        fseek(fid,9,-1);
        %if flag2D, type = 'POINT2DF'; else type = 'FLOAT'; end % type
        %fwrite(fid,length(type),'uint32');
        typelength = fread(fid,1,'uint32');
        %fprintf(fid,type);
        type = char(fread(fid,typelength,'uchar'));
        %fwrite(fid,ntemps,'uint32'); % nombre d'instants
        ntemps = fread(fid,1,'uint32');
        
        for i=1:ntemps
            %fwrite(fid,i-1,'uint32');
            fread(fid,1,'uint32');
            %fwrite(fid,nsommets,'uint32');
            nsommets = fread(fid,1,'uint32'); if i==1, texture = zeros(ntemps,nsommets); end
            %fwrite(fid,texture(i,:),'float');
            texture(i,:) = fread(fid,nsommets,'float')';
        end
        
    end
