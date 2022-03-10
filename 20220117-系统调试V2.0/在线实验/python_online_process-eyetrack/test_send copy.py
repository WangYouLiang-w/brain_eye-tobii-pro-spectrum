import socket
from cv2 import initUndistortRectifyMap
import time
# 建立服务端
ClientSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
ClientIp = socket.gethostbyname(socket.gethostname())    #获取本地ip
ClientAddr = (ClientIp, 40008)                      #设置端口号
ClientSocket.bind(ClientAddr)


while True:
    # send_data = input("请输入要发送的数据：")
    # if send_data == 'exit':
    #     break
    send_data = 1
    ClientSocket.sendto(bytes(str(send_data), "utf8"),('192.168.137.1',40007)) # 由于接收是在windows上，而windows中默认编码是gbk
    time.sleep(0.4)
# 关闭套接字
ClientSocket.close()

