import Foundation

struct Host: Identifiable {
    let id = UUID()
    var name: String

    init(name: String = "Unknown") {
        self.name = name
    }

    static func example() -> Host {
        Host(name: "Rostelekom")
    }

    static func examples() -> [Host] {
        [
            Host(name: "Skybourne"),
            Host(name: "Eziz"),
        ]
    }
}
