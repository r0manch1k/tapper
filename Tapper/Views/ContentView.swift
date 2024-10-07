import SpriteKit
import SwiftUI

struct ContentView: View {
    @StateObject private var clientManager: ClientManager = ClientManager()
    var currentScene: String = getLuckyString()

    private var scene: SKScene {
        let scene = GameScene(fileNamed: currentScene)!
        scene.scaleMode = .aspectFit
        return scene
    }

    var body: some View {
        HStack(spacing: 0) {
            SpriteView(scene: scene)
                .frame(width: 960, height: 540)
            SidebarView()
                .frame(width: 200)
        }
        .frame(width: 1160, height: 540)
        .environmentObject(clientManager)
    }
}

func getLuckyString() -> String {
    let rand: Int = Int.random(in: 0 ... 100)
    return rand > 0 ? "GameScene0" : "GameScene1"
}

#Preview {
    ContentView()
}
