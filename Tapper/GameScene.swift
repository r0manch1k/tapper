//
//  GameScene.swift
//  Tapper
//
//  Created by Роман Соколовский on 26.09.2024.
//

import SpriteKit
import CoreGraphics

class GameScene: SKScene {
    
    var playerNode = SKSpriteNode()
    var oldMousePosition = NSPoint(x: 0, y: 0)
    var playerSpeed: Double = 650
    var alphaValue: Double = 0.1
    var jumpStrenght = 250
    
    override func didMove(to view: SKView) {
        playerNode = childNode(withName: "Hamster") as! SKSpriteNode
    }
    
    override func mouseDown(with event: NSEvent) {
        oldMousePosition = event.locationInWindow
    }
    
    override func mouseDragged(with event: NSEvent) {
        let newMousePosition = event.locationInWindow
        let velocity = CGVector(dx: newMousePosition.x - oldMousePosition.x, dy: 0)
        
        playerNode.physicsBody?.applyForce(velocity)
    }
    
    override func keyDown(with event: NSEvent) {
        let pressedKey = event.characters!
        var velocity: CGVector
        
        alphaValue = easeOutCirc(alphaValue)
        let currentSpeed = lerp(0, playerSpeed, alphaValue)
        
        if pressedKey == "a" || pressedKey == "A" {
            velocity = CGVector(dx: -currentSpeed, dy: 0)
            playerNode.physicsBody?.applyForce(velocity)
        } else if pressedKey == "d" || pressedKey == "D" {
            velocity = CGVector(dx: currentSpeed, dy: 0)
            playerNode.physicsBody?.applyForce(velocity)
        }
    }
    
    override func keyUp(with event: NSEvent) {
        let pressedKey = event.characters!
        
        if pressedKey == " " {
            playerNode.physicsBody?.applyImpulse(CGVector(dx: 0, dy: jumpStrenght))
        } else if pressedKey == "a" || pressedKey == "A" || pressedKey == "d" || pressedKey == "D" {
            alphaValue = 0.1
        }
    }
    
    func lerp(_ a: Double, _ b: Double, _ t: Double = 0.1) -> Double {
        return a + t * (b - a)
    }
    
    func easeOutCirc(_ x: Double) -> Double {
        return sqrt(1 - pow(x - 1, 2))
    }
}

