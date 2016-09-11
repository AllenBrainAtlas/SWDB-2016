function varargout=fn_readmesh ( filename )
% function [vertex,faces,normals]=fn_readmesh ( filename )
% function {vertex,faces}=fn_readmesh ( filename )
%
% See also fn_savemesh

% Thomas Deneux
% Copyright 2005-2012

if nargin==0, filename=fn_getfile({'*.vtk;*.tri;*.mesh'}); end
if isempty(findstr(filename,'.')), filename = [filename '.vtk']; end

fid=fopen(filename,'r');

[p name ext] = fileparts(filename);
switch lower(ext(2:end))
    
case 'vtk'
    
    for i=1:4 
        tline = fgetl(fid);
    end
    tline=fscanf(fid,'%s',1);
    %keyboard
    nvertex=fscanf(fid,'%d',1);
    tline = fgetl(fid);
    
    vertex=fscanf(fid,'%f',3*nvertex);
    %for i=1:nvertex
    %    vertex(1:3,i)=fscanf(fid,'%f',3);
    %end
    vertex=reshape(vertex,3,nvertex);
    
    fscanf(fid,'%s',1); nfaces=fscanf(fid,'%d',1); fgetl(fid);
    
    %for i=1:nfaces
    %    fscanf(fid,'%f',1);
    %    faces(1:3,i)=fscanf(fid,'%f',3);
    %end
    faces=fscanf(fid,'%f',4*nfaces);
    faces=reshape(faces,4,nfaces);
    faces=faces(2:4,:)+1;

case 'tri'
    
    nvertex=fscanf(fid,'- %d',1);
    vertex=fscanf(fid,'%f',6*nvertex);
    vertex=reshape(vertex,6,nvertex)';
    vertex=vertex(:,1:3);
    
    nfaces=fscanf(fid,'\n- %d',1);
    fscanf(fid,'%d',2);
    faces=fscanf(fid,'%d',3*nfaces);
    faces=reshape(faces,3,nfaces)';
    faces=faces(:,1:3)+1;
    
case 'mesh'
    
    [file_format, COUNT] = fread(fid, 5, 'uchar') ;
    
    if strcmp(char(file_format'),'ascii')
        
        fscanf(fid,'%s %i %i %i',4);
        nvertex= fscanf(fid,'%i',1);
        [vertex, COUNT] = fscanf(fid,' ( %f , %f , %f ) ',3*nvertex);
        vertex = reshape(vertex,3,nvertex)';
        
        fscanf(fid,'%i %i',2);
        nfaces= fscanf(fid,'%i',1);
        faces = fscanf(fid,' ( %i , %i , %i ) ',3*nfaces);
        faces = reshape(faces,3,nfaces)'+1;
                
    else
        
        [lbindian, COUNT] = fread(fid, 4, 'uchar') ;
        [arg_size, COUNT] = fread(fid, 1, 'uint32') ;
        [VOID, COUNT] = fread(fid, arg_size, 'uchar') ;
        
        [vertex_per_face, COUNT] = fread(fid, 1, 'uint32') ;
        [mesh_time, COUNT] = fread(fid, 1, 'uint32') ;
        
        [mesh_step, COUNT] = fread(fid, 1, 'uint32') ;
        [vertex_number, COUNT] = fread(fid, 1, 'uint32') ;
        
        [vertex, COUNT] = fread(fid, 3*vertex_number, 'float32') ;
        [arg_size, COUNT] = fread(fid, 1, 'uint32') ;
        vertex=reshape(vertex,3,vertex_number)';
        
        [normal, COUNT] = fread(fid, 3*vertex_number, 'float32') ;
        [arg_size, COUNT] = fread(fid, 1, 'uint32') ;
        normal=reshape(normal, 3, vertex_number)' ;
        
        [faces_number, COUNT] = fread(fid, 1, 'uint32') ;
        [faces, COUNT] = fread(fid, vertex_per_face*faces_number, 'uint32') ;
        faces=reshape(faces,vertex_per_face,faces_number)' + 1;
        
    end
end

fclose(fid);

% matrices -> 3 x n
vertex = vertex';
faces = faces';
    
if nargout<=2, varargout{1}={vertex,faces}; else varargout={vertex,faces}; end

