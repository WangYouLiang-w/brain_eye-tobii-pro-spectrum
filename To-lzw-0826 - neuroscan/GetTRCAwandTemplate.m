%% "Hyperparamters" Setting
OVERLAP_TRIALS = 2;
global N_target
global stimulilength
N_target = 12;
stimulilength = 0.4;
%% Creat file folder
subjectName = 'tff';
mkdir('./Extract_data',subjectName);
block = 'block1';
mkdir(['./Extract_data/',subjectName], block); 
currentFolder = ['./Extract_data/',subjectName, '/', block,'/'];
% %% neuroscan数据提取
EEG = pop_loadcnt(['./subjects/',subjectName,'/','Session2-Point4/1.cnt']);
stimulitlength = 0.4; %刺激长度 每个标签：采集250*0.5 = 125个脑电数据
srate = 250;
fs = 250;
delay = 0.14;
EEG = pop_resample(EEG,250);
eeg = EEG;
data = eeg.data;
data = [data(1,:);data(3:9,:)];
event = eeg.event;
triggernum = 360;
for eventnum = 1:triggernum
    triggertype(eventnum,1) = event(eventnum).type;
    triggerpos(eventnum,1) = event(eventnum).latency;
end
uniquetrigger = unique(triggertype);
uniquetriggernum = size(unique(triggertype),1);
for triggernum = 1:uniquetriggernum
    currenttrigger = uniquetrigger(triggernum);
    currenttriggerpos = triggerpos(triggertype==currenttrigger);
    for j = 1:size(currenttriggerpos,1)
        epoch(:,:,j,uniquetrigger(triggernum))=data(:,floor(currenttriggerpos(j))+0.14*srate+1:floor(currenttriggerpos(j))+0.14*srate+stimulitlength*srate);
    end
end
epoch_mean = mean(epoch,2);
epoch_mean = repmat(epoch_mean(:,:,:,:),1,stimulitlength*srate);
epoch = epoch-epoch_mean;  %中心化处理
%%
epochdata = permute(epoch,[2,1,3,4]);
%% Filter design(FIR)
% n = 48;%滤波器阶数
% Wn = 2*[6,80]/fs;
% b = fir1(n,Wn,'bandpass');
% currentdata = permute(filter(b,1,double(epochdata)),[2,1,3,4]);
% %currentdata = currentdata(:,floor(n/2):end,:,:);
% [offline_acc,LDA_classifier] = cross_validation(currentdata,OVERLAP_TRIALS);
% fprintf('Offline data accuracy: %5.2f %% \n', offline_acc)
%% 陷波处理
% [f_b50,f_a50] = notch_egg(250,45);
% notchdata = filtfilt(f_b50,f_a50,double(epochdata));
%% Filter design(IIR)
Wp=[2*6/fs 2*40/fs];%通带的截止频率为2.75hz--75hz,有纹波
Ws=[2*4/fs 2*(40+2)/fs];%阻带的截止频率
[N,Wn]=cheb1ord(Wp,Ws,4,30);
[f_b,f_a] = cheby1(N,0.5,Wn);%f_b为系统函数的分子，f_a为系统函数的分母。
currentdata = permute(filtfilt(f_b,f_a,double(epochdata)),[2,1,3,4]);
[acc,LDA_classifier] = cross_validation(currentdata,OVERLAP_TRIALS);
%% TRCA model training
for testloop = 1:6
        for target = 1:size(epochdata,4)
            w = trca_matrix(currentdata(:,:,:,target));
            W(:,target) = w(:,1);
        end
        template = squeeze(mean(currentdata,3));
end
%% Save model
save([currentFolder,'EEG'], 'EEG');
save([currentFolder,'W'], 'W');
save([currentFolder,'epochdata'], 'epochdata');
save([currentFolder,'template'], 'template');
save([currentFolder,'IIR_b_a'], 'f_b','f_a');
% save([currentFolder,'FIR_b'], 'b');
% save([currentFolder,['ldaW_',num2str(OVERLAP_TRIALS)]], 'LDA_classifier');
save([currentFolder,'LDA_classifier'], 'LDA_classifier');
Simulated_online(OVERLAP_TRIALS,1,LDA_classifier);

%%
% block = 'block';
%%%%%%%%PREDEFINE HERE%%%%%%%%%
% for i = 1:6
%     switch i
%         case (1)
%             EEG = pop_loadcnt(['E:\wyl','\',block,'\','1.cnt']);
%         case (2)
%             EEG = pop_loadcnt(['E:\wyl','\',block,'\','2.cnt']);
%         case (3)
%             EEG = pop_loadcnt(['E:\wyl','\',block,'\','3.cnt']);
%         case (4)
%             EEG = pop_loadcnt(['E:\wyl','\',block,'\','4.cnt']);
%         case (5)
%             EEG = pop_loadcnt(['E:\wyl','\',block,'\','5.cnt']);
%         case (6)
%             EEG = pop_loadcnt(['E:\wyl','\',block,'\','6.cnt']);
%     end
%     stimulitlength = 0.4; %刺激长度 每个标签：采集250*0.5 = 125个脑电数据
%     srate = 250;
%     fs = 250;
%     delay = 0.14;
%     EEG = pop_resample(EEG,250);
%     eeg = EEG;
%     data = eeg.data;
%     data = [data(1,:);data(3:9,:)];
%     event = eeg.event;
%     triggernum = 60;
%     for eventnum = 1:triggernum
%         triggertype(eventnum,1) = event(eventnum).type;
%         triggerpos(eventnum,1) = event(eventnum).latency;
%     end
%     uniquetrigger = unique(triggertype);
%     uniquetriggernum = size(unique(triggertype),1);
%     for triggernum = 1:uniquetriggernum
%         currenttrigger = uniquetrigger(triggernum);
%         currenttriggerpos = triggerpos(triggertype==currenttrigger);
%         for j = 1:size(currenttriggerpos,1)
%             epoch(:,:,j,uniquetrigger(triggernum))=data(:,floor(currenttriggerpos(j))+0.14*srate+1:floor(currenttriggerpos(j))+0.14*srate+stimulitlength*srate);
%         end
%     end
%     epoch_mean = mean(epoch,2);
%     epoch_mean = repmat(epoch_mean(:,:,:,:),1,stimulitlength*srate);
%     epoch = epoch-epoch_mean;  %中心化处理
%     epochdatas{1,i} = epoch;       
% end
% epoch = cat(3,epochdatas{1,1},epochdatas{1,2});
% epoch = cat(3,epoch,epochdatas{1,3});
% epoch = cat(3,epoch,epochdatas{1,4});
% epoch = cat(3,epoch,epochdatas{1,5});
% epoch = cat(3,epoch,epochdatas{1,6});