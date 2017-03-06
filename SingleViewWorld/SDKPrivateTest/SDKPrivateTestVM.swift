#if PRIVATE_SDK
//
//  SDKPrivateTestViewModel.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 7/20/16.
//  Copyright © 2016 samsung. All rights reserved.
//
    
import UIKit
import SmartView
import RxSwift
import Alamofire

public enum privateDisplayMode {
    case unknown
    case tvlist
    case applist
    case connectionfail
}

class SDKPrivateTestVM{

    let queue = DispatchQueue.global(qos: .userInteractive)
    let serviceSearch = Service.search()
    var deviceIp : String? = nil
    var serviceChannel : Channel? = nil
    var installedAppsData : [[String:Any]]? = nil
    //var discoveredTV : [privateTVInfo] = []
    var savedMessage : [String] = []
    var application : Application? = nil
    var remote : RemoteControl? = nil
    let TargetTV :String = "[TV] Bed room"
    
    fileprivate let appsDataSubject = BehaviorSubject<privateDisplayMode>(value: .unknown)
    internal var appsData: Observable<privateDisplayMode> {
        return appsDataSubject.asObservable()
    }
    
    fileprivate let iconDataSubject = BehaviorSubject<Data?>(value: nil)
    internal var iconData: Observable<Data?> {
        return iconDataSubject.asObservable()
    }
    
    var services = [Service]()
    
    init() {
        serviceSearch.delegate = self
        serviceSearch.start()
        //serviceSearch.startUsingBLE()
    }
    
    func close(){
        serviceSearch.stop()
        serviceSearch.delegate = nil
        serviceChannel?.disconnect()
        serviceChannel?.delegate = nil
        remote?.disconnect()
        remote?.delegate = nil
        application?.disconnect()
        application?.delegate = nil
        disconnectTV()
    }
    
    fileprivate func processInstalledApp(){
        for appNames in installedAppsData! {
            let appName = appNames["name"] as! String
            Log.test("\(appName)")
        }
    }
    
    func launchApp(_ index:Int) {
        if let appDatas = installedAppsData?[index-1] {
            let urlString : String = "http://\(deviceIp!):8001/api/v2/applications/\(appDatas["appId"] as! String)"
            //let urlString : String = "http://\(deviceIp!):8001/api/v2/applications/EdenViewingTile_11101200001"
            
            let url = URL(string: urlString)
            Log.test("request url : \(urlString)")
            
            Alamofire.request(url! , method: .post, parameters: nil, encoding: JSONEncoding.default, headers: nil)
                .response(completionHandler: { (data) in
                //
            })
            
        }
    }
    
    func getAppName(_ index:Int) -> String? {
        let appData = installedAppsData?[index-1]
        return appData?["name"] as? String
    }
    
    func getDiscoveredTVName(_ index:Int) -> String? {
        let service = services[index] as Service
        return service.name as String
    }
    
    func getDiscoveredTVCount() -> Int {
        return services.count
    }
    
    func connectToTV(_ index:Int){

        serviceSearch.stop()
        serviceSearch.delegate = nil
        
        let service = services[index]
        service.getDeviceInfo(5, completionHandler:{ (discoveryRecord, error) -> Void in

            if  let deviceInfo = discoveryRecord?["device"] as? [String:AnyObject],
                let ip = deviceInfo["ip"] as? String
            {
                self.deviceIp = ip
            }
        })

        /*
            createChannel
         */
        //self.serviceChannel = service.createChannel(self.channelId)
        //self.serviceChannel?.delegate = self
        //self.serviceChannel?.setSecurityMode(security: false, completionHandler: { (isSecure, error) in
        //    self.serviceChannel?.connect()
        //})
        
        
        /*
            createRemoteControl
        */
        self.remote = service.createRemoteControl()
        self.remote?.delegate = self
        self.remote?.setSecurityMode(security: false, completionHandler: { (isSecure, error) in
            self.remote?.connect()
        })
        
        /*
            createApplication
        */
        // let dic : Dictionary  = ["userID":"idTest", "userPW":"1234"]
        //do{
        //    let data = try JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
        //    let final : [String : AnyObject] = ["id" : String.init(data: data, encoding: String.Encoding.utf8)! as AnyObject]
        //    Log.test("createApplication with \(final)")
        //    application = service.createApplication(appId as AnyObject, channelURI: channelId, args: final)
        //} catch {
        //    print("JSON Error : \(error)")
        //}
        //application!.delegate = self
        //application!.connectionTimeout = 5
        //
        //let attr : [String:String] = ["name" : UIDevice.current.name]
        //application!.connect(attr)
    }
    
    func disconnectTV() {
        application?.disconnect({ (err) in
            Log.test("disconnect error:\(err)")
        })
    }
    
    func getAppImage(_ index:Int) {
        
        if let appData = installedAppsData?[index-1] {
            let imageURI = appData["icon"] as! String
            let dic = ["iconPath":imageURI]
            print("fetching icon \(imageURI)")
            //serviceChannel!.publish(event: "ed.apps.icon", message: dic as AnyObject?, target: MessageTarget.Host.rawValue as AnyObject)
            remote?.publishEden(event: "ed.apps.icon", message: dic as AnyObject?)
            //application?.publish(event: "ed.apps.icon", message: dic as AnyObject?, target: MessageTarget.Host.rawValue as AnyObject)
        }
    }
    
    
    func sendData(_ msg : String) {
        //let message : [String : AnyObject] = ["msg" : msg as AnyObject]
        //application?.publish(event:"fireMissile", message: message as AnyObject?)
    }
}


extension SDKPrivateTestVM : RemoteControlDelegate {
    
    @objc func onInputStart(_ inputType: IMEInputType){
    }
    
    @objc func onInputEnd(){
    }

    @objc func onInputSync(_ text: String){
    }

    @objc func onPointerEnabled(_ enabled: Bool){
    }

    @objc func onConnect(_ error: NSError?){
        Log.test("onConnect - \(error)")
        if error != nil {
            self.appsDataSubject.onNext(.connectionfail)
        } else {
            //serviceChannel?.publish(event: "ed.installedApp.get", message: nil, target: MessageTarget.Host.rawValue as AnyObject)
            remote?.publishEden(event: "ed.installedApp.get", message: nil)
            //application?.publish(event: "ed.installedApp.get", message: nil, target: MessageTarget.Host.rawValue as AnyObject)
        }
    }

    @objc func onDisconnect(_ error: NSError?){
        Log.test("onDisconnect - \(error)")
    }

    @objc func onVoiceAppChange(_ status: VoiceAppStatus){
    }
    
    @objc func onMessage(_ payload: Any, event: String) {
        Log.test("\(event)")
        switch event {
        case "ed.installedApp.get":
            if let data = payload as? [String:AnyObject] {
                queue.async {
                    if let mesData = data["data"] as? [[String:Any]]{
                        self.installedAppsData = mesData
                    }
                    self.appsDataSubject.onNext(.applist)
                }
            }
            break
        case "ed.apps.icon":
            if let data = payload as? [String:AnyObject], let _ = data["iconPath"] as? String {
                queue.async {
                    if let imageData = data["imageBase64"] as? String {
                        let appIconData = Data(base64Encoded: imageData, options: .ignoreUnknownCharacters)
                        self.iconDataSubject.onNext(appIconData)
                    }
                }
            } else {
                self.iconDataSubject.onNext(nil)
            }
            break
        case "ed.edenApp.get":
            break
        case "say":
            savedMessage.append(payload as! String)
            break;
        case "fireMissile":
            Log.test("fireMissile-\(payload)")
        default:
            break
        }
    }
}


extension SDKPrivateTestVM : ChannelDelegate{
    
    @objc internal func onConnect(_ client: SmartView.ChannelClient?, error: NSError?){
        Log.test("onConnect - \(error)")
        if error != nil {
            self.appsDataSubject.onNext(.connectionfail)
        } else {
            //serviceChannel?.publish(event: "ed.installedApp.get", message: nil, target: MessageTarget.Host.rawValue as AnyObject)
            remote?.publishEden(event: "ed.installedApp.get", message: nil)
            //application?.publish(event: "ed.installedApp.get", message: nil, target: MessageTarget.Host.rawValue as AnyObject)
        }
    }
    @objc internal func onReady(){}
    @objc internal func onDisconnect(_ client: SmartView.ChannelClient?, error: NSError?){
        Log.test("onDisconnect")
        self.appsDataSubject.onNext(.tvlist)
    }
    @objc internal func onMessage(_ message: SmartView.Message){
        Log.test("\(message.event)")
        switch message.event {
        case "ed.installedApp.get":
            if let data = message.data {
                queue.async {
                    if let mesData = data["data"] as? [[String:Any]]{
                        self.installedAppsData = mesData
                    }
                    self.appsDataSubject.onNext(.applist)
                }
            }
            break
        case "ed.apps.icon":
            if let data = message.data as? [String:AnyObject], let _ = data["iconPath"] as? String {
                queue.async {
                    if let imageData = data["imageBase64"] as? String {
                        let appIconData = Data(base64Encoded: imageData, options: .ignoreUnknownCharacters)
                        self.iconDataSubject.onNext(appIconData)
                    }
                }
            } else {
                self.iconDataSubject.onNext(nil)
            }
            break
        case "ed.edenApp.get":
            break
        case "say":
            savedMessage.append(message.data as! String)
            break;
        case "fireMissile":
            Log.test("fireMissile-\(message.data)")
        default:
            break
        }
    }
    @objc internal func onData(_ message: SmartView.Message, payload: Data){
        Log.test("onData")
        Log.test("data is \(message.data) from \(message.from) with payload \(payload)")
    }
    @objc internal func onClientConnect(_ client: SmartView.ChannelClient){
        Log.test("onClientConnect")
    }
    @objc internal func onClientDisconnect(_ client: SmartView.ChannelClient){
        Log.test("onClientDisconnect")
    }
    @objc internal func onError(_ error: NSError){
        Log.test("onError \(error)")
    }
}

extension SDKPrivateTestVM : ServiceSearchDelegate {
    
    @objc internal func onServiceFound(_ service: SmartView.Service) {
        Log.test("onServiceFound - \(service.name)")
        services.append(service)
        self.appsDataSubject.onNext(.tvlist)
    }
    
    @objc internal func onServiceLost(_ service: SmartView.Service) {
        Log.test("onServiceLost - \(service)")
    }
    
    @objc internal func onStop() {
        Log.test("onStop")
    }
    
    @objc internal func onStart() {
        Log.test("onStart")
    }
    
    @objc internal func onFoundOnlyBLE(_ NameOfTV: String) {
        Log.test("onFoundOnlyBLE : \(NameOfTV)")
    }
}
    
#endif
