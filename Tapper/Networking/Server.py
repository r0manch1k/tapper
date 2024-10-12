import sys
import socket
import logging
import threading
import subprocess

logging.basicConfig(format='[%(asctime)s | %(levelname)s]: %(message)s',
                    datefmt='%d.%m.%Y %H:%M:%S',
                    level=logging.INFO)


class SocketManager:
    def __init__(self):
        self.serverPort = 20001
        self.serverIp = self._getSockAddr()

        self.socketManager = socket.socket(family=socket.AF_INET, 
                                           type=socket.SOCK_DGRAM)
        self.socketManager.bind((self.serverIp, 
                                 self.serverPort))
        self.socketManager.settimeout(180)

        self.clients = {}
        self.buffer = 2048
        self.running = True

    def run(self) -> None:
        logging.info(f"Server {self.serverIp}:{self.serverPort} is connecting...")

        while self.running:
            try:
                packet, address = self.socketManager.recvfrom(self.buffer)
            except:
                logging.info(f"Server timed out")
                self._shutdown()
                break
                
            packet_thread = threading.Thread(
                target=self._handlePacket, args=(packet, address))
            packet_thread.start()

        self.socketManager.close()
    
    def _handlePacket(self, packet, address) -> None:
        decoddedPacket = packet.decode("utf-8")
        # logging.info(f"Recieved: {decoddedPacket}")

        if decoddedPacket.startswith("dc"):
            logging.info(f"Client disconnected: {self.clients[address]}")

            if len(self.clients) != 1:
                self.clients.pop(address)

                leaveMsg = "dc:" + self.clients[address]
                self._sendAll(leaveMsg)

            else:
                self.socketManager.settimeout(None)
                self._shutdown()
                return

        elif decoddedPacket.startswith("im"):
            if address not in self.clients:
                name = decoddedPacket[3:]
                self.clients[address] = name
                logging.info(f"""Client connected: "{name}" {address}""")

                lobbyMsg = "lobby:" + ':'.join(list(self.clients.values()))
                self._sendAll(lobbyMsg)

        elif decoddedPacket.startswith("sd"):
            self.socketManager.settimeout(None)
            self._shutdown()
            return

        else:
            for client in self.clients:
                if client != address:
                    self.socketManager.sendto(packet, client)
    
    def _sendAll(self, msg: str) -> None:
        for client in self.clients:
            self.socketManager.sendto(
                msg.encode("utf-8"),
                client)
    
    def _shutdown(self) -> None:
        self._sendAll("dc")
        self.clients.clear()
        self.running = False
        self.socketManager.sendto("".encode("utf-8"), (self.serverIp, self.serverPort))
        
        logging.info("Server shutdown...")

    def _getSockAddr(self) -> str:
        _ip = str()
        try:
            _ip = subprocess.check_output(["ipconfig", "getifaddr", "en0"]).decode("utf-8")[:-1]
        except:
            logging.error("NERWORK_ERROR!")
            self._shutdown()
            sys.exit(1)

        return _ip


if __name__ == "__main__":
    server = SocketManager()
    server.run()
    sys.exit()