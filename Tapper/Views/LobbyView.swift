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
            HStack(spacing: 5, content: {
                Text("Your IP: \(myIp)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.gray)
                Button {
                    NSPasteboard.general.declareTypes([.string], owner: nil)
                    let pasteboard = NSPasteboard.general
                    pasteboard.setString(myIp, forType: .string)
                } label: {
                    Image(systemName: "document.on.document.fill")
                }
                .controlSize(.mini)
                .buttonStyle(.borderless)
                Spacer()
            })
            
            Spacer()
        }
    }
}
