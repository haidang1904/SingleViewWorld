//
//  movieDiaryPopUpVC.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 09/03/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import UIKit
import Foundation

class movieDiaryPopUpVC: UIViewController {

    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    
    @IBAction func checkButtonChange(_ sender: UIButton) {

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        datePicker.setDate(Date(), animated: true)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
