import SpriteKit

class GameScene: SKScene {
    var playerNode = SKSpriteNode()
    var oldMousePosition = NSPoint(x: 0, y: 0)
    var playerSpeed: Double = 650
    var alphaValue: Double = 0.1
    var jumpStrenght = 250
    var cloudNodes: [(SKNode, Double, SKAction)] = []
    let jumpSound: NSSound = NSSound(named: "jump.wav")!

    override func didMove(to view: SKView) {
        playerNode = childNode(withName: "Hamster") as! SKSpriteNode

        enumerateChildNodes(withName: "Cloud") {
            node, _ in

            let finishPos = self.getOutOfScenePosX(node)
            let cloudMoveAction: SKAction = SKAction.moveBy(x: 2500, y: 0, duration: TimeInterval(TimeInterval.random(in: 320 ... 340) * node.frame.width / 120))
            self.cloudNodes.append((node, finishPos, cloudMoveAction))
            node.run(cloudMoveAction)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        for cloud in cloudNodes {
            let finishPos = cloud.1
            if cloud.0.position.x >= finishPos + 50 {
                cloud.0.position.x = -finishPos
                cloud.0.run(cloud.2)
            }
        }
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

        alphaValue += 0.3
        let currentSpeed = lerp(0, playerSpeed, alphaValue) // Not exactly the lerp...

        if pressedKey == "a" || pressedKey == "A" || pressedKey == "ф" || pressedKey == "Ф" {
            velocity = CGVector(dx: -currentSpeed, dy: 0)
            playerNode.physicsBody?.applyForce(velocity)
        } else if pressedKey == "d" || pressedKey == "D" || pressedKey == "в" || pressedKey == "В" {
            velocity = CGVector(dx: currentSpeed, dy: 0)
            playerNode.physicsBody?.applyForce(velocity)
        }
    }

    override func keyUp(with event: NSEvent) {
        let pressedKey = event.characters!

        if pressedKey == " " {
            playerNode.physicsBody?.applyImpulse(CGVector(dx: 0, dy: jumpStrenght))
            if !jumpSound.isPlaying {
                DispatchQueue.global().async {
                    self.jumpSound.play()
                }
            }
        } else if pressedKey == "a" || pressedKey == "A" || pressedKey == "d" || pressedKey == "D" {
            alphaValue = 0.1
        }
    }

    func getOutOfScenePosX(_ node: SKNode) -> Double {
        let pos: Double = size.width / 2 + node.frame.width / 2
        return pos
    }

    func lerp(_ a: Double, _ b: Double, _ t: Double = 0.1) -> Double {
        return a + t * (b - a)
    }

//    func easeOutCirc(_ x: Double) -> Double {
//        return sqrt(1 - pow(x - 1, 2))
//    }
}
