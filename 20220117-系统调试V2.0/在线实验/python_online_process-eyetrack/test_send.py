import socket
from cv2 import initUndistortRectifyMap
import time

import numpy as np
# 建立服务端
ClientSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
ClientIp = socket.gethostbyname(socket.gethostname())    #获取本地ip
ClientAddr = (ClientIp, 8848)                      #设置端口号
ClientSocket.bind(ClientAddr)

send_data = 1
while True:
    # send_data = input("请输入要发送的数据：")
    # if send_data == 'exit':
    #     break
   
    send_data = np.mod(send_data,12)
   
    ClientSocket.sendto(bytes(str(send_data),  "utf8"),('192.168.137.1',8847)) # 由于接收是在windows上，而windows中默认编码是gbk
    time.sleep(0.4)
    send_data = send_data + 1
    
# 关闭套接字
ClientSocket.close()

