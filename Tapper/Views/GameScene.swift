import SpriteKit
import GameplayKit
import SwiftUI
import AVFoundation

enum GameState {
    case playground
    case lobby
    case game
}

extension GameState {
    mutating func toPlayground() {
        self = .playground
    }
    
    mutating func toLobby() {
        self = .lobby
    }
    
    mutating func toGame() {
        self = .game
    }
    
    func isState(_ state: GameState) -> Bool {
        return self == state
    }
}

enum GameCharacters: String, CaseIterable {
    case hamster = "Hamster"
    case panda = "Panda"
    case bear = "Bear"
    case tiger = "Tiger"
    case koala = "Koala"
    case kissland = "Kissland"
}

enum Bar: String, CaseIterable {
    case purple = "Bar_Purple"
    case red = "Bar_Red"
    case brown = "Bar_Brown"
    case blue = "Bar_Blue"
}

protocol GameControllerDelegate: AnyObject {
    func receiveGameData(_ gameData: GameData)
    func gameStarted() // Called only from game creator
    func gameEnded()
}

class GameScene: SKScene, GameControllerDelegate, SKPhysicsContactDelegate {
    
    @Environment(\.callAlert) var callAlert
    
    var tapperConnection: TapperConnection?
    
    private var playerNode: SKSpriteNode = SKSpriteNode()
    private var friendsNodes: [String: SKSpriteNode] = [:] // [Name: PlayerNode]
    private var namesLabels: [SKSpriteNode: SKLabelNode] = [:] // [PlayerNode: Label]
    private var barsNodes: [SKSpriteNode: SKLabelNode] = [:] // [PlayerNode: ScoreLabel]
    private var collisionWith: [SKSpriteNode: Bool] = [:]
    private var isKeyPressed: [SKSpriteNode: Bool] = [:]
    private var pawsNodes: [SKSpriteNode: SKSpriteNode] = [:] // [PlayerNode: PawNode]
    private var pawAction: SKAction = SKAction()
    
    private var taggedNode: SKSpriteNode = SKSpriteNode()
    
    private var gameState: GameState = .playground
    private var myName: String = "Me"
    private var myCharacter: String = GameCharacters.allCases.randomElement()!.rawValue
    private var isServer: Bool = false
    
    private var categoryMaskNumber: UInt32 = 0
    
    var backgroundAudio: SKAudioNode = SKAudioNode()
    var jumpAudio: SKAudioNode = SKAudioNode()
    var swishAudio: SKAudioNode = SKAudioNode()
    var whipAudio: SKAudioNode = SKAudioNode()
    private var isWhipSound: Bool = false
    
    private let cameraNode: SKCameraNode = SKCameraNode()
    private var cameraFrame: CGRect = CGRect()

    var startCameraZoomValue: CGFloat = 1.3
    
    private var HUDNode: SKNode = SKNode()
    private var sceneBounds: [CGFloat] = [] // [TOP, RIGHT, BOTTOM, LEFT]
    private var backgroundNode: SKNode = SKNode()
    private var midgroundNode: SKNode = SKNode()
    private var foregroundNode: SKNode = SKNode()
    
    private let playerSpeed: CGFloat = 650
    private let jumpStrenght: CGFloat = 250
    private var deltaValue: CGFloat = 0.1
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        self.physicsWorld.contactDelegate = self
        
        var bound: SKNode
        var boundPosition: CGFloat
        
        bound = childNode(withName: "Top")!
        boundPosition = bound.position.y - bound.frame.height / 2
        sceneBounds.append(boundPosition)
        
        bound = childNode(withName: "Right")!
        boundPosition = bound.position.x - bound.frame.width / 2
        sceneBounds.append(boundPosition)
        
        bound = childNode(withName: "Bottom")!
        boundPosition = bound.position.y + bound.frame.height / 2 - 250
        sceneBounds.append(boundPosition)
        
        bound = childNode(withName: "Left")!
        boundPosition = bound.position.x + bound.frame.width / 2
        sceneBounds.append(boundPosition)
        
        backgroundNode = childNode(withName: "Far")!
        midgroundNode = childNode(withName: "Middle")!
        foregroundNode = childNode(withName: "Close")!
            
        playerNode = addPlayerToScene(myCharacter)
        isKeyPressed[playerNode] = false
        setPlayerPaw(playerNode: playerNode, playerCharacter: myCharacter)
        taggedNode = playerNode
        
        cameraNode.position = playerNode.position
        addChild(cameraNode)
        camera = cameraNode
        cameraFrame = CGRect(x: frame.minX, y: frame.minY, width: frame.width * startCameraZoomValue, height: frame.height * startCameraZoomValue)
        cameraNode.run(SKAction.scale(to: startCameraZoomValue, duration: 5))
        
        cameraNode.addChild(HUDNode)
        HUDNode.position = .zero
        
        backgroundAudio = SKAudioNode(fileNamed: "audio\(Int.random(in: 1..<3)).mp3")
        backgroundAudio.isPositional = false
        backgroundAudio.run(SKAction.changeVolume(to: 0, duration: 0))
        addChild(backgroundAudio)
        
        jumpAudio = SKAudioNode(fileNamed: "jump.wav")
        jumpAudio.isPositional = false
        jumpAudio.autoplayLooped = false
        jumpAudio.run(SKAction.changeVolume(to: 0.8, duration: 0))
        addChild(jumpAudio)
        
        swishAudio = SKAudioNode(fileNamed: "swish.wav")
        swishAudio.isPositional = false
        swishAudio.autoplayLooped = false
        swishAudio.run(SKAction.changeVolume(to: 0.3, duration: 0))
        addChild(swishAudio)
        
        whipAudio = SKAudioNode(fileNamed: "whip.wav")
        whipAudio.isPositional = false
        whipAudio.autoplayLooped = false
        whipAudio.run(SKAction.changeVolume(to: 0.3, duration: 0))
        addChild(whipAudio)
        
        playBackgroundMusic()
    }
    
    func setConnection(_ connection: TapperConnection) {
        tapperConnection = connection
        tapperConnection!.gameControllerDelegate = self
    }
    
    private func playBackgroundMusic() {
        backgroundAudio.run(SKAction.changeVolume(to: 0.2, duration: 5))
        backgroundAudio.run(SKAction.play())
    }
    
    private func stopBackgroundMusic() {
        backgroundAudio.run(SKAction.changeVolume(to: 0, duration: 5))
        backgroundAudio.run(SKAction.play())
    }
    
    override func update(_ currentTime: TimeInterval) {
        let playerPosition = playerNode.position
        
        if isCameraOutOfSceneX(playerPosition) == false {
            cameraNode.position.x = playerPosition.x
        }
        if isCameraOutOfSceneY(playerPosition) == false {
            cameraNode.position.y = playerPosition.y
        }
        
        backgroundNode.position = CGPoint(x: -(playerPosition.x / 60), y: 0)
        midgroundNode.position = CGPoint(x: -(playerPosition.x / 55), y: 0)
        foregroundNode.position = CGPoint(x: -(playerPosition.x / 50), y: 0)
        
        setPlayerPawPosition(playerNode: playerNode, pawNode: pawsNodes[playerNode]!)
        pawsNodes[playerNode]?.isHidden = isKeyPressed[playerNode]! ? false : true

        handleGameProcess()
    }
    
    private func handleGameProcess() {
        if gameState.isState(GameState.lobby) && friendsNodes.count > 0 {
            if isServer == false {
                stopBackgroundMusic()
            }
            gameState.toGame()
        }
        
        switch gameState {
        case .playground:
            gameState.toLobby()
            break
        case .lobby:
            break
        case .game:
            sendGameData()
            
            for friend in friendsNodes {
                let node: SKSpriteNode = friend.value
                setPlayerNamePos(playerNode: node)
                if let isPressed = isKeyPressed[node] {
                    if let paw = pawsNodes[node] {
                        paw.isHidden = !isPressed
                        setPlayerPawPosition(playerNode: node, pawNode: paw)
                    } else {
                        setPlayerPaw(playerNode: node, playerCharacter: GameCharacters.allCases.randomElement()!.rawValue)
                    }
                    if let isCollision = collisionWith[node] {
                        isWhipSound = isCollision
                        if isCollision && isPressed {
                            if taggedNode == playerNode {
                                taggedNode = node
                            } else if taggedNode == node {
                                taggedNode = playerNode
                            }
                        }
                    } else {
                        collisionWith.updateValue(false, forKey: node)
                    }
                } else {
                    isKeyPressed.updateValue(false, forKey: node)
                }
            }
        }
    }
    
    internal func didBegin(_ contact: SKPhysicsContact) {
        let firstNode = contact.bodyA.node as! SKSpriteNode
        let secondNode = contact.bodyB.node as! SKSpriteNode
        if (contact.bodyA.categoryBitMask < 10) && (contact.bodyB.categoryBitMask < 10) {
            if firstNode == playerNode {
                collisionWith.updateValue(true, forKey: secondNode)
            }
            if secondNode == playerNode {
                collisionWith.updateValue(true, forKey: firstNode)
            }
        }
    }
    
    internal func didEnd(_ contact: SKPhysicsContact) {
        let firstNode = contact.bodyA.node as! SKSpriteNode
        let secondNode = contact.bodyB.node as! SKSpriteNode
        if (contact.bodyA.categoryBitMask < 10) && (contact.bodyB.categoryBitMask < 10) {
            if firstNode == playerNode {
                collisionWith.updateValue(false, forKey: secondNode)
            }
            if secondNode == playerNode {
                collisionWith.updateValue(false, forKey: firstNode)
            }
        }
    }
    
    private func setNewPlayer(playerName: String, playerCharacter: String) -> SKSpriteNode {
        friendsNodes.updateValue(addPlayerToScene(), forKey: playerName)
        setPlayerBar(playerNode: friendsNodes[playerName]!, name: playerName, character: playerCharacter)
        setPlayerName(playerNode: friendsNodes[playerName]!, name: playerName)
        return friendsNodes[playerName]!
    }
    
    private func addPlayerToScene(_ character: String? = nil) -> SKSpriteNode {
        var c: String? = character
        if c == nil {
            c = GameCharacters.allCases.randomElement()!.rawValue
        }
        let newPlayerNode: SKSpriteNode = SKSpriteNode(imageNamed: c!)
        newPlayerNode.size = CGSize(width: newPlayerNode.frame.width / (newPlayerNode.frame.height / 110), height: 110)
        newPlayerNode.physicsBody = SKPhysicsBody(circleOfRadius: newPlayerNode.size.height / 2 + 5)
        newPlayerNode.physicsBody?.mass = 0.2
        newPlayerNode.physicsBody?.collisionBitMask = 1
        newPlayerNode.position = CGPoint(x: 0, y: 300)
        newPlayerNode.physicsBody?.usesPreciseCollisionDetection = true
        newPlayerNode.physicsBody?.categoryBitMask = categoryMaskNumber
        var bitMask: UInt32 = 0
        for i in 0...categoryMaskNumber {
            bitMask = bitMask | i
        }
//        newPlayerNode.physicsBody?.collisionBitMask = bitMask
        newPlayerNode.physicsBody?.contactTestBitMask = bitMask
        insertChild(newPlayerNode, at: 5)
        setPlayerPaw(playerNode: newPlayerNode, playerCharacter: c!)
        return newPlayerNode
    }
    
    private func setPlayerPaw(playerNode: SKSpriteNode, playerCharacter: String) {
        let pawNode: SKSpriteNode = SKSpriteNode(imageNamed: "Paw_" + playerCharacter)
        pawNode.size = CGSize(width: 40, height: 40)
        pawNode.isHidden = true
        pawsNodes.updateValue(pawNode, forKey: playerNode)
        addChild(pawNode)
    }
    
    private func setPlayerPawPosition(playerNode: SKSpriteNode, pawNode: SKSpriteNode) {
        let radius: CGFloat = playerNode.frame.width / 2
        let rotation: CGFloat = playerNode.zRotation
        pawNode.zRotation = rotation
        pawNode.position.x = playerNode.position.x + cos(rotation) * radius
        pawNode.position.y = playerNode.position.y + sin(rotation) * radius
    }
    
    private func setPlayerBar(playerNode: SKSpriteNode, name: String, character: String) {
        let barHeight: CGFloat = 100
        
        let barImage = SKSpriteNode(imageNamed: Bar.allCases.randomElement()!.rawValue)
        barImage.size = CGSize(width: barImage.frame.width / (barImage.frame.height / barHeight), height: barHeight)
        
        let playerImage = SKSpriteNode(imageNamed: character)
        barImage.addChild(playerImage)
        playerImage.anchorPoint = CGPoint(x: 0, y: 0.5)
        playerImage.size = CGSize(width: playerImage.frame.width / (playerImage.frame.height / (barHeight / 1.5)), height: barHeight / 1.5)
        playerImage.position = CGPoint(x: -barImage.frame.width / 2 + barHeight / 6, y: 0)
        
        let nameLabel = SKLabelNode()
        let nameText: String = name.count > 13 ? (String(name.substring(with: 0..<10)) + "...") : name
        nameLabel.text = "[" + nameText + "]"
        nameLabel.fontSize = barHeight / 4.33
        nameLabel.fontName = "Poppins"
        nameLabel.fontColor = SKColor.white
        barImage.addChild(nameLabel)
        nameLabel.position = CGPoint(x: playerImage.position.x + playerImage.frame.width + nameLabel.frame.width / 2 + 20, y: nameLabel.frame.height / 3)
        
        let scoreLabel = SKLabelNode()
        scoreLabel.text = "100"
        scoreLabel.fontSize = barHeight / 4.33
        scoreLabel.fontName = "Poppins"
        scoreLabel.fontColor = SKColor.lightGray
        barImage.addChild(scoreLabel)
        scoreLabel.position = CGPoint(x: playerImage.position.x + playerImage.frame.width + scoreLabel.frame.width / 2 + 20, y: -playerImage.frame.height / 3)
        
        HUDNode.addChild(barImage)
        barImage.position = CGPoint(x: -frame.width / 2 - barImage.frame.width + 20, y: frame.height / 2 - barHeight / 2 - 20)
        
        let appearAction: SKAction = SKAction.moveTo(x: -frame.width / 2 + barImage.frame.width / 2 + 20, duration: 0.7)
        appearAction.timingMode = .easeOut
        barImage.run(appearAction)
        
        barsNodes.updateValue(scoreLabel, forKey: playerNode)
    }
    
    private func setPlayerName(playerNode: SKSpriteNode, name: String) {
        let textNode: SKLabelNode = SKLabelNode()
        textNode.text = name
        textNode.fontName = "SignPainter"
        textNode.fontSize = 35
        textNode.fontColor = SKColor.white
        namesLabels.updateValue(textNode, forKey: playerNode)
        addChild(textNode)
    }
    
    private func setPlayerNamePos(playerNode: SKSpriteNode) {
        guard let nameLabel = namesLabels[playerNode] else {
            setPlayerNamePos(playerNode: playerNode)
            return
        }
        nameLabel.position.x = playerNode.position.x
        nameLabel.position.y = playerNode.position.y + 80
    }
    
    func sendGameData() {
        let gameData: GameData = GameData(name: myName, skin: myCharacter, velocity: playerNode.physicsBody!.velocity, playerX: playerNode.position.x, playerY: playerNode.position.y, keyPressed: isKeyPressed[playerNode]!, score: (0, 0))
        tapperConnection!.send(message: gameData.toString())
    }
    
    func isCameraOutOfSceneX(_ cameraPosition: CGPoint) -> Bool {
        return ((cameraPosition.x + cameraFrame.width / 2) > sceneBounds[1]) || ((cameraPosition.x - cameraFrame.width / 2) < sceneBounds[3])
    }
    
    func isCameraOutOfSceneY(_ cameraPosition: CGPoint) -> Bool {
        return ((cameraPosition.y + cameraFrame.height / 2) > sceneBounds[0]) || ((cameraPosition.y - cameraFrame.height / 2) < sceneBounds[2])
    }

    override func keyDown(with event: NSEvent) {
        let pressedKey = event.characters!
        var velocity: CGVector = CGVector(dx: 0, dy: 0)

        deltaValue += 0.2
        let currentSpeed = lerp(0, playerSpeed, deltaValue)
        
        if (pressedKey == "a") || (pressedKey == "A") || (pressedKey == "ф") || (pressedKey == "Ф") {
            velocity = CGVector(dx: -currentSpeed, dy: 0)
        } else if (pressedKey == "d") || (pressedKey == "D") || (pressedKey == "в") || (pressedKey == "В") {
            velocity = CGVector(dx: currentSpeed, dy: 0)
        } else if (pressedKey == "s") || (pressedKey == "S") || (pressedKey == "ы") || (pressedKey == "Ы") {
            velocity = CGVector(dx: 0, dy: -currentSpeed)
        } else if (pressedKey == "k") || (pressedKey == "K") || (pressedKey == "л") || (pressedKey == "Л") {
            isKeyPressed[playerNode] = true
            if isWhipSound {
                whipAudio.run(SKAction.play())
            } else {
                swishAudio.run(SKAction.play())
            }
        }
        
        playerNode.physicsBody?.applyForce(velocity)
    }

    override func keyUp(with event: NSEvent) {
        let releasedKey = event.characters!
        let velocity: CGVector = CGVector(dx: 0, dy: jumpStrenght)

        if releasedKey == " " {
            playerNode.physicsBody?.applyImpulse(velocity)
            jumpAudio.run(SKAction.play())
        } else if (releasedKey == "a") || (releasedKey == "A") || (releasedKey == "ф") || (releasedKey == "Ф") || (releasedKey == "d") || (releasedKey == "D") || (releasedKey == "в") || (releasedKey == "В") || (releasedKey == "s") || (releasedKey == "S") || (releasedKey == "ы") || (releasedKey == "Ы") {
            deltaValue = 0.1
        } else if (releasedKey == "k") || (releasedKey == "K") || (releasedKey == "л") || (releasedKey == "Л") {
            isKeyPressed[playerNode] = false
        }
    }

    func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat = 0.1) -> CGFloat {
        return a + t * (b - a)
    }
    
    // GAME CONTROLLER DELEGATE FUNCTIONS:
    
    func receiveGameData(_ gameData: GameData) {
        let playerName: String = gameData.name
        
        guard let friendNode = friendsNodes[playerName] else {
            let friendNode = setNewPlayer(playerName: playerName, playerCharacter: gameData.skin)
            friendNode.position = CGPoint(x: gameData.playerX, y: gameData.playerY)
            return
        }
        
        friendNode.position = CGPoint(x: gameData.playerX, y: gameData.playerY)
    }
    
    func gameEnded() {
        if isServer == false {
            playBackgroundMusic()
        }
        isServer = false
        return
    }
    
    func gameStarted() {
        print("startGame from GameScene")
        
        myName = tapperConnection!.myDeviceName
        setPlayerName(playerNode: playerNode, name: String(myName.dropFirst()))
        
        sendGameData()
        gameState.toLobby()
        
        isServer = true
        return
    }
}
    
