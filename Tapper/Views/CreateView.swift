import SwiftUI

enum CreateState {
    case waiting
    case start
}

struct CreateView: View {
    
    @EnvironmentObject var tapperConnection: TapperConnection
    @Environment(\.callAlert) var callAlert
    
    @Binding var isActive: Bool
    
    @State private var showAlert: Bool = false
    @State var showDisconnect: Bool = false
    @State private var alertText: String = "Something went wrong"
    
    @State var hostsList: [HostData] = []
    @State var myIp: String = "nah you're alone in this bruh💀"
    
    @State var createState: CreateState = .waiting

    var body: some View {
        VStack {
            LobbyView(hostsList: $hostsList, myIp: $myIp)
            
            Spacer()
            
            VStack(spacing: 5) {
                switch createState {
                case .waiting:
                    Label {
                        Text("Waiting for players...")
                    } icon: {
                        Image(systemName: "progress.indicator")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.gray)
                    .symbolEffect(.rotate, options: .repeat(.continuous))
                case .start:
                    Button {
                        startGame()
                    } label: {
                        Text("Start")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                    

                if showDisconnect {
                    Button {
                        endGame()
                    } label: {
                        Text("Disconnect")
                    }
                    .font(.caption)
                    .buttonStyle(.link)
                    .foregroundStyle(.red)
                } else {
                    Button {
                        leaveView()
                    } label: {
                        Text("Back")
                    }
                    .font(.caption)
                    .buttonStyle(.link)
                }
            }
        }
        .onAppear(perform: {
            myIp = tapperConnection.myIp
        })
        .onChange(of: tapperConnection.messageLobby) {
            refreshHostsList(tapperConnection.messageLobby)
        }
        .onChange(of: tapperConnection.messageDc) {
            endGame()
        }
    }
    
    private func startGame() {
        tapperConnection.startGame()
        showDisconnect = true
        
    }
    
    private func endGame() {
        tapperConnection.closeConnection()
        isActive = false
    }
    
    private func refreshHostsList(_ hostsList_: [HostData]) {
        hostsList = hostsList_
        showDisconnect = true
        if hostsList_.count > 1 {
            createState = .start
        }
    }
    
    private func leaveView() {
        tapperConnection.closeConnection()
        isActive = false
    }
}
