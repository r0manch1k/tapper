import SwiftUI

struct SidebarView: View {
    @State private var showLobby: Bool = false
    @State private var showJoin: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            HStack(alignment: .bottom, spacing: 5) {
                Text("Tapper Game")
                    .fontWeight(.bold)
                Text("by R&R")
                    .fontWeight(.ultraLight)
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.leading)
            }

            NavigationStack {
                HStack {
                    VStack(alignment: .leading, spacing: 10.0) {
                        Text("Click Create to start a new game. You will be moved to the lobby. Please wait for other players to join, then click Start to begin.")
                        Text("If you would like to join an existing lobby, click Join and enter the server's IP address followed by the port number.")
                        Text("Tap on the other hamster. The hamster that reaches 10 taps first wins.")
                        Text("Mind you can't press two or more keys at the time.")
                        Text("Thank's for playing!")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.gray)

                    Spacer()
                }

                Spacer()

                Button(action: {
                    showLobby = true
                }, label: {
                    Spacer()
                    Text("Create")
                    Spacer()
                })
                .buttonStyle(.borderedProminent)
                .navigationDestination(isPresented: $showLobby) {
                    VStack {
                        LobbyView(showLobby: $showLobby)
                    }
                }
                .navigationBarBackButtonHidden(true)

                Button(action: {
                    showJoin = true
                }, label: {
                    Spacer()
                    Text("Join")
                    Spacer()
                })
                .buttonStyle(.bordered)
                .navigationDestination(isPresented: $showJoin) {
                    VStack {
                        JoinView(showJoin: $showJoin)
                    }
                }
                .navigationBarBackButtonHidden(true)
            }
        }
        .padding(10.0)
        .listStyle(.sidebar)
    }
}

#Preview {
    SidebarView()
}
