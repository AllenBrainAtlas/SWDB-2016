function m = fn_email(flag)
% function fn_email
% function fn_email('setserver')
%--------------
% sends an email !!
% prompts for recipient, title, attachments and text

% Thomas Deneux
% Copyright 2004-2012

if nargin==1 
    if ~strcmp(flag,'setserver'), error argument, end
    setserver
    return
end

if ~ispref('Internet') || ~ispref('Internet','SMTP_Server') ...
        || isempty(getpref('Internet','SMTP_Server')), setserver, end

TO = {};
str = input(['To: '],'s');
while str
    if isempty(strfind(str,'@'))
        emails = fn_userconfig('fn_email');
        if isempty(emails), emails = struct; end
        if ~isfield(emails,str)
            strfull = input(['Enter full address for new nickname ''' str ''': '],'s');
            if isempty(strfull), disp 'Aborted', return, end
            emails.(str) = strfull; %#ok<STRNU>
            fn_userconfig('fn_email',emails)
            str = strfull;
        else
            fprintf(repmat('\b',1,length(str)+1))
            str = emails.(str);
            fprintf([str '\n'])
        end
    end
    TO{end+1} = str;
    str = input(['To: '],'s');
end

SUBJECT = input(['Subject: '],'s');

ATTACHMENTS = {};
str = input(['Figures to attach: '],'s');
if strcmp(str,'all')
    f = findobj(0,'type','figure');
elseif fn_ismemberstr(str,{'cur' 'gcf'})
    f = gcf;
else
    f = str2num(str); %#ok<ST2NM>
end
while ~all(ishandle(f))
    disp('invalid figure number(s)')
    str = input(['Figures to attach: '],'s');
    if strcmp(str,'all')
        f = findobj(0,'type','figure');
    elseif fn_ismemberstr(str,{'cur' 'gcf'})
        f = gcf;
    else
        f = str2num(str); %#ok<ST2NM>
    end
end
if ~isempty(f)
    str = input(['Format for figures [fig,png]:'],'s');
    if isempty(str), str = 'fig,png'; end
    fformat = fn_strcut(str,',');
    fprintf('saving figures... ')
end
for i=1:length(f)
    % change paper-position property
    pos = get(f(i),'position');                       % position in the screen
    set(f(i),'paperunits','inches','paperposition',[5 5 pos([3 4])/100])     % keep the same image ratio
    figname{i} = fn_autofigname(f(i)); %#ok<*AGROW>
    for j=1:length(fformat)
        fn_savefig(f(i),[figname{i} '.' fformat{j}],fformat{j})
        ATTACHMENTS{end+1}=[figname{i} '.' fformat{j}];
    end
end
if ~isempty(f)
    disp('done')
end

str = input(['Mfile or file to attach: '],'s');
while str
    if exist(str,'file')
        ATTACHMENTS{end+1}=str; 
    else
        str2 = which(str); 
        if str2, str=str2; else str=fullfile(pwd,str); end
        if exist(str,'file')
            ATTACHMENTS{end+1}=str; 
        else 
            disp('[file not found]'), 
        end
    end
    str = input(['Mfile or file to attach: '],'s');
end

MESSAGE={};
prv = 'bouh';
str = input(['Text: '],'s');
while ~isempty(prv) || ~isempty(str)
    MESSAGE{end+1} = str;
    prv = str;
    str = input(['Text: '],'s');
end
MESSAGE = [MESSAGE '' '[mail sent from Matlab using fn_email, see http://trac.int.univ-amu.fr/brick]'];

MAIL = {TO,SUBJECT,MESSAGE,ATTACHMENTS};

str = input(['Send mail now ? [y] '],'s');
if ~any(findstr(str,'n'))
    fprintf('sending mail... ')
    try 
        sendmail(MAIL{:})
    catch ME
        disp 'failed!'
        disp(ME.message)
        disp 'Try ''fn_email setserver'' to set your Server parameters,'
        disp 'then send your mail with Matlab function ''sendmail''.'
        m = MAIL;
        return
    end
    try
        for i=1:length(f)
            for j=1:length(fformat)
                delete([figname{i} '.' fformat{j}])
            end
        end
    end
    disp('done')
    if nargout>0, m=MAIL; end
else
    m=MAIL;
end
    
%---
function setserver

disp('Setting your SMTP server and e-mail')
smtp = input('SMTP server [e.g. smtp.gmail.com]: ','s');
port = input('SMTP port (press Enter to use default): ','s');
username = input('If server requires authentification, enter user name, otherwise press Enter: ','s');
if isempty(username)
    password = '';
else
    password = input('Enter your password: ','s');
end
email = input('Your e-mail address: ','s');
setpref('Internet','SMTP_Server',smtp)
setpref('Internet','SMTP_Username',username)
setpref('Internet','SMTP_Password',password)
setpref('Internet','E_mail',email)

switch port
    case ''
        % use default
    case '465'
        props = java.lang.System.getProperties;
        props.setProperty('mail.smtp.auth','true');
        props.setProperty('mail.smtp.socketFactory.class', ...
            'javax.net.ssl.SSLSocketFactory');
        props.setProperty('mail.smtp.socketFactory.port','465');
    case '587'
        props = java.lang.System.getProperties;
        props.setProperty('mail.smtp.port','587');
    otherwise
        disp(['i am not sure how to set port ' port '...'])
        props = java.lang.System.getProperties;
        props.setProperty('mail.smtp.port',port);
end