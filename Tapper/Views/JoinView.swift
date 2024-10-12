import SwiftUI

enum JoinStates: String {
    case connecting = "Connecting..."
    case waiting = "Waiting for starting..."
    case none = ""
}

struct JoinView: View {
    
    @EnvironmentObject var tapperConnection: TapperConnection
    @Environment(\.callAlert) var callAlert
    
    @Binding var isActive: Bool
    
    @State private var serverIp: String = ""
    @State var myIp: String = "nah you're alone in this bruh"
    
    @State private var joinState: JoinStates = JoinStates.none

    @State private var showLobby: Bool = false
    
    @State var hostsList: [HostData] = []
    
    var body: some View {
        VStack {
            NavigationStack {
                VStack(alignment: .leading) {
                    TextField(
                        "IP...",
                        text: $serverIp
                    )
                    .textFieldStyle(.roundedBorder)
                    .foregroundStyle(.gray)
                    .disableAutocorrection(true)
                    Button {
                        connectToServer(serverIp)
                    } label: {
                        Spacer()
                        Text("Connect")
                        Spacer()
                    }
                    .font(.subheadline)
                    .buttonStyle(.borderedProminent)
                    
                    Text("\(tapperConnection.messageLobby)")
                        .opacity(0)
                    
                    Spacer()
                }
                .onChange(of: tapperConnection.messageLobby) {
                    refreshHostsList(tapperConnection.messageLobby)
                }
            }
            .navigationDestination(isPresented: $showLobby, destination: {
                LobbyView(hostsList: $hostsList, myIp: $myIp)
            })
            
            Label {
                Text(joinState.rawValue)
            } icon: {
                Image(systemName: "progress.indicator")
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(Color.gray)
            .symbolEffect(.rotate, options: .repeat(.continuous))
            .opacity(joinState == JoinStates.none ? 0 : 1)
            
            Button {
                leaveView()
            } label: {
                Text("Back")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.link)
        }
    }
    
    private func connectToServer(_ serverIp: String) {
        if serverIp == "" {
            return
        }
        
        joinState = JoinStates.connecting
        
        do {
            try tapperConnection.createConnection(ip: serverIp)
            myIp = tapperConnection.myIp
        } catch let error as CustomErrors {
            callAlert!(error.rawValue)
            joinState = JoinStates.none
            return
        } catch {
            callAlert!(error.localizedDescription)
            joinState = JoinStates.none
            return
        }
        
        joinState = JoinStates.waiting
    }
    
    private func refreshHostsList(_ hostsList_: [HostData]) {
        showLobby = true
        hostsList = hostsList_
        joinState = .waiting
    }
    
    private func leaveView() {
        tapperConnection.closeConnection()
        isActive = false
    }
}
