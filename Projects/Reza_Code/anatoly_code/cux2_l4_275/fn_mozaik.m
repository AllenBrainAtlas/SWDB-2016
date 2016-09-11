classdef fn_mozaik < hgsetget
   
    properties
        images
        n
        s
        clip
        pos
    end

    methods
        function set.images(M,images)
            M.images = images;
            M.n = length(M.images); %#ok<MCSUP>
            siz = fn_map(@size,M.images);
            M.s = cat(1,siz{:})'; %#ok<MCSUP>
            M.clip = double([min(fn_map(@(x)min(x(:)),M.images)) max(fn_map(@(x)max(x(:)),M.images))]); %#ok<MCSUP>
        end
        function align(M)
            if isempty(M.images), error 'set images first', end
            M.pos = zeros(2,M.n);
            
            for i=1:M.n-1
                a = fn_filt(M.images{i},5,[1 2]); 
                b = fn_filt(M.images{i+1},5,[1 2]);
                d = fn_xregister(a,b,.2);
                M.pos(:,i+1) = M.pos(:,i)+d(:);
                show(M,[i i+1],'color')
                drawnow
%                 pause
            end
        end
        function aligntool(M)
            c = cell(2,M.n*2);
            for i=1:M.n
                c{1,i} = ['x' num2str(i)];
                c{2,i} = M.pos(1,i);
                c{1,M.n+i} = ['y' num2str(i)];
                c{2,M.n+i} = M.pos(2,i);
            end
            st = struct(c{:});
            step = 10;
            m = fn_round(max(M.s(:))*sqrt(M.n),step);
            [c{2,:}] = deal(['slider ' num2str(-m) ' ' num2str(m) ' ' num2str(step)]);
            c = [c(:,1:M.n) {'xxx'; 'label'} c(:,M.n+1:end)];
            spec = struct(c{:});
            fn_control(st,spec,'ncol',2,@(u)update(u));
            function update(u)
                M.pos = reshape(struct2array(u),M.n,2)';
                show(M)
            end
        end
        function A = show(M,varargin)
            % function [a =] show(M[,idx][,'fast|slow|color'])
            persistent hi oldpos
            if isempty(M.pos), error 'align first', end
            
            idx = 1:M.n; method = 'fast';
            for i=1:length(varargin)
                a = varargin{i};
                if isnumeric(a)
                    idx = a;
                elseif ischar(a)
                    method = a;
                end
            end
            nidx = length(idx);
                  
            % some size computations
            bl = min(M.pos(:,idx),[],2);
            ur = max(M.pos(:,idx)+M.s(:,idx),[],2);
            curax = [bl(1) ur(1) bl(2) ur(2)];
            fullsize = row(-bl+ur);
            
            % prepare figure
            hf = 914;
            if ~ishandle(hf), figure(hf), end
            ha = get(hf,'children');
            if ~isscalar(ha)
                clf(hf)
                colormap(hf,gray(256))
                ha = axes('parent',hf);
            end
            doredraw = ~strcmp(method,'fast') || ~(nidx==M.n && length(hi)==M.n && all(ishandle(hi)));
            if doredraw, axis(ha,curax), end

            % display
            switch method
                case 'color'
                    if nidx~=2, error 'method ''slowcolor'' valid only for 2 images', end
                    A = zeros([fullsize 3]);
                    for k=1:2
                        i = idx(k);
                        [ii jj] = deal(-bl(1)+M.pos(1,i)+(1:M.s(1,i)),-bl(2)+M.pos(2,i)+(1:M.s(2,i)));
                        im = fn_clip(double(M.images{i}),M.clip);
                        if k==1
                            A(ii,jj,1) = im;
                            A(ii,jj,3) = im; %/2;
                        else
                            A(ii,jj,2) = im;
                            %a(ii,jj,3) = a(ii,jj,3)+im/2;
                        end
                    end
                    imagesc(curax(1:2),curax(3:4),permute(A,[2 1 3]),'parent',ha,M.clip)
                    title(ha,sprintf('%i/%i',idx))
                    if nargout==0, clear A, end
                case 'slow'
                    A = zeros(fullsize);
                    totalweight = zeros(fullsize);
                    for k=1:nidx
                        i = idx(k);
                        [ii jj] = deal(-bl(1)+M.pos(1,i)+(1:M.s(1,i)),-bl(2)+M.pos(2,i)+(1:M.s(2,i)));
                        dist2edge = bsxfun(@min,min(1:M.s(1,i),M.s(1,i):-1:1)',min(1:M.s(2,i),M.s(2,i):-1:1));
                        weight = dist2edge;
                        A(ii,jj) = A(ii,jj)+double(M.images{i}).*weight;
                        totalweight(ii,jj) = totalweight(ii,jj)+weight;
                    end
                    A = A./totalweight;
                    imagesc(curax(1:2),curax(3:4),A','parent',ha,M.clip)
                    if nargout==0, clear A, end
                case 'fast'
                    if doredraw
                        hi = zeros(1,nidx);
                        for k=1:nidx
                            i = idx(k);
                            hi(k) = imagesc(M.pos(1,i)+[1 M.s(1,i)],M.pos(2,i)+[1 M.s(2,i)], ...
                                M.images{i}','alphadata',M.clip(2)-M.images{i}', ...
                                'parent',ha,M.clip);
                            if k==1, hold(ha,'on'), end
                        end
                        hold(ha,'off')
                    else
                        haschanged = find(any(M.pos~=oldpos),1);
                        for i=haschanged
                            set(hi(i),'xdata',M.pos(1,i)+[1 M.s(1,i)],'ydata',M.pos(2,i)+[1 M.s(2,i)])
                            uistack(hi(i),'top')
                        end
                        %                         ha = get(hi(1),'parent');
                        %                         axis(ha,curax)
                    end
                    oldpos = M.pos; 
            end
            axis(ha,'image')
        end
    end
    
end