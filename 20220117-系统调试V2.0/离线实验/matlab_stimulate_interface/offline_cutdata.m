clc
clear all
% datapath = 'G:\xfr\orignal data\zyr0823';
datapath = 'E:\wyl';
% datapath = 'D:\lxy0721';
% savepath = 'G:\xfr\dw-mat';

srate = 1000;
stimlength = 2.5;
delay = 0.14;
blocks = 5;
for block_i = 1:1:blocks
    EEG = pop_loadcnt([datapath '\block' num2str(block_i) '.cnt']);
%     EEG = pop_resample(EEG,250);
    eeg = EEG;
%     data = eeg.data([56 48 55 54 57 58 61 62 63],:);
    data = eeg.data;
    event = eeg.event;

    label = cell2mat({event.type});
    labelstart = round(cell2mat({event.latency}));
    

    for i = 1:40
%         epochdata(:,:,label(i*2),block_i) = data(:,floor(labelstart(i*2))+delay*fs+1:floor(labelstart(i*2))+delay*fs+stimlength*fs);
%         epochdata(:,:,label(i*2-1),block_i) = data(:,floor(labelstart(i*2-1))+delay*srate+1:floor(labelstart(i*2-1))+delay*srate+stimlength*srate);
        epochdata(:,:,label(i),block_i) = data(:,floor(labelstart(i))+delay*srate+1:floor(labelstart(i))+delay*srate+stimlength*srate);
%         floor(labelstart(i))
%         epochdata(:,:,label(i),block_i) = data(:,labelstart(i)+delay*srate+1:labelstart(i)+delay*srate+stimlength*srate);
%         epochdata(:,:,label(i),block_i) = data(:,floor(labelstart(i)) + 1:floor(labelstart(i)) + stimlength*srate);
    end
end

% epochdata = epochdata - mean(epochdata,2);
fprintf('...Saving data...\n');
% save([savepath '\zyr0823.mat'],'epochdata');
fprintf('...Done...');
fprintf('\n');
