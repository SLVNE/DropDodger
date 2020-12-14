//
//  GameScene.swift
//  messing
//

import SpriteKit
// import this for the tilt control, gives us access to the accelerometer
import CoreMotion
// this is for the tilt control
var motionManager: CMMotionManager!

// create different game states for the menu
enum GameState {
    case firstScreen
    case playing
    case dead
    case fadeInSettings
    case fadeOutSettings
}

// create many more variables for what is actually shown during the different game states
var logo: SKSpriteNode!
var gameOver: SKSpriteNode!
var settingsButton: SKSpriteNode!
var playButton: SKSpriteNode!
var disableVolumeButton: SKSpriteNode!
var controlModeButton: SKSpriteNode!
var tiltModeButton: SKSpriteNode!
var touchModeButton: SKSpriteNode!
var toggleBackground: SKShapeNode!
var tapToPlay: SKSpriteNode!
var backgroundMusic: SKAudioNode!

// this gives the game state a default value
var gameState = GameState.firstScreen

// this variable is used for the deadzone
// the position of the last touch is stored in here to access it in the update function
var lastState = CGPoint(x: 0, y: 0)

// used to fix bugs with the change of game states when pausing the game
var isDead = false
var isPlaying = false

// variable to know which control mode is currently used
var touchControl = true

// initialize our texture atlas
let objectAtlas = SKTextureAtlas(named: "objects")
let playerAtlas = SKTextureAtlas(named: "player")

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player: SKSpriteNode!
    
    // create a variable for the moving background
    var bground = SKSpriteNode()
    
    // create a local variable for our player
    var scoreLabel: SKLabelNode!
    
    // initial setup of the score
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
        
        //check for existing scores and set some defaults if none are present
        initializeScore()
        
        // check which control mode is used and save it into the variable touchControl
        let defaults = UserDefaults.standard
        touchControl = defaults.bool(forKey: "touchEnabled") //as? [Bool] ?? [Bool]()
        // intialize accelerometer if necessary
        if !touchControl {
            motionManager = CMMotionManager()
            motionManager.startAccelerometerUpdates()
        }
        
        if let musicURL = Bundle.main.url(forResource: "playMusic", withExtension: "mp3") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
        
        
        // create all of our sprites
        createScore()
        createPlayer()
        createBGround()
        // createbuttons also prints logo and tap to play icon
        createButtons()
        
        // print our leaderboard on the first screen
        printLeaderboard()
        
        
        // make the logo and the tap to play icon fade in alternating
        let fadeInLogo = SKAction.fadeIn(withDuration: 3)
        let fadeOutLogo = SKAction.fadeOut(withDuration: 1.5)
        let waitLongLogo = SKAction.wait(forDuration: 8)
        let waitLongTap = SKAction.wait(forDuration: 10)
        let waitShortLogo = SKAction.wait(forDuration: 3.5)
        let sequenceLogo = SKAction.repeatForever(SKAction.sequence([fadeInLogo, waitShortLogo, fadeOutLogo, waitLongTap]))
        // make the tap to play icon blink
        // not very elegant but simple
        let fadeInTap = SKAction.fadeIn(withDuration: 0.5)
        let fadeOutTap = SKAction.fadeOut(withDuration: 0.5)
        let sequenceTap = SKAction.repeatForever(SKAction.sequence([waitLongLogo, fadeInTap, fadeOutTap, fadeInTap, fadeOutTap, fadeInTap, fadeOutTap, fadeInTap, fadeOutTap, fadeInTap, fadeOutTap, fadeInTap, fadeOutTap, fadeInTap, fadeOutTap, fadeInTap, fadeOutTap, fadeInTap, fadeOutTap, fadeInTap, fadeOutTap]))
        
        logo.run(sequenceLogo)
        headerLabel.run(sequenceLogo)
        enumerateChildNodes(withName: "scoreLineLabel") { (node, _) in
             node.run(sequenceLogo)
        }
        tapToPlay.run(sequenceTap)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // runs each time there's a new touch detected
        // get the location of the touch
        for touch in touches {
            let location = touch.location(in: self)
            // check the game state, react according to that (buttons or other interactions, like move the player, etc.)
            checkGameState(location: location)
            
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // I think runs the for loop for as many times as there are touches
        // move our player with touch if that's the current control mode
        if touchControl {
            for touch in touches {
                
                let location = touch.location(in: self)
                
                // this is a factor that decides how fast the player sprite follows the user's touch
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
                lastState.x = location.x
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // only stop it if we're using touch controls
        if touchControl {
            // stop player movement if finger is lifted
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        // stop the player movement if the player is inside the deadzone
        // necessary here because otherwise drift occurs when the touch is not moving
        if abs(lastState.x - player.position.x) < 30 {
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        }
        
        // resets isDead when it reaches the initial screen
        if gameState == .firstScreen {
            isDead = false
        }
        
        moveBGround()
        
        // use tilt control if enabled
        if !touchControl {
            if let accelerometerData = motionManager.accelerometerData {
                let velocityFactor: Double = 5000
                let acceleration = accelerometerData.acceleration.x * velocityFactor
                // only move the player if the acceleration is above a certain treshold, meaning the following line introduces a deadzone so the player doesn't move around when there's accelerometer drift
                if abs(acceleration) > 100 {
                    player.physicsBody?.velocity = CGVector(dx: Int(acceleration), dy: 0)
                }
                // we need to update the lastState so the deadzone at the begginning of the update function gets true and stops the player
                // otherwise the deadzone we just introduced would leave the player at his last velocity
                lastState.x = player.position.x
                // debugging
                //print(Int(acceleration))
            }
        }
        
        // check if the player is moving to the left or right and adjust the image accordingly
        let playerVelocity = player.physicsBody?.velocity.dx
        if playerVelocity ?? 0 >= CGFloat(30) {
            player.run(SKAction.setTexture(playerAtlas.textureNamed("skydiverR")))
        }
        else if playerVelocity ?? 60 <= CGFloat(-30) {
            player.run(SKAction.setTexture(playerAtlas.textureNamed("skydiverL")))
        }
    }
    
    func createPlayer() {
        let playerTexture = playerAtlas.textureNamed("skydiverL")
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
        
        // keep the player from leaving the screen
        let xRange = SKRange(lowerLimit: frame.minX, upperLimit: frame.maxX)
        let yRange = SKRange(lowerLimit: frame.minY, upperLimit: frame.maxY)
        player.constraints = [SKConstraint.positionX(xRange,y:yRange)]
    }
    
    // this function detects contact
    func didBegin(_ contact: SKPhysicsContact) {
        
        // this line fixes the last accidental double writing of the score
        if gameState == .dead {
            return
        }
        
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
        
        // check for contact with an obstacle
        if contact.bodyA.node == player || contact.bodyB.node == player {
            
            backgroundMusic.removeFromParent()
            // play a sound when the collision happens
            let sound = SKAction.playSoundFileNamed("slap.m4a", waitForCompletion: false)
            run(sound)
            // this shows the gameover sprite when the player dies
            gameOver.alpha = 1
            gameState = .dead
            isDead = true
            // backgroundMusic.run(SKAction.stop())
            
            player.removeFromParent()
            
            // couldn't play music when self.isPaused = true so we reverted to speed = 0 to stop the game
            // if tilt active the player can still be moved but the player is removed so it should work
            //self.isPaused = true
            speed = 0
            
            //add the score to storage
            addScore()
            
            // print our leaderboard
            printLeaderboard()
            
            
            // change the music for when the player dies
            
        }
        // try to fix that two collisions are detected and the score gets created twice
        // NEEDS TO BE FIXED - update, it has been fixed
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
    
    func createObstacles(movingDuration: Double, obstacleType: String) {
        // save the texture of our image into a constant
        let obstacleTexture = objectAtlas.textureNamed(obstacleType)
        
        // create a sprite with physics body for our obastacle
        let obstacle = SKSpriteNode(texture: obstacleTexture)
        obstacle.physicsBody = SKPhysicsBody(texture: obstacleTexture, size: obstacleTexture.size())
        // it's not dynamic because we don't want it to trigger a physics simulation when it colllides with something
        obstacle.physicsBody?.isDynamic = false
        
        // set a Z position so it is in fron the background
        obstacle.zPosition = 1
        
        //obstacle.setScale(0.3)
        
        // we could rotate the obstacle with this line of code
        // obstacle.zRotation = .pi/2

        // create a bar that moves with the object so we can keep count of the score when our player has contact with it
        let ScoreCountBar = SKSpriteNode(color: UIColor.red, size: CGSize(width: frame.width, height: 32))
        ScoreCountBar.name = "scoreDetect"
        ScoreCountBar.physicsBody = SKPhysicsBody(rectangleOf: ScoreCountBar.size)
        ScoreCountBar.physicsBody?.isDynamic = false
        
        ScoreCountBar.zPosition = 0
        ScoreCountBar.alpha = 0
        
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
    // I tested with breakpoints and this gets run everytime when a new obstacle comes up
    // that's why we can adjust the speed of our obstacles here as the score increases
    func startObstacles(initialObstacleFrequency: Double) {
        let create = SKAction.run { [unowned self] in
            // constants for calculating the speed
            let initialSpeed = 6.00
            let obstacleSpeedFactor = 0.1
            // calculates the speed
            // speed is actually the time the object takes from its creation to the top of the screen
            // this means the lower the speed, the faster the object moves
            let obstacleSpeed = initialSpeed / (Double(score) * obstacleSpeedFactor + 1)
            // debugging
            //print("speed is: ", obstacleSpeed)
            // this list contains the names of all of the pictures of our obstacles
            let obstacles = ["birdSwarm", "brightCloud", "eagle", "jet", "lightningCloud", "ufo"]
            // this picks a random obstacle
            let randomObstacle = obstacles.randomElement()!
            // this actually creates the obstacle
            self.createObstacles(movingDuration: obstacleSpeed, obstacleType: randomObstacle)
        }
        
        /*var obstacleFrequency = [3.00]
        // this part does not work... this code gets stuck in an infinite loop and I don't understand why
        let changeFrequency = SKAction.run { [unowned self] in
            let obstacleFrequencyFactor = 0.5
            obstacleFrequency [0] = initialObstacleFrequency / (Double(score) * obstacleFrequencyFactor + 1)
            print("frequency inside the run is: ", obstacleFrequency [0])
            let wait = SKAction.wait(forDuration: TimeInterval(obstacleFrequency [0]))
            run(wait)
        }*/
        let wait = SKAction.wait(forDuration: 3)
        // unfortunately this part of the code only gets executed once, at this point the frequency changes and gets faster but I'm unable to update the wait
        // I tried putting the wait inside the function but then we get stuck in an infinite loop and I can't seem to fix it
        //let wait = SKAction.wait(forDuration: TimeInterval(obstacleFrequency [0]))
        //print("frequency outside the run is: ", obstacleFrequency [0])
        let sequence = SKAction.sequence([create, /*changeFrequency,*/ wait])
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
    func createButtons() {
        // this is the logo that is show at the beginning of each game
        // we should add a real menu with options here later
        logo = SKSpriteNode(imageNamed: "logo")
        logo.position = CGPoint(x: frame.midX, y: frame.maxY/4)
        logo.zPosition = 3
        addChild(logo)
        
        // add a tap to play icon that get animated in the first screen
        tapToPlay = SKSpriteNode(imageNamed: "tapToPlay")
        tapToPlay.position = CGPoint(x: frame.midX, y: frame.midY)
        tapToPlay.zPosition = 3
        // make it invisible at first
        tapToPlay.setScale(0.5)
        tapToPlay.alpha = 0
        addChild(tapToPlay)
        
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
        playButton.alpha = 0.9
        playButton.zPosition = 4
        
        // this creates our disable volume button button and adds it invisibly
        disableVolumeButton = SKSpriteNode(imageNamed: "disableVolumeButton")
        disableVolumeButton.position = CGPoint(x: frame.midX, y: frame.midY + disableVolumeButton.size.height * 3)
        disableVolumeButton.alpha = 0.9
        disableVolumeButton.zPosition = 4
        
        // this creates our play button and adds it invisibly
        controlModeButton = SKSpriteNode(imageNamed: "controlModeButton")
        controlModeButton.position = CGPoint(x: frame.midX, y: frame.midY - controlModeButton.size.height * 3)
        controlModeButton.alpha = 0.9
        controlModeButton.zPosition = 4
        
        tiltModeButton = SKSpriteNode(imageNamed: "tilt")
        tiltModeButton.setScale(0.558)
        tiltModeButton.position = CGPoint(x: frame.midX - tiltModeButton.size.width/1.5, y: frame.midY - tiltModeButton.size.height * 1.45)
        tiltModeButton.alpha = 0.9
        tiltModeButton.zPosition = 4
        
        touchModeButton = SKSpriteNode(imageNamed: "touch")
        touchModeButton.setScale(0.5)
        touchModeButton.position = CGPoint(x: frame.midX + touchModeButton.size.width/1.5, y: frame.midY - tiltModeButton.size.height * 1.5)
        touchModeButton.alpha = 0.9
        touchModeButton.zPosition = 4
        
        toggleBackground = SKShapeNode(rectOf: CGSize(width: touchModeButton.size.width, height: tiltModeButton.size.height), cornerRadius: 20)
        toggleBackground.fillColor = UIColor.white
        toggleBackground.alpha = 0.9
        
        if touchControl {
        toggleBackground.position = CGPoint(x: frame.midX + touchModeButton.size.width/1.5, y: frame.midY - tiltModeButton.size.height * 1.5)
        }
        
        if !touchControl {
        toggleBackground.position = CGPoint(x: frame.midX - tiltModeButton.size.width/1.5, y: frame.midY - tiltModeButton.size.height * 1.5)
        }
        toggleBackground.zPosition = 3
        
    }
    
    
    //this function acts as the main switcher between game states
    func checkGameState(location: CGPoint){
        
        // see if our settings button has been touched before we check anything else
        if settingsButton.contains(location) && gameState != .fadeOutSettings {
            
            gameState = .fadeInSettings
            //speed = 0
            self.isPaused = true
        }
        
        // we call this function in touchesBegin
        switch gameState {
        
            case .dead:
                // if the game state is dead, reload the scene on a new touch
                if let scene = GameScene(fileNamed: "GameScene") {
                    scene.scaleMode = .aspectFill
                    // create the transition between the old and the new scene
                    let transition = SKTransition.moveIn(with: SKTransitionDirection.up, duration: 0.5)
                    view?.presentScene(scene, transition: transition)
                    isPlaying = false
                    gameState = .firstScreen
                }
        
            case .firstScreen:
                // stop and change the sick beat
                backgroundMusic.removeFromParent()
                
                if let musicURL = Bundle.main.url(forResource: "inGameMusic", withExtension: "mp3") {
                    backgroundMusic = SKAudioNode(url: musicURL)
                    addChild(backgroundMusic)
                }
                
                // initial screen with logo before each game, tap to play
                
                gameState = .playing
                isDead = false
                let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                let remove = SKAction.removeFromParent()
                let wait = SKAction.wait(forDuration: 0.0)
                let activatePlayer = SKAction.run { [unowned self] in
                    startObstacles(initialObstacleFrequency: 3)
                }
                
                // create an action sequence that makes our logo fade out
                let sequence = SKAction.sequence([fadeOut, wait, activatePlayer, remove])
                headerLabel.run(SKAction.sequence([fadeOut, wait, remove]))
                // remove the leaderboard
                enumerateChildNodes(withName: "scoreLineLabel") { (node, _) in
                     node.run(SKAction.sequence([fadeOut, wait, remove]))
                }
                
                //scoreLineLabel.run(SKAction.sequence([fadeOut, wait, remove]))
                logo.run(sequence)
                tapToPlay.run(SKAction.sequence([fadeOut, wait, remove]))
                
                // we started the game, so we change isPlaying according to that
                isPlaying = true
                
                // add player to game scene
                addChild(player)

            case .playing:
                // move the player to the new touch
                // check if the player is dead, if so change game state
                if isDead == true {
                    gameState = .dead
                    break
                }
                
                // only use touch controls if that's our setting
                if touchControl {
                    // factor to decide how fast the player moves towards the touch input
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
                    lastState.x = location.x
                }


            case .fadeInSettings:
                // show our menu buttons
                addChild(playButton)
                addChild(disableVolumeButton)
                //addChild(controlModeButton)
                addChild(touchModeButton)
                addChild(tiltModeButton)
                addChild(toggleBackground)
                logo.zPosition = -1
                tapToPlay.zPosition = -1
                headerLabel.zPosition = -1
                enumerateChildNodes(withName: "scoreLineLabel") { (node, _) in
                     node.zPosition = -1
                }
                gameState = .fadeOutSettings
                
                // stop our physics simulation
                //speed = 0
                self.isPaused = true
            
            case .fadeOutSettings:
                // removes the settings buttons
                // if statement for the buttons
                // if resume button is pressed:
                if playButton.contains(location) {
                    // hide our buttons
                    playButton.removeFromParent()
                    disableVolumeButton.removeFromParent()
                    //controlModeButton.removeFromParent()
                    touchModeButton.removeFromParent()
                    tiltModeButton.removeFromParent()
                    toggleBackground.removeFromParent()
                    if isDead == false {
                        //speed = 1
                        self.isPaused = false
                    }
                    
                    // set the game state according to isPlaying and isDead
                    if isPlaying == false {
                        gameState = .firstScreen
                        logo.zPosition = 4
                        tapToPlay.zPosition = 4
                        headerLabel.zPosition = 2
                        enumerateChildNodes(withName: "scoreLineLabel") { (node, _) in
                             node.zPosition = 2
                        }
                    }
                    else if isPlaying == true {
                        gameState = .playing
                        if isDead == true {
                            gameState = .dead
                        }
                    }
                }
                // if control mode button is pressed
                else if tiltModeButton.contains(location) {
                    let defaults = UserDefaults.standard
                    touchControl = defaults.bool(forKey: "touchEnabled")
                    // if it's false toggle it to switch it to true and vice versa
                    touchControl = false
                    defaults.setValue(touchControl, forKey: "touchEnabled")
                    
                    // debugging
                    //print(touchControl)
                    
                    // if our control mode is tilt, start collecting accelerometer data
                    // else means it's touch and then we stop collecting accelerometer data
                   
                    toggleBackground.position = CGPoint(x: frame.midX - tiltModeButton.size.width/1.5, y: frame.midY - tiltModeButton.size.height * 1.5)
                    motionManager = CMMotionManager()
                    motionManager.startAccelerometerUpdates()
                    
                    
                    // add code here to switch images
                }
                
                else if touchModeButton.contains(location) {
                    let defaults = UserDefaults.standard
                    touchControl = defaults.bool(forKey: "touchEnabled")
                    // if it's false toggle it to switch it to true and vice versa
                    touchControl = true
                    defaults.setValue(touchControl, forKey: "touchEnabled")
                    
                    // debugging
                    //print(touchControl)
                    
                    // if our control mode is tilt, start collecting accelerometer data
                    // else means it's touch and then we stop collecting accelerometer data
                    
                    toggleBackground.position = CGPoint(x: frame.midX + touchModeButton.size.width/1.5, y: frame.midY - tiltModeButton.size.height * 1.5)
                    motionManager.stopAccelerometerUpdates()
                    
                    
                    // add code here to switch images
                }
        }
        
    }
    
    // check if the leaderboard and settings default values exist, if not, set them to our defaults
    func initializeScore() {
        
        let defaults = UserDefaults.standard
        
        if defaults.array(forKey: "scoreBoard") == nil {
            print("fuck")
            let scoreBoard = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            defaults.set(scoreBoard, forKey: "scoreBoard")
            
            let nameBoard = ["test", "test", "test", "test", "test", "test", "test", "test", "test", "test"]
            defaults.set(nameBoard, forKey: "nameBoard")
        
            let volumeDisabled = false
            defaults.setValue(volumeDisabled, forKey: "volumeDisabled")
            
            let touchEnabled = true
            defaults.setValue(touchEnabled, forKey: "touchEnabled")
        }
    }
    
    func addScore() {
        // save the score in the storage
        let defaults = UserDefaults.standard
        //read our scoreBoard
        var scoreBoard: [Int] = defaults.array(forKey: "scoreBoard") as? [Int] ?? [Int]()
        var nameBoard: [String] = defaults.array(forKey: "nameBoard") as? [String] ?? [String]()
        // if the current score is bigger than the last one, replace the lowest score with the other one
        if score > scoreBoard[9] {
            scoreBoard[9] = score
            scoreBoard.sort(by: >)
            
            // this loop checks for the index of the newly added score (after sorting)
            // and adds the player name to the same index but in the nameBoard array
            for counter in 0...9 {
                if scoreBoard[counter] == score {
                    nameBoard.insert(("New Player" + String(score)), at: counter)
                    nameBoard.remove(at: 10)
                    break
                }
            }
            defaults.set(scoreBoard, forKey: "scoreBoard")
            defaults.set(nameBoard, forKey: "nameBoard")
            // just some debugging
            //print(scoreBoard)
            //print(nameBoard)
        }
    }
    
    // this probably uses an unnecessary amount of memory but otherwise I always run into scope issues
    // variables for label nodes for the leaderboard labels
    var headerLabel: SKLabelNode!
    var scoreLineLabel: SKLabelNode!
    
    func printLeaderboard(){
        // save the score in the storage
        let defaults = UserDefaults.standard
        //read our scoreBoard
        let scoreBoard: [Int] = defaults.array(forKey: "scoreBoard") as? [Int] ?? [Int]()
        let nameBoard: [String] = defaults.array(forKey: "nameBoard") as? [String] ?? [String]()
        var leaderboard: [String] = []
        for i in 0...scoreBoard.count - 2 {
            leaderboard.append((String(i + 1) + ".").padding(toLength: 7, withPad: " ", startingAt: 0) + String(scoreBoard[i]).padding(toLength: 10, withPad: " ", startingAt: 0) + nameBoard[i].padding(toLength: 10, withPad: " ", startingAt: 0))
            // just debugging
            //print(leaderboard[i])
        }
        leaderboard.append((String(10) + ".").padding(toLength: 6, withPad: " ", startingAt: 0) + String(scoreBoard[9]).padding(toLength: 10, withPad: " ", startingAt: 0) + nameBoard[9].padding(toLength: 10, withPad: " ", startingAt: 0))
        
        // formatting is a little off becuase apple doesn't provide a way to use a monospaced font with an SKLabel node
        // print the header label once
        headerLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        headerLabel.fontSize = 52
        headerLabel.position = CGPoint(x: frame.midX, y: frame.maxY/3 - logo.size.height/0.9)
        headerLabel.text = "Top 10 Best Scores".padding(toLength: 26, withPad: " ", startingAt: 0)
        headerLabel.fontColor = UIColor.black
        headerLabel.zPosition = 2
        addChild(headerLabel)
        
        for i in 0...scoreBoard.count - 1 {
            // function to print the leaderboard
            // create the place label
            scoreLineLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
            scoreLineLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
            scoreLineLabel.fontSize = 40
            scoreLineLabel.text = leaderboard[i]
            // can't do it dynamically, meaning there's no way to allign it in the middle
            scoreLineLabel.position = CGPoint(x: frame.midX - 225, y: headerLabel.position.y * 1.3 - CGFloat((i + 1) * 40))
            scoreLineLabel.fontColor = UIColor.black
            scoreLineLabel.zPosition = 2
            scoreLineLabel.name = "scoreLineLabel"
            addChild(scoreLineLabel)
        }
    }
    
    func playBackground(){
        if let musicURL = Bundle.main.url(forResource: "inGameMusic", withExtension: "mp3") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
    }
    
}

//  Code by Silvian Ene and Ludwig Mueller
//  Obstacle Images by Cameron Lai Harris
//  Icons by Ludwig Mueller
//  App Logo by Silvian Ene
//  Jorge Hernandez - Chopsticks
