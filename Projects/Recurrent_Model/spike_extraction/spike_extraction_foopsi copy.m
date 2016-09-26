imagecount=0;
cellcount=0;
spiketm={};
h=figure('Position', [100, 100, 2000, 1000]);hold on;
celltype='L4_Cux2_VISp';

for imagecount=0:3
    eval(['calcium=' celltype  num2str(imagecount) ';'])
    tic
    for k=1:1 %size(calcium,1)
    disp(sprintf('extracing for image_%d cell_%d',imagecount, k));
        try
            [c,b,c1,g,sn,sp] = constrained_foopsi(double(calcium(k,:)));
            %noiselevel=std(calcium(k,:))
            thr=.05;
            sptm=find(sp>thr)/30;
            if k==20
                plot(1:length(calcium(k,:)),calcium(k,:),1:length(sp),sp,'*');drawnow;
            end
            spiketm{cellcount+k}=sptm;
        catch
            disp('something wrong, check!')
        end
    end
    disp(sprintf('image_%d has %d cells and takes %d sec',imagecount, size(calcium,1),round(toc)));
    cellcount=cellcount+size(calcium,1);
end
dropboxpath='C:\Dropbox\Dropbox\SWDB-2016\project\localsparsenoise\';
save([dropboxpath celltype '_spiketime.mat' ],'spiketm')
plot([1 size(calcium,2)],[thr thr],'linewidth',4)
savefig(h,celltype)