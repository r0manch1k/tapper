struct GameData {
    var playerX: Double = 0
    var playerY: Double = 0
    var mouseX: Double = 0
    var mouseY: Double = 0
    var mouseClicked: Bool = false

    func toString() -> String {
        return "state:\(playerX):\(playerY):\(mouseX):\(mouseY):\(mouseClicked.toInt())"
    }
}
