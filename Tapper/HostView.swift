import SwiftUI

struct HostView: View {
    let hostName: String
    let isServer: Bool

    var body: some View {
        Button {
            print("j")
        } label: {
            HStack {
                Image(systemName: "wifi")
                Text(hostName)
                Spacer()
//                Text(isServer ? "Server" : "")
//                    .font(.caption)
//                    .fontWeight(.semibold)
//                    .foregroundColor(Color.gray)
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .symbolEffect(.variableColor, options: .repeat(.continuous))
            }
            .padding(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
            .font(.callout)
        }
        .cornerRadius(10)
    }
}

#Preview {
    HostView(hostName: "localhost", isServer: true)
}
