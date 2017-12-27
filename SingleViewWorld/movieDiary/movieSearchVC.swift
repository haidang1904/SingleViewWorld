//
//  movieSearchVC.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 07/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import UIKit
import RxSwift
import SDWebImage

@objc open class movieSearchVC: UIViewController {

    let viewModel = movieSearchVM()
    fileprivate let disposeBag = DisposeBag()
    var showDetailViewFromSearch: ((_ selectedMovie: MovieModel?) -> Void)? = nil
    
    @IBOutlet weak var searchResultTable: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    
    @IBAction func goSearch(_ sender: UIButton) {
        if let keyword = searchTextField.text {
            Log.test("send Text : \(keyword)")
            self.viewModel.sendSearchAPItoNaver(keyword: keyword)
        } else {
            Log.test("No Text : \(String(describing: searchTextField.text))")
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        searchResultTable.isHidden = true
        viewModel.isSearch
            .observeOn(MainScheduler.instance)
            .subscribe(onNext : { [weak self] (mode:Bool) in
                if mode == true {
                    self?.searchResultTable.isHidden = false
                    self?.searchResultTable.reloadData()
                    self?.searchTextField.resignFirstResponder()
                } else {
                    self?.searchResultTable.isHidden = true
                    Log.test("result is 0")
                }
            })
            .disposed(by: disposeBag)
            //.addDisposableTo(disposeBag)

        viewModel.isDownloadImage
            .observeOn(MainScheduler.instance)
            .subscribe(onNext : { [weak self] (mode:Bool) in
                if mode == true {
                    self?.searchResultTable.reloadData()
                }
            })
            .disposed(by: disposeBag)
            //.addDisposableTo(disposeBag)
        
        let backItem = UIBarButtonItem()
        backItem.title = "BACK"
        self.navigationItem.backBarButtonItem = backItem
        
        searchTextField.becomeFirstResponder()
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension movieSearchVC: UITableViewDelegate,UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: false)
        if let movieInfo = viewModel.getMovieInfo((indexPath as NSIndexPath).row) {
            self.showDetailViewFromSearch?(movieInfo)
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        var returnValue : Int = 0
        returnValue = viewModel.getResultCount()
        return returnValue
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell : SearchResultCell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
        
        cell.providerDesc?.text = viewModel.getName((indexPath as NSIndexPath).row)
        cell.providerIcon?.image = viewModel.getImage((indexPath as NSIndexPath).row)
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
}

extension movieSearchVC : UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let keyword = searchTextField.text, keyword != "" {
            Log.test("send Text : \(keyword)")
            self.viewModel.sendSearchAPItoNaver(keyword: keyword)
            textField.resignFirstResponder()
        } else {
            Log.test("No Text : \(String(describing: searchTextField.text) )")
        }
        return true
    }
}
