 %% 离线实验  
% 更改持续刺激时间在55行；更改cue时间在56行；       
% profile on 
sca;    
clear;clc;    
close  all;             
clearvars;           
%% 打标签的时候用     
config_io;
LPTAdr =57084; 
lptwrite(LPTAdr, 0);             
%%
% Here we call some defau  lt setting      for setting up Psy chtoolbox
Screen('Preference','SyncTestSettings', [0.002],[50],[0.1],[5]); 
% Get the screen numbers     
screens = Screen('Screens');     
% Select the external screen if it is present, else revert to the native
% screen
screenNumber = max(screens); 
 
%% 建立udp连接
% % 接收端
% % 192.168.213.93    
udpt1=udp('127.0.0.1', 8848, 'LocalPort', 8847);  %ip7 
udpt2=udp('169.254.29.63', 40008, 'LocalPort', 40007)  
fopen(udpt1); 
fopen(udpt2); 
 
%% Parameter setting
% Initialize PTB toolbox ----------------------------------------------
HideCursor;%隐藏鼠标
KbName('UnifyKeyNames');%把当前系统的键盘按键的命名方案统一转换为MacOX-X系统的命名方案，提高移植性，建议每段程序均写
escKey = KbName('ESCAPE');
Numblock = 1;  %做12次 一个小时            
NumTrial  = 12 ; 
WHITE           = [255, 255, 255]; 
BLACK           = [ 0,   0,   0];
RED             = [255,   0,   0];  
GREEN           = [0,255,0];
BG_COLOR        = BLACK;                                % Background color
TEXT_FONT       = 'Times';
FONT_SIZE       = 32;
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, BLACK);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);     
[centX, centY] = RectCenter(windowRect);   %RectCenter返回最接近rect中心的整数x，y点。

% Stimulus parameters setting -----------------------------------------
stimDur         = 0.4   ;% [s]  2.1       
rest            = 1 ; 
refreshRate     = round(1/Screen('GetFlipInterval', window));     % [Hz] 
lenCode         = round(refreshRate       *stimDur);
lenrest        = round(refreshRate*rest);  
numTarg         = 12;

%刺激频率和相位
stimFreq = [9.0,12.0,10.0,11.5,9.5,8.5,8.0,11.0,10.5,12.5,13.0,13.5]; 
stimPhase = [1.05,2.80,0.70,2.45,1.75,0.35,0.0,2.10,1.40,3.15,3.5,3.85]*pi; 
%%
stimSize = 150 ;  %140                                % [pixel]
Space = 50;     %50
topSpace = 300;
buttomSpace = 50; %50 
leftSpace = 10; %10
rightSpace = 10; %10

%% 刺激方块位置
% Center location of stimuli [X, Y]
% 12刺激
position = {[0,325],[-100,-325],[325,325],[-300,-325],[-525,100],...
            [525,100],[525,-100],[-525,-100],[-325,325],[0,-125],[300,-325],[100,-325]};     
for i = 1:12
    centLocOfStim{i}(1) = centX + position{i}(1); 
    centLocOfStim{i}(2) = centY - position{i}(2);
end

%% 刺激块的位置
for i = 1 : numTarg
    stimLoc{i}(1) =  centLocOfStim{i}(1)-stimSize/2; % Cordinate of vertex 顶点
    stimLoc{i}(2) =  centLocOfStim{i}(2)-stimSize/2;   % [Upper left X, Upper left Y, Lower right X, Lower right Y]
    stimLoc{i}(3) =  centLocOfStim{i}(1)+stimSize/2;
    stimLoc{i}(4) =  centLocOfStim{i}(2)+stimSize/2;
end 

%% 提示框的位置
for i = 1 : numTarg
    stimLoc1{i}(1) =  centLocOfStim{i}(1)-160/2; % Cordinate of vertex 顶点
    stimLoc1{i}(2) =  centLocOfStim{i}(2)-160/2;   % [Upper left X, Upper left Y, Lower right X, Lower right Y]
    stimLoc1{i}(3) =  centLocOfStim{i}(1)+160/2;
    stimLoc1{i}(4) =  centLocOfStim{i}(2)+160/2;
end 

%% 反馈输入框位置
LocOfFeedback = [-15,65,1935,120];  %-70-55, -70
%反馈输入框中字符'>>'的位置
symbolFeedback = {'>>'}; 
LocOfsymbolFeedback = [LocOfFeedback(1)+5,...
            LocOfFeedback(2)];

LocOfFeedbacksymbol = [LocOfsymbolFeedback(1)+50,LocOfsymbolFeedback(2)]; 
Pre_symbol = '';

symbol = {'a','b','c','d','e','f','g','h','i','j','k','l'};

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
% randomseries = randperm(40);   %Generate randomseries
randomseries = 1:12;  
%% cue提示
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
        %反馈输入框
        Screen('FillRect',offScreen1(cue_win_i),WHITE,LocOfFeedback);
        %反馈输入框中的‘>>’字符
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
    if stimu_win_i == lenCode                   % 保证最后一帧是全白的
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
flag = 0;%按键标志，如果按键了则退出
flag1 = 0;%有无反馈标志
flag2 = 0;%按键标志，按键退出

%% 迭代
trial = 1;
count = 0;
last_trial = 1;
udp_trial = 0;
while trial <= NumTrial
    count = count + 1;
    if flag ==1
        flag = 0;
        break
    end
    try
       %% 反馈 
        if flag1
            for win_i = 1:1:lenCode
                code = flickCode{randomseries(targ_i)}(win_i)*255;
                Screen('FillRect', offScreen2(win_i), [code, code, code], stimLoc{randomseries(targ_i)});
                Screen('DrawText', offScreen2(win_i), symbol{randomseries(targ_i)}, symbolLoc{randomseries(targ_i)}(1), symbolLoc{randomseries(targ_i)}(2), BLACK);
                Screen('FillRect',offScreen2(win_i),WHITE,LocOfFeedback); 
                Screen('DrawText',offScreen2(win_i),symbolFeedback{1},LocOfsymbolFeedback(1),LocOfsymbolFeedback(2),BLACK);
                Screen('DrawText',offScreen2(win_i),Later_symbol,LocOfFeedbacksymbol(1),LocOfFeedbacksymbol(2),BLACK);
            end
        end
       %% draw stimulate
        trialStart = tic;   %刺激计时 
        for stimu_win_i = 1:1:lenCode  
            if flag2
                flag = 1;
                flag2 = 0; 
                break
            end 
            %% If 'ESC' key is pressed, the iteration will be finished.
            [~, ~, keyCode] = KbCheck;
            if keyCode(escKey) 
                flag = 1;
                for win_i1 = 1
                    for targ_i = randomseries(trial)
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

            %% 打标签
            if stimu_win_i==1
                lptwrite(LPTAdr,randomseries(trial));
                rev_ttt = datetime;
                rev_ttt.Second       
            end       
            if stimu_win_i==1 + 2
                lptwrite(LPTAdr,0);
            end

           %% 接受数据处理电脑的反馈 
           if udpt1.BytesAvailable >= 1
               data_othermat = fread(udpt1,udpt1.BytesAvailable);  % 接收反馈结
               data_othermat = char(data_othermat);
               data_othermat                   
               eye_decide_result = data_othermat-'a'+1;           
               if udp_trial == 1
               %眼动分类结果的反馈
                    Screen('FrameRect', offScreen1(win_i_trial),BLACK ,stimLoc1{randomseries(last_eye_decide_result)},6);                         
               end                   
               %提示框   
               Screen('FrameRect', offScreen1(stimu_win_i),GREEN, stimLoc1{randomseries(eye_decide_result)},6);   
               udp_trial = 1;
               win_i_trial = stimu_win_i;
               last_eye_decide_result = eye_decide_result; 

           end

           if udpt2.BytesAvailable >= 1
              data_othermat = fread(udpt2,udpt2.BytesAvailable);  % 接收反馈结果
              data_othermat = char(data_othermat);
              brain_decide_result = data_othermat;
%                     脑电分类结果的反馈
              flag1 = 1; 
              Later_symbol = [Pre_symbol,data_othermat];
              Pre_symbol = Later_symbol;
              for win_i1 = 1 
                   for targ_i = randomseries(trial)                
                        Screen('FillRect', offScreen1(win_i1), WHITE, stimLoc{targ_i}); 
                        Screen('DrawText', offScreen1(win_i1), symbol{targ_i}, symbolLoc{targ_i}(1), symbolLoc{targ_i}(2), BLACK);
                        Screen('FillRect',offScreen1(win_i1),WHITE,LocOfFeedback);
                        Screen('DrawText',offScreen1(win_i1),symbolFeedback{1},LocOfsymbolFeedback(1),LocOfsymbolFeedback(2),BLACK);
                        if flag1 
                            Screen('DrawText',offScreen1(win_i1),Later_symbol,LocOfFeedbacksymbol(1),LocOfFeedbacksymbol(2),BLACK);
                        end   
                    end % targ_i 
               end 

              for win_i1 = 1 
                  Screen('CopyWindow', offScreen1(win_i1), window);
                  Screen('Flip', window);                               
              end % win_i1                 

            end    
            Screen('CopyWindow', offScreen2(stimu_win_i), window);
            Screen('Flip', window);   
        end %stimu_win_i 
        rev_tt = datetime; 
        rev_tt.Second      
        stimTime = toc(trialStart);
        stimTime
        trial = mod(trial,12);
        trial = trial+1;
        if count > 250
            count = 0;
        end
    %%
    catch err 
        ShowCursor;
        rethrow(err); 
        Screen('CloseAll');
        clear all
    end
end

%% 不用管
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

%% 不用连接了就关闭 
fclose(udpt1);    
delete(udpt1);  
clear udpt1  
fclose(udpt2);    
delete(udpt2); 
clear udpt2  
%% 不用连接了就关闭
Screen('CloseAll');
clear; 

