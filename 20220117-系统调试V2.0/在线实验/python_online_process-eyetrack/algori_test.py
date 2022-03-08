from codeop import CommandCompiler
import numpy as np
import scipy.signal as signal
import scipy.io as scio
from scipy import trapz
from threading import Thread
import socket
import time
import heapq
from mne.time_frequency import psd_array_welch
#from numba import jit



class algorithmthread(Thread):

    def __init__(self,eye_decide_result):
        Thread.__init__(self)
        self.client_ip = socket.gethostbyname(socket.gethostname())
        self.client_addr = (self.client_ip, 8848)
        self.client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.controlCenterAddr = ('127.0.0.1',8847)                   # ('127.0.0.1',8847)
        self.eye_track_result = eye_decide_result
        

    def run(self):
        char = ['a','b','c','d','e','f','g','h','i','j','k','l']
        while True:
            if self.eye_track_result.value!=0:
                eye_decide_result = char[self.eye_track_result.value-1]
                command =  eye_decide_result
                self.sendCommand(command) 
                self.eye_track_result.value = 0
                print(self.eye_track_result.value)
                
    def sendCommand(self,command):
        msg = bytes(str(command), "utf8")
        self.client_socket.sendto(msg,self.controlCenterAddr)


