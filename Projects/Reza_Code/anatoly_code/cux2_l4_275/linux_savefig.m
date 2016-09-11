function linux_savefig(hf,fname,subframe)
% function linux_savefig(hf[,fname[,subframe]])
%---
% save figure with handle hf in folder fn_cd('capture'), under the name
% figuretitle_date_time.png
%
% works only under linux, with ImageMagick installed or on Mac OS
%
% Input:
% - hf          figure handle
% - fname       file name (if not specified, a default name is built based
%               on figure name, and saving folder is defined by
%               fn_cd('capture')) 
% - subframe    logical - this will enable user selection of a subpart of
%               the figure
%               or 4-element vector - indicating the position of a subpart
%               of the figure in pixel units

% Thomas Deneux
% Copyright 2009-2012

if nargin==0, help linux_savefig, return, end

% Get figure name
figure(hf), pause(.5)
if strcmp(get(hf,'numbertitle'),'on')
    if mod(hf,1)
        figname = sprintf('Figure %.6f',hf);
    else
        figname = sprintf('Figure %i',hf);
    end
else
    figname = '';
end
name = get(hf,'name');
if ~isempty(name)
    if isempty(figname)
        figname = name;
    else
        figname = [figname ': ' name];
    end
end

% Saving name
if nargin<2
    fname = fn_autofigname(hf);
else
    fname = regexprep(fname,'( |:)*','_');
end
fname = fn_fileext(fname,'png');

% Sub-frame
if nargin<3
    subframe = [];
elseif isscalar(subframe)
    % logical value
    if subframe
        subframe = fn_figselection(hf);
        disp(['Sub-frame selection: ' sprintf(' %i',subframe)])
    else
        subframe = [];
    end
end
if isempty(subframe)
    pos = get(hf,'position');
    subframe = [0 0 pos(3)+1 pos(4)+1];
end

% Use system command for screenshot
if strfind(computer,'MAC')
    
    % Mac: use 'screencapture' command to capture the full screen
    figure(hf), pause(.1)
    system(['screencapture ''' fname '''']);
    
    % Cut the image according to figure position
    a = imread(fname);
    pos = get(hf,'position'); pos(2) = pos(2)+21; % something strange here
    pos = [pos(1)+subframes(1) pos(2)+subframes(2) subframes(3:4)];
    a = a(size(a,1)+1-pos(2)-pos(4)+(1:pos(4)-1),pos(1)+(1:pos(3)-1),:);
    imwrite(a,fname)
    
else
    
    % Get figure id using linux command 'xwininfo'
    [status result] = system(['xwininfo -name "' figname '"']);
    if status, disp(result), error('an error occured'), end
    token = regexp(result,'Window id: 0x([a-h\d])*','tokens');
    id = token{1}{1};
    
    % Save figure using ImageMagick function 'import' through the id
    [status result] = system(['import -window 0x' id ' "' fname '"']);
    if status, disp(result), error('an error occured'), end
    
    % Cut the image according to subframe specification
    a = imread(fname);
    a = a(size(a,1)+1-subframe(2)-subframe(4)+(1:subframe(4)-1),subframe(1)+(1:subframe(3)-1),:);
    imwrite(a,fname)
end
