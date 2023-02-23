import math
import numpy as np
import socket
from os import makedirs
from tobiiresearch.implementation import EyeTracker
from multiprocessing import Process,Manager
from scipy.io import savemat
import keyboard
import serial

class OnlineEyeDataGet(Process):

    def __init__(self,q,q1,FilePath):
        Process.__init__(self)
        self.gaze_data = np.zeros((7,1)) 
        self.event  = np.zeros((3,1))     
        self.eye_tracker_data = []
        self.event_data = []
        self.FilePath = FilePath
        self.eyecount = 0
        self.eventcount = 0
        self.my_eyetraker = None
        self.q = q
        self.q1 = q1



    def gaze_data_callback(self,data):
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
        # 避免队列堵塞
        if self.q1.full():
            try:
                for i in range(7):
                    eye_data = self.gaze_data[i]
                    if i<=3:        
                        if math.isnan(eye_data):
                            eye_data = 0
                        self.q.put(int(eye_data*10000),block=False) 
                    else:
                        self.q.put(int(eye_data),block=False)
                self.gaze_data[6] = 0
            except:
                self.gaze_data[6] = 0
                print('队列已满')


    def event_data_callback(self,data):
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
            self.gaze_data[6] = data['value']
            print(data['value'])
            self.event_data.append(np.copy(self.event))
            self.eventcount = self.eventcount + 1
            print(self.eventcount)


    def close_my_eyetraker(self):
        '''关闭订阅'''
        self.my_eyetraker.unsubscribe_from(EyeTracker.EYETRACKER_GAZE_DATA,self.gaze_data_callback)
        self.my_eyetraker.unsubscribe_from(EyeTracker.EYETRACKER_EXTERNAL_SIGNAL, self.event_data_callback)
        print('已关闭订阅！')
        '''存储眼动数据'''
        savemat(self.FilePath+'EYE_Online1.mat',{'eye_data':self.eye_tracker_data,'event_data':self.event_data}) 
        print('存储成功！')
   
        
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
        self.my_eyetraker.subscribe_to(EyeTracker.EYETRACKER_GAZE_DATA,self.gaze_data_callback, as_dictionary=True)
        self.my_eyetraker.subscribe_to(EyeTracker.EYETRACKER_EXTERNAL_SIGNAL,self.event_data_callback, as_dictionary=True)
        # time.sleep(2000)
        while True:
            if keyboard.read_key() == 'down':
                print('采集结束！')   
                break
        self.close_my_eyetraker()


class OnlineEyeDataSender(Process):

    CHANNELS = ['right_gaze_data[0]', 'right_gaze_data[1]', 'left_gaze_data[0]', 'left_gaze_data[1]', 
            'decivertime_stamp', 'systime_stamp', 'label']

    def __init__(self,q,q1,fs_orig = 120,bs=None):
        Process.__init__(self)
        self.sever_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sever_ip = '169.254.14.131'
        self.sever_socket_addr = (self.sever_ip,40008)
        self.sever_socket.bind(self.sever_socket_addr)

        # 等待客户端连接
        self.client_socket = None
        self.clientAddr = None

        self.q = q
        self.q1 = q1
      
        self.fs_orig = fs_orig
        self.channels = len(self.CHANNELS)
        print(self.channels)
        self.dur_one_packet = 0.04
        self.n_points = int(np.round(fs_orig*self.dur_one_packet))
        self.connect = 0
        
        if bs:
            self.bs = bytearray(bs)
        else:
            self.bs = bytearray(0)

  
    def connect_tcp(self):
        '''等待客户端建立连接'''
        self.sever_socket.listen()
        try:
            self.client_socket, self.clientAddr = self.sever_socket.accept()   # accept() 是阻塞的 直到有客户端连接为止
            self.q1.put(1)    # 开始采集数据
            self.connect = 1  # 开始发送数据
        except:
            print('没有有效连接')
       

    
    def RecverMsg(self):
        print('')
        

    def run(self):
        # 先与接收的客户端建立连接
        self.connect_tcp()
     
        while True:
            if self.connect:
                '''将数据进行打包'''
                try:
                    if self.q.full():  
                        for i in range(self.q.qsize()):
                            val = self.q.get()
                            bytes_val = bytearray(val.to_bytes(8, byteorder='little'))
                            self.bs += bytes_val
                        bytes_pck_length = bytearray(len(self.bs).to_bytes(4, byteorder='little'))
                        self.bs = bytes_pck_length + self.bs
                        self.client_socket.send(self.bs)
                        self.bs = bytearray(0)
                        print('发送成功')
                except:
                        print('发送失败')
                        self.client_socket.close()
                    


if __name__ == '__main__': 
    #--------------共享变量-------------#
    fs = 120
    data_length = 0.1
    
    #进程间的共享队列进行通信
    q = Manager().Queue(maxsize=int(fs*data_length*7))  
    q1 = Manager().Queue(maxsize=1)  
   

    #-----------创建存储文件------------#
    subject_name = 'wyl'
    FilePath = './eye_data/'+subject_name+'/'
    try:
        makedirs(FilePath)
    except:
        print('当前文件已存在！')

    #-------子进程进行眼动数据获取和发送------#  
    data = OnlineEyeDataGet(q,q1,FilePath)
    data.daemon = True
    data.start()

    sender = OnlineEyeDataSender(q,q1,fs)
    sender.daemon = True
    sender.start()

    #-------主进程终止------# 
    while True:
        if keyboard.read_key() == 'up':
            print('采集结束！')   
            break
