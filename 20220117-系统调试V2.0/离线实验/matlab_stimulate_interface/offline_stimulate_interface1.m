 %% ����ʵ��  
% ���ĳ����̼�ʱ����55�У�����cueʱ����56�У�       
% profile on 
sca;    
clear;clc;    
close  all;            
clearvars;   
%% ���ǩ��ʱ����  
% config_io;
% LPTAdr =20220; 
% lptwrite(LPTAdr, 0);           

%%
% Here we call some defau  lt setting      for setting up Psychtoolbox
Screen('Preference','SyncTestSettings', [0.002],[50],[0.1],[5]); 
% Get the screen numbers     
screens = Screen('Screens');    
% Select the external screen if it is present, else revert to the native
% screen
screenNumber = max(screens); 
%% ����udp����
% % ���ն�
% % 192.168.213.93    
% udpt=udp('127.0.0.1', 8848, 'LocalPort', 8847);  %ip7 
% udpt=udp('192.168.18.19', 40008, 'LocalPort', 40007)  
% fopen(udpt); 

  
%% Parameter setting
% Initialize PTB toolbox ----------------------------------------------
HideCursor;%�������
KbName('UnifyKeyNames');%�ѵ�ǰϵͳ�ļ��̰�������������ͳһת��ΪMacOX-Xϵͳ�����������������ֲ�ԣ�����ÿ�γ����д
escKey = KbName('ESCAPE');
Numblock = 6;  %��12�� һ��Сʱ            
NumTrial  = 12 ; 
WHITE           = [255, 255, 255]; 
BLACK           = [ 0,   0,   0];
RED             = [255,   0,   0];  
BG_COLOR        = BLACK;                                % Background color
TEXT_FONT       = 'Times';
FONT_SIZE       = 32;
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, BLACK);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);     
[centX, centY] = RectCenter(windowRect);   %RectCenter������ӽ�rect���ĵ�����x��y�㡣

% Stimulus parameters setting -----------------------------------------
stimDur         = 0.4   ;% [s]  2.1       
rest            = 1 ; 
refreshRate     = round(1/Screen('GetFlipInterval', window));     % [Hz] 
lenCode         = round(refreshRate       *stimDur);
lenrest        = round(refreshRate*rest);  
numTarg         = 12;

%�̼�Ƶ�ʺ���λ
stimFreq = [9.0,12.0,10.0,11.5,9.5,8.5,8.0,11.0,10.5,12.5,13.0,13.5];
stimPhase = [1.05,2.80,0.70,2.45,1.75,0.35,0.0,2.10,1.40,3.15,3.5,3.85]*pi; 
%%
stimSize = 150 ;  %140                                % [pixel] 
Space = 50;     %50
topSpace = 300;
buttomSpace = 50; %50 
leftSpace = 10; %10
rightSpace = 10; %10

%% �̼�����λ��
% Center location of stimuli [X, Y]
% 12�̼�
position = {[0,325],[-100,-325],[325,325],[-300,-325],[-525,100],...
            [525,100],[525,-100],[-525,-100],[-325,325],[0,-125],[300,-325],[100,-325]};     
for i = 1:12
    centLocOfStim{i}(1) = centX + position{i}(1); 
    centLocOfStim{i}(2) = centY - position{i}(2);
end

%% �̼��ַ�λ��
for i = 1 : numTarg
    stimLoc{i}(1) =  centLocOfStim{i}(1)-stimSize/2; % Cordinate of vertex ����
    stimLoc{i}(2) =  centLocOfStim{i}(2)-stimSize/2;   % [Upper left X, Upper left Y, Lower right X, Lower right Y]
    stimLoc{i}(3) =  centLocOfStim{i}(1)+stimSize/2;
    stimLoc{i}(4) =  centLocOfStim{i}(2)+stimSize/2;
end 

%% ���������λ��
LocOfFeedback = [-15,65,1935,120];  %-70-55, -70
%������������ַ�'>>'��λ��
symbolFeedback = {'>>'}; 
LocOfsymbolFeedback = [LocOfFeedback(1)+5,...
            LocOfFeedback(2)];

LocOfFeedbacksymbol = [LocOfsymbolFeedback(1)+50,LocOfsymbolFeedback(2)]; 
Pre_symbol = '';

symbol = {'TakeOff','Land','Forward','Down','Left','Right','CW','CCW','Up','Keep','Back','Hover'};


%% Generate flickering sequences
for targ_i = 1:1:numTarg
    flickCode{targ_i} = exp_GenFlickerCode(lenCode, stimFreq(targ_i), refreshRate, 'sinusoid', stimPhase(targ_i));
end % targ_i
 
Screen(window,'TextSize',  80);
Screen(window, 'TextFont', 'Times');
bounds = Screen(window, 'TextBounds', 'Press Space To Begin');
Screen('DrawText', window, 'Press Space To Begin', centX- bounds(RectRight)/2, centY  - bounds(RectBottom)/2, WHITE);
Screen('Flip', window); 
% KbWait;
KbStrokeWait;
randomseries = randperm(12);   %Generate randomseries 

%% cue��ʾ
for cue_win_i = 1:1:lenrest
    % Create off-screens
    offScreen1(cue_win_i) = Screen(window, 'OpenOffScreenWindow', BLACK);
    % Set symbols
    Screen(offScreen1(cue_win_i), 'TextColor', WHITE);
    Screen(offScreen1(cue_win_i), 'TextFont', TEXT_FONT);
    Screen(offScreen1(cue_win_i), 'TextSize', FONT_SIZE);
    
    for targ_i = 1:1:numTarg
        bounds = Screen(offScreen1(cue_win_i), 'TextBounds', symbol{randomseries(targ_i)});
        symbolLoc{randomseries(targ_i)} = [centLocOfStim{randomseries(targ_i)}(1) - bounds(RectRight)/2,...
            centLocOfStim{randomseries(targ_i)}(2) - bounds(RectBottom)/2];
        
        Screen('FillRect', offScreen1(cue_win_i), WHITE, stimLoc{randomseries(targ_i)});
        Screen('DrawText', offScreen1(cue_win_i), symbol{randomseries(targ_i)}, symbolLoc{randomseries(targ_i)}(1), symbolLoc{randomseries(targ_i)}(2), BLACK);
        %���������
        Screen('FillRect',offScreen1(cue_win_i),WHITE,LocOfFeedback);
        %����������еġ�>>���ַ�
        Screen('DrawText',offScreen1(cue_win_i),symbolFeedback{1},LocOfsymbolFeedback(1),LocOfsymbolFeedback(2),BLACK);
    end % targ_i
    % Draw rectangle stimuli and symbols
    
end % cue_win_i

%% Stimulation
for stimu_win_i = 1:1:lenCode
    % Create off-screens
    offScreen2(stimu_win_i) = Screen(window, 'OpenOffScreenWindow', BLACK);
    % Set symbols
    Screen(offScreen2(stimu_win_i), 'TextColor', WHITE);
    Screen(offScreen2(stimu_win_i), 'TextFont', TEXT_FONT);
    Screen(offScreen2(stimu_win_i), 'TextSize', FONT_SIZE);
           
    for targ_i = 1:1:numTarg
        bounds = Screen(offScreen2(stimu_win_i), 'TextBounds', symbol{randomseries(targ_i)});
    end % targ_i 
    
    % Draw rectangle stimuli and symbols
    if stimu_win_i == lenCode                   % ��֤���һ֡��ȫ�׵�
        for targ_i = 1:1:numTarg
            Screen('FillRect', offScreen2(stimu_win_i), WHITE, stimLoc{randomseries(targ_i)});
            Screen('DrawText', offScreen2(stimu_win_i), symbol{randomseries(targ_i)}, symbolLoc{randomseries(targ_i)}(1), symbolLoc{randomseries(targ_i)}(2), BLACK);
            Screen('FillRect',offScreen2(stimu_win_i),WHITE,LocOfFeedback);
            Screen('DrawText',offScreen2(stimu_win_i),symbolFeedback{1},LocOfsymbolFeedback(1),LocOfsymbolFeedback(2),BLACK);
        end % targ_i
    else
        for targ_i = 1:1:numTarg
            code = flickCode{randomseries(targ_i)}(stimu_win_i)*255;
            Screen('FillRect', offScreen2(stimu_win_i), [code, code, code], stimLoc{randomseries(targ_i)});
            Screen('DrawText', offScreen2(stimu_win_i), symbol{randomseries(targ_i)}, symbolLoc{randomseries(targ_i)}(1), symbolLoc{randomseries(targ_i)}(2), BLACK);
            Screen('FillRect',offScreen2(stimu_win_i),WHITE,LocOfFeedback); 
            Screen('DrawText',offScreen2(stimu_win_i),symbolFeedback{1},LocOfsymbolFeedback(1),LocOfsymbolFeedback(2),BLACK);
        end % targ_i 
    end
end % stimu_win_i
%%
flag = 0;%������־��������������˳�
flag1 = 0;%���޷�����־
flag2 = 0;%������־�������˳�

%% ����
for trial = 1 : NumTrial
    if flag ==1
        flag = 0;
        break
    end
    try
       %% ��ʾ
        cuestart = tic;   
        for cue_win_i = 1:1:lenrest
            if trial >1   % ǰһ�����
                Screen('FillRect', offScreen1(cue_win_i), WHITE, stimLoc{randomseries(trial-1)});
                Screen('DrawText', offScreen1(cue_win_i), symbol{randomseries(trial-1)}, symbolLoc{randomseries(trial-1)}(1), symbolLoc{randomseries(trial-1)}(2), BLACK);
                Screen('FillRect',offScreen1(cue_win_i),WHITE,LocOfFeedback);
                Screen('DrawText',offScreen1(cue_win_i),symbolFeedback{1},LocOfsymbolFeedback(1),LocOfsymbolFeedback(2),BLACK);
            end 
            Screen('FillRect', offScreen1(cue_win_i), RED, stimLoc{randomseries(trial)});
            Screen('DrawText', offScreen1(cue_win_i), symbol{randomseries(trial)}, symbolLoc{randomseries(trial)}(1), symbolLoc{randomseries(trial)}(2), BLACK);
            Screen('FillRect',offScreen1(cue_win_i),WHITE,LocOfFeedback);
            Screen('DrawText',offScreen1(cue_win_i),symbolFeedback{1},LocOfsymbolFeedback(1),LocOfsymbolFeedback(2),BLACK);
            % ��֤֮ǰʶ����ַ����ٻ�����
            if flag1
                Screen('DrawText',offScreen1(cue_win_i),Later_symbol,LocOfFeedbacksymbol(1),LocOfFeedbacksymbol(2),BLACK);
            end
        end %cue_win_i
        disp(['calcu=' num2str(toc(cuestart))]);
       %% draw cue
        for cue_win_i = 1:1:lenrest   
            % If 'ESC' key is pressed, the iteration will be finished.
            [~, ~, keyCode] = KbCheck;
            if keyCode(escKey)
                flag2 = 1;
                break;
            end
            Screen('CopyWindow', offScreen1(cue_win_i), window);
            Screen('Flip', window);    
        end % cue_win_i
        disp(['cue=' num2str(toc(cuestart))]);
 
      %% draw stimulate
       trialStart = tic;   %�̼���ʱ 
       for epoch = 1:5
            for stimu_win_i = 1:1:lenCode     
                if flag2
                    flag = 1;
                    flag2 = 0;
                    break
                end 
                % If 'ESC' key is pressed, the iteration will be finished.
                [~, ~, keyCode] = KbCheck;
                if keyCode(escKey) 
                    flag = 1;
                    for win_i1 = 1
                        for targ_i =  randomseries(trial)
                            Screen('FillRect', offScreen1(win_i1), WHITE, stimLoc{randomseries(targ_i)});
                            Screen('DrawText', offScreen1(win_i1), symbol{randomseries(targ_i)}, symbolLoc{randomseries(targ_i)}(1), symbolLoc{randomseries(targ_i)}(2), BLACK);
                            Screen('FillRect',offScreen1(win_i1),WHITE,LocOfFeedback);
                            Screen('DrawText',offScreen1(win_i1),symbolFeedback{1},LocOfsymbolFeedback(1),LocOfsymbolFeedback(2),BLACK);
                        end % targ_i  
                    end
                    for win_i1 = 1
                        Screen('CopyWindow', offScreen1(win_i1), window);
                        Screen('Flip', window);
                    end % win_i
                    break; 
                end
                
                %% ���ǩ
    %             if stimu_win_i==1 
    %                 lptwrite(LPTAdr,randomseries(trial));
    %                 rev_ttt = datetime;
    %                 rev_ttt.Second       
    %             end       
    %             if stimu_win_i==1 + 2
    %                 lptwrite(LPTAdr,0);
    %              end
                Screen('CopyWindow', offScreen2(stimu_win_i), window);
                Screen('Flip', window);   
               %% 
            end % stimu_win_i
        end % epoch
        rev_tt = datetime; 
        rev_tt.Second     
        stimTime = toc(trialStart);
        stimTime  
    %%
    catch err 
        ShowCursor;
        rethrow(err); 
        Screen('CloseAll');
        clear all
    end
end

%% ���ù�
tic;
trialWait = tic; 
trialWait1 =tic;
% KbCheck = [];
space = KbName('space');
Screen(window,'TextSize',  80);
Screen(window,'TextFont',  'Times');
symbolfinal2 = 'Press Space To End';
bounds2 = Screen(window, 'TextBounds', symbolfinal2);
while toc(trialWait) < 30 
    [~, ~, keyCode] = KbCheck;
    if keyCode(space)
        break; 
    end
    
    while toc(trialWait1) >= 1
        symbolfinal1 = ['Please Take A Rest   ',num2str(round(toc(trialWait))),'/30s'];
        bounds1 = Screen(window, 'TextBounds', symbolfinal1);
        Screen('DrawText', window,  symbolfinal1, centX- bounds1(RectRight)/2, centY - bounds1(RectBottom) , WHITE);
        Screen('DrawText', window,  symbolfinal2, centX- bounds2(RectRight)/2, centY , WHITE);
        %     DrawFormattedText(window, 'Press Space To Continue', 'center',centY+80, [1,1,1]);
        Screen('Flip', window);
        tic
        trialWait1 =tic;
    end
end 

%% ���������˾͹ر� 
% fclose(udpt);    
% delete(udpt);
% clear udpt  
%% ���������˾͹ر�
Screen('CloseAll');
%  
clear