//
//  SearchDetailsVC.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 10/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import UIKit
import SDWebImage
import RealmSwift

class SearchDetailsVC: UIViewController {

    var viewModel: SearchDetailsVM?

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    
    @IBAction func saveButtonAction(_ sender: UIButton) {
        viewModel?.saveMovie()
        let _ = self.navigationController?.popViewController(animated: false)
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        viewModel?.deleteMovie()
        let _ = self.navigationController?.popViewController(animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fillOutDetails()
        //viewModel?.saveMovie()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fillOutDetails() {
        titleLabel.text = String(htmlEncodedString: (viewModel?.movieDetail?.title)!)
        if let subtitle = viewModel?.movieDetail?.subtitle {
            subtitleLabel.text = subtitle
        }
        imageView.sd_setImage(with: URL(string: (viewModel?.movieDetail?.image)!),placeholderImage: UIImage(named: "poster_placeholder"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //self.navigationController?.isNavigationBarHidden = false
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

extension String {
    
    init(htmlEncodedString: String) {
        self.init()
        guard let encodedData = htmlEncodedString.data(using: .utf8) else {
            self = htmlEncodedString
            return
        }
        let attributedOptions : [String:Any] = [
            NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType as Any,
            NSCharacterEncodingDocumentAttribute:String.Encoding.utf8.rawValue as Any
        ]
        do {
            let attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            self = attributedString.string
        } catch {
            self = htmlEncodedString
        }
    }
}
