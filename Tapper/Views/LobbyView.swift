import SwiftUI

struct LobbyView: View {

    var playersList: [Player]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Lobby")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.gray)

            Divider()
            ForEach(playersList) { player in
                PlayerView(hostName: player.name, isServer: true)
            }
            Divider()
            Text("Your IP: 192.29.0.34")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.gray)
        }
    }
}

#Preview {
    LobbyView(playersList: [Player(name: "HUESOS")])
}
