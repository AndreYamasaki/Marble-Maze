//
//  GameScene.swift
//  Project26
//
//  Created by user on 12/08/21.
//

import SpriteKit
import CoreMotion

enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case finish = 16
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //MARK: - Attributes
    
    var player: SKSpriteNode!
    var lastTouchPosition: CGPoint?
    var motionManager: CMMotionManager?
    
    var scoreLabel: SKLabelNode!

    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var isGameOver = false
    
    //MARK: - didMove
    
    override func didMove(to view: SKView) {
        
        let background = SKSpriteNode(imageNamed: "background.jpg")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
        
        loadLevel()
        createPlayer()
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        motionManager = CMMotionManager()
    //instructs Core Motion to start collecting accelerometer information we can read later
        motionManager?.startAccelerometerUpdates()
    }
    
    //MARK: - Methods
    
    func loadLevel() {
        
        //putting the path of the file into a constant
        guard let levelURL = Bundle.main.url(forResource: "level1", withExtension: "txt") else {
            fatalError("Could not find level1.txt in the app bundle.")
        }
        //putting the content of the file into a String
        guard let levelString = try? String(contentsOf: levelURL) else {
            fatalError("Could not load level1.txt from the app bundle.")
        }

        let lines = levelString.components(separatedBy: "\n")

        for (row, line) in lines.reversed().enumerated() {
            for (column, letter) in line.enumerated() {
                //Each square in the game world occupies a 64x64 space, so we can find its position by multiplying its row and column by 64. But: remember that SpriteKit calculates its positions from the center of objects, so we need to add 32 to the X and Y coordinates in order to make everything lines up on our screen.
                let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)

                if letter == "x" {
                    // load wall
                    let node = SKSpriteNode(imageNamed: "block")
                    node.position = position

                    node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
                    node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
                    node.physicsBody?.isDynamic = false
                    addChild(node)
                } else if letter == "v"  {
                    // load vortex
                    let node = SKSpriteNode(imageNamed: "vortex")
                    node.name = "vortex"
                    node.position = position
                    node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false
                    
                //a number defining the type of object this is for considering collisions.
                    node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
                //a number defining which collisions we want to be notified about.
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                //a number defining what categories of object this node should collide with,
                    node.physicsBody?.collisionBitMask = 0
                    addChild(node)
                } else if letter == "s"  {
                    // load star
                    let node = SKSpriteNode(imageNamed: "star")
                    node.name = "star"
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false

                    node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    node.position = position
                    addChild(node)
                } else if letter == "f"  {
                    // load finish
                    let node = SKSpriteNode(imageNamed: "finish")
                    node.name = "finish"
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false

                    node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    node.position = position
                    addChild(node)
                } else if letter == " " {
                    // this is an empty space – do nothing!
                } else {
                    fatalError("Unknown level letter: \(letter)")
                }
            }
        }
    }
    
    func createPlayer() {
        player = SKSpriteNode(imageNamed: "player")
        player.position = CGPoint(x: 96, y: 672)
        player.zPosition = 1
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5

        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
    //Returns the result of performing a bitwise OR operation on the two given values.
        player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.finish.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        addChild(player)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            lastTouchPosition = location
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            lastTouchPosition = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        lastTouchPosition = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        guard isGameOver == false else { return }
        
    //calculate the difference between the current touch and the player's position, then use that to change the gravity value of the physics world
        #if targetEnvironment(simulator) //this code only exists if using simulator
        if let currentTouch = lastTouchPosition {
                let diff = CGPoint(x: currentTouch.x - player.position.x, y: currentTouch.y - player.position.y)
                physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
            }
        #else //code using actual iPad
        if let accelerometerData = motionManager.accelerometerData {
        //pass accelerometeData to physicsWorld.gravity
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50)
        }
        #endif
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }

        if nodeA == player {
            playerCollided(with: nodeB)
        } else if nodeB == player {
            playerCollided(with: nodeA)
        }
    }
    
    func playerCollided(with node: SKNode) {
        
        if node.name == "vortex" {
            player.physicsBody?.isDynamic = false
            isGameOver = true
            score -= 1

            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(to: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([move, scale, remove])

            player.run(sequence) { [weak self] in
                self?.createPlayer()
                self?.isGameOver = false
            }
        } else if node.name == "star" {
            node.removeFromParent()
            score += 1
        } else if node.name == "finish" {
            // next level?
        }
    }
}
