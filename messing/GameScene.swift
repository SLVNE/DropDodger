//
//  GameScene.swift
//  messing
//
//  Created by Ludwig Müller on 16.11.20.
//  Restructuring and physics update by Silvian Ene on 19.11.20.

import SpriteKit

// create different game states for the menu
enum GameState {
    case showingLogo
    case playing
    case dead
}

// create three more variables for what is actually shown during the different game states
var logo: SKSpriteNode!
var gameOver: SKSpriteNode!
// this gives the game state a default value
var gameState = GameState.showingLogo

var last_state = CGPoint(x: 0, y: 0)

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
        // startObstacles(obstacleFrequency: 3)
        createBGround()
        
        createLogos()
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // I think runs the for loop for as many times as there are touches
        //player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        //player.physicsBody?.applyImpulse(CGVector(dx: 20000, dy: 0))
        
        switch gameState {
            case .showingLogo:
                gameState = .playing

                let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                let remove = SKAction.removeFromParent()
                let wait = SKAction.wait(forDuration: 0.5)
                let activatePlayer = SKAction.run { [unowned self] in
                    // self.player.physicsBody?.isDynamic = true
                    startObstacles(obstacleFrequency: 3)
                }

                let sequence = SKAction.sequence([fadeOut, wait, activatePlayer, remove])
                logo.run(sequence)

            case .playing:
                for touch in touches {
                    
                    let location = touch.location(in: self)
                    
                    let velocityFactor: CGFloat = 5
                    
                    // adjust the player velocity according to how far the player is away from the touch location
                    let playerVelocity = location.x - player.position.x
                    
                    // if the player is outside our designated deadzone move him towards the location of the touch
                    if ((playerVelocity) > 30 || (playerVelocity) < -30 ){
                        player.physicsBody?.velocity = CGVector(dx: velocityFactor * playerVelocity, dy: 0.0)
                    }
                    
                    // don't move the player when he is in the deadzone
                    else {
                        player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                    }
                    
                    // save the last location so we can call it in the update function in order to stop the player movement as he approaches the deazone when the touch is not moving
                    last_state.x = location.x
                }

            case .dead:
                if let scene = GameScene(fileNamed: "GameScene") {
                    scene.scaleMode = .aspectFill
                    let transition = SKTransition.moveIn(with: SKTransitionDirection.right, duration: 1)
                    view?.presentScene(scene, transition: transition)
                    gameState = .showingLogo
                }
            }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // I think runs the for loop for as many times as there are touches
        for touch in touches {
            
            let location = touch.location(in: self)
            
            let velocityFactor: CGFloat = 5
            
            // adjust the player velocity according to how far the player is away from the touch location
            let playerVelocity = location.x - player.position.x
            
            // if the player is outside our designated deadzone move him towards the location of the touch
            if ((playerVelocity) > 30 || (playerVelocity) < -30 ){
                player.physicsBody?.velocity = CGVector(dx: velocityFactor * playerVelocity, dy: 0.0)
            }
            
            // don't move the player when he is in the deadzone
            else {
                player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            }
            
            // save the last location so we can call it in the update function in order to stop the player movement as he approaches the deazone when the touch is not moving
            last_state.x = location.x
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // stop player movement if finger is lifted
        player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        // stop the player movement if the player is inside the deadzone
        // necessary here because otherwise drift occurs when the touch is not moving
        if abs(last_state.x - player.position.x) < 30 {
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        }
        
        moveBGround()
        
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
            // this shows the gameover sprite when the player dies
            gameOver.alpha = 1
            gameState = .dead
            // backgroundMusic.run(SKAction.stop())
            
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
    
    // this function creates the buttons for the menus as sprites
    func createLogos() {
        // this is the logo that is show at the beginning of each game
        // we should add a real menu with options here later
        logo = SKSpriteNode(imageNamed: "logo")
        logo.position = CGPoint(x: frame.midX, y: frame.midY)
        logo.zPosition = 3
        addChild(logo)
        
        // this is the gameover immage
        // we should add game stats here
        // maybe also a record board
        gameOver = SKSpriteNode(imageNamed: "gameover")
        gameOver.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOver.alpha = 0
        gameOver.zPosition = 3
        addChild(gameOver)
    }
}
