import SwiftUI

struct JoinView: View {
    @Binding var showJoin: Bool

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
        
        Label {
            Text("Waiting for starting...")
        } icon: {
            Image(systemName: "progress.indicator")
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(Color.gray)
        .symbolEffect(.rotate, options: .repeat(.continuous))

        Button {
            showJoin = false
        } label: {
            Text("Back")
                .font(.caption)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.link)
    }
}

#Preview {
    @Previewable @State var providedValue: Bool = false
    JoinView(showJoin: $providedValue)
}
