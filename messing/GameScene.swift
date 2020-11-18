//
//  GameScene.swift
//  messing
//
//  Created by Ludwig Müller on 16.11.20.
//

import SpriteKit

class GameScene: SKScene {
    
    // create a variable for the moving background
    var bground = SKSpriteNode()
    
    // create a local variable for our player
    private var player : SKSpriteNode?
    
    override func didMove(to view: SKView) {
        // change the anchor point of something for whatever reason, oh and 0.5, 0.5 is also the default value, so there's no logical reason to do this... maybe we can remove it some day when we understand what it actually does
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // assign picture to our player sprite node
        player = SKSpriteNode(imageNamed: "redBall.png")
        // change the size of the sprite node, there probably exist more elegant ways to do this
        player?.setScale(0.2)
        
        // next line would alter the point where we grap our player sprite
        // (x: 0,5, y: 0.5) is default value
        // player?.anchorPoint = CGPoint(x: 1, y: 0.5)
        
        player?.position = CGPoint(x: 0, y: 400)
        
        // if sibling order is ignored, which we do in the GameViewController.swift file, then spriteKit renders our sprites in the order of their z-value
        // give sprite the z-value 1 so it's higher than our background
        player?.zPosition = 1
        
        self.addChild(player!)
        
        createBGround()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // I think runs the for loop for as many times as there are touches
        for touch in touches {
            
            // save the location of the touch into a variable
            let location = touch.location(in: self)
            
            // change the player's position to the position of the touch
            player!.position.x = location.x
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // I think runs the for loop for as many times as there are touches
        for touch in touches {
            
            // save the location of the touch into a variable
            let location = touch.location(in: self)
            
            // change the player's position to the position of the touch
            player!.position.x = location.x
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        moveBGround()
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
            self.addChild(bground)
        }
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
