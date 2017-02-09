//
//  SDKPrivateTestVC.swift
//  SingleViewWorld
//
//  Created by samsung on 2016. 5. 30..
//  Copyright © 2016년 samsung. All rights reserved.
//

import UIKit
import SmartView
import Darwin
import Alamofire
import RxSwift

@objc open class SDKPriavteTestVC: UIViewController {
    
    @IBOutlet weak var installedApplistTableView: UITableView!
    @IBOutlet weak var iconDataImageView: UIImageView!
    @IBOutlet weak var iconDataView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textFieldBottomConstraint: NSLayoutConstraint!
    
    let cellID : String =  "installedAppListCell"
    let SDKPrivateTest = SDKPrivateTestVM()
    fileprivate let disposeBag = DisposeBag()
    var displayMode : privateDisplayMode = .unknown
    var selectedIndex : Int? = nil
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        installedApplistTableView.delegate = self
        installedApplistTableView.dataSource = self
        installedApplistTableView.register(UINib.init(nibName: cellID, bundle: nil), forCellReuseIdentifier: cellID)

        self.iconDataView.isHidden = true
        self.textField.isHidden = true
        self.textField.delegate = self

        SDKPrivateTest.appsData
            .observeOn(MainScheduler.instance)
            .subscribe(onNext : { [weak self] (mode:privateDisplayMode) in
                self!.displayMode = mode
                self!.modeChanged();
                self!.installedApplistTableView.reloadData()
            })
            .addDisposableTo(disposeBag)
        
        SDKPrivateTest.iconData
            .observeOn(MainScheduler.instance)
            .subscribe(onNext : { [weak self] (imageData : Data?) in
                if let imageData = imageData{
                    self!.iconDataImageView.image = UIImage(data: imageData)
                    self!.iconDataView.isHidden = false
                    Log.lhjtest("show")
                } else {
                    Log.lhjtest("hide")
                }
            })
            .addDisposableTo(disposeBag)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameDidChanged), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)

    }

    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        SDKPrivateTest.close();
        super.viewWillDisappear(animated)
    }
    
    open func modeChanged() {
        switch displayMode {
        case .connectionfail:
            let alert = UIAlertController(title: "Connection Fail", message: "Application is not installed on this TV", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            self.displayMode = .tvlist
        case .applist:
            break
        default:
            textField.isHidden = true
            textField.resignFirstResponder()
            break
        }
    }
    
    open func keyboardFrameDidChanged(_ notification : Notification) {
        if let info : [AnyHashable: Any] = (notification as NSNotification).userInfo {
            if let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                textFieldBottomConstraint.constant = UIApplication.shared.keyWindow!.frame.height - keyboardFrame.origin.y
                Log.test("constraint = \(textFieldBottomConstraint.constant)")
            }
        }
    }
    
    @IBAction func launchBtnClicked(_ sender: UIButton) {
        if let index = selectedIndex {
            SDKPrivateTest.launchApp(index)
            selectedIndex = nil
        }
        self.iconDataView.isHidden = true
    }
    
    @IBAction func closeBtnClicked(_ sender: UIButton) {
        self.iconDataView.isHidden = true
    }
}

extension SDKPriavteTestVC: UITableViewDelegate,UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        switch displayMode {
            case .applist:
                if indexPath.row == 0 {
                    //TODO Remote Control
                } else {
                    SDKPrivateTest.getAppImage((indexPath as NSIndexPath).row)
                }
                selectedIndex = (indexPath as NSIndexPath).row
                break
            case .tvlist:
                SDKPrivateTest.connectToTV((indexPath as NSIndexPath).row)
                break
            default:
                break
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        
        var returnValue : Int = 0
        switch displayMode {
        case .applist:
            if let ret = SDKPrivateTest.installedAppsData?.count{
                returnValue = ret + 1
            }
            break
        case .tvlist:
            returnValue = SDKPrivateTest.getDiscoveredTVCount()
            break
        default:
            break
        }
        return returnValue
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{

        let cell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        switch displayMode {
            case .applist:
                if indexPath.row == 0 {
                    cell.textLabel?.text = "REMOTE CONTROL"
                }else {
                    if let appName = SDKPrivateTest.getAppName((indexPath as NSIndexPath).row){
                        cell.textLabel?.text = appName
                    }
                }
                break
            case .tvlist:
                if let appName = SDKPrivateTest.getDiscoveredTVName((indexPath as NSIndexPath).row){
                    cell.textLabel?.text = appName
                }
                break
            default:
                break
        }
        return cell
    }
}

extension SDKPriavteTestVC : UITextFieldDelegate {
    public func textFieldDidEndEditing(_ textField: UITextField) {
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        if (textField.text != "")
        {
            Log.test("Text Send - \(textField.text)")
            SDKPrivateTest.sendData(textField.text!)
        }
        return true
    }
}
