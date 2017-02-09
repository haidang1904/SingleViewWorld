//
//  CardGameModeVC.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 8/16/16.
//  Copyright © 2016 samsung. All rights reserved.
//

import UIKit
import RxSwift
import SpriteKit

@objc open class CardGameModeVC: UIViewController {
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        let welcome : MenuScene = MenuScene(size: CGSize(width: skView.bounds.width,height: skView.bounds.height))
        
        skView.presentScene(welcome)
    }
    
    override open var shouldAutorotate : Bool {
        return true
    }
    
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override open var prefersStatusBarHidden : Bool {
        return true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
