import CocoaAsyncSocket
import Foundation
import Network

class TapperConnection: NSObject, ObservableObject, GCDAsyncUdpSocketDelegate {
    private var connection: GCDAsyncUdpSocket

    private var _isServer = false
    private var _isClient = false
    private var serverAlive = false
    private var serverPort: UInt16 = 20001
    private var serverIp: String = "127.0.0.1"
    
    weak var gameControllerDelegate: GameControllerDelegate?

    private var _myIp = ""
    private var _myPort: UInt16 = 20002
    private var _myDeviceName = Host.current().localizedName ?? ""

    @Published var messageDc: [HostData] = []
    @Published var messageLobby: [HostData] = []

    override init() {
        connection = GCDAsyncUdpSocket()
        super.init()
        connection.setDelegate(self)
        connection.setDelegateQueue(DispatchQueue.main)
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
    
    private func shell(command: String) {
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", command]

        do {
            try process.run()
        } catch {
            print("Error running Server: \(error)")
        }
    }

    func createConnection() async throws {
        let ip = getMyIp()
        if ip != nil {
            serverIp = ip!
            _myIp = ip!
        } else {
            print(CustomErrors.InvalidAddress.localizedDescription)
            return
        }

        _isServer = true
        await runServer()
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
            print(CustomErrors.NetworkError.localizedDescription)
            return
        }

        _isClient = true
        connectToServer()
    }
    
    func startGame() {
        gameControllerDelegate?.gameStarted()
    }
    
    private func runServer() async {
        let currentFileURL = URL(fileURLWithPath: #file)
        let serverURL = currentFileURL.deletingLastPathComponent().appending(component: "Server.sh")
        
        shell(command: serverURL.path())

        while messageLobby == [] {
            connectToServer()
        }
    }
    
    private func connectToServer() {
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
        
        if _isServer {
            send(message: "im:\(_myDeviceName)!")
        } else {
            send(message: "im:\(_myDeviceName)")
        }
    }

    func closeConnection() {
        if isServer {
            send(message: "sd")
        } else {
            send(message: "dc:\(_myDeviceName)")
        }
        connection.close()
        
        messageDc = []
        messageLobby = []
        _isClient = false
        _isServer = false
        serverAlive = false
    }

    func send(message: String) {
        let data = message.data(using: .utf8)!
        connection.send(data, withTimeout: 0.1, tag: 0)
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        let response: String = String(decoding: data, as: UTF8.self)
        print("Received data: \(response)")

        var decodedData: Any
        var messageType: MessageType
        (decodedData, messageType) = try! Decoder.decodeMessage(response)

        switch messageType {
        case MessageType.lobby:
            messageLobby = decodedData as! [HostData]
        case MessageType.dc:
            messageDc = decodedData as! [HostData]
        case MessageType.gamedata:
            gameControllerDelegate?.receiveGameData(decodedData as! GameData)
        }
    }
}
