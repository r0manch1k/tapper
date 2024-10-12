import SwiftUI

struct LobbyView: View {

    @Binding var hostsList: [HostData]
    @Binding var myIp: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("Lobby")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.gray)

            Divider()
            ForEach(hostsList) { host in
                HostView(hostName: host.name, isServer: host.isServer)
            }
            Divider()
            Text("Your IP: \(myIp)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.gray)
            Spacer()
        }
    }
}
