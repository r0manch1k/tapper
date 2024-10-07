#
#   ServerManager.py
#   Tapper
#
#   Created by Ruslan Kutorgin on 30.09.2024.


import socket
import threading
import subprocess


class SocketManager:
    def __init__(self) -> None:
        self.socket_manager = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
        self.server_ip = self._get_sock_addr()
        self.server_port = 20001

        self.client_addresses = []
        self.thread = threading.Thread(target=self.connect)

        self.msg_1 = str()
        self.msg_2 = str()
    
    def connect(self) -> None:
        self.socket_manager.bind((self.server_ip, self.server_port))
        print(f"Server {self.server_ip} is connecting...")
        
        while (True):
            in_msg, in_addr = self.socket_manager.recvfrom(2048)
            print("received: ", in_msg.decode('utf-8'))

            if in_msg.decode('utf-8').startswith("dc:") \
            and len(self.client_addresses) == 2:
                self.client_addresses.remove(in_addr)
                print("Client disconnected: ", in_addr)
            
            elif in_msg.decode('utf-8').startswith("dc:") \
            and len(self.client_addresses) == 1:
                self.client_addresses.remove(in_addr)
                print("Client disconnected: ", in_addr)
                break

            elif in_msg.decode('utf-8').startswith("im:") \
            and len(self.client_addresses) < 2:
                if (len(self.client_addresses) == 0):
                    self.msg_1 = in_msg
                    self.client_addresses.append(in_addr)
                    print("Client connected: ", in_addr)

                elif (len(self.client_addresses) == 1 \
                and in_addr[0] != self.client_addresses[0][0]):
                    self.socket_manager.sendto(in_msg, self.client_addresses[0])
                    self.socket_manager.sendto(self.msg_1, in_addr)
                    self.client_addresses.append(in_addr)  
                    print("Client connected: ", in_addr)

            elif len(self.client_addresses) == 2:
                if all ([in_addr[0] == addr[0] for addr in self.client_addresses]):
                    for out_addr in self.client_addresses: 
                        if out_addr[0] != in_addr[0]: 
                            print(f"""Message: \"{in_msg.decode('utf-8')}\" from client: \"{in_addr}\" to client: \"{out_addr}\"""")
                            self.socket_manager.sendto(in_msg, out_addr)
        
    def listen(self) -> None:
        self.thread.start()
    
    def _get_sock_addr(self) -> str:
        _ip = str()
        try:
            _ip = subprocess.check_output(["ipconfig", "getifaddr", "en0"]).decode("utf-8")[:-1]
        except:
            print("NERWORK_ERROR!")

        return _ip


sock_mngr = SocketManager()
sock_mngr.listen()