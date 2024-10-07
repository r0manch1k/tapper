import SwiftUI

// |CONNECTED|GAMEDATA|
// |   1bit  |  8bit  |

// GAMEDATA
// |MOUSEX|MOUSEY|MOUSECLICKED|


// iam:ROMAN -> accepted:RUSYA
// mystate:12:23:1: -> otherstate:12:1

struct SidebarView: View {
    @State var showCreate: Bool = false
    @State var showJoin: Bool = false

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
                    HStack {
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
                    }

                    Spacer()

                    Button {
                        showCreate = true
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
}

#Preview {
    SidebarView()
}
