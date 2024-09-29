//
//  ContentView.swift
//  Tapper
//
//  Created by Роман Соколовский on 27.09.2024.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    
    var scene: SKScene {
        let scene = GameScene(fileNamed: "GameScene")!
        scene.scaleMode = .aspectFill
        return scene
    }
    
    var body: some View {
        HStack(spacing: 0) {
            SpriteView(scene: scene)
                .frame(width: 800, height: 500)
            VStack {
                Text("There'll be players")
                List {
                    Text("A List Item")
                    Text("A Second List Item")
                    Text("A Third List Item")
                }
            }
        }
        .frame(width: 1000, height: 500)
        .fixedSize()
    }
}

#Preview {
    ContentView()
}
