import SwiftUI

struct CreateView: View {
    
    @EnvironmentObject var tapperConnection: TapperConnection
    @Environment(\.callAlert) var callAlert
    
    @Binding var isActive: Bool
    @State private var showStart: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertText: String = "Something went wrong"
    
    @State var hostsList: [HostData] = []
    @State var myIp: String = "nah you're alone in this bruh💀"

    var body: some View {
        VStack {
            LobbyView(hostsList: $hostsList, myIp: $myIp)
            
            Spacer()
            
            VStack(spacing: 5) {
                if showStart {
                    Button {
                        startGame()
                    } label: {
                        Text("Start")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Label {
                        Text("Waiting for players...")
                    } icon: {
                        Image(systemName: "progress.indicator")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.gray)
                    .symbolEffect(.rotate, options: .repeat(.continuous))
                }
                
                Button {
                    leaveView()
                } label: {
                    Text("Back")
                }
                .font(.caption)
                .buttonStyle(.link)
            }
        }
        .onAppear(perform: {
            myIp = tapperConnection.myIp
        })
        .onChange(of: tapperConnection.messageLobby) {
            refreshHostsList(tapperConnection.messageLobby)
        }
    }
    
    private func startGame() {
        tapperConnection.startGame()
        
    }
    
    private func refreshHostsList(_ hostsList_: [HostData]) {
        hostsList = hostsList_
        if hostsList_.count > 1 {
            showStart = true
        }
    }
    
    private func leaveView() {
        tapperConnection.closeConnection()
        isActive = false
    }
}
