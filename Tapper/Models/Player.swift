import Foundation

struct Player: Identifiable {
    let id = UUID()
    var name: String

    init(name: String = "Unknown") {
        self.name = name
    }

    static func example() -> Player {
        Player(name: "Rostelekom")
    }

    static func examples() -> [Player] {
        [
            Player(name: "Skybourne"),
            Player(name: "Eziz"),
        ]
    }
}
