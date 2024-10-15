import CoreFoundation

enum MessageType {
    case lobby
    case gamedata
    case dc
}

class Decoder {
    
    static func decodeMessage(_ message: String) throws -> (Any, MessageType) {
        let parts: [String] = message.components(separatedBy: ":")
        let messageType: String = parts.first!
        
        switch messageType {
        case "lobby":
            return (toHostsList(Array(parts.dropFirst())), MessageType.lobby)
        case "gamedata":
            return (toGameData(Array(parts.dropFirst())), MessageType.gamedata)
        case "dc":
            return (toHostsList(Array(parts.dropFirst())), MessageType.dc)
        default:
            throw CustomErrors.DecoderError
        }
    }
    
    static func toGameData(_ parts: [String]) -> GameData {
        let gameData: GameData = try! GameData(name: parts[0], skin: parts[1], velocity: parts[2].toVector(), playerX: parts[3].toDouble(), playerY: parts[4].toDouble(), keyPressed: parts[5].toBool(), score: parts[6].toTuple())

        return gameData
    }
    
    static func toHostsList(_ parts: [String]) -> [HostData] {
        let hostsListString: [String] = parts
        
        var hostsList: [HostData] = []
        
        for host in hostsListString {
            hostsList.append(HostData(name: host, isServer: host.last == "!" ? true : false))
        }
        
        return hostsList
    }
}

extension Bool {
    func toInt() -> Int {
        return self ? 1 : 0
    }
}

extension String {
    func toInt() throws -> Int {
        guard let result: Int = Int(self) else {
            throw CustomErrors.DataError
        }
        return result
    }
    
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
    
    func toTuple() throws -> (Int, Int) {
        guard let fisrt = Int(self.components(separatedBy: ",")[0].dropFirst()) else {
            throw CustomErrors.DataError
        }
        guard let second =  Int(self.components(separatedBy: ",")[1].dropLast()) else {
            throw CustomErrors.DataError
        }
        return (fisrt, second)
    }
    
    func toVector() throws -> CGVector {
        guard let a = Double(self.components(separatedBy: ",")[0].dropFirst()) else {
            throw CustomErrors.DataError
        }
        guard let b =  Double(self.components(separatedBy: ",")[1].dropLast()) else {
            throw CustomErrors.DataError
        }
        return CGVector(dx: a, dy: b)
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

extension GameData {
    func toString() -> String {
        let result: String = "gamedata:\(name):\(skin):\(velocity.toString()):\(playerX):\(playerY):\(keyPressed.toInt()):\(tupleToString(score))"
        return result
    }
}

extension CGVector {
    func toString() -> String {
        return "(\(self.dx),\(self.dy))"
    }
}

func tupleToString(_ tuple: (Int, Int)) -> String {
    return "(\(tuple.0),\(tuple.1))"
}
