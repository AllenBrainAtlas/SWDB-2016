imagecount=0;
cellcount=0;
spiketm={};
h=figure('Position', [100, 100, 2000, 1000]);hold on;
celltype='L4_Scnn1a_VISp';

for imagecount=0:3
    eval(['calcium=' celltype '_' num2str(imagecount) '(:,1:104700);'])
    tic
    for k=1:size(calcium,1)
    disp(sprintf('extracing for image_%d cell_%d',imagecount, k));
        try
        [c,b,c1,g,sn,sp] = constrained_foopsi(double(calcium(k,:)));
        %noiselevel=std(calcium(k,:))
        thr=.05;
        sptm=find(sp>thr)/30;
        if k==20
            plot(1:length(calcium(k,:)),calcium(k,:),1:length(c),c,1:length(sp),sp,'*',[1 104700],[thr thr]);drawnow;
        end
        spiketm{cellcount+k}=sptm;
        end
    end
    disp(sprintf('image_%d has %d cells and takes %d sec',imagecount, size(calcium,1),round(toc)));
    cellcount=cellcount+size(calcium,1);
end
dropboxpath='C:\Dropbox\Dropbox\SWDB-2016\project\localsparsenoise\';
save([dropboxpath celltype '_spiketime.mat' ],'spiketm')
savefig(h,celltype)