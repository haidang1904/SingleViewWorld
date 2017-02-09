//
//  MenuScene.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 8/16/16.
//  Copyright © 2016 samsung. All rights reserved.
//

import UIKit
import SpriteKit

class MenuScene: SKScene {
    
    var sceneCreated : Bool = false
    
    fileprivate func createMenuNode() -> SKLabelNode {
        
        let MenuNode : SKLabelNode = SKLabelNode()
        MenuNode.name = "MenuNode"
        MenuNode.text = "SpriteKit Demo - Tap Screen to Play"
        MenuNode.fontSize = 20
        MenuNode.fontColor = SKColor.black
        
        MenuNode.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        
        return MenuNode
    }
    
    override func didMove(to view: SKView) {
        if !sceneCreated {
            self.backgroundColor = SKColor.gray
            self.scaleMode = .aspectFill
            self.addChild(self.createMenuNode())
            self.sceneCreated = true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let menuNode : SKNode? = self.childNode(withName: "MenuNode")
        
        if let _ =  menuNode {
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        
    }
    
}
