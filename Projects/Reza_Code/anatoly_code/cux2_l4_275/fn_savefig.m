function fn_savefig(varargin)
% function fn_savig([hf][,fname][,options...])
%---
% Save an image of one or several figure(s). Large number of options
% are available. 
% If function is called with no argument, or only with hf, an interface is
% displayed that lets user choose the saving options.
% 
% Input:
% - hf          vector of figure handles [default: current figure]
% - fname       char array or cell array - file name(s) [default: prompt
%               user] 
% - 'askname' or 'autoname'     prompt or do not prompt user for figure
%               name, but build an automatic name, inside folder
%               fn_cd('capture') [default]
% - format      'png', 'bmp', 'jpg', 'eps', 'ps' or 'fig', or a cell array with
%               several formats [default: inferred from file name, or 'png'
%               if file name has no extension]
% - 'capture' or 'savefig'  capture method: 'capture' [default unless a
%               vector format is requested] uses Matlab function 
%               getframe to capture an image which is saved to a file
%               (i.e. the image will be strictly identical to what is seen
%               on screen); 'savefig' uses Matlab function saveas to save
%               (i.e. display will be changed according to some figure
%               properties such as 'PaperPosition', see also parameter
%               'scaling' below)
% - 'subframe'  user select a sub-part of the figure to save ('capture'
%               method only)
% - rectangle   a 4-element vector defining the sub-part of the figure to
%               save ('capture' method only)
% - 'content'   cut image to remove white sides ('capture' method only)
% - 'show' or 'showonly'    show the captured image in a new figure
% - scaling     a scalar that defines by how much to scale the figure
%               compared to screen display ('savefig' method only)
% - 'append', 'append+pdf' or 'ps2pdf'  append to file (ps file only) and
%               make pdf if specified ('ps2pdf' does not save the figure,
%               but only convert existing ps file to pdf)
% 
% See also: fn_saveimg


% Thomas Deneux
% Copyright 2003-2012


% Input
% (prompt user or scan input)
if nargin==0 || (nargin==1 && all(fn_isfigurehandle(varargin{1})))
    hfig = fn_switch(nargin,0,[],1,varargin{1});
    doax = false;
    s = struct( ...
        'autoname',     {true       'logical'   'auto figure name'}, ...
        'method',       {''         {'' 'capture' 'save figure'} 'method'}, ...
        'subframe',     {'full image' {'full image' 'select sub-rectangle' 'remove white sides'} 'cut image (''capture'' only)'}, ...
        'show',         {'save only' {'save only' 'show only' 'save and show'} 'show in new figure (''capture'' only)?'}, ...
        'scaling',      {[]         'xdouble'    'scaling (''save figure'' only)'}, ...
        ... 'invertcolor',  {false      'logical'   'white background (''save figure'' only)'}, ...
        'format',       {'png'      {'png' 'jpg' 'eps' 'ps' 'pdf' 'fig'} 'file format'}, ...
        'append',       {'no'       {'no' 'append' 'append+pdf'} 'append (ps file only)'} ...
        );
    s = fn_structedit(s);
    if isempty(s), return, end
    s.invertcolor = [];
    if isempty(s), return, end % canceled
    fname = {};
    s.format = {s.format};
    if strcmp(s.method,'save figure'), s.method = 'savefig'; end
    rect = {};
else
    hfig = []; doax = false;
    fname = {};
    rect = {};
    s = struct('autoname',false,'method','','subframe','full image', ...
        'show','save only','scaling',[],'format',{{}},'invertcolor',[],'append','no');
    k = 0;
    while k<length(varargin)
        k = k+1;
        a = varargin{k};
        if isnumeric(a) && isvector(a) && length(a)==4 && any(a(1:2)>20)
            rect = {a};
        elseif isscalar(a) && ishandle(a) && strcmp(get(a,'type'),'axes')
            doax = true;
            ha = a;
            if ~isempty(hfig), error argument, end
        elseif isempty(hfig) && ~doax && all(fn_isfigurehandle(a))
            hfig = a;
        elseif isnumeric(a) && isempty(s.scaling)
            s.scaling = a;
        elseif isnumeric(a)
            % problem: what we thought was a scaling parameter was
            % actually a figure handle!?
            if ~fn_isfigurehandle(s.scaling), error 'numeric argument seems to be neither a figure handle, neither a scaling parameter', end
            hfig = [hfig s.scaling]; %#ok<AGROW>
            s.scaling = a;
        elseif iscell(a)
            if fn_ismemberstr(a{1},{'png' 'bmp' 'jpg' 'eps' 'ps' 'pdf' 'fig'})
                s.format = lower(a);
            else
                fname = a;
            end
        elseif ischar(a)
            if ~isvector(a)
                fname = cellstr(a);
            elseif fn_ismemberstr(a,{'scale' 'scaling'})
                k = k+1;
                s.scaling = varargin{k};
            elseif strcmp(a,'autoname')
                s.autoname = true;
            elseif strcmp(a,'askname')
                s.autoname = false;
            elseif fn_ismemberstr(a,{'capture' 'savefig'})
                s.method = a;
            elseif strcmp(a,'subframe')
                s.subframe = 'select sub-rectangle';
            elseif strcmp(a,'content')
                s.subframe = 'remove white sides';
            elseif fn_ismemberstr(a,{'show' 'showonly'})
                s.show = a;
            elseif fn_ismemberstr(a,{'png' 'bmp' 'jpg' 'eps' 'ps' 'pdf' 'fig'})
                s.format{end+1} = lower(a);
            elseif fn_ismemberstr(a,{'append','append+pdf','ps2pdf'})
                s.append = a;
            elseif any(a==',')
                % formats separated by commas
                tmp = fn_strcut(a,', ');
                if ~all(ismember(tmp,{'png' 'bmp' 'jpg' 'eps' 'ps' 'pdf' 'fig'}))
                    disp(['interpreting ''' a ''' as a file name'])
                    fname{end+1} = a; %#ok<AGROW>
                else
                    s.format = [s.format tmp];
                end
            else
                fname{end+1} = a; %#ok<AGROW>
            end
        elseif isnumeric(a)
            s.scaling = a;
        else
            error argument
        end
    end
end
% (figure(s))
if isempty(hfig) && ~doax, hfig = gcf; end
nfig = length(hfig) + doax;
if doax, hfig = fn_parentfigure(ha); end
% (file names)
if strcmp(s.show,'showonly')
    % no need for file names
elseif ~isempty(fname)
    if length(fname)~=nfig
        error 'number of file names does not match number of figures';
    end
elseif s.autoname
    fname = cell(1,nfig);
    for k=1:nfig, fname{k} = [fn_autofigname(hfig(k)) '_scale' num2str(s.scaling)]; end
else
    fname = cell(1,nfig);
    for k=1:nfig
        fname{k} = fn_savefile( ...
            '*.png;*.PNG;*.bmp;*.BMP;*.jpg;*.JPG;*.eps;*.EPS;*.ps;*.PS;*.pdf;*.PDF;*.fig;*.FIG', ...
            ['Select file where to save figure ' figname(hfig(k))]);
        if ~fname{k}, return, end
    end
end
% (format)
format = cell(1,nfig);
if strcmp(s.show,'showonly')
    [format{:}] = deal('');
else
    for k=1:nfig
        [p base ext] = fileparts(fname{k});
        fname{k} = fullfile(p,base); %#ok<AGROW>
        if isempty(ext)
            if isempty(s.format), format{k} = {'png'}; else format{k} = s.format; end
        else
            ext = lower(ext(2:end)); % remove the dot and use lower case
            if ~isempty(s.format) && ~isequal(s.format,{ext})
                %disp 'incompatible format definitions'
                fname{k} = [fname{k} '.' ext]; %#ok<AGROW>
                format{k} = s.format;
            else
                format{k} = {ext};
            end
        end
    end
end
% (method)
if any(ismember([format{:}],{'eps' 'ps' 'pdf' 'fig'})) || ~isempty(s.scaling)
    if strcmp(s.method,'capture'), error '''capture'' cannot save vector format files or adjust the scaling', else s.method='savefig'; end
end
if ~strcmp(s.subframe,'full image') || ~strcmp(s.show,'save only') || doax
    if strcmp(s.method,'savefig'), error '''savefig'' method cannot save a figure subpart', else s.method = 'capture'; end
    if ~strcmp(s.subframe,'full image') && doax, error 'cannot select a subpart of an axes', end
end
if isempty(s.method), s.method = 'capture'; end

% Save
for k=1:nfig
    if doax, hobj = ha; else hobj = hfig(k); end
    formatk = format{k};
    switch s.method
        case 'savefig'
            % remove as many callbacks as possible, prepare uicontrols
            if doax, error 'not implemented yet', end
            state = preparefig(hobj,any(strcmp(formatk,'fig')));
            % add an axes to prevent ps2pdf bug on images
            if any(ismember(formatk,{'ps' 'pdf'}))
                ha = findall(hfig(k),'tag','axes_for_ps2pdf_bug');
                if isempty(ha)
                    ha = axes('parent',hfig(k),'pos',[-1 -1 .1 .1],'handlevisibility','off');
                end
                uistack(ha,'bottom')
            end
            % change paperposition property
            pos = fn_getpos(hobj,'inches'); % position in the screen
            if isempty(s.scaling), s.scaling = 1; end
            paperpos = [0 0 pos([3 4])*s.scaling];
            set(hobj,'paperUnits','inches','paperposition',paperpos)     % keep the same image ratio
            invertcolor = s.invertcolor;
            if isempty(invertcolor)
                invertcolor = isempty(findall(hobj,'type','uicontrol'));
            end
            set(hobj,'inverthardcopy',fn_switch(invertcolor))
            printflags = fn_switch(invertcolor,{},{'-loose'});
            for i=1:length(formatk)
                fnamei = [fname{k} '.' fn_switch(formatk{i},'pdf','ps',formatk{i})];
                formatki = fn_switch(formatk{i},{'eps' 'ps' 'pdf'},'psc2',formatk{i});
                if strcmp(formatki,'fig')
                    saveas(hobj,fnamei)
                else
                    if strcmp(formatk{i},'ps') && any(strfind(s.append,'append')) && exist([fname{k} '.ps'],'file')
                        printflags{end+1}='-append'; %#ok<AGROW>
                    end
                    if ~strcmp(s.append,'ps2pdf')
                        print(hobj,fnamei,['-d' formatki],printflags{:})
                    end
                    if strcmp(formatk{i},'pdf') || (strcmp(formatk{i},'ps') && any(strfind(s.append,'pdf')))
                        ps2pdf('psfile',[fname{k} '.ps'],'pdffile',[fname{k} '.pdf'], ...
                            'gspapersize',fn_strcat(paperpos(3:4),'x'),'deletepsfile',1,'verbose',0)
                    end
                end
            end
            % restore callbacks and so on
            restorefig(state)
        case 'capture'
            if strcmp(s.subframe,'select sub-rectangle')
                rect = {fn_figselection(hobj)};
            end
            im = getfield(getframe(hobj,rect{:}),'cdata');
            if strcmp(s.subframe,'remove white sides')
                bg = im(1,1,:);
                isbg = all(fn_eq(im,bg),3);
                ii = find(~all(isbg,2),1,'first'):find(~all(isbg,2),1,'last');
                jj = find(~all(isbg,1),1,'first'):find(~all(isbg,1),1,'last');
                im = im(ii,jj,:);
            end
            if doax
                % remove sides
                im = im(2:end-1,2:end-1,:);
            end
            if ~strcmp(s.show,'show only')
                for i=1:length(formatk)
                    imwrite(im,[fname{k} '.' formatk{i}],formatk{i})
                end
            end
            if ~strcmp(s.show,'save only')
                [ny nx nc] = size(im); %#ok<ASGLU>
                hfnew = figure; fn_setfigsize(hfnew,nx,ny);
                axes('pos',[0 0 1 1]) 
                image(im)
                set(gca,'xtick',[],'ytick',[])
            end
    end
end

% reset paperposition property to allow use of saveas


%---
function state = preparefig(hf,docallbacks)

% objects
state.hf = hf;
state.controls = unique(findall(hf,'type','uicontrol'));

% store properties
state.controlsprop = fn_get(state.controls,'visible','struct');

% overwrite properties
% (hide controls who are not visible because a parent is not visible)
for i=1:length(state.controls)
    ui = state.controls(i);
    hobj = ui;
    while ~strcmp(get(hobj,'type'),'figure')
        if strcmp(get(hobj,'visible'),'off')
            set(ui,'visible','off')
            break
        end
        hobj = get(hobj,'parent');
    end    
end

if ~docallbacks, return, end

% store callback properties
allobj = findall(hf);
state.allobj = allobj(~strcmp(get(allobj,'type'),'uimenu'));
state.buttons = allobj(ismember(get(allobj,'type'),{'uicontrol' 'uimenu'}));
state.spec = allobj(ismember(get(allobj,'type'),{'uipanel'}));
winprop = {'windowbuttondownfcn' 'windowbuttonupfcn' 'windowbuttonmotionfcn' ...
    'keypressfcn' 'windowkeypressfcn' 'windowkeyreleasefcn' 'windowscrollwheelfcn' ...
    'closerequestfcn' 'handlevisibility'};
state.figcallbacks = fn_get(hf,winprop,'struct');
state.butcallbacks = fn_get(state.buttons,{'callback' 'keypressfcn'},'struct');
state.speccallbacks = fn_get(state.spec,{'SelectionChangeFcn'},'struct');
state.allcallbacks = fn_get(state.allobj,{'userdata' 'buttondownfcn' 'createfcn' 'deletefcn' 'resizefcn' 'appdata'},'struct');

% overwrite properties
fn_set(hf,winprop,'default') % note that the default for 'closerequestfcn' is @closereq
fn_set(state.buttons,{'callback' 'keypressfcn'},'')
fn_set(state.spec,{'SelectionChangeFcn'},'')
fn_set(state.allobj,{'userdata' 'buttondownfcn' 'createfcn' 'deletefcn' 'resizefcn' 'appdata'},{[] '' '' '' '' struct})

%---
function restorefig(state)

fn_set(state.controls,state.controlsprop)

if ~isfield(state,'allobj'), return, end

fn_set(state.hf,state.figcallbacks)
fn_set(state.buttons,state.butcallbacks);
fn_set(state.spec,state.speccallbacks)
fn_set(state.allobj,state.allcallbacks)

%---
function name = figname(hf)
% function name = figname(hf)
%---
% get a meaningful name for a given figure

name = get(hf,'name');
if isempty(name)
    num = get(hf,'number');
    if ~isempty(num), name = num2str(num); end
end