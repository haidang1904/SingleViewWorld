//
//  SSLTestVC.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 10/18/16.
//  Copyright © 2016 samsung. All rights reserved.
//

import UIKit
import SmartView
import Darwin
import Alamofire
import RxSwift

@objc open class VarietyTestVC: UIViewController {
    
    @IBOutlet weak var VarietyList: UITableView!
    @IBOutlet weak var VarietySwitch: UISwitch!
    @IBOutlet weak var VarietyBTN: UIButton!
    
    @IBAction func changeSwitch(_ sender: UISwitch) {
        
    }
    
    @IBAction func btnClick(_ sender: UIButton) {
        VarietyTest.discoverStart()
        //if(VarietyTest.discoverStart()) {
        //    Log.test("Discover Start")
        //} else {
        //    Log.test("Discover Fail")
        //}
    }

    let cellID : String =  "VarietyListCell"
    let VarietyTest = VarietyTestVM()
    fileprivate let disposeBag = DisposeBag()
    var selectedIndex : Int? = nil

    
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        Log.test("Variety test")
        
        VarietyList.delegate = self
        VarietyList.dataSource = self
        VarietyList.register(UINib.init(nibName: cellID, bundle: nil), forCellReuseIdentifier: cellID)

        VarietyTest.appsData
            .observeOn(MainScheduler.instance)
            .subscribe(onNext : { (mode:Bool) in
                
                })
            .addDisposableTo(disposeBag)
        
        VarietyTest.connectData
            .observeOn(MainScheduler.instance)
            .subscribe(onNext : { [weak self] (mode:Bool) in
                    self!.VarietyList.reloadData()
                })
            .addDisposableTo(disposeBag)
        
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        VarietyTest.close();
        super.viewWillDisappear(animated)
    }
}

extension VarietyTestVC: UITableViewDelegate,UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){

    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        var returnValue : Int = 0
        returnValue = VarietyTest.getDiscoveredTVCount()
        return returnValue
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        if let appName = VarietyTest.getDiscoveredTVName((indexPath as NSIndexPath).row){
            cell.textLabel?.text = appName
        }
        return cell
    }
}
