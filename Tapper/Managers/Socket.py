#
#   ServerManager.py
#   Tapper
#
#   Created by Ruslan Kutorgin on 30.09.2024.


import socket
import threading


class ServerManager:
    def __init__(self) -> None:
        self.socket_manager = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
        self.server_ip = self._get_sock_addr()
        self.server_port = 20001

        self.client_addresses = []
        self.thread = threading.Thread(target=self.connect)
    
    def connect(self) -> None:
        self.socket_manager.bind((self.server_ip, self.server_port))
        print(f"Server {self.server_ip} is connecting...")
        
        while (True):
            in_msg, in_addr = self.socket_manager.recvfrom(2048)

            if in_msg.decode('utf-8') == "TAPPER_CONNECTED" \
            and len(self.client_addresses) < 2 \
            and all([in_addr[0] == addr[0] for addr in self.client_addresses]) \
            and self.client_addresses == []:
                self.client_addresses.append(in_addr)  
                print("Client connected: ", in_addr)

            elif in_msg.decode('utf-8') == "TAPPER_DISCONNECTED":
                break

            elif len(self.client_addresses) == 2:
                for out_addr in self.client_addresses: 
                    if out_addr[0] != in_addr[0]: 
                        print(f"""Message: \"{in_msg.decode('utf-8')}\" from client: \"{in_addr}\" to client: \"{out_addr}\"""")
                        self.socket_manager.sendto(in_msg, out_addr)
    
    def listen(self) -> None:
        self.thread.start()
    
    def _get_sock_addr(self) -> str:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(("8.8.8.8", 80))
        except:
            print("NERWORK_ERROR!")

        return s.getsockname()[0]
    
    # def broadcast(self) -> None:
    #     broadcast_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    #     broadcast_socket.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

    #     server_ip = socket.gethostbyname(socket.gethostname())
    #     broadcast_message = f"SERVER_IP:{server_ip}".encode("utf-8")

    #     while not self.broadcast_event.is_set():
    #         broadcast_socket.sendto(broadcast_message, ('<broadcast>', 20001))
    #         print(f"Broadcasting server: {server_ip}")

    #         self.broadcast_event.wait(0.5)


sock_mngr = ServerManager()
sock_mngr.listen()