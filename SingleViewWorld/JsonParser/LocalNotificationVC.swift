//
//  LocalNotificationVC.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 21/11/2016.
//  Copyright © 2016 samsung. All rights reserved.
//

import UIKit
import Darwin
import UserNotifications

@objc open class LocalNotificationVC: UIViewController {

    var timer : Timer? = nil
    
    @IBOutlet weak var getBtn: UIButton!
    @IBOutlet weak var timeLabel: UILabel!

    
    override open func viewDidLoad() {
        super.viewDidLoad()

        timeLabel.text = ""
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(printCurrentTime), userInfo: nil, repeats: true)
        // Do any additional setup after loading the view.
        
        if #available(iOS 10.0, *) {
            let noti = UNUserNotificationCenter.current()
            noti.requestAuthorization(options: [.alert, .sound, .badge]) { (res, error) in
                Log.test("UNUserNotificationCenter is \(res)")
            }
        } else {
            // Fallback on earlier versions
        }

    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.getPendingNotificationRequests(completionHandler: { (notis) in
                Log.test("viewWillDisappear current reserved notification is \(notis.count)")
            })
        } else {
            // Fallback on earlier versions
        }
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func getBtnAction(_ sender: UIButton) {
    
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()
            content.title = NSString.localizedUserNotificationString(forKey: "Elon said:", arguments: nil)
            content.body = NSString.localizedUserNotificationString(forKey: "Hello Tom！Get up, let's play with Jerry!", arguments: nil)
            content.sound = UNNotificationSound.default()
            content.badge = UIApplication.shared.applicationIconBadgeNumber as NSNumber?;
            content.categoryIdentifier = "com.elonchan.localNotification"
            // Deliver the notification in five seconds.
            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 10.0, repeats: false)
            Log.test("trigger.nextTriggerDate() is \(trigger.nextTriggerDate())")
            let request = UNNotificationRequest.init(identifier: "FiveSecond", content: content, trigger: trigger)
            
            // Schedule the notification.
            Log.test("Set Local Notification after 1 minute!!!")
            let center = UNUserNotificationCenter.current()
            center.add(request)
            center.getPendingNotificationRequests(completionHandler: { (notis: [UNNotificationRequest]) in
                for noti in notis {
                    
                    
                    Log.test("\(notis.count)")
                    Log.test("\(noti.identifier)")
                    

                }
                
            })
        } else {
            // Fallback on earlier versions
        }

    }
    
    @objc func printCurrentTime() {
        let now = Date.init()
        let dateformatter = DateFormatter.init()
        dateformatter.dateFormat = "YYYY년MM월dd일 hh:mm:ss"
        dateformatter.timeZone = TimeZone.current
        timeLabel.text = dateformatter.string(from: now)
    }

}
