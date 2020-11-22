//
//  GameScene.swift
//  messing
//
//  Created by Ludwig Müller on 16.11.20.
//  Restructuring and physics update by Silvian Ene on 19.11.20.

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player: SKSpriteNode!
    
    // create a variable for the moving background
    var bground = SKSpriteNode()
    
    // create a local variable for our player
    
    var scoreLabel: SKLabelNode!

    var score = 0 {
        didSet {
            scoreLabel.text = "SCORE: \(score)"
        }
    }
    
    func createScore() {
        scoreLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        scoreLabel.fontSize = 36

        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 60)
        scoreLabel.text = "SCORE: 0"
        scoreLabel.fontColor = UIColor.black
        scoreLabel.zPosition = 2

        addChild(scoreLabel)
    }
    
    override func didMove(to view: SKView) {
        
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
       
        //physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        physicsWorld.contactDelegate = self
        
        createScore()
        createPlayer()
        startRocks()
        createBGround()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // I think runs the for loop for as many times as there are touches
        //player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        //player.physicsBody?.applyImpulse(CGVector(dx: 20000, dy: 0))
        
        for touch in touches {
            
            let location = touch.location(in: self)
            
            player!.position.x = location.x
            
        }
    }
    
    func createPlayer() {
        let playerTexture = SKTexture(imageNamed: "redBall")
        player = SKSpriteNode(texture: playerTexture)
        player.zPosition = 10
        player.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        player.setScale(0.3)
        player.position = CGPoint(x: 0, y: frame.height * 0.33)
        
        
        addChild(player)
        
        player.physicsBody = SKPhysicsBody(texture: playerTexture, size: player.size)
        player.physicsBody!.contactTestBitMask = player.physicsBody!.collisionBitMask
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = false;
        player.physicsBody?.collisionBitMask = 0
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // I think runs the for loop for as many times as there are touches
        for touch in touches {
            
            let location = touch.location(in: self)
            
            player!.position.x = location.x
            
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        moveBGround()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.node?.name == "scoreDetect" || contact.bodyB.node?.name == "scoreDetect" {
            if contact.bodyA.node == player {
                contact.bodyB.node?.removeFromParent()
            } else {
                contact.bodyA.node?.removeFromParent()
            }

            //let sound = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
            //run(sound)

            score += 1

            return
        }

        guard contact.bodyA.node != nil && contact.bodyB.node != nil else {
            return
        }
    }
    
    func createBGround(){
        // not sure why but we found that it wouldn't create a continuos background with other values for the for loop
        for i in 0...4 {
            // create sprite nodes for the background
            let bground = SKSpriteNode(imageNamed: "background")
            bground.name =  "BGround"
            // sets the size to the size of the scene
            bground.size = CGSize(width: (self.scene?.size.width)!, height: (self.scene?.size.height)!)
            // center the background
            bground.anchorPoint = CGPoint(x: 0, y: 0.5)
            bground.position = CGPoint(x: -bground.frame.width / 2, y: CGFloat(i) * bground.size.width)
            //bground.physicsBody = SKPhysicsBody(texture: bground.texture!, size: bground.texture!.size())
            //bground.physicsBody?.isDynamic = false
            self.addChild(bground)
        }
    }
    
    func createRocks() {
        // 1
        
        let rockTexture = SKTexture(imageNamed: "redBox")

        //let topRock = SKSpriteNode(texture: rockTexture)
        //topRock.zRotation = .pi
        //topRock.xScale = -1.0

        let rocc = SKSpriteNode(texture: rockTexture)
        rocc.physicsBody = SKPhysicsBody(texture: rockTexture, size: rockTexture.size())
        rocc.physicsBody?.isDynamic = false

        //topRock.zPosition = 1
        rocc.zPosition = 1
        //rocc.zRotation = .pi/2

        //2
        let rockCollision = SKSpriteNode(color: UIColor.red, size: CGSize(width: frame.width, height: 32))
        rockCollision.name = "scoreDetect"
        rockCollision.physicsBody = SKPhysicsBody(rectangleOf: rockCollision.size)
        rockCollision.physicsBody?.isDynamic = false
        
        rockCollision.zPosition = 1
        
        //rockCollision.anchorPoint = CGPoint(x: 0.5, y: 0)
        //rocc.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        //addChild(topRock)
        addChild(rocc)
        addChild(rockCollision)

        // 3
        //let yPosition = -frame.height/2

        //let max = CGFloat(frame.height / 3)
        let xPosition = CGFloat.random(in: -frame.width/2...frame.width/2)

        // 4
        //topRock.position = CGPoint(x: xPosition, y: yPosition + topRock.size.height + rockDistance)
        rocc.position = CGPoint(x: xPosition, y: -frame.height/2)//CGFloat(yPosition) - rockDistance)
        rockCollision.position = CGPoint(x: 0, y: -frame.height/2 - (rocc.size.height/2 + rockCollision.size.height/2))

        let endPosition = frame.width + (rocc.frame.width * 2)

        let moveAction = SKAction.moveBy(x: 0, y: endPosition, duration: 8)
        let moveSequence = SKAction.sequence([moveAction, SKAction.removeFromParent()])
        //topRock.run(moveSequence)
        rocc.run(moveSequence)
        rockCollision.run(moveSequence)
    }
    
    func startRocks() {
        let create = SKAction.run { [unowned self] in
            self.createRocks()
        }

        let wait = SKAction.wait(forDuration: 3)
        let sequence = SKAction.sequence([create, wait])
        let repeatForever = SKAction.repeatForever(sequence)

        run(repeatForever)
    }
    
    func moveBGround(){
        // no idea how this works but it makes the background move somehow
        self.enumerateChildNodes(withName: "BGround", using: ({
            (node, error) in
            
            // change the speed of the moving background
            node.position.y += 20
            
            // if image is at the bottom of the screen, move it to the top
            if node.position.y > ((self.scene?.size.height)!) {
                
                node.position.y -= (self.scene?.size.height)! * 3
            }
        }))
    }
}
