import SpriteKit
import SwiftUI

struct CallAlertKey: EnvironmentKey {
    static let defaultValue: ((String) -> Void)? = nil
}

extension EnvironmentValues {
    var callAlert: ((String) -> Void)? {
        get { self[CallAlertKey.self] }
        set { self[CallAlertKey.self] = newValue }
    }
}

struct ContentView: View {
    @StateObject var tapperConnection: TapperConnection = TapperConnection()
    
    @State private var showAlert: Bool = false
    @State private var alertText: String = "Something went wrong"
    
    private var scene: SKScene {
        let scene = GameScene(fileNamed: "GameScene")!
        scene.setConnection(tapperConnection)
        scene.scaleMode = .aspectFill
        return scene
    }

    var body: some View {
        HStack(spacing: 0) {
            SpriteView(scene: scene)
                .frame(minWidth: 960, idealWidth: 960, minHeight: 540, idealHeight: 540)
            
            SidebarView()
                .frame(minWidth: 200, idealWidth: 200)
        }
        .frame(minWidth: 1160, idealWidth: 1160, maxWidth: 1160, minHeight: 540, idealHeight: 540, maxHeight: 540)
        .environmentObject(tapperConnection)
        .environment(\.callAlert, callAlert)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("ERROR"), message: Text(alertText), dismissButton: .default(Text("OK")))
        }
        .onDisappear(perform: {
            showAlert = false
        })
    }
    
    func callAlert(_ text: String) {
        alertText = text
        showAlert = true
    }
}

#Preview {
    ContentView()
}
