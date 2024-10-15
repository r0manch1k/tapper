import Network
import Combine
import Foundation
import CocoaAsyncSocket

class TapperConnection: NSObject, ObservableObject, GCDAsyncUdpSocketDelegate {
    var connection: GCDAsyncUdpSocket
    
    var serverAlive = false
    private var _isServer = false
    private var _isClient = false
    private var serverPort: UInt16 = 20001
    private var serverIp: String = "127.0.0.1"
    
    weak var gameControllerDelegate: GameControllerDelegate?

    private var _myIp = ""
    private var _myPort: UInt16 = 20002
    private var _myDeviceName = Host.current().localizedName ?? ""

    @Published var messageDc: [HostData] = []
    @Published var messageLobby: [HostData] = []
    @Published var messageGameData: GameData?
    
    private var taskAsync: Task<(), Never>!
    
    override init() {
        connection = GCDAsyncUdpSocket()
        
        super.init()
        connection.setDelegate(self)
        connection.setDelegateQueue(DispatchQueue.main)
    }
    
    func startGame() {
        gameControllerDelegate?.gameStarted()
    }
    
    var isServer: Bool {
        get {
            return _isServer
        }
    }
    
    var isClient: Bool {
        get {
            return _isClient
        }
    }

    var myIp: String {
        return _myIp
    }

    var myDeviceName: String {
        return _myDeviceName
    }

    func getMyIp() -> String? {
        var address: String?

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en2" || name == "en3" || name == "en4" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {
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

    private func isValidIP(_ ip: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")
        return regex.firstMatch(in: ip, range: NSRange(location: 0, length: ip.utf16.count)) != nil
    }
    
    private func shell(command: String) throws {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        
        do {
            try task.run()
        } catch {
            throw CustomErrors.NetworkError
        }
    }

    func createConnection() throws {
        let ip = getMyIp()
        if ip != nil {
            serverIp = ip!
            _myIp = ip!
        } else {
            throw CustomErrors.InvalidAddress
        }

        _isServer = true
        
        runServer()
    }

    func createConnection(ip: String) throws {
        if isValidIP(ip) {
            serverIp = ip
        } else {
            throw CustomErrors.InvalidAddress
        }

        let myIp = getMyIp()
        if myIp != nil {
            _myIp = myIp!
        } else {
            throw CustomErrors.NetworkError
        }

        _isClient = true
        
        taskAsync = Task {
            await connectToServer()
        }
    }
    
    private func runServer() {
        let currentFileURL = URL(fileURLWithPath: #file)
        let serverURL = currentFileURL.deletingLastPathComponent().appending(component: "Server.sh")
        
        try! shell(command: "xattr -d com.apple.quarantine \(serverURL.path())")
        try! shell(command: "chmod +x \(serverURL.path())")
        try! shell(command: serverURL.path())
        
        taskAsync = Task {
            await connectToServer()
        }
    }
    
    private func setupConnection() {
        do {
            try connection.bind(toPort: _myPort)
        } catch {
            print(error.localizedDescription)
        }
        
        do {
            try connection.connect(toHost: serverIp, onPort: serverPort)
        } catch {
            print(error.localizedDescription)
        }
        
        do {
            try connection.beginReceiving()
        } catch {
            print(error.localizedDescription)
        }
        
        connection.setMaxSendBufferSize(1024)
        connection.setMaxReceiveIPv4BufferSize(1024)
    }
    
    private func connectToServer() async {
        while !taskAsync.isCancelled {
            setupConnection()
            if _isServer {
                send(message: "im:\(_myDeviceName)!")
            } else {
                send(message: "im:\(_myDeviceName)")
            }
            
            if messageLobby != [] {
                serverAlive = true
                break
            }
        }
    }

    func closeConnection() {
        if serverAlive {
            if isServer {
                send(message: "sd")
                try! shell(command: "killall Server.sh")
            } else {
                send(message: "dc:\(_myDeviceName)")
            }
        }
        connection.close()
        taskAsync.cancel()
        
        messageDc = []
        messageLobby = []
        _isClient = false
        _isServer = false
        serverAlive = false
        
        gameControllerDelegate?.gameEnded()
    }

    func send(message: String) {
        let data = message.data(using: .utf8)!
        connection.send(data, withTimeout: -1, tag: 0)
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        let response: String = String(decoding: data, as: UTF8.self).components(separatedBy: "\n")[0]
        
        print("RESPONSE: \(response)")
            
        var decodedData: Any
        var messageType: MessageType
        (decodedData, messageType) = try! Decoder.decodeMessage(response)
        
        switch messageType {
        case MessageType.lobby:
            messageLobby = decodedData as! [HostData]
        case MessageType.dc:
            messageDc = decodedData as! [HostData]
            closeConnection()
        case MessageType.gamedata:
            messageGameData = (decodedData as! GameData)
        }
    }
}
