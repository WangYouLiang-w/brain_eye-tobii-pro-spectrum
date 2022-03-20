function Simulated_online(overlap_trials,is_LDA_apply,LDA_classifier)
subject = 'tff';
global N_target
global stimulilength
%% Load data and preprocess
% Model data
folder_path = ['./Extract_data/',subject,'/block1/'];
% load([folder_path,'FIR_b.mat']);
load([folder_path,'IIR_b_a.mat']);
load([folder_path,'template.mat']);
load([folder_path,'W.mat']);
EEG = pop_loadcnt(['./subjects/',subject,'/','Session2-Simulation-Point4/1.cnt']);
EEG = pop_resample(EEG,250);
eeg = EEG;
data = eeg.data;
data = [data(1,:);data(3:9,:)];
event = eeg.event;
triggernum = 540;
triggertype = zeros(triggernum,1);
triggerpos = zeros(triggernum,1);
for eventnum = 1:triggernum
    triggertype(eventnum,1) = event(eventnum).type;
    triggerpos(eventnum,1) = event(eventnum).latency;
end
trigger_series = [0,1,2,3,4,5,6,7,8,9,10,11,1,3,5,0,7,9,11,2,4,6,8,10,0,8,2,10,4,3,9,6,7,11,5,1]+1;
all_triggers = repmat(trigger_series,15,1);
all_triggers = all_triggers(:);

% Variable definition
fs = 250;
stimuli_length = 0.4*fs;
visual_delay = 0.14*fs;
result_saver = zeros(triggernum,1);

% Number of overlap epochs:
overlap_epochs = overlap_trials;
overlap_buffer = zeros(N_target,overlap_epochs);
overlap_temp = 0;

total_output = 0;
right_in_output = 0;
wrong_in_output = 0;
total_no_output = 0;
right_in_no_output = 0;
wrong_in_no_output = 0;
rightflag = 0;

%% Simulated online test loop
for i_num_epoch = 1:triggernum
    % Extract a single epoch for simulated online test.
    current_epoch = data(:,floor(triggerpos(i_num_epoch))+visual_delay+1:floor(triggerpos(i_num_epoch))+visual_delay+stimuli_length);
    % Zero-mean
    % Filter data
%     filter_data = filter(b,1,current_epoch');
    filter_data = filtfilt(f_b,f_a,double(current_epoch'));
    % Feature extraction and pattern recognition
    corr_coef_saver = zeros(size(template,3),1);
    for i_template = 1:size(template,3)
        corr_coef_saver(i_template,1) = corr2(filter_data*W,template(:,:,i_template)'*W);
    end
    %% Overlap accumulate
    overlap_buffer(:,mod(overlap_temp,overlap_epochs)+1)=corr_coef_saver;
    decision_buffer = sum(overlap_buffer,2);
    if find(decision_buffer==max(max(decision_buffer)))==all_triggers(i_num_epoch)&&i_num_epoch>=3
        result_saver(i_num_epoch) = 1;
        rightflag = 1;
    else
        rightflag = 0;
    end
    if is_LDA_apply == 1
        sorted_buffer = sort(decision_buffer,'descend');
        max_submax_value = sorted_buffer(1:2)';
        linear_score = [1,max_submax_value]*LDA_classifier';
        P = exp(linear_score) ./ repmat(sum(exp(linear_score),2),[1 2]);
        % Result decide, confusion matrix
        if P(1)>P(2) && rightflag==1
            total_no_output = total_no_output+1;
            right_in_no_output = right_in_no_output+1;
        elseif P(1)>P(2) && rightflag==0
            total_no_output = total_no_output+1;
            wrong_in_no_output = wrong_in_no_output+1;
        elseif P(1)<P(2) && rightflag==1
            total_output = total_output+1;
            right_in_output = right_in_output+1;
        elseif P(1)<P(2) && rightflag==0
            total_output = total_output+1;
            wrong_in_output = wrong_in_output+1;
        end
    end             
    overlap_temp = overlap_temp+1;
end
if is_LDA_apply == 0
    ACC = sum(result_saver)/triggernum;
    ITR = ITR_computer(N_target,stimulilength*overlap_trials,ACC);
    fprintf('\n')
    fprintf('Simulated online data analysis result without applying LDA:')
    table(ACC, ITR)
else
    Precision = right_in_output/total_output;
    ITR = ITR_computer(N_target,(stimulilength*triggernum/total_output)*overlap_trials,Precision);
    Recall = right_in_output/(right_in_output+wrong_in_no_output);
    F1 = 2*Precision*Recall/(Precision+Recall);
    fprintf('\n')
    fprintf('Simulated online data analysis result with applying LDA:')
    table(Precision,ITR,Recall,F1)
end
