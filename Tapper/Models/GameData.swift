import CoreFoundation

struct GameData {
    var name: String
    var skin: String
    var velocity: CGVector
    var playerX: Double
    var playerY: Double
    var keyPressed: Bool
    var score: (Int, Int)
}
