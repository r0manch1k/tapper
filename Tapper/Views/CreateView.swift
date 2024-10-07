import SwiftUI

struct CreateView: View {
    @Binding var isActive: Bool

    var body: some View {
        VStack {
            LobbyView(playersList: [])
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
                    isActive = false
                } label: {
                    Text("Back")
                }
                .font(.caption)
                .buttonStyle(.link)
            }
        }
        
    }
}

#Preview {
    @Previewable @State var providedValue: Bool = false
    CreateView(isActive: $providedValue)
}
