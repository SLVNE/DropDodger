//
//  GameScene.swift
//  messing
//
//  Created by Ludwig Müller on 16.11.20.
//

import SpriteKit

class GameScene: SKScene {
    
    private var redBall : SKSpriteNode?
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        redBall = SKSpriteNode(imageNamed: "redBall.png")
        redBall?.setScale(0.2)
        redBall?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        redBall?.position = CGPoint(x: 0, y: 400)
        
        self.addChild(redBall!)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            
            let location = touch.location(in: self)
            
            redBall!.position.x = location.x
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            
            let location = touch.location(in: self)
            
            redBall!.position.x = location.x
            
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
