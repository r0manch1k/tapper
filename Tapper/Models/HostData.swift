import Foundation

struct HostData: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var isServer: Bool

    static func example() -> HostData {
        HostData(name: "Rostelekom", isServer: false)
    }

    static func examples() -> [HostData] {
        [
            HostData(name: "Skybourne", isServer: false),
            HostData(name: "Eziz", isServer: false),
        ]
    }
}
