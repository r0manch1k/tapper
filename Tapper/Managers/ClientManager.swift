import Network
import Foundation


struct StateData{
    var player_x: Double = 0
    var player_y: Double = 0
    var mouse_x: Double = 0
    var mouse_y: Double = 0
    var clicked: Bool = false

    func to_string() -> String {
        let int_clicked: Int = clicked ? 1 : 0
        return "state:\(player_x):\(player_y):\(mouse_x):\(mouse_y):\(int_clicked)"
    }

    func from_string(_ string: String) -> StateData {
        let parts = string.split(separator: ":")
        return StateData(player_x: Double(parts[1])!, player_y: Double(parts[2])!, mouse_x: Double(parts[3])!, mouse_y: Double(parts[4])!, clicked: parts[5] == "1")
    }
}


class ClientManager {
    var connection: NWConnection?
    var server_port: UInt16 = 20001
    var server_ip: String = "127.0.0.1"
    
    var buffer = 2048
    var in_data = StateData()
    var out_data = StateData()
        
    init(_server_ip: String) {
        self.server_ip = _server_ip
    }
    
    private func join_to_server() {
        self.connection = NWConnection(host: NWEndpoint.Host(self.server_ip), port: NWEndpoint.Port(rawValue: self.server_port)!, using: .udp)
            
        if self.get_server_state() == "ready" {
            self.connection?.start(queue: .global())
            self.send(message: "TAPPER_CONNECTED")
        }
    }
        
    func get_server_state() -> String {
        if self.connection?.state == .ready {
            return "ready"
        } else if self.connection?.state == .setup {
            return "setup"
        } else if self.connection?.state == .cancelled {
            return "cancelled"
        } else if self.connection?.state == .preparing {
            return "preparing"
        } else {
            return "connection error"
        }
    }
    
    func get_out_data() -> StateData {
        return self.out_data
    }
    
    func set_in_data(data: StateData) {
        self.in_data = data
    }
    
    func prepare_connection() {
        self.join_to_server()
    }
        
    func connect() {
        self.prepare_connection()
        self.connection = NWConnection(host: NWEndpoint.Host(self.server_ip), port: NWEndpoint.Port(rawValue: self.server_port)!, using: .udp)
            
        if self.get_server_state() == "ready" {
            self.connection?.start(queue: .global())
            
            self.send(message: self.in_data.to_string())
            self.receive()
                
            // while true {
            //    self.send(message: self.in_data.to_string())
            //    self.receive()
            // }
        }
    }
        
    func send(message: String) {
        self.connection?.send(content: message.data(using: String.Encoding.utf8), completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            print(NWError!.errorCode)
        })))
    }
        
    func receive() {
        self.connection?.receiveMessage { (data, context, isComplete, error) in
            print(isComplete)
            print(String(decoding: data ?? Data(), as: UTF8.self))
            self.out_data = StateData().from_string(String(decoding: data ?? Data(), as: UTF8.self))
        }
    }
}


class ServerManager : ClientManager {
    init() {
        var _server_ip = "127.0.0.1"
        super.init(_server_ip: _server_ip)
        
        if self.get_server_ip() != nil {
            _server_ip = self.get_server_ip()!
        }
    }
        
    func get_server_ip() -> String? {
        var address : String?
            
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
            
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
                
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    
                let name = String(cString: interface.ifa_name)
                if  name == "en0" || name == "en2" || name == "en3" || name == "en4" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {
                        
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname, socklen_t(hostname.count),
                        nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                }
            }
        }
            
        freeifaddrs(ifaddr)
        return address
    }
    
    private func run_server() {
        // ...
        // run executable python server file
        // ...
        
        self.connection = NWConnection(host: NWEndpoint.Host(self.server_ip), port: NWEndpoint.Port(rawValue: self.server_port)!, using: .udp)
            
        if self.get_server_state() == "ready" {
            self.connection?.start(queue: .global())
            self.send(message: "TAPPER_CONNECTED")
        }
    }
    
    override func prepare_connection() {
        self.run_server()
    }
}

// USE ".connect()" FOR CONNECT TO SERVER
// USE ".get_data()" AND ".set_data()" FOR COMMUNICATE WITH OTHER PLAYER
// USE "StateData()" STRUCT FOR STORING GAME DATA
