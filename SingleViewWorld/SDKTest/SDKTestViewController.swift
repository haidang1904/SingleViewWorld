//
//  SDKTestViewController.swift
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

@objc open class SDKTestViewController: UIViewController {
    
    @IBOutlet weak var installedApplistTableView: UITableView!
    @IBOutlet weak var iconDataImageView: UIImageView!
    @IBOutlet weak var iconDataView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textFieldBottomConstraint: NSLayoutConstraint!
    
    let cellID : String =  "installedAppListCell"
    let SDKTest = SDKTestViewModel()
    fileprivate let disposeBag = DisposeBag()
    var displayMode : DisplayMode = .unknown
    var selectedIndex : Int? = nil
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        Log.test("Swift test")
        
        installedApplistTableView.delegate = self
        installedApplistTableView.dataSource = self
        installedApplistTableView.register(UINib.init(nibName: cellID, bundle: nil), forCellReuseIdentifier: cellID)

        self.iconDataView.isHidden = true
        self.textField.isHidden = true
        self.textField.delegate = self

        SDKTest.appsData
            .observeOn(MainScheduler.instance)
            .subscribe(onNext : { [weak self] (mode:DisplayMode) in
                self!.displayMode = mode
                self!.modeChanged();
                self!.installedApplistTableView.reloadData()
            })
            .addDisposableTo(disposeBag)
        
        SDKTest.iconData
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
        SDKTest.close();
        super.viewWillDisappear(animated)
    }
    
    open func modeChanged() {
        switch displayMode {
        case .chatmode:
            textField.isHidden = false
        case .connectionfail:
            let alert = UIAlertController(title: "Connection Fail", message: "Application is not installed on this TV", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            self.displayMode = .tvlist
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
            SDKTest.launchApp(index)
            selectedIndex = nil
        }
        self.iconDataView.isHidden = true
    }
    
    @IBAction func closeBtnClicked(_ sender: UIButton) {
        self.iconDataView.isHidden = true
    }
    
//    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//
//        let touch : UITouch = (event?.allTouches()?.first)!
//        if (textField.isFirstResponder() && touch.view != textField) {
//            textField.resignFirstResponder()
//        }
//        super.touchesBegan(touches, withEvent: event)
//    }
}

extension SDKTestViewController: UITableViewDelegate,UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        switch displayMode {
            case .applist:
                SDKTest.getAppImage((indexPath as NSIndexPath).row)
                selectedIndex = (indexPath as NSIndexPath).row
                break
            case .tvlist:
                SDKTest.connectToTV((indexPath as NSIndexPath).row)
                break
            case .chatmode:
                //TODO
                break
            default:
                break
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        
        var returnValue : Int = 0
        switch displayMode {
        case .applist:
            if let ret = SDKTest.installedAppsData?.count{
                returnValue = ret
            }
            break
        case .tvlist:
            returnValue = SDKTest.getDiscoveredTVCount()
            break
        case .chatmode:
            //TODO
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
                if let appName = SDKTest.getAppName((indexPath as NSIndexPath).row){
                    cell.textLabel?.text = appName
                }
                break
            case .tvlist:
                if let appName = SDKTest.getDiscoveredTVName((indexPath as NSIndexPath).row){
                    cell.textLabel?.text = appName
                }
                break
            case .chatmode:
                //TODO
                break
            default:
                break
        }
        return cell
    }
}

extension SDKTestViewController : UITextFieldDelegate {
    public func textFieldDidEndEditing(_ textField: UITextField) {
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        if (textField.text != "")
        {
            Log.test("Text Send - \(textField.text)")
            SDKTest.sendData(textField.text!)
        }
        return true
    }
}
