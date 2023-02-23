import numpy as np
import time
from struct import pack,unpack
from os import makedirs
from tobiiresearch.implementation import EyeTracker
from threading import Thread
from scipy.io import savemat
import keyboard
from multiprocessing import Process
import serial

class EyetrackerGetData_Offline(Process):
    '''
    离线眼动数据采集模块：
    @存储形式:EYE.mat
                 eye_data
                 event_data
    '''
    def __init__(self,FilePath):
        Process.__init__(self)
        self.gaze_data = np.zeros((6,1)) 
        self.event  = np.zeros((3,1))     
        self.eye_tracker_data = []
        self.event_data = []
        self.FilePath = FilePath
        self.eyecount = 0
        self.eventcount = 0
        self.my_eyetraker = None

        # 使用前先初始化一下，把电平拉低 在注释掉，不然会和刺激界面打标签冲突
        self.port = serial.Serial(port= 'com4',baudrate=115200)# 端口地址 107=0xdefc，205=52988
        self.port.write([0])#标签置0   
        self.port.close()
        
    
    def __gaze_data_callback(self,data):
        '''
        获取眼动数据:
        @gaze_data[right_gaze_data1,
                    right_gaze_data2,
                    left_gaze_data1,
                    left_gaze_data2,
                    device_time_stamp,
                    system_time_stamp,]
        '''
        self.gaze_data[0]=data['right_gaze_point_on_display_area'][0]
        self.gaze_data[1]=data['right_gaze_point_on_display_area'][1]
        self.gaze_data[2]=data['left_gaze_point_on_display_area'][0]
        self.gaze_data[3]=data['left_gaze_point_on_display_area'][1]
        self.gaze_data[4]=data['device_time_stamp']
        self.gaze_data[5]=data['system_time_stamp']
        self.eye_tracker_data.append(np.copy(self.gaze_data))
        self.eyecount = self.eyecount + 1
     
        
    
    def __event_data_callback(self,data):
        '''
        获取标签数据:
        @event_data[label_value,
                    device_time_stamp,
                    system_time_stamp]
        '''
        if data['value'] != 0:
            self.event[0] = data['value']
            self.event[1] = data['device_time_stamp']
            self.event[2] = data['system_time_stamp']
            # print(data['value'])
            self.event_data.append(np.copy(self.event))
            self.eventcount = self.eventcount + 1
            print(self.eventcount)
    

    def run(self):
        #---------find eye tracker---------#
        while self.my_eyetraker is None:
            try:
                found_eyetrakers = EyeTracker.find_all_eyetrackers()
                self.my_eyetraker = found_eyetrakers[0]
            except:
                print('connected failed,try again!') 
        print("Address:" + self.my_eyetraker.address)
        print("Model:" + self.my_eyetraker.model)
        print("Name(It's OK if this is empty):" + self.my_eyetraker.device_name)
        print("Serial number:" + self.my_eyetraker.serial_number)
        print('connected successfully!!!')

        #---------订阅执行相应的回调函数--------#
        self.my_eyetraker.subscribe_to(EyeTracker.EYETRACKER_GAZE_DATA,self.__gaze_data_callback, as_dictionary=True)
        self.my_eyetraker.subscribe_to(EyeTracker.EYETRACKER_EXTERNAL_SIGNAL,self.__event_data_callback, as_dictionary=True)
        while True:
            if keyboard.read_key() == 'down':
                print('采集结束！')
                break
        self.close_my_eyetraker()

 
    def close_my_eyetraker(self):
        '''关闭订阅'''
        self.my_eyetraker.unsubscribe_from(EyeTracker.EYETRACKER_GAZE_DATA,self.__gaze_data_callback)
        self.my_eyetraker.unsubscribe_from(EyeTracker.EYETRACKER_EXTERNAL_SIGNAL, self.__event_data_callback)
        '''存储眼动数据'''
        savemat(self.FilePath+'EYE.mat',{'eye_data':self.eye_tracker_data,'event_data':self.event_data})



if __name__ == '__main__': 
    #--------------共享变量-------------#
    eye_fs = 120
    data_length = 0.5
    #-----------创建存储文件------------#
    subject_name = 'xj'
    FilePath = './eye_data/'+subject_name+'/'
    try:
        makedirs(FilePath)
    except:
        print('当前文件已存在！')
 
    #----------------子进程------------# 
    eye_data_sever_process = EyetrackerGetData_Offline(FilePath)
    eye_data_sever_process.daemon = True
    eye_data_sever_process.start()
    eye_data_sever_process.join()

