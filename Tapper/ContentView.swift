import SpriteKit
import SwiftUI

struct ContentView: View {
    var scene: SKScene {
        let scene = GameScene(fileNamed: "GameScene")!
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
    }
}

#Preview {
    ContentView()
}
