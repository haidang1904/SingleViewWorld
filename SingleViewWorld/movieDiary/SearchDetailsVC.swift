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
    let fab = KCFloatingActionButton()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var directorLabel: UILabel!
    @IBOutlet weak var actorLabel: UILabel!
    @IBOutlet weak var watchedImageView: UIImageView!
    @IBOutlet weak var watchedDateLabel: UILabel!
    
    @IBOutlet weak var saveView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var checkButton: UIButton!
    
    @IBAction func checkButtonChange(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        Log.test("\(datePicker.date)")
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton?) {
        self.saveView.isHidden = true
    }
    
    @IBAction func saveButtonAction(_ sender: UIButton) {
        
        if checkButton.isSelected == true {
            
            viewModel?.saveMovie(watchDate: "")
            
        } else {
        
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            let watchDate = dateFormatter.string(from: datePicker.date)
            viewModel?.saveMovie(watchDate: watchDate)
        }
        self.saveView.isHidden = true
        self.fillOutDetails(model: viewModel!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let model = viewModel {
            model.movieDelegate = self
            fillOutDetails(model: model)
            addFloatingActionButton()
        }
        self.saveView.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        //self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(false)
        //self.navigationController?.isNavigationBarHidden = false
    }
    func addFloatingActionButton() {
        
        fab.addItem(item: createFloatingButton(title: "Back To Library", handler: { [weak self] items in self?.closeButtonAction(nil)}))
        
        if let value = viewModel?.movieDetail?.isBucketList.value {
            fab.addItem(item: createFloatingButton(title: "Delete From List", handler: { [weak self] items in self?.showAlertView()}))
            if value == 1 {
                fab.addItem(item: createFloatingButton(title: "Add Watched", handler: {[weak self] _ in self?.presentSaveView()}))
            }
        } else {
            fab.addItem(item: createFloatingButton(title: "Add Bucket", handler: { [weak self] items in self?.viewModel?.saveMovieForBucket()}))
            fab.addItem(item: createFloatingButton(title: "Add Watched", handler: {[weak self] _ in self?.presentSaveView()} ))
            
        }
        
        fab.sticky = true
        fab.openAnimationType = .fade
        fab.animationSpeed = 0.05
        self.view.addSubview(fab)
        
    }
    
    func reLoadButton() {
        let views = self.view.subviews
        var floatingButtonView : KCFloatingActionButton? = nil
        for view in views {
            if view.isKind(of: KCFloatingActionButton.classForCoder()) {
                Log.test("Found!!!")
                floatingButtonView = view as? KCFloatingActionButton
                break
            }
        }
        
        if floatingButtonView != nil {
            floatingButtonView?.items.removeAll()
            Log.test("removeAll!!!")
            floatingButtonView?.removeFromSuperview()
            Log.test("removeFromSuperview!!!")
            addFloatingActionButton()
        }
        //addFloatingActionButton()
    }
    
    func createFloatingButton(title:String, handler:@escaping ((KCFloatingActionButtonItem) -> Void)) -> KCFloatingActionButtonItem{
        let button = KCFloatingActionButtonItem()
        button.title = title
        button.handler = handler
        
        return button
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

        if model.movieDetail?.isBucketList.value == 0 {
            UIView.animate(withDuration: 1.0, animations: {
                self.watchedImageView.image = UIImage(named: "watch_stamp")
                if model.movieDetail?.dateOfWatch != "" {
                    self.watchedDateLabel.text = model.movieDetail?.dateOfWatch
                } else {
                    self.watchedDateLabel.text = "Unknown Date"
                }
                
            }, completion: { result in
                
            })
        }
    }
    
    func showAlertView() {
        let title = String(htmlEncodedString: (viewModel?.movieDetail?.title)!)
        let message = "영화를 리스트에서 삭제하고 이전화면으로 돌아갑니다."
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
    func presentSaveView() {
        self.saveView.isHidden = false
    }
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
            reLoadButton()
            //saveButton.setTitle("DELETE", for: .normal)
            break
        case .deleted:
            Log.test("delete successfully from the DB")
            closeButtonAction(nil)
            //saveButton.setTitle("SAVE", for: .normal)
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
