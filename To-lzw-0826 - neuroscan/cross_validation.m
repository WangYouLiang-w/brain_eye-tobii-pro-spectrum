function [offline_acc,LDA_classifier] = cross_validation(data,overlap_trials)
% This function was applid to analysis the offline data by using
% leave-one-out strategy. The input data should be filterd data which size
% like n_chan*n_samples*n_trials*n_targets. In the lda training process,
% the max and submax decision value pairs of test set in each validation
% loop and their offline classification results were gathered to train the
% lda classifier.
OVERLAP_TRIALS = overlap_trials;
valid_select_index = zeros(size(data,3), 6);
for block_iter = 1:6
    valid_select_index((block_iter-1)*5+1:block_iter*5,block_iter)=ones(5,1);
end

% compute number of classifier after overlap
% Total_num = (totol_trial/5)*(5-OVERLAP_TRIALS+1)
total_trial_num = (size(data,3)*size(data,4)/5)*(6-OVERLAP_TRIALS);
biggest_coefs_mat = [];
label_mat = [];
right_trials_count =0;
count = 0;

% train and test set split
for block_iter = 1:6
    traindata = data(:,:,logical(1-valid_select_index(:,block_iter)),:);
    testdata = data(:,:,logical(valid_select_index(:,block_iter)),:);
    % Use train data set to train the trca sptial filter
    for target = 1:size(traindata,4)
        w = trca_matrix(traindata(:,:,:,target));
        W(:,target) = w(:,1);
    end
    template = squeeze(mean(traindata,3));
    % single test data for get decision
    for target_iter = 1:size(testdata,4)
        coef_mat = zeros(size(template,3),OVERLAP_TRIALS);
        for test_iter = 1:size(testdata,3)
            data_epoch = testdata(:,:,test_iter,target_iter);
            trial_temp = mod(test_iter,OVERLAP_TRIALS)+1;
            for template_iter = 1:size(template,3)
                coef_mat(template_iter,trial_temp)= corr2(data_epoch'*W,template(:,:,template_iter)'*W);
            end
            if test_iter >= OVERLAP_TRIALS
                decision_vector = sum(coef_mat,2);
                count = count+1;
                if find(decision_vector==max(decision_vector))==target_iter
                    right_trials_count = right_trials_count+1;
                    label_mat = [label_mat,1];
                else
                    label_mat = [label_mat,0];
                end
                sorted_decision_value = sort(decision_vector,'descend');
                biggest_coefs_mat = [biggest_coefs_mat;sorted_decision_value(1:2)'];
            end
        end
    end
end
offline_acc = right_trials_count/total_trial_num*100;
LDA_classifier = LDA(biggest_coefs_mat,label_mat);
end