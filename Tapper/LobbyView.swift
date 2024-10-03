import SwiftUI

struct LobbyView: View {
    @Binding var showLobby: Bool

    let examples: [Host] = Host.examples()

    var body: some View {
        VStack(alignment: .leading) {
            Text("Lobby")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.gray)

            Divider()
            ForEach(examples) { host in
                HostView(hostName: host.name, isServer: true)
            }
            Divider()
            Text("Your IP: 192.29.0.34")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.gray)
        }
        
        Spacer()
        
        VStack(spacing: 5) {
            Button {
                print("Start")
            } label: {
                Text("Start")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            Button {
                showLobby = false
            } label: {
                Text("Back")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.link)
        }
    }
}

#Preview {
    @Previewable @State var providedValue: Bool = false
    LobbyView(showLobby: $providedValue)
}
