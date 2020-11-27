//
//  GameScene.swift
//  messing
//
//  Created by Ludwig Müller on 16.11.20.
//  Restructuring and physics update by Silvian Ene on 19.11.20.

import SpriteKit

// create different game states for the menu
enum GameState {
    case firstScreen
    case playing
    case dead
    case fadeInSettings
    case fadeOutSettings
}

// create three more variables for what is actually shown during the different game states
var logo: SKSpriteNode!
var gameOver: SKSpriteNode!
var settingsButton: SKSpriteNode!
var playButton: SKSpriteNode!
var disableVolumeButton: SKSpriteNode!
var controlModeButton: SKSpriteNode!

// this gives the game state a default value
var gameState = GameState.firstScreen

var last_state = CGPoint(x: 0, y: 0)

//these variables helped me debug the issues
//and do some switching between states
var isDead = false
var isPlaying = false

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
        
        //It's 4AM, I don't remember why I put this here but it won't work without it
        loadButtons()
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // runs each time there's a new touch detected
        // get the location of the touch
        for touch in touches {
            let location = touch.location(in: self)
            
            checkGameState(location: location)
            
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
        
        if gameState == .firstScreen {
            isDead = false
        }
        
        moveBGround()
    }
    
    func createPlayer() {
        let playerTexture = SKTexture(imageNamed: "redBall")
        player = SKSpriteNode(texture: playerTexture)
        player.zPosition = 3
        player.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        player.setScale(0.3)
        player.position = CGPoint(x: 0, y: frame.height * 0.33)
        
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
            isDead = true
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
    func loadButtons() {
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
        
        // this is our settings button
        settingsButton = SKSpriteNode(imageNamed: "settingsButton")
        // make it semitransparent
        settingsButton.alpha = 0.8
        settingsButton.zPosition = 3
        settingsButton.setScale(0.3)
        // create a point in the right upper corner to put our settings button there
        let settingsPosition = CGPoint(x: frame.maxX - settingsButton.size.width / 4, y: frame.maxY - settingsButton.size.width / 4)
        //        (x: frame.size.width - (settingsButton.size.width, y: frame.size.height - settingsButton.size.height)
        settingsButton.position = settingsPosition
        addChild(settingsButton)
        
        //load the buttons for the settings menu
        showSettings()
        
    }
    
    //this function calls on the settings functions
    func showSettings() {
        // these are the buttons for our settings
        // this creates our play button and adds it invisibly
        playButton = SKSpriteNode(imageNamed: "resumeButton")
        playButton.position = CGPoint(x: frame.midX, y: frame.midY)
        //playButton.alpha = 0
        playButton.zPosition = 4
        
        // this creates our disable volume button button and adds it invisibly
        disableVolumeButton = SKSpriteNode(imageNamed: "disableVolumeButton")
        disableVolumeButton.position = CGPoint(x: frame.midX, y: frame.midY + disableVolumeButton.size.height * 3)
        //disableVolumeButton.alpha = 0
        disableVolumeButton.zPosition = 4
        
        // this creates our play button and adds it invisibly
        controlModeButton = SKSpriteNode(imageNamed: "controlModeButton")
        controlModeButton.position = CGPoint(x: frame.midX, y: frame.midY - controlModeButton.size.height * 3)
        //disableVolumeButton.alpha = 0
        controlModeButton.zPosition = 4
    }
    
    
    //this function acts as the main switcher between states
    func checkGameState(location: CGPoint){
        
        // see if our settings button has been touched before we check anything else
        if settingsButton.contains(location) && gameState != .fadeOutSettings {
            gameState = .fadeInSettings
        }
        
        switch gameState {
            
            case .dead:
                if let scene = GameScene(fileNamed: "GameScene") {
                    scene.scaleMode = .aspectFill
                    let transition = SKTransition.moveIn(with: SKTransitionDirection.up, duration: 0.5)
                    view?.presentScene(scene, transition: transition)
                    isPlaying = false
                    gameState = .firstScreen
                }
        
            case .firstScreen:
                gameState = .playing
                isDead = false
                let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                let remove = SKAction.removeFromParent()
                let wait = SKAction.wait(forDuration: 0.5)
                let activatePlayer = SKAction.run { [unowned self] in
                    // self.player.physicsBody?.isDynamic = true
                    startObstacles(obstacleFrequency: 3)
                }

                let sequence = SKAction.sequence([fadeOut, wait, activatePlayer, remove])
                logo.run(sequence)
                
                isPlaying = true
                addChild(player)

            case .playing:
                if isDead == true {
                    gameState = .dead
                    break
                }
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


            case .fadeInSettings:
                // show our menu buttons
                addChild(playButton)
                addChild(disableVolumeButton)
                addChild(controlModeButton)
                logo.removeFromParent()
                gameState = .fadeOutSettings
                
                // add code to stop the game
                speed = 0
            
            case .fadeOutSettings:
                    // if statement for the buttons
                    if playButton.contains(location) {
                        // hide our buttons
                        playButton.removeFromParent()
                        disableVolumeButton.removeFromParent()
                        controlModeButton.removeFromParent()
                        if isDead == false {
                            speed = 1
                        }
                        // change game state to playing
                        
                        if isPlaying == false {
                            gameState = .firstScreen
                            addChild(logo)
                        }
                        else if isPlaying == true {
                            gameState = .playing
                            if isDead == true {
                                gameState = .dead
                            }
                        }
                    }
        }
        
    }
}
