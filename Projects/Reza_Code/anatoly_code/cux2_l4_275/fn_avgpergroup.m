function [averages nrep] = fn_avgpergroup(data,conds,dim,nrepmax)
% function [averages nrep] = fn_avgpergroup(data,conds,dim[,nrepmax])
%---
% average individual groups separately in a dataset that splits into
% several groups
% 
% Input:
% - data        ND array 
% - conds       a vector of length size(data,dim) - indicates to which
%               group does belong each repetition along dimension dim
% - dim         the dimension on which to operate averaging
% - nrepmax     (optional) the maximal number of repetitions to use for
%               each group: if a group has more repetitions, the extra ones
%               are ignored; if a group has less, an error is generated.
%               Use flag 'same' to use the number of repetitions of the
%               smallest group.
%
% Output:
% - averages    ND array, its size in dimension dims is the number of
%               groups (i.e. length(unique(conds)) ), sizes in all other
%               dimensions are identical to those of data
%
% See also fn_arrangepercond

% sizes
s = size(data);
if isvector(data) && nargin<3, dim = find(s~=1); end
if ~isvector(conds) || length(conds)~=s(dim)
    error 'length of ''conds'' does not match size of ''data'' in dimension ''dim'''
end
u = unique(conds);
ngroup = length(u);
groups = cell(1,ngroup);
for i=1:ngroup, groups{i} = find(conds==u(i)); end
npergroup = fn_itemlengths(groups);
% if nargout<2, disp(['number of repetitions per group: ' num2str(npergroup,' %i')]), end
if nargin<4
    nrepmax = 0;
    nrep = npergroup;
elseif ischar(nrepmax)
    if ~strcmp(nrepmax,'same'), error('invalid flag ''%s''',nrepmax), end
    nrepmax = min(npergroup);
    nrep = nrepmax;
else
    if any(npergroup<nrepmax), error 'some group do not have enough elements', end
    nrep = nrepmax;
end
if nrepmax && nargout<2
    disp(['-> keep ' num2str(nrep) ' repetitions'])
end

% average
averages = cell(1,ngroup);
subs = repmat({':'},[1 length(s)]);
for i=1:ngroup
    if nrepmax
        subs{dim} = groups{i}(1:nrepmax);
    else
        subs{dim} = groups{i};
    end
    averages{i} = mean(fn_subsref(data,subs{:}),dim);
end
averages = cat(dim,averages{:});


