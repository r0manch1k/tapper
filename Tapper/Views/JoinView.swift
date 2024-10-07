import SwiftUI

enum States: String {
    case connecting = "Connecting..."
    case waiting = "Waiting for starting..."
    case none = ""
}

struct JoinView: View {
    @Binding var isActive: Bool
    @State private var showLobby: Bool = false
    @State private var serverIp: String = ""
    @State private var joinState: States = .none
    @State private var showAlert: Bool = false
    @State private var alertText: String = "Something went wrong!"
    @EnvironmentObject private var clientManger: ClientManager

    @State var playersList: [Player] = []

    var body: some View {
        VStack {
            NavigationStack {
                VStack(alignment: .leading) {
                    HStack {
                        TextField(
                            "...",
                            text: $serverIp
                        )
                        .textFieldStyle(.roundedBorder)
                        .foregroundStyle(.gray)
                        .disableAutocorrection(true)
                    }

                    Button {
                        Task {
                            await connectToServer(serverIp)
                        }
                    } label: {
                        Spacer()
                        Text("Connect")
                        Spacer()
                    }
                    .font(.subheadline)
                    .buttonStyle(.borderedProminent)
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Error!"), message: Text(alertText), dismissButton: .default(Text("Got it!")))
                    }
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showLobby, destination: {
                LobbyView(playersList: playersList)
                Spacer()
            })

            if joinState != .none {
                Label {
                    Text(joinState.rawValue)
                } icon: {
                    Image(systemName: "progress.indicator")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.gray)
                .symbolEffect(.rotate, options: .repeat(.continuous))
            }

            Button {
                isActive = false
            } label: {
                Text("Back")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.link)
        }
    }

    private func connectToServer(_ serverInfo: String) async {
        joinState = .connecting
        
        var response: String = ""

        do {
            response = try await clientManger.connectToServer(serverIp)
        } catch CustomErrors.InvalidAddress {
            callAlert("Invalid IP address")
            return
        } catch CustomErrors.NetworkError {
            callAlert("Unable to connect to server")
            return
        } catch {
            return
        }

        do {
            playersList = try Decoder.toPlayersList(response)
        } catch CustomErrors.DecoderError {
            callAlert("Invalid data recieved")
            return
        } catch {
            return
        }

        showLobby = true

        joinState = .waiting
    }
    
    private func callAlert(_ text: String) {
        joinState = .none
        alertText = "Invalid IP address"
        showAlert = true
    }
}

#Preview {
    @Previewable @State var providedValue: Bool = false
    JoinView(isActive: $providedValue)
}
