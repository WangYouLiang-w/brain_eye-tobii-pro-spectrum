# import socket


# client_ip = socket.gethostbyname(socket.gethostname())
# # client_addr = (client_ip, 8848)
# client_addr = (client_ip, 40008)

# char = ['a','b','c','d','e','f','g','h','i','j','k','l']

# command1 = 11
# command2 = 10
# result1 = char[command1]
# result2 = char[command2]
# client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
# client_socket.bind(client_addr)
# # controlCenterAddr = ('127.0.0.1', 8847)
# controlCenterAddr = ('169.254.29.63', 40007)

# command = result1 + result2
# while True:
#     msg = bytes(str(command), "utf8")
#     client_socket.sendto(msg, controlCenterAddr)
#     print(msg)