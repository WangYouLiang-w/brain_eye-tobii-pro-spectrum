from psychopy import visual,parallel
from psychopy.contrib.lazy_import import ImportReplacer
from psychopy.logging import data, setDefaultClock
from psychopy.tools.mathtools import length
from psychopy.visual import image, rect, text, window
from psychopy import event
import json
import math
import time
import numpy as np
import pygame
from pygame.constants import FULLSCREEN



class StimulateProcess():
    def __init__(self):
        #===========================设置标签接口======================#
        self.port = parallel.ParallelPort(address=0xdefc)# 端口地址 107=0xdefc，205=52988
        self.port.setData(0)#标签置0

        presettingfile = open('PreSettings_Single_tenclass.json')
        settings = json.load(presettingfile)
        self.stimulationLength = settings[u'stimulationLength'][0]    # 刺激时长
        self.stimulifre = settings[u'frequence']                      # 刺激频率
        self.phase = np.array(settings[u'phase'])              # 刺激相位
        self.phase = self.phase*np.pi
        self.cuelen = settings[u'cuelen'][0]                          # 提示长度
        self.textList = settings[u'controlCommand']                   # 字符列表
        self.textposition = settings[u'textposition']                 # 字符位置
        self.position = settings[u'position']                         # 刺激块的位置 
        self.framerate = settings[u'framerate'][0]                    # 屏幕刷新频率
        self.cueseries =settings[u'cueSeries']                        
        self.stimulus_blocks = len(self.position)                     # 刺激块的个数
        self.stimulus_loop = 5
        
        # 自定义的全局变量
        self.w = 1920
        self.h = 1080
        self.is_full_screen = True
        self.win_w = 1920
        self.win_h = 1080
        self.hc = self.h/self.win_h
        self.wc = self.w/self.win_w
        self.choice =  1
        self.dt = 1/self.framerate
        self.stim_texts = []
        self.stim_Rects = []
        self.cue_Rects = []
        self.res_time= []
        self.test_Rects = [] 
        self.c = {}
        self.position_stim =[(int(0*self.wc),int(325*self.hc)),(int(-100*self.wc),int(-325*self.hc)),(int(325*self.wc),int(325*self.hc)),(int(-300*self.wc),int(-325*self.hc)),(int(-525*self.wc),int(100*self.hc)),(int(525*self.wc),int(100*self.hc)),(int(525*self.wc),int(-100*self.hc)),(int(-525*self.wc),int(-100*self.hc)),(int(-325*self.wc),int(325*self.hc)),(int(0*self.wc),int(-125*self.hc)),(int(300*self.wc),int(-325*self.hc)),(int(100*self.wc),int(-325*self.hc))]
        self.startText = 'Press space to begin! Press any key to exit!'


    def interface(self):
        ''' 闪烁刺激界面 '''
        win = visual.Window(pos=(0,0),color=(0,0,0),fullscr=self.is_full_screen,colorSpace = 'rgb255',size = (self.w,self.h))
        win.mouseVisible = False # 隐藏鼠标
        
        ''' 刺激界面非闪烁下的整体效果 '''
        for i in range(len(self.position)):
            Rect_test = rect.Rect(win,pos=(self.position[str(i)][0]*self.wc,self.position[str(i)][1]*self.hc),
                                size=(150*self.wc,150*self.hc),units = 'pix',fillColor=(255,255,255),colorSpace = 'rgb255')
            self.test_Rects.append(Rect_test)

        ''' 刺激界面的提示字符 '''
        for i in range(self.stimulus_blocks):
            Texts_Stim = visual.TextStim(win,text=self.textList[str(i)],font='Times New Roman',pos=(self.textposition[str(i)][0]*self.wc,self.textposition[str(i)][1]*self.hc),units='pix',color=(0,0,0),colorSpace='rgb255',height=35*self.wc)
            self.stim_texts.append(Texts_Stim)  

        ''' 提示刺激块 '''
        for i in range(self.stimulus_blocks):
            Rect_cue = rect.Rect(win,pos=(self.textposition[str(i)][0]*self.wc,self.textposition[str(i)][1]*self.hc),size=(150*self.wc,150*self.hc),units = 'pix',fillColor=(255,0,0),colorSpace = 'rgb255')
            self.cue_Rects.append(Rect_cue)

        ''' 刺激块 '''
        for t in range(int(self.stimulationLength*self.framerate)):
            color_stim = self.stimu_sqeuence(t)
            color_stim = list(color_stim.values())
            Rects_Stim = visual.ElementArrayStim(win,fieldShape='sqr',nElements = self.stimulus_blocks,xys=self.position_stim,
                                                sizes=(150*self.wc,150*self.hc),units = 'pix',colors=color_stim,colorSpace = 'rgb255',
                                                elementTex=np.ones([150,150]),elementMask = np.ones([150,150]))
            self.stim_Rects.append(Rects_Stim)

        '''开始提醒'''
        StartTexts_Stim = visual.TextStim(win,text='Press Space To Begin',font='Times New Roman',pos=(0,0),units='pix',color=(255,255,255),colorSpace='rgb255',height=65*self.wc)
        StartTexts_Stim.draw()
        win.flip()
        # 等待按键
        event.waitKeys(keyList=['space'])
            
        """ 刺激界面显示"""
        for loop in self.cueseries:   
            for i in loop:
                ''' 提示 '''
                for t in range(int(self.cuelen*self.framerate)):       # 提示时长
                    # 显示刺激界面非闪烁状态下的整体效果
                    [test_Rect.draw() for test_Rect in self.test_Rects]   
                    # 提示刺激块变红
                    self.cue_Rects[i].draw()
                    # 显示字符
                    [text_stim.draw() for text_stim in self.stim_texts]
                    win.flip()

                '''  刺激 '''
                tic = time.time()
                for j in range(self.stimulus_loop):                    # 连续刺激 打5个标签
                    StimulusCount = 1
                    for rect_stim in self.stim_Rects:                        
                        # tic = time.time() 

                        '''打标签'''
                        if StimulusCount == 1:
                            self.port.setData(i+1)

                        if StimulusCount == 3:
                            self.port.setData(0)
                        
                        StimulusCount = StimulusCount + 1

                        rect_stim.draw()

                        '''任意键退出'''
                        if event.getKeys():
                            print(np.average(self.res_time))
                            win.close()
                            break      

                        # 显示提示字符
                        [text_stim.draw() for text_stim in self.stim_texts]
                        win.flip()
                        
                toc = time.time()
                T = toc-tic
                self.res_time.append(T)
                print(T)
        print(np.average(self.res_time))
        win.flip()  

    
    def stimu_sqeuence(self,t):
        ''' 刺激序列 '''
        for i in range(len(self.stimulifre)):
            cor= ((np.sin(2*math.pi*self.stimulifre[i]*self.dt*t+self.phase[i])+1)/2)*255
            self.c[i] = ([cor,cor,cor])                    
        return self.c 


if __name__ == '__main__':
    stimulate = StimulateProcess()
    stimulate.interface()



    # "frequence":[9.00,15.0,11.0,14.0,10.0,8.00,7.00,13.0,12.0,0.00,22.0,24.0],
    # "phase":    [1.05,3.05,1.75,2.75,1.40,0.70,0.35,2.40,2.05,0.00,1.00,1.45],