//
//  WelcomeScene.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 8/5/16.
//  Copyright © 2016 samsung. All rights reserved.
//

import UIKit
import SpriteKit

class WelcomeScene: SKScene {

    var sceneCreated : Bool = false
    
    fileprivate func createWelcomeNode() -> SKLabelNode {
        
        let WelcomeNode : SKLabelNode = SKLabelNode()
        WelcomeNode.name = "welcomeNode"
        WelcomeNode.text = "SpriteKit Demo - Tap Screnn to Play"
        WelcomeNode.fontSize = 20
        WelcomeNode.fontColor = SKColor.black
        
        WelcomeNode.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        
        return WelcomeNode
    }
    
    override func didMove(to view: SKView) {
        if !sceneCreated {
            self.backgroundColor = SKColor.gray
            self.scaleMode = .aspectFill
            self.addChild(self.createWelcomeNode())
            self.sceneCreated = true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let welcomeNode : SKNode? = self.childNode(withName: "welcomeNode")
        
        if let _ =  welcomeNode {
            let fadeAway : SKAction = SKAction.fadeOut(withDuration: 0.5)
            welcomeNode?.run(fadeAway, completion: {
                let archeryScene : SKScene = ArcheryScene(size: self.size)
                let doors : SKTransition = SKTransition.doorway(withDuration: 1.0)
                self.view?.presentScene(archeryScene, transition: doors)
            })
        }
    }
    
    override func update(_ currentTime: TimeInterval) {

    }
    
}
