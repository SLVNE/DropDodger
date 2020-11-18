//
//  GameScene.swift
//  messing
//
//  Created by Ludwig Müller on 16.11.20.
//

import SpriteKit

class GameScene: SKScene {
    
    var bground = SKSpriteNode()
    
    
    private var redBall : SKSpriteNode?
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        redBall = SKSpriteNode(imageNamed: "redBall.png")
        redBall?.setScale(0.2)
        redBall?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        redBall?.position = CGPoint(x: 0, y: 400)
        
        self.addChild(redBall!)
        
        createBGround()
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
        moveBGround()
    }
    
    func createBGround(){
        for i in 0...3 {
         
            let bground = SKSpriteNode(imageNamed: "background")
            bground.name =  "BGround"
            bground.size = CGSize(width: (self.scene?.size.width)!, height: (self.scene?.size.height)!)
            bground.anchorPoint = CGPoint(x: 0, y: 0.5)
            bground.position = CGPoint(x: -bground.frame.width/2, y: CGFloat(i) * bground.size.width)
            self.addChild(bground)
        }
    }
    
    func moveBGround(){
        
        self.enumerateChildNodes(withName: "BGround", using: ({
            (node, error) in
            
            node.position.y -= 2
            
            if node.position.y < -((self.scene?.size.height)!) {
                
                node.position.y += (self.scene?.size.height)! * 3
            }
        }))
    }
}
