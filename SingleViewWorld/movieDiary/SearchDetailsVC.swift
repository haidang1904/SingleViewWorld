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
    @IBOutlet weak var directorLabel: UILabel!
    @IBOutlet weak var actorLabel: UILabel!
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func saveButtonAction(_ sender: UIButton) {
        if saveButton.currentTitle == "SAVE" {
            viewModel?.saveMovie()
        } else {
            showAlertView()
        }
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        
        let _ = self.navigationController?.popViewController(animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let model = viewModel {
            model.movieDelegate = self
            fillOutDetails(model: model)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //self.navigationController?.isNavigationBarHidden = false
    }
    
    func fillOutDetails(model : SearchDetailsVM) {
        titleLabel.text = String(htmlEncodedString: (model.movieDetail?.title)!)
        
        if let subtitle = model.movieDetail?.subtitle {
            subtitleLabel.text = String(htmlEncodedString: subtitle)
        }
        if let director = model.movieDetail?.director {
            directorLabel.text = director.dropLast()
        }
        
        if let actor = model.movieDetail?.actor {
            actorLabel.text = actor.dropLast()
        }
        
        imageView.sd_setImage(with: URL(string: (model.movieDetail?.image)!),placeholderImage: UIImage(named: "poster_placeholder"))
        changeText()
    }
    
    func changeText() {
        if let isSaved = viewModel?.isSaved(), isSaved == true {
            saveButton.setTitle("DELETE", for: .normal)
        } else {
            saveButton.setTitle("SAVE", for: .normal)
        }
    }
    
    func showAlertView() {
        let title = String(htmlEncodedString: (viewModel?.movieDetail?.title)!)
        let message = "REMOVE??"
        let cancelMsg = "CANCEL"
        let okMsg = "OK"
        
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: okMsg, style: .default) { (UIAlertAction) in
            self.viewModel?.deleteMovie()
        }
        alertView.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: cancelMsg, style: .default) { (UIAlertAction) in

        }
        alertView.addAction(cancelAction)

        self.present(alertView, animated: true, completion: nil)
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

extension SearchDetailsVC:SearchDetailDelegate {
    func didSaveMovie() {
        Log.test("didSaveMovie()")
        saveButton.setTitle("DELETE", for: .normal)
    }
    
    func didDeleteMovie() {
        Log.test("didDeleteMovie()")
        saveButton.setTitle("SAVE", for: .normal)
    }
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
    
    func dropLast(_ n: Int = 1) -> String {
        return String(characters.dropLast(n))
    }
    
    var dropLast: String {
        return dropLast()
    }
}
