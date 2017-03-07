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
import KCFloatingActionButton

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
            viewModel?.saveMovie(isWatched: 0)
        } else {
            showAlertView()
        }
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton?) {
        
        let _ = self.navigationController?.popViewController(animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let model = viewModel {
            model.movieDelegate = self
            fillOutDetails(model: model)
            addFloatingActionButton()
        }
        saveButton.isHidden = true
        closeButton.isHidden = true
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
    func addFloatingActionButton() {
        let fab = KCFloatingActionButton()
        let saveWatchedList = KCFloatingActionButtonItem()
        let saveBucketList = KCFloatingActionButtonItem()
        let deleteFromList = KCFloatingActionButtonItem()
        let backToList = KCFloatingActionButtonItem()
        
        saveWatchedList.title = "Save Watched List"
        saveBucketList.title = "Save Bucket List"
        deleteFromList.title = "Delete From List"
        backToList.title = "Back To List"
        
        saveWatchedList.handler = { [weak self] items in
            self?.viewModel?.saveMovie(isWatched: 0)
        }
        saveBucketList.handler = { [weak self] items in
            self?.viewModel?.saveMovie(isWatched: 1)
        }
        deleteFromList.handler = { [weak self] items in
            self?.viewModel?.deleteMovie()
        }
        backToList.handler = { [weak self] items in
            self?.closeButtonAction(nil)
        }
        
        fab.addItem(item: backToList)
        fab.addItem(item: deleteFromList)
        fab.addItem(item: saveBucketList)
        fab.addItem(item: saveWatchedList)
        
        fab.sticky = true
        fab.openAnimationType = .fade
        fab.animationSpeed = 0.01
        self.view.addSubview(fab)
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
        if let isSaved = viewModel?.isSaved(), isSaved == .none {
            saveButton.setTitle("SAVE", for: .normal)
        } else {
            saveButton.setTitle("DELETE", for: .normal)
        }
    }
    
    func showAlertView() {
        let title = String(htmlEncodedString: (viewModel?.movieDetail?.title)!)
        let message = "영화를 삭제합니다."
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
    
    func eventHandler(code:SearchDetailErrorType) {
    /*
         case saved                  // save successfully into the DB
         case deleted                // delete successfully from the DB
         case existWatched           // already exist watched list in the DB
         case existBucket            // already exist bucket list in the DB
         case moveToWatched          // move from Bucket to Watched
         case canNotMoveToBucket     // can not move from Watched to Bucket
         case notExist               // not exist in the DB
    */
        switch code {
        case .saved:
            Log.test("save successfully into the DB")
            saveButton.setTitle("DELETE", for: .normal)
            break
        case .deleted:
            Log.test("delete successfully from the DB")
            saveButton.setTitle("SAVE", for: .normal)
            break
        case .existWatched:
            Log.test("already exist watched list in the DB")
            break
        case .existBucket:
            Log.test("already exist bucket list in the DB")
            break
        case .moveToWatched:
            Log.test("move from Bucket to Watched")
            break
        case .canNotMoveToBucket:
            Log.test("can not move from Watched to Bucket")
            break
        case .notExist:
            Log.test("not exist in the DB")
            break
        default:
            break
        }
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
