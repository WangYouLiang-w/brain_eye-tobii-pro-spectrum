 %% 在线实验  
% 更改持续刺激时间在55行；更改cue时间在56行；       
% profile on 
sca;    
clear;clc;    
close all;            
clearvars;   
        
%% 打标签的时候用  
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
 
%% 建立udp连接
% % 接收端
% % 192.168.213.93    
% udpt=udp('127.0.0.1', 8848, 'LocalPort', 8847);  %ip7 
% udpt=udp('192.168.18.19', 40008, 'LocalPort', 40007)  
% fopen(udpt); 

  
%% Parameter setting
% Initialize PTB toolbox ----------------------------------------------
HideCursor;%隐藏鼠标
KbName('UnifyKeyNames');%把当前系统的键盘按键的命名方案统一转换为MacOX-X系统的命名方案，提高移植性，建议每段程序均写
escKey = KbName('ESCAPE');
Numblock = 1;  %做12次 一个小时            
NumTrial = 40 ; 
WHITE           = [255, 255, 255]; 
BLACK           = [ 0,   0,   0];
RED             = [255,   0,   0];  
BG_COLOR        = BLACK;                                % Background color
TEXT_FONT       = 'Times';
FONT_SIZE       = 32;
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, BLACK);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);     
[centX, centY] = RectCenter(windowRect);   %RectCenter返回最接近rect中心的整数x，y点。

% Stimulus parameters setting -----------------------------------------
stimDur         = 3;% [s]  2.1       
rest            = 1; 
refreshRate     = round(1/Screen('GetFlipInterval', window));     % [Hz] 
lenCode         = round(refreshRate*stimDur);
lenrest        = round(refreshRate*rest);  
numTarg         = 40;

%刺激频率和相位
for i = 1:numTarg
    temp(i) = 8 + 0.2 * ( i- 1);
end  

temp1 = [0,1,0,1,0.5,1.5,0.5,1.5,1,0,1,0,1.5,0.5,1.5,0.5,0,1,0,1,0.5,1.5,0.5,1.5,1,0,1,0,1.5,0.5,1.5,0.5,0,1,0,1,0.5,1.5,0.5,1.5];
for i = 1:10 
    for j=1:4
        stimFreq(i,j) = temp(j + 4 * (i-1));
        stimPhase(i,j) = temp1(j + 4 * (i-1));
    end    
end
stimFreq = stimFreq(:);   % Hz
stimPhase = stimPhase(:);    % pi π 
stimFreq = stimFreq';
stimPhase = stimPhase'* pi;   %
%%
stimSize = 150 ;  %140                                % [pixel]
Space = 50;     %50
topSpace = 300;
buttomSpace = 50; %50 
leftSpace = 10; %10
rightSpace = 10; %10

%% 刺激方块位置
% Center location of stimuli [X, Y]
% 40字符的刺激界面
index = 0;
for i = 1:4
    for j=1:10
        index = index + 1;
        centLocOfStim{index}(1) = centX - leftSpace/2-rightSpace/2 - (5.5 - j) * (stimSize + Space) + leftSpace ;%刺激方块中间x轴坐标
        centLocOfStim{index}(2) = centY - topSpace/2-buttomSpace/2 -(3 - i)*(stimSize + Space)+ topSpace; %刺激方块中间y轴坐标
    end
end

%% 刺激字符位置
for i = 1 : numTarg
    stimLoc{i}(1) =  centLocOfStim{i}(1)-stimSize/2; % Cordinate of vertex 顶点
    stimLoc{i}(2) =  centLocOfStim{i}(2)-stimSize/2;   % [Upper left X, Upper left Y, Lower right X, Lower right Y]
    stimLoc{i}(3) =  centLocOfStim{i}(1)+stimSize/2;
    stimLoc{i}(4) =  centLocOfStim{i}(2)+stimSize/2;
end 

%% 反馈输入框位置
LocOfFeedback = [stimLoc{1}(1),(stimLoc{1}(2)-70-55),(stimLoc{1}(1) + 10*stimSize + 9*Space),(stimLoc{1}(2)-70)];  %-70-55, -70
%反馈输入框中字符'>>'的位置
symbolFeedback = {'>>'};
LocOfsymbolFeedback = [LocOfFeedback(1)+5,...
            LocOfFeedback(2)];

LocOfFeedbacksymbol = [LocOfsymbolFeedback(1)+50,LocOfsymbolFeedback(2)]; 
Pre_symbol = '';

symbol={'1','2','3','4','5','6','7','8','9','0','Q','W','E','R','T','Y','U','I','O','P','A','S', ...
    'D','F','G','H','J','K','L',' ','<','Z','X','C','V','B','N','M',',','.'};

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
randomseries = 1:40;  

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
for trial = 1 : NumTrial
    if flag ==1
        flag = 0;
        break
    end
    try
       %% 提示
        cuestart = tic;   
        for cue_win_i = 1:1:lenrest 
            if trial >1   % 前一个变白
                Screen('FillRect', offScreen1(cue_win_i), WHITE, stimLoc{randomseries(trial-1)});
                Screen('DrawText', offScreen1(cue_win_i), symbol{randomseries(trial-1)}, symbolLoc{randomseries(trial-1)}(1), symbolLoc{randomseries(trial-1)}(2), BLACK);
                Screen('FillRect',offScreen1(cue_win_i),WHITE,LocOfFeedback);
                Screen('DrawText',offScreen1(cue_win_i),symbolFeedback{1},LocOfsymbolFeedback(1),LocOfsymbolFeedback(2),BLACK);
            end 
            Screen('FillRect', offScreen1(cue_win_i), RED, stimLoc{randomseries(trial)});  %%%%%%%
            Screen('DrawText', offScreen1(cue_win_i), symbol{randomseries(trial)}, symbolLoc{randomseries(trial)}(1), symbolLoc{randomseries(trial)}(2), BLACK);
            Screen('FillRect',offScreen1(cue_win_i),WHITE,LocOfFeedback);
            Screen('DrawText',offScreen1(cue_win_i),symbolFeedback{1},LocOfsymbolFeedback(1),LocOfsymbolFeedback(2),BLACK);
            
            % 保证之前识别的字符都再画出来
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
            trialStart = tic;   %刺激计时
            %% 打标签
%             if stimu_win_i==1
%                 lptwrite(LPTAdr,randomseries(trial));
%                 rev_ttt = datetime;
%                 rev_ttt.Second       
%             end       
%             if stimu_win_i==1 + 2
%                 lptwrite(LPTAdr,0);
%             end
            
           %% 接受数据处理电脑的反馈 
%             if stimu_win_i >= 0.3*refreshRate
%                if udpt.BytesAvailable >= 1
%                    data_othermat = fread(udpt,udpt.BytesAvailable);  % 接收反馈结果
%                    rev_t = datetime;
%                    rev_t.Second      
%                    data_othermat = char(data_othermat);     
%                    
%                    flag1 = 1;  
%                    Later_symbol = [Pre_symbol,data_othermat];
%                    Pre_symbol = Later_symbol;
% 
%                    for win_i1 = 1 
%                        for targ_i = randomseries(trial)                
%                             Screen('FillRect', offScreen1(win_i1), WHITE, stimLoc{targ_i}); 
%                             Screen('DrawText', offScreen1(win_i1), symbol{targ_i}, symbolLoc{targ_i}(1), symbolLoc{targ_i}(2), BLACK);
%                             Screen('FillRect',offScreen1(win_i1),WHITE,LocOfFeedback);
%                             Screen('DrawText',offScreen1(win_i1),symbolFeedback{1},LocOfsymbolFeedback(1),LocOfsymbolFeedback(2),BLACK);
%                             if flag1 
%                                 Screen('DrawText',offScreen1(win_i1),Later_symbol,LocOfFeedbacksymbol(1),LocOfFeedbacksymbol(2),BLACK);
%                             end   
%                         end % targ_i 
%                    end 
%                     
%                   for win_i1 = 1 
%                       Screen('CopyWindow', offScreen1(win_i1), window);
%                       Screen('Flip', window);                               
%                   end % win_i1
% %                 lptwrite(LPTAdr,0); 
%                   %  break                      %%反馈退出
%                end     
%             end     
           %%
            Screen('CopyWindow', offScreen2(stimu_win_i), window);
            Screen('Flip', window);     
        end % stimu_win_i
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
% fclose(udpt);    
% delete(udpt);
% clear udpt  

%% 不用连接了就关闭
Screen('CloseAll');
%  