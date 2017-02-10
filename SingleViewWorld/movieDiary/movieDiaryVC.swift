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
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        searchTextField.text = "라라랜드"
        
//        
//        VarietyTest.connectData
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext : { [weak self] (mode:Bool) in
//                self!.VarietyList.reloadData()
//            })
//            .addDisposableTo(disposeBag)
        
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
        // Do any additional setup after loading the view.
    }

    override open func didReceiveMemoryWarning() {
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
        if let image = diaryVM.getImage((indexPath as NSIndexPath).row){
            cell.providerIcon?.image = image
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
}

