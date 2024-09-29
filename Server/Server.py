import socket

server_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)

server_sock.bind(("localhost", 2000))

while True:
    # bytesAddressPair = server_sock.recvfrom(1024)
    # sock, addr = server_sock.accept()
    # print(bytesAddressPair)
    server_sock.close()
