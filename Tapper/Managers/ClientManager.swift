import Network
import Foundation


extension Bool {
    func toInt() -> Int {
        return self ? 1 : 0
    }
}


extension String {
    func toDouble() throws -> Double {
        guard let result: Double = Double(self) else {
            throw CustomErrors.dataError
        }
        return result
    }

    func toBool() throws -> Bool {
        guard let result: Int = Int(self) else {
            throw CustomErrors.dataError
        }
        return result > 0 ? true : false
    }
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }

    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
}


enum CustomErrors: Error {
    case dataError
}


struct GameData {
    var playerX: Double = 0
    var playerY: Double = 0
    var mouseX: Double = 0
    var mouseY: Double = 0
    var mouseClicked: Bool = false

    func toString() -> String {
        return "state:\(playerX):\(playerY):\(mouseX):\(mouseY):\(mouseClicked.toInt())"
    }

    func toGameData(_ string: String) -> GameData {
        let parts = string.components(separatedBy: ":")

        let gameData: GameData = try! GameData(playerX: parts[1].toDouble(), playerY: parts[2].toDouble(), mouseX: parts[3].toDouble(), mouseY: parts[4].toDouble(), mouseClicked: parts[5].toBool())

        return gameData
    }
}


class SocketConnection {
    fileprivate var serverAlive = false
    fileprivate var connection: NWConnection?
    fileprivate var serverPort: UInt16 = 20001
    fileprivate var serverIp: String = "127.0.0.1"
    
    fileprivate var buffer = 2048
    fileprivate var _inputData = GameData()
    fileprivate var _outputData = GameData()
    
    fileprivate var _otherPlayerName = ""
    fileprivate var _currentPlayerName = ""
    
    init() {
        self._currentPlayerName = self.getCurrentPlayerName()
    }
    
    var inputData: GameData {
        get {
            return self._inputData
        }
        set (__inputData) {
            _inputData = __inputData
        }
    }
    
    var outputData: GameData {
        get {
            return self._outputData
        }
    }
    
    var otherPlayerName: String {
        get {
            return self._otherPlayerName
        }
    }
    
    fileprivate func getCurrentPlayerName() -> String {
        return Host.current().localizedName ?? ""
    }
        
    func updateServerState(to state: NWConnection.State) {
        switch (state) {
        case .setup:
            self.serverAlive = true
        case .waiting:
            self.serverAlive = true
        case .ready:
            self.serverAlive = true
        case .failed:
            self.serverAlive = false
        case .cancelled:
            self.serverAlive = false
        case .preparing:
            self.serverAlive = false
        default:
            self.serverAlive = false
        }
    }
    
    fileprivate func updateOtherPlayerName(name: String) {
        self._otherPlayerName = name
    }
        
    func openConnection() {
        if !self.serverAlive {
            self.prepareConnection()
        }
    }
    
    fileprivate func prepareConnection() {
        self.connection = NWConnection(host: NWEndpoint.Host(self.serverIp), port: NWEndpoint.Port(rawValue: self.serverPort)!, using: .udp)
        self.connection?.stateUpdateHandler = self.updateServerState(to:)
        self.connection?.start(queue: .global())
        
        while !self.serverAlive {}
        self.send(message: "TAPPER_CONNECTED " + self._currentPlayerName)
        print("User connected to server")
    }

    func closeConnection() {
        if self.serverAlive {
            self.send(message: "TAPPER_DISCONNECTED")
            self.serverAlive = false
            self.connection?.cancel()
        }
    }
        
    func send(message: String) {
        self.connection?.send(content: message.data(using: String.Encoding.utf8), completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
                print("Data was sent!")
            } else {
                print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            }
        })))
    }
        
    func receive() -> GameData {
        self.connection?.receiveMessage { data, context, isComplete, error in
            if (isComplete) {
                if (data != nil) {
                    let receivedData = String(decoding: data!, as: UTF8.self)
                    print("Received message: \(receivedData)")
                    
                    if receivedData.hasPrefix("TAPPER_CONNECTED") {
                        let name = receivedData.substring(with: ("TAPPER_CONNECTED".count)..<(receivedData.count))
                        self.updateOtherPlayerName(name: name)
                        
                    } else if receivedData == receivedData {
                        self.updateOtherPlayerName(name: "")
                        
                    } else {
                        self._outputData = GameData().toGameData(receivedData)
                    }
                } else {
                    print("ERROR! Data == nil")
                }
            }
        }
        return self._outputData
    }
}


class ClientManager : SocketConnection {
    private var _clientDeviceName = ""
    
    var clientDeviceName: String {
        get {
            return self._clientDeviceName
        }
    }
    
    override init() {
        super.init()
    }
    
    func setServerIp(_ ip: String) {
        if isValidIP(ip) {
            self.serverIp = ip
        }
    }
    
    func isValidIP(_ ip: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")
        return regex.firstMatch(in: ip, range: NSRange(location: 0, length: ip.utf16.count)) != nil
    }
}


class ServerManager : SocketConnection {
    private var _serverDeviceName = ""
    
    var serverDeviceName: String {
        get {
            return self._serverDeviceName
        }
    }
    
    override init() {
        super.init()
        
        if self.getServerIp() != nil {
            self.serverIp = self.getServerIp()!
        }
    }
        
    func getServerIp() -> String? {
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
    
    override func prepareConnection() {
        // ...
        // run executable python server file
        // ...
        
        super.prepareConnection()
    }
}


// USE ".connect()" FOR CONNECT TO SERVER
// USE ".get_data()" AND ".set_data()" FOR COMMUNICATE WITH OTHER PLAYER
// USE "StateData()" STRUCT FOR STORING GAME DATA

let server = ServerManager()
server.openConnection()
