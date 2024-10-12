import SpriteKit
import GameplayKit
import SwiftUI
import AVFoundation

enum GameState {
    case none
    case start
}

enum GameCharacters: String, CaseIterable {
    case hamster = "Hamster"
    case panda = "Panda"
    case bear = "Bear"
    case tiger = "Tiger"
    case koala = "Koala"
    case kissland = "Kissland"
}

protocol GameControllerDelegate: AnyObject { // Receive other player gamedata, send self gamedata
    func receiveGameData(_ gameData: GameData)
    func gameStarted() // Called only from game creator
    func gameEnded()
}

class GameScene: SKScene, GameControllerDelegate {
    
    @Environment(\.callAlert) var callAlert
    
    var tapperConnection: TapperConnection?
    
    private var playerNode: SKSpriteNode = SKSpriteNode()
    private var friendsNodes: [String: SKSpriteNode] = [:]
    private var nameLabels: [SKSpriteNode: SKLabelNode] = [:]
    private var keyPressed: Bool = false
    private var gameState: GameState = .none
    private var myName: String = "Me"
    private var myCharacter: String = GameCharacters.hamster.rawValue
    private var isServer: Bool = false
    
    var backgroundAudio: SKAudioNode = SKAudioNode()
    var jumpAudio: SKAudioNode = SKAudioNode()
    
    private let cameraNode: SKCameraNode = SKCameraNode()
    private var cameraFrame: CGRect = CGRect()

    var startCameraZoomValue: CGFloat = 1.3
    
    private var sceneBounds: [CGFloat] = [] // [TOP, RIGHT, BOTTOM, LEFT]
    private var backgroundNode: SKNode = SKNode()
    private var midgroundNode: SKNode = SKNode()
    private var foregroundNode: SKNode = SKNode()
    
    private let playerSpeed: CGFloat = 650
    private let jumpStrenght: CGFloat = 250
    private var deltaValue: CGFloat = 0.1
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
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
            
        playerNode = addPlayerToScene()
        
        cameraNode.position = playerNode.position
        addChild(cameraNode)
        camera = cameraNode
        cameraFrame = CGRect(x: frame.minX, y: frame.minY, width: frame.width * startCameraZoomValue, height: frame.height * startCameraZoomValue)
        cameraNode.run(SKAction.scale(to: startCameraZoomValue, duration: 5))
        
        backgroundAudio = SKAudioNode(fileNamed: "audio.mp3")
        backgroundAudio.isPositional = false
        backgroundAudio.run(SKAction.changeVolume(to: 0, duration: 0))
        addChild(backgroundAudio)
        
        jumpAudio = SKAudioNode(fileNamed: "jump.wav")
        jumpAudio.isPositional = false
        jumpAudio.autoplayLooped = false
        jumpAudio.run(SKAction.changeVolume(to: 0.8, duration: 0))
        addChild(jumpAudio)
        
        playBackgroundMusic()
    }
    
    func setConnection(_ connection: TapperConnection) {
        tapperConnection = connection
        tapperConnection!.gameControllerDelegate = self
    }
    
    private func playBackgroundMusic() {
        backgroundAudio.run(SKAction.changeVolume(to: 0.05, duration: 5))
        backgroundAudio.run(SKAction.play())
    }
    
    private func addPlayerToScene() -> SKSpriteNode {
        myCharacter = GameCharacters.allCases.randomElement()!.rawValue
        let newPlayerNode: SKSpriteNode = SKSpriteNode(imageNamed: myCharacter)
        newPlayerNode.size = CGSize(width: newPlayerNode.frame.width / (newPlayerNode.frame.height / 110), height: 110)
        newPlayerNode.physicsBody = SKPhysicsBody(circleOfRadius: newPlayerNode.size.height / 2 + 5)
        newPlayerNode.physicsBody?.mass = 0.2
        newPlayerNode.position = CGPoint(x: 0, y: 300)
        insertChild(newPlayerNode, at: 5)
        return newPlayerNode
    }
    
    override func update(_ currentTime: TimeInterval) {
        let playerPosition = playerNode.position
        
        if !isCameraOutOfSceneX(playerPosition) {
            cameraNode.position.x = playerPosition.x
        }
        if !isCameraOutOfSceneY(playerPosition) {
            cameraNode.position.y = playerPosition.y
        }
        
        backgroundNode.position = CGPoint(x: -(playerPosition.x / 60), y: 0)
        midgroundNode.position = CGPoint(x: -(playerPosition.x / 55), y: 0)
        foregroundNode.position = CGPoint(x: -(playerPosition.x / 50), y: 0)

        handleGameProcess()
    }
    
    private func handleGameProcess() {
        
    }
    
    private func setPlayerName(playerNode: SKSpriteNode, name: String) {
        let textNode: SKLabelNode = SKLabelNode()
        textNode.text = name
        textNode.fontName = "SignPainter"
        textNode.fontSize = 35
        textNode.fontColor = SKColor.white
        nameLabels.updateValue(textNode, forKey: playerNode)
        addChild(textNode)
    }
    
    private func setPlayerNamePos(playerNode: SKSpriteNode) {
        guard let nameLabel = nameLabels[playerNode] else {
            setPlayerNamePos(playerNode: playerNode)
            return
        }
        nameLabel.position.x = playerNode.position.x
        nameLabel.position.y = playerNode.position.y + 80
    }
    
    func sendGameData() {
        let gameData: GameData = GameData(name: myName, skin: myCharacter, velocity: playerNode.physicsBody!.velocity, playerX: playerNode.position.x, playerY: playerNode.position.y, keyPressed: keyPressed, score: (0, 0))
        tapperConnection!.send(message: gameData.toString())
    }
    
    func isCameraOutOfSceneX(_ cameraPosition: CGPoint) -> Bool {
        return ((cameraPosition.x + cameraFrame.width / 2) > sceneBounds[1]) || ((cameraPosition.x - cameraFrame.width / 2) < sceneBounds[3])
    }
    
    func isCameraOutOfSceneY(_ cameraPosition: CGPoint) -> Bool {
        return ((cameraPosition.y + cameraFrame.height / 2) > sceneBounds[0]) || ((cameraPosition.y - cameraFrame.height / 2) < sceneBounds[2])
    }
    
//    func setPlayersPositions() {
//        let sceneWidth: CGFloat = self.frame.width
//        let sceneBeginning: CGFloat = self.frame.minX
//        
//        var players: [SKSpriteNode] = []
//        players.append(playerNode)
//        players.append(guestNode!)
//        
//        let playersCount = players.count
//
//        for i in 0...playersCount {
//            players[i].position = CGPoint(x: sceneBeginning + sceneWidth / CGFloat(playersCount), y: 200)
//        }
//    }

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
            keyPressed = true
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
            keyPressed = false
        }
    }

    func getOutOfScenePosX(_ node: SKNode) -> CGFloat {
        let pos: CGFloat = size.width / 2 + node.frame.width / 2
        return pos
    }

    func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat = 0.1) -> CGFloat {
        return a + t * (b - a)
    }
    
    func receiveGameData(_ gameData: GameData) {
        let playerName: String = gameData.name
        
        if let friendNode = friendsNodes[playerName] {
            friendNode.position = CGPoint(x: gameData.playerX, y: gameData.playerY)
        } else {
            friendsNodes.updateValue(addPlayerToScene(), forKey: playerName)
            setPlayerName(playerNode: friendsNodes[playerName]!, name: playerName)
        }
        
        gameState = .start
    }
    
    func gameEnded() {
        return
    }
    
    func gameStarted() {
        print("startGame from GameScene")
        
        myName = tapperConnection!.myDeviceName
        setPlayerName(playerNode: playerNode, name: String(myName.dropFirst()))
        
        sendGameData()
        gameState = .start
        
        isServer = true
        return
    }
}
    
