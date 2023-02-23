# import numpy as np
# import socket
# import queue
# import time
# from struct import pack,unpack
# from os import makedirs
# from tobiiresearch.implementation import EyeTracker
# from threading import Thread
# from scipy.io import savemat
# import keyboard

# class OnlineEyeDataSender():


#     def __init__(self,FilePath,bs=None):
#         Thread.__init__(self)

#         self.client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#         self.client_ip = socket.gethostbyname(socket.gethostname())
#         self.address = (self.client_ip,4008)
#         if bs:
#             self.bs = bytearray(bs)
#         else:
#             self.bs = bytearray(0)



#     def connect_tcp(self):
#         '''与服务端尝试建立连接'''
#         for i in range(5):
#             try:
#                  time.sleep(1.5)
#                  self.client_socket.connect(self.address)
#                  print('连接成功')
#                  break
#             except:
#                 print('连接失败')



#     def data_packet(self,val_queue):
#         '''将数据进行打包'''
#         try:
#             if val_queue.full():
#                 for i in range(val_queue.qsize()):
#                     val = val_queue.get()
#                     bytes_val = bytearray(val.to_bytes(4, byteorder='little'))
#                     self.bs += bytes_val
#                 bytes_pck_length = bytearray(len(self.bs).to_bytes(4, byteorder='little'))
#                 self.bs = bytes_pck_length + self.bs
#                 self.client_socket.sendto(self.bs,self.address)
#                 self.bs = bytearray(0)
#         except:
#             print('发送失败')
#             self.client_socket.close()


#     def get_pck_has_head(self):
#         bytes_pck_length = bytearray(len(self.bs).to_bytes(4, byteorder='little'))
#         return bytes_pck_length + self.bs





# if __name__ == '__main__':
#     q = queue.Queue(maxsize=40)
#     p = OnlineEyeDataSender()
#     p.connect_tcp()
#     while True:
#         for i in range(40):
#             time.sleep(0.02)
#             q.put(i)
#         p.data_packet(q)
 

import queue



q = queue.Queue(maxsize=20)

try:
    for i in range(21):
        q.put(i,block=False)
except:
    for i in range(q.qsize()):
        print(q.get(i))