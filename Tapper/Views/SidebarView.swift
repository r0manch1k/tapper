import SwiftUI

struct SidebarView: View {
    
    @EnvironmentObject var tapperConnection: TapperConnection
    @Environment(\.callAlert) var callAlert
    
    @State var showCreate: Bool = false
    @State var showJoin: Bool = false
    @State var showLoading: Bool = false

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
                VStack {
                    VStack(alignment: .leading, spacing: 10.0) {
                        Text("Click Create to start a new game. You will be moved to the lobby. Please wait for other players to join, then click Start to begin.")
                        Text("If you would like to join an existing lobby, click Join and enter the server's IP address followed by the port number.")
                        Text("Keep tapping on the other hamster. The hamster that reaches 10 taps first wins.")
                        Text("Mind you can't press two or more keys at the time.")
                        Text("Good Luck!")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.gray)

                    Spacer()
                    
                    Label {
                        Text("Creating...")
                    } icon: {
                        Image(systemName: "progress.indicator")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.gray)
                    .symbolEffect(.rotate, options: .repeat(.continuous))
                    .opacity(showLoading ? 1 : 0)

                    Button {
                        Task {
                            await createGame()
                        }
                    } label: {
                        Spacer()
                        Text("Create")
                        Spacer()
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        showJoin = true
                    } label: {
                        Spacer()
                        Text("Join")
                        Spacer()
                    }
                    .buttonStyle(.bordered)
                }
                .environmentObject(tapperConnection)
                .navigationBarBackButtonHidden(true)
                .navigationDestination(isPresented: $showCreate, destination: {
                    CreateView(isActive: $showCreate)
                })
                .navigationDestination(isPresented: $showJoin, destination: {
                    JoinView(isActive: $showJoin)
                })
            }
        }
        .padding(10.0)
        .listStyle(.sidebar)
    }
    
    func createGame() async {
        showLoading = true
        do {
            try await tapperConnection.createConnection()
        } catch let error as CustomErrors {
            callAlert!(error.rawValue)
            showLoading = false
            return
        } catch {
            callAlert!(error.localizedDescription)
            showLoading = false
            return
        }
        showLoading = false
        showCreate = true
    }
}

#Preview {
    SidebarView()
}
