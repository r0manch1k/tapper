import Foundation
import Network

enum CustomErrors: Error {
    case DataError
    case NetworkError
    case InvalidAddress
    case DecoderError
}

class SocketConnection {
    fileprivate var serverAlive = false
    fileprivate var connection: NWConnection!
    fileprivate var serverPort: UInt16 = 5000
    fileprivate var serverIp: String = "127.0.0.1"

    fileprivate var buffer = 2048
    fileprivate var _inputData = ""
    fileprivate var _outputData = ""

    fileprivate var _otherPlayerName = ""
    fileprivate var _currentPlayerName = ""

    init() {
        _currentPlayerName = currentPlayerName()
    }

    var otherPlayerName: String {
        return _otherPlayerName
    }

    func currentPlayerName() -> String {
        return Host.current().localizedName ?? ""
    }

    @Sendable
    func updateServerState(to state: NWConnection.State) {
        switch state {
        case .setup:
            serverAlive = true
        case .waiting:
            serverAlive = true
        case .ready:
            serverAlive = true
        case .failed:
            serverAlive = false
        case .cancelled:
            serverAlive = false
        case .preparing:
            serverAlive = false
        default:
            serverAlive = false
        }
    }

    fileprivate func updateOtherPlayerName(name: String) {
        _otherPlayerName = name
    }

    fileprivate func prepareConnection() async -> String {
        connection = NWConnection(host: NWEndpoint.Host(serverIp), port: NWEndpoint.Port(rawValue: serverPort)!, using: .udp)
        connection.stateUpdateHandler = updateServerState(to:)
        connection.start(queue: DispatchQueue.global())

        while !serverAlive {}
        send(message: "im:\(_currentPlayerName)")
        
        let response = await receive()
    
        return response
    }

    func closeConnection() {
        send(message: "dc:" + _currentPlayerName)
        serverAlive = false
        connection.cancel()
    }

    func send(message: String) {
        connection.send(content: message.data(using: String.Encoding.utf8), completion: NWConnection.SendCompletion.contentProcessed(({ NWError in
            if NWError == nil {
                print("Data was sent!")
            } else {
                print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            }
        })))
    }

    func receive() async -> String {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65535) { data, _, isComplete, _ in
                print("ZALUPA EBANAYA")
                if isComplete {
                    if data != nil {
                        let receivedData: String = String(decoding: data!, as: UTF8.self)
                        print("Received message: \(receivedData)")
                        self._outputData = receivedData
                    } else {
                        print("ERROR! Data == nil")
                    }
                }
            }
            return self._outputData
        }
    }



    

class ClientManager: SocketConnection, ObservableObject {
    override init() {
        super.init()
    }

    func isValidIP(_ ip: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")
        return regex.firstMatch(in: ip, range: NSRange(location: 0, length: ip.utf16.count)) != nil
    }

    func connectToServer(_ ip: String) async throws -> String {
        if isValidIP(ip) {
            serverIp = ip
        } else {
            throw CustomErrors.InvalidAddress
        }

        let response = await prepareConnection()
        if serverAlive {
            return response
        }
        throw CustomErrors.NetworkError
    }
}

class ServerManager: SocketConnection, ObservableObject {
    override init() {
        super.init()

        if getServerIp() != nil {
            serverIp = getServerIp()!
        }
    }

    func getServerIp() -> String? {
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

    override func prepareConnection() async -> String {
        // ...
        // run executable python server file
        // ...

        await super.prepareConnection()
    }

    func connectToServer() async throws -> String {
        let response = await prepareConnection()
        if serverAlive {
            if response.hasPrefix("im:") {
                _currentPlayerName = response.substring(with: 3 ..< (response.count - 1))
            }
            return response
        }
        throw CustomErrors.NetworkError
    }
}

extension Bool {
    func toInt() -> Int {
        return self ? 1 : 0
    }
}

extension String {
    func toDouble() throws -> Double {
        guard let result: Double = Double(self) else {
            throw CustomErrors.DataError
        }
        return result
    }

    func toBool() throws -> Bool {
        guard let result: Int = Int(self) else {
            throw CustomErrors.DataError
        }
        return result > 0 ? true : false
    }

    func index(from: Int) -> Index {
        return index(startIndex, offsetBy: from)
    }

    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex ..< endIndex])
    }
}

// USE ".connect()" FOR CONNECT TO SERVER
// USE ".get_data()" AND ".set_data()" FOR COMMUNICATE WITH OTHER PLAYER
// USE "StateData()" STRUCT FOR STORING GAME DATA

func main() async throws {
    let client = ClientManager()
    let s = try! await client.connectToServer("10.193.188.255")
    print(s)
}

// Task {
//    try! await main()
//    print("lox")
// }
