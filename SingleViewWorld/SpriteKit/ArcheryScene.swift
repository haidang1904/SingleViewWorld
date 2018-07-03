//
//  ArcheryScene.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 8/5/16.
//  Copyright © 2016 samsung. All rights reserved.
//

import UIKit
import SpriteKit

class ArcheryScene: SKScene {

    var sceneCreated : Bool = false
    var score : Int = 0
    var ballCount : Int = 0
    var archerAnimation : NSArray = []
    
    let ballCategory : UInt32 = 0x1 << 1
    let arrowCategory : UInt32 = 0x1 << 0
    
    override func didMove(to view: SKView){
        if !sceneCreated {
            self.score = 0
            self.ballCount = 40
            self.physicsWorld.gravity = CGVector(dx: 0, dy: -1.0)
            self.physicsWorld.contactDelegate = self
            self.initArcheryScene()
            self.sceneCreated = true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let archerNode : SKNode? = self.childNode(withName: "archerNode")
        
        if let _ = archerNode {
            let animate : SKAction = SKAction.animate(with: self.archerAnimation as! [SKTexture], timePerFrame: 0.05)
            
            let shootArrow : SKAction = SKAction.run({
                let arrowNode : SKNode = self.createArrowNode()
                self.addChild(arrowNode)
                arrowNode.physicsBody?.applyImpulse(CGVector(dx: 35.0, dy: 0))
            })
            
            let sequence : SKAction = SKAction.sequence([animate,shootArrow])
            
            archerNode?.run(sequence)
        }
    }

    
    func initArcheryScene() {
        
        self.backgroundColor = SKColor.white
        self.scaleMode = .aspectFill
        
        let archerNode : SKSpriteNode = self.createArcherNode()
        self.addChild(archerNode)

        let archerFrames : NSMutableArray = NSMutableArray()
        let archerAtlas : SKTextureAtlas = SKTextureAtlas(named: "archer")
        
        for i in 1...archerAtlas.textureNames.count {
            let textureString : String = String(format: "archer%03d", i)
            archerFrames.add(archerAtlas.textureNamed(textureString))
        }
        self.archerAnimation = archerFrames
        
        let releaseBalls : SKAction = SKAction.sequence([SKAction.perform(#selector(createBallNode), onTarget: self),SKAction.wait(forDuration: 1)])
        self.run(SKAction.sequence([SKAction.repeat(releaseBalls, count: self.ballCount),SKAction.wait(forDuration: 5)]), completion: {
            self.gameOver()
        })
    }
    
    func createArcherNode() -> SKSpriteNode {
        
        let archerNode : SKSpriteNode = SKSpriteNode(imageNamed: "archer001.png")
        archerNode.name = "archerNode"
        archerNode.position = CGPoint(x: self.frame.minX+55,y: self.frame.midY)
        return archerNode
    }
    
    func createArrowNode() -> SKSpriteNode {
        
        let arrowNode : SKSpriteNode = SKSpriteNode(imageNamed: "ArrowTexture")
        arrowNode.name = "arrowNode"
        arrowNode.position = CGPoint(x: self.frame.minX+100, y: self.frame.midY)
        arrowNode.physicsBody = SKPhysicsBody(rectangleOf: arrowNode.frame.size)
        arrowNode.physicsBody?.usesPreciseCollisionDetection = true
        arrowNode.physicsBody?.categoryBitMask = self.arrowCategory
        arrowNode.physicsBody?.collisionBitMask = self.arrowCategory | self.ballCategory
        arrowNode.physicsBody?.contactTestBitMask = self.arrowCategory | self.ballCategory
        
        return arrowNode
    }
    
    @objc func createBallNode() {
        
        let ballNode : SKSpriteNode = SKSpriteNode(imageNamed: "BallTexture")
        ballNode.name = "ballNode"
        ballNode.position = CGPoint(x: randomBetween(150.0, high: self.size.width), y: self.size.height-50)
        ballNode.physicsBody = SKPhysicsBody(circleOfRadius: (ballNode.size.width/2)-7)
        ballNode.physicsBody?.usesPreciseCollisionDetection = true
        ballNode.physicsBody?.categoryBitMask = self.ballCategory
        
        self.addChild(ballNode)
    }
    
    func createScoreNode() -> SKLabelNode {
    
        let scoreNode : SKLabelNode = SKLabelNode()
        let newScore : String = String(format: "Score: %i", self.score)
        scoreNode.name = "scoreNode"
        scoreNode.text = newScore
        scoreNode.fontSize = 60
        scoreNode.fontColor = SKColor.red
        
        scoreNode.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        
        return scoreNode
    }
    
    func gameOver() {
        
        let scoreNode : SKLabelNode = self.createScoreNode()
        self.addChild(scoreNode)
        let fadeOut : SKAction = SKAction.sequence([SKAction.wait(forDuration: 3),SKAction.fadeOut(withDuration: 3)])
        let welcomeReturn : SKAction = SKAction.run {
            let transition : SKTransition = SKTransition.reveal(with: .down, duration: 1.0)
            let welcomeScene : WelcomeScene = WelcomeScene(size: self.size)
            
            self.scene?.view?.presentScene(welcomeScene, transition: transition)
        }
        
        let sequence : SKAction = SKAction.sequence([fadeOut,welcomeReturn])
        self.run(sequence)
    }
    
    fileprivate func randomFloat() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(RAND_MAX)
    }
    
    fileprivate func randomBetween(_ low:CGFloat, high:CGFloat) -> CGFloat {
        return randomFloat() * (high - low) + low
    }
}

extension ArcheryScene: SKPhysicsContactDelegate {
    
    internal func didBegin(_ contact: SKPhysicsContact) {
        //let firstNode : SKSpriteNode = contact.bodyA.node as! SKSpriteNode
        let secondNode : SKSpriteNode = contact.bodyB.node as! SKSpriteNode
        
        if (contact.bodyA.categoryBitMask == arrowCategory && contact.bodyB.categoryBitMask == ballCategory) {
            
            let contactPoint : CGPoint = contact.contactPoint
//            let contactX :CGFloat = contactPoint.x
            let contactY : CGFloat = contactPoint.y
            let targetX : CGFloat = secondNode.position.x
            let targetY : CGFloat = secondNode.position.y
            let margin : CGFloat = secondNode.frame.size.height/2 - 25
            
            if ((contactY > (targetY - margin)) && (contactY < (targetY + margin))) {
                let burstPath : String = Bundle.main.path(forResource: "BurstParticle", ofType: "sks")!
                let burstNode : SKEmitterNode = NSKeyedUnarchiver.unarchiveObject(withFile: burstPath) as! SKEmitterNode
                burstNode.position = CGPoint(x: targetX, y: targetY)
                
                secondNode.removeFromParent()
                self.addChild(burstNode)
//                let joint : SKPhysicsJointFixed = SKPhysicsJointFixed.jointWithBodyA(contact.bodyA, bodyB: contact.bodyB, anchor: CGPointMake(contactX, contactY))
//                self.physicsWorld.addJoint(joint)
//                
//                let texture : SKTexture = SKTexture(imageNamed: "ArrowHitTexture")
//                firstNode.texture = texture

                self.score += 1
                Log.test("did contact!! score : \(self.score)")
            }
        }
    }
}
