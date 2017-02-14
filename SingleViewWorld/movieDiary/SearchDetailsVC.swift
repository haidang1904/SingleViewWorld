//
//  SearchDetailsVC.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 10/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import UIKit
import SDWebImage

class SearchDetailsVC: UIViewController {

    var viewModel: SearchDetailsVM?

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.sd_setImage(with: URL(string: (viewModel?.movieDetail?.image)!), placeholderImage: UIImage(named: "poster_placeholder"))
        
        fillOutDetails()
        Log.test("viewDidLoad: \(viewModel?.movieDetail?.description)")
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fillOutDetails() {
        
        titleLabel.text = viewModel?.movieDetail?.title
        subtitleLabel.text = "(\(viewModel?.movieDetail?.subtitle))"
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
