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
        // create a score label
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
        startObstacles(obstacleFrequency: 3)
        createBGround()
        
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // I think runs the for loop for as many times as there are touches
        //player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        //player.physicsBody?.applyImpulse(CGVector(dx: 20000, dy: 0))
        
        for touch in touches {
            
            let location = touch.location(in: self)
            
            let velocityFactor: CGFloat = 5
            
            let playerVelocity = location.x - player.position.x
            
            if (playerVelocity) > 30 {
                print(location.x - player!.position.x)
                player.physicsBody?.velocity = CGVector(dx: velocityFactor * playerVelocity, dy: 0.0)
            }
            
            else if (playerVelocity) < -30 {
                print(location.x - player!.position.x)
                player.physicsBody?.velocity = CGVector(dx: velocityFactor * playerVelocity, dy: 0.0)
            }
            
            else {
                player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            }
            
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
            
            let velocityFactor: CGFloat = 5
            
            let playerVelocity = location.x - player.position.x
            
            if (playerVelocity) > 30 {
                print(location.x - player!.position.x)
                player.physicsBody?.velocity = CGVector(dx: velocityFactor * playerVelocity, dy: 0.0)
            }
            
            else if (playerVelocity) < -30 {
                print(location.x - player!.position.x)
                player.physicsBody?.velocity = CGVector(dx: velocityFactor * playerVelocity, dy: 0.0)
            }
            
            else {
                player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            }
            
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        moveBGround()
        
    }
    
    // this function detects contact
    func didBegin(_ contact: SKPhysicsContact) {
        // this figures out in which order the function returns the colliding bodies
        // that matters because we have to remove the right body
        if contact.bodyA.node?.name == "scoreDetect" || contact.bodyB.node?.name == "scoreDetect" {
            // this removes the bar that we use to count the score so we don't have unnecessary nodes in our program
            if contact.bodyA.node == player {
                contact.bodyB.node?.removeFromParent()
            } else {
                contact.bodyA.node?.removeFromParent()
            }

            //let sound = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
            //run(sound)
            
            // increment our score
            score += 1

            return
        }

        // it's possible that two contacts are detected, player and box or vice versa
        // the first time we detect a contact we remove the bar which would result in an error because the body that collided doesn't exist anymore
        // therefore we cancel the function if one of the bodies doesn't exist
        guard contact.bodyA.node != nil && contact.bodyB.node != nil else {
            return
        }
        
        if contact.bodyA.node == player || contact.bodyB.node == player {
            player.removeFromParent()
            speed = 0
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
    
    func createObstacles(movingDuration: Int8) {
        // save the texture of our image into a constant
        let obstacleTexture = SKTexture(imageNamed: "redBox")
        
        // create a sprite with physics body for our obastacle
        let obstacle = SKSpriteNode(texture: obstacleTexture)
        obstacle.physicsBody = SKPhysicsBody(texture: obstacleTexture, size: obstacleTexture.size())
        // it's not dynamic because we don't want it to trigger a physics simulation when it colllides with something
        obstacle.physicsBody?.isDynamic = false
        
        // set a Z position so it is in fron the background
        obstacle.zPosition = 1
        
        // we could rotate the obstacle with this line of code
        // obstacle.zRotation = .pi/2

        // create a bar that moves with the object so we can keep count of the score when our player has contact with it
        let ScoreCountBar = SKSpriteNode(color: UIColor.red, size: CGSize(width: frame.width, height: 32))
        ScoreCountBar.name = "scoreDetect"
        ScoreCountBar.physicsBody = SKPhysicsBody(rectangleOf: ScoreCountBar.size)
        ScoreCountBar.physicsBody?.isDynamic = false
        
        ScoreCountBar.zPosition = 1
        
        //addChild(topRock)
        addChild(obstacle)
        addChild(ScoreCountBar)

        // create a random x position for our obstacles
        let xPosition = CGFloat.random(in: -frame.width/2...frame.width/2)
        
        // place the obstacles and the score counting bar
        obstacle.position = CGPoint(x: xPosition, y: -frame.height/2)
        ScoreCountBar.position = CGPoint(x: 0, y: -frame.height/2 - (obstacle.size.height/2 + ScoreCountBar.size.height/2))

        let endPosition = frame.height + obstacle.frame.height

        // move the obstacle and the score bar upwards
        let moveAction = SKAction.moveBy(x: 0, y: endPosition, duration: TimeInterval(movingDuration))
        let moveSequence = SKAction.sequence([moveAction, SKAction.removeFromParent()])
        obstacle.run(moveSequence)
        ScoreCountBar.run(moveSequence)
    }
    
    // start creating an obstacle every obstacleFrequency seconds
    func startObstacles(obstacleFrequency: Float16) {
        let create = SKAction.run { [unowned self] in
            self.createObstacles(movingDuration: 6)
        }

        let wait = SKAction.wait(forDuration: TimeInterval(obstacleFrequency))
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
