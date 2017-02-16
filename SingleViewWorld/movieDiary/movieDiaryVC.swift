//
//  movieDiaryVC.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 07/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import UIKit
import RxSwift
import SDWebImage



@objc open class movieDiaryVC: UIViewController {

    let diaryVM = movieDiaryVM()
    fileprivate let disposeBag = DisposeBag()
    var showDetailView: ((_ selectedMovie: MovieModel?) -> Void)? = nil
    
    @IBOutlet weak var searchResultTable: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    
    @IBAction func goSearch(_ sender: UIButton) {
        if let keyword = searchTextField.text {
            Log.test("send Text : \(keyword)")
            self.diaryVM.sendSearchAPItoNaver(keyword: keyword)
        } else {
            Log.test("No Text : \(searchTextField.text)")
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        

    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        searchTextField.text = "서유기"
        
        diaryVM.isSearch
            .observeOn(MainScheduler.instance)
            .subscribe(onNext : { [weak self] (mode:Bool) in
                if mode == true {
                    self?.searchResultTable.reloadData()
                    self?.searchTextField.resignFirstResponder()
                }
            })
            .addDisposableTo(disposeBag)

        diaryVM.isDownloadImage
            .observeOn(MainScheduler.instance)
            .subscribe(onNext : { [weak self] (mode:Bool) in
                if mode == true {
                    self?.searchResultTable.reloadData()
                }
            })
            .addDisposableTo(disposeBag)
        
        let backItem = UIBarButtonItem()
        backItem.title = "Back to"
        self.navigationItem.backBarButtonItem = backItem
        // Do any additional setup after loading the view.
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
//    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        Log.test("segue.identifier \(segue.identifier)")
//        if let navCon = segue.destination as? UINavigationController {
//            //navCon.navigationBar.barStyle =
//        }
//        
//    }

}

extension movieDiaryVC: UITableViewDelegate,UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: false)
        if let movieInfo = diaryVM.getMovieInfo((indexPath as NSIndexPath).row) {
            self.showDetailView?(movieInfo)
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        var returnValue : Int = 0
        returnValue = diaryVM.getResultCount()
        return returnValue
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell : SearchResultCell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
        if let appName = diaryVM.getName((indexPath as NSIndexPath).row){
            cell.providerDesc?.text = appName
        }
        cell.providerIcon?.image = diaryVM.getImage((indexPath as NSIndexPath).row)
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
}

