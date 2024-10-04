#
#   ClientManager.py
#   Tapper
#
#   Created by Ruslan Kutorgin on 30.09.2024.


import socket
import random


class SocketClientManager:
    def __init__(self):
        self.server_address = ("10.193.164.157", 20001)

        self.socket_manager = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
        self.buffer_size = 1024
    
    def connect(self):
        self.socket_manager.connect(self.server_address)

        while (True):
            self.send(str(random.randint(1, 123)))
            self.receive()
    
    def send(self, msg):
        msg_to_bytes = str.encode(msg)
        self.socket_manager.send(msg_to_bytes)

    def receive(self):
        server_msg = self.socket_manager.recvfrom(self.buffer_size)[0].decode("utf-8")
        print(server_msg)
    

mnger = SocketClientManager()
mnger.connect()
