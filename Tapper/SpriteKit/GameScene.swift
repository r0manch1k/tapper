import SpriteKit

class GameScene: SKScene {
    private var playerNode = SKSpriteNode()
    private var oldMousePosition = NSPoint(x: 0, y: 0)
    private var playerSpeed: Double = 650
    private var alphaValue: Double = 0.1
    private var jumpStrenght = 250
    private var cloudNodes: [(SKNode, Double, SKAction)] = []
    private let jumpSound: NSSound? = NSSound(named: "jump.wav")!

    override func didMove(to view: SKView) {
        // Unsafe wrapping :(
        playerNode = childNode(withName: "Player") as! SKSpriteNode

        // Iterate and setup cloud nodes (Need to fix cloud movement)
        enumerateChildNodes(withName: "Object") {
            node, _ in

            let finishPos = self.getOutOfScenePosX(node)
            let cloudMoveAction: SKAction = SKAction.moveBy(x: CGFloat.random(in: 2000 ... 2500), y: 0, duration: TimeInterval(TimeInterval.random(in: 320 ... 340) * node.frame.width / 120))
            self.cloudNodes.append((node, finishPos, cloudMoveAction))
            node.run(cloudMoveAction)
        }

        // Safely handle the sound loading
        if jumpSound == nil {
            print("Failed to load sound: jump.wav") // Throwing error doesn't go well with override func
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Optimize cloud movement and re-running actions
        for (node, finishPos, action) in cloudNodes {
            if node.position.x >= finishPos {
                node.position.x = -finishPos
                node.removeAllActions()
                node.run(action)
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

        alphaValue += 0.1
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
            if !jumpSound!.isPlaying {
                DispatchQueue.global().async {
                    self.jumpSound!.play()
                }
            }
        } else if pressedKey == "a" || pressedKey == "A" || pressedKey == "d" || pressedKey == "D" {
            alphaValue = 0.1
        }
    }

    func getOutOfScenePosX(_ node: SKNode) -> Double {
        // Assume some logic for calculating the out of scene position based on node
        let pos: Double = size.width / 2 + node.frame.width / 2
        return pos
    }

    func lerp(_ a: Double, _ b: Double, _ t: Double = 0.1) -> Double {
        return a + t * (b - a)
    }
}
