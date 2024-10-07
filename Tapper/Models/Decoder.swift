struct Decoder {
    static func toGameData(_ s: String) throws -> GameData {
        let parts = s.components(separatedBy: ":")
        
        if parts.first != "state" {
            throw CustomErrors.DecoderError
        }

        let gameData: GameData = try! GameData(playerX: parts[1].toDouble(), playerY: parts[2].toDouble(), mouseX: parts[3].toDouble(), mouseY: parts[4].toDouble(), mouseClicked: parts[5].toBool())

        return gameData
    }
    
    static func toPlayersList(_ s: String) throws -> [Player] {
        let parts = s.components(separatedBy: ":")
        
        if parts.first != "im" {
            throw CustomErrors.DecoderError
        }
        
        let playersListString: [String] = Array(parts.dropFirst())
        
        var playersList: [Player] = []
        
        for player in playersListString {
            playersList.append(Player(name: player))
        }
        
        return playersList
    }
}
