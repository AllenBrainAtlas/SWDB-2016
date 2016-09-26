imagecount=0;
cellcount=0;
%spiketm={};
h=figure('Position', [100, 100, 1600, 400]);hold on;
celltype='L4_Cux2_VISp';
thr=.05;

for imagecount=0:3
    eval(['calcium=' celltype num2str(imagecount) '(:,104701:end);'])
    eval(['timechunks='  'timeframe' num2str(imagecount) ';'])
    timechunks=(timechunks-timechunks(1))/30
    timechunks(6)-timechunks(5)+timechunks(4)-timechunks(3)+timechunks(2)
    tic
    for k=1:size(calcium,1)
    disp(sprintf('extracing for image_%d cell_%d',imagecount, k));
        try
            [c,b,c1,g,sn,sp] = constrained_foopsi(double(calcium(k,:)));
            %noiselevel=std(calcium(k,:))
            sptm=(find(sp>thr)+104700)/30;
            if k==10
                plot(104701:length(calcium(k,:))+104700,calcium(k,:),104701:length(sp)+104700,sp,'*');drawnow;
            end
            temp=[spiketm{cellcount+k};sptm];
            spiketm_2{cellcount+k}=temp(temp>0&temp<timechunks(2)| temp>timechunks(3)&temp<timechunks(4) | temp>timechunks(5)&temp<timechunks(6));
        catch
            disp('something wrong, check!')
        end
    end
    disp(sprintf('image_%d has %d cells and takes %d sec',imagecount, size(calcium,1),round(toc)));
    cellcount=cellcount+size(calcium,1);
end
dropboxpath='C:\Dropbox\Dropbox\SWDB-2016\project\localsparsenoise\';
save([dropboxpath celltype '_spiketime_added_and_picked.mat' ],'spiketm_2')
plot([104701 105000],[thr thr],'linewidth',2)
savefig(h,[celltype 'added and picked'])