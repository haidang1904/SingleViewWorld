/*

Copyright (c) 2014 Samsung Electronics

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

import Foundation


public typealias GetServiceCompletionHandler = (_ service: Service?, _ error: NSError? ) -> Void

///  A Service instance represents the multiscreen service root on the remote device
///  Use the class to control top level services of the device
///
@objc open class Service : NSObject
{
    fileprivate var discoveryRecord: [String:AnyObject]

    internal var transportType: ChannelTransportType

    internal var providers = NSMutableSet()
    
    //Discovery Type LAN/BLE
    open internal(set) var discoveryType = ServiceSearchDiscoveryType.LAN
    
    private enum SecureModeState: String
    {
        case Unknown
        case NotSupported
        case Supported
    }
    
    private var isSecureModeSupported : SecureModeState = SecureModeState.Unknown
    private let TV_YEAR_15 = 15
    
    static var isWoWAndConnectStarted:Bool = false
    static let DEFAULT_WOW_TIMEOUT_VALUE:TimeInterval = 6
    
    internal var mediaPlayer: MediaPlayer? = nil
    
    /// The id of the service
    open var id: String
    {
        return discoveryRecord["id"] as! String
    }

    /// The uri of the service (http://<ip>:<port>/api/v2/)
    open var uri: String
    {
        return discoveryRecord["uri"] as! String
    }

    /// The name of the service (Living Room TV)
    open var name: String
    {
        return discoveryRecord["name"] as! String
    }

    /// The version of the service (x.x.x)
    open var version: String
    {
        return discoveryRecord["version"] as! String
    }

    /// The type of the service (Samsung SmartTV)
    open var type: String
    {
        return (discoveryRecord["device"] as! [String:AnyObject])["model"] as! String
    }
    
    open var voiceControlSupported: Bool
    {
        if  let deviceInfo = discoveryRecord["device"] as? [String:AnyObject],
            let voiceSupport = deviceInfo["VoiceSupport"] as? String
        {
            return NSString(string: voiceSupport).boolValue
        }
        
        return false
    }
    
    
    open var gamePadSupported: Bool
    {
        if  let deviceInfo = discoveryRecord["device"] as? [String:AnyObject],
            let gamepadSupport = deviceInfo["GamePadSupport"] as? String
    {
            return NSString(string: gamepadSupport).boolValue
        }
        
        return false
    }
    
    open var smartHubAgreement: Bool
    {
        if  let deviceInfo = discoveryRecord["device"] as? [String:AnyObject],
            let smartHubAgreement = deviceInfo["smartHubAgreement"] as? String
        {
            return NSString(string: smartHubAgreement).boolValue
        }
        
        return false
    }
    
    open var edenSupported: Bool
    {
        if  let deviceInfo = discoveryRecord["isSupport"] as? String
        {
            return deviceInfo.contains("EDEN_available")
        }
        return false
    }
    
    open var countryCode: String?
    {
        return (discoveryRecord["device"] as! [String:AnyObject])["countryCode"] as? String
    }
    
    /// The service description
    override open var description: String
    {
        return "\(type(of: self)): { id: \(id), name: \(name), version: \(version) }"
    }

    /// Initializer
    ///
    internal init(txtRecordDictionary: [String:AnyObject])
    {
        discoveryRecord = txtRecordDictionary
        //    device = nil
        transportType = ChannelTransportType.webSocket
    }

    /**
     This asynchronously method retrieves a dictionary of additional information about the device the service is running on
     
       - parameter timeout: timeout
     
       - parameter completionHandler: A block to handle the response dictionary
     
          - deviceInfo: The device info dictionary
          - error: An error info if getDeviceInfo failed
     */
    
    open func getDeviceInfo(_ timeout: Int, completionHandler: @escaping (_ deviceInfo: [String:AnyObject]?, _ error: NSError?) -> Void )
    {
        let doGetCompletionHandler : RequestCompletionHandler = { (responseHeaders: [String:String]?, data: Data?, error: NSError?)  in

            if error != nil {
                completionHandler(nil, error)
            } else {
                let jsonResult : [String:AnyObject]?
                
                do{
                    jsonResult = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:AnyObject]
                    completionHandler(jsonResult, error)
                } catch {
                    Log.error("\(error)")
                }
            }
        }
        Requester.doGet(uri, headers: [:] , timeout: TimeInterval(timeout), completionHandler: doGetCompletionHandler)
    }

    /**
       Creates an application instance belonging to that service
     
       - parameter id: The id of the application
     
            - For an installed application this is the string id as provided by Samsung, If your TV app is still in development, you can use the folder name of your app as the id. Once the TV app has been released into Samsung Apps, you must use the supplied app id.`
            - For a cloud application this is the application's URL
     
       - parameter channelURI: The uri of the Channel ("com.samsung.multiscreen.helloworld")
     
       - parameter args: A dictionary of command line aruguments to be passed to the Host TV App
       - returns: An Application instance or nil if application id or channel id is empty
     
     */
    open func createApplication(_ id: AnyObject, channelURI: String, args: [String:AnyObject]?) -> Application?
    {
        if channelURI.isEmpty
        {
            return nil;
        }
        
        switch id
        {
            case _ as URL:
                break
            
            case let id as String:
                if id.isEmpty
                {
                    return nil;
                }
            
            default:
                return nil
        }

        return Application(appId: id, channelURI: channelURI, service: self, args: args)
    }

    /**
       Creates a channel instance belonging to that service ("mychannel")
     
       - parameter `: The uri of the Channel ("com.samsung.multiscreen.helloworld")
     
       - returns: A Channel instance
     */
    open func createChannel(_ channelURI: String) -> Channel
    {
        return Channel(uri: channelURI , service: self)
    }
    
    /// Creates remote control for the device represented by the service
    ///
    ///  - returns: A RemoteControl instance or nil if the service does not support Remote Control API
    ///
    open func createRemoteControl() -> RemoteControl?
    {
        if let remoteVersion = self.discoveryRecord["remote"] as? String
        {
            if !remoteVersion.hasPrefix("0")
            {
                let remoconChannel = RemoteControlChannel(uri: "samsung.remote.control", service: self)
                return RemoteControl(channel: remoconChannel)
            }
        }
        
        return nil
    }

    /// Creates Gamepad Control for the device represented by the service
    ///
    ///  - returns: A GamepadControl instance to support API
    ///
	open func createGamepadControl() -> GamepadControl?
    {
        let gameChannel = GamepadControlChannel(uri: "samsung.gamepad.control", service: self)
        return GamepadControl(channel: gameChannel)
    }
    

     /**
     Creates media player instance if not yet created
     
     - parameter appName:
     
     - returns: mediaPlayer instance
     */
    internal func createMediaPlayer(_ appName : String) -> MediaPlayer
    {
        if mediaPlayer == nil
        {
            mediaPlayer = MediaPlayer(service: self, appName: appName)
        }
        
        return mediaPlayer!
    }
    
    /**
     Creates video player instance
     
     - parameter appName:
     
     - returns: VideoPlayer instance
     */
    open func createVideoPlayer(_ appName : String) -> VideoPlayer
    {
        return VideoPlayer(mediaplayer: createMediaPlayer(appName))
    }
    
    /**
     Creates audio player instance
     
     - parameter appName:
     
     - returns: AudioPlayer instance
     */
    open func createAudioPlayer(_ appName : String) -> AudioPlayer
    {
        return AudioPlayer(mediaplayer: createMediaPlayer(appName))
    }
    /**
     Creates photo player instance
     
     - parameter appName:
    
     - returns: PhotoPlayer instance
     */
    open func createPhotoPlayer(_ appName : String) -> PhotoPlayer
    {
        return PhotoPlayer(mediaplayer: createMediaPlayer(appName))
    }

    //MARK: - class methods -
    /**
       Creates a service search object
     
       - returns: An instance of ServiceSearch
     
     */
    open class func search() -> ServiceSearch
    {
        return ServiceSearch()
    }

    /**
       This asynchronous method retrieves a service instance given a service URI
     
       - parameter uri: The uri of the service
       - parameter timeOut:
       - parameter completionHandler: The completion handler with the service instance or an error
            - service: The service instance
            - timeout: The timeout for the request
            - error: An error info if getByURI fails
     */
    open class func getByURI(_ uri: String, timeout: TimeInterval, completionHandler: @escaping (_ service: Service?, _ error: NSError? ) -> Void)
    {
        let doGetCompletionHandler : RequestCompletionHandler =
        { (responseHeaders: Dictionary<String,String>?, data: Data?, error: NSError?) in
        
            if error != nil
            {
                completionHandler(nil, error)
            }
            else
            {
                if let jsonResult: [String:AnyObject] = JSON.parse(data: data!)  as? [String:AnyObject]
                {
                    let service = Service(txtRecordDictionary: jsonResult)
                    completionHandler(service, error)
                }
                else
                {
                    completionHandler(nil, error)
                }
            }
        }

        Requester.doGet(uri, headers: [:] , timeout: timeout, completionHandler: doGetCompletionHandler)
    }

    
    /**
       This asynchronous method retrieves a service instance given a service id
     
       - parameter id: The id of the service
       - parameter completionHandler: The completion handler with the service instance or an error
            - service: The service instance
            - error: An error info if getById fails
     */
    open class func getById(_ id: String, completionHandler: @escaping (_ service: Service?, _ error: NSError? ) -> Void)
    {
        var findObserver: AnyObject!
        var stopObserver: AnyObject!
        let search = ServiceSearch(id: id)
        
        stopObserver = search.on(MSDidStopSearch, performClosure:
        { (notification) -> Void in
        
            search.off(findObserver)
            search.off(stopObserver)
            // important - break ownership cycle to make sure completionHandler provided by client does not have to take care about 'self' capturing
            findObserver = nil
            stopObserver = nil
            
            let searchError = NSError(domain: "Service Search Error", code: -1, userInfo: [NSLocalizedDescriptionKey:"Operation timeout"])
            completionHandler(nil, searchError)
        })
        
        findObserver = search.on(MSDidFindService, performClosure:
        { (notification) -> Void in
        
            search.off(findObserver)
            search.off(stopObserver)
            // important - break ownership cycle to make sure completionHandler provided by client does not have to take care about 'self' capturing
            findObserver = nil
            stopObserver = nil
            
            let error: NSError? = (notification! as NSNotification).userInfo?["error"] as? NSError
            let service: Service? = (notification! as NSNotification).userInfo?["service"] as? Service
            completionHandler(service, error)
        })
        
        search.start()
    }
    
    /**
      Retrieve the Mac converted to Bytes.
     
      - parameter macAddr: Mac Address of TV
     
      - returns: Mac Address converted to Bytes
     */
    
    class func convertMacAddrToBytes(_ macAddr:NSString) ->[Int8]
    {
        let arr = macAddr.components(separatedBy: ":")
        
        var macAddressByte = [Int8](repeating: 0, count: 6)
        
        for (index, value) in arr.enumerated() {
            let hex = Int8(bitPattern: UInt8(value, radix:16)!)
            macAddressByte[index] = hex
        }
        
        return macAddressByte
    }

    /**
      Send a packet for WakeUpAndConnect.
     
      - parameter uri: the uri of service
      - parameter service: The service instance
      - parameter error: An error info if getByURI fails
     */
    class func WakeUpAndConnect(_ uri:String, completionHandler: @escaping (_ service:Service?, _ error:NSError?) -> Void)
    {
        Service.getByURI(uri, timeout: 2, completionHandler: { (service, error) -> Void in

            if(service != nil)
            {
                isWoWAndConnectStarted = false
                completionHandler(service, error)
                
            }
            else
            {
                if(isWoWAndConnectStarted)
                {
                    WakeUpAndConnect(uri, completionHandler: {(nservice, error) -> Void in
                        
                        completionHandler(nservice, error)
                    })
                }
                else
                {
                    isWoWAndConnectStarted = false
                    completionHandler(service, error)
                    
                }
            }
            })
    }
    
    
    /**
      Send a packet for WakeOnWirelessLan.
     
      - parameter macAddr: Mac Address of TV
     */
    
    open class func WakeOnWirelessLan(_ macAddr:String)
    {
        
        let magicPacketId:NSString = "FF:FF:FF:FF:FF:FF";
        let broadCastAddr:String = "255.255.255.255";
       // let wakeUpIdentifier = "SECWOW";
       // let secureOn:NSString = "00:00:00:00:00:00";
     
        
        let packetSizeAlloc = 102;
        var var17 = packetSizeAlloc + 6;
        var17 += 12;
        
        
        // converting magic packet to bytes
        var tmpList = convertMacAddrToBytes(magicPacketId)
        let data = NSMutableData(bytes: tmpList, length: tmpList.count)
        
        // converting MAC to byte
        tmpList = convertMacAddrToBytes(macAddr as NSString)
       
        for _ in 1...16
        {
            data.append(tmpList, length: tmpList.count)
        }
        
        let length:Int = data.length
        print("data length\(length)")
        
//        let udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global(priority: 0))
        let udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global(qos: .background))
        
        var error: NSError? = nil
        
        do {
            try udpSocket!.enableBroadcast(true)
        } catch let error1 as NSError {
            error = error1
            Log.error("udpSearchSocket  bindToPort \(error)")
        } catch {
            Log.error("udpSearchSocket  bindToPort: unknown error")
            return
        }
        
        do {
            try udpSocket!.beginReceiving()
        } catch let error1 as NSError {
            error = error1
            Log.error("udpSearchSocket  begin Receiving \(error)")
        } catch {
            Log.error("udpSearchSocket  begin Receiving")
            return
        }
        
        udpSocket!.setIPv4Enabled(true)
        udpSocket!.setIPv6Enabled(false)
        
        udpSocket?.send(data as Data!, toHost: broadCastAddr, port: 2016, withTimeout: 1, tag: 1)
    }
    
    /**
     Update isWoWAndConnectStarted to false
     */
   class func updateWOWAndConnectStarted()
    {
        isWoWAndConnectStarted = false
    }
    
    /**
      Send a packet via WakeOnWirelessLan and create and connect to particular appilcation
     
      - parameter macAddr: Mac Address of TV
      - parameter uri: The uri of service
      - parameter service: The service instance
      - parameter error: An error info if getByURI fails
     */
    open class func WakeOnWirelessAndConnect(_ macAddr:String, uri:String, completionHandler: @escaping (_ service:Service? , _ error: NSError? ) -> Void) -> Void
    {
        WakeOnWirelessAndConnect(macAddr,  uri: uri, timeOut: DEFAULT_WOW_TIMEOUT_VALUE, completionHandler: {(service, error) -> Void in
            
            completionHandler(service,  error)
        })
    }
    
    /**
      Send a packet via WakeOnWirelessLan and create and connect to particular appilcation
     
      - parameter macAddr: Mac Address of TV
      - parameter uri: The uri of service
      - parameter timeOut: timeout to wakeup
      - parameter service: The service instance
      - parameter error: An error info if getByURI fails
     */
    open class func WakeOnWirelessAndConnect(_ macAddr:String, uri:String, timeOut:TimeInterval ,completionHandler: @escaping (_ service:Service? , _ error: NSError? ) -> Void) -> Void
    {
        if (isWoWAndConnectStarted)
        {
            return
        }
        isWoWAndConnectStarted = true
        
        if(macAddr.characters.count == 0)
        {
            return
        }
        
        WakeOnWirelessLan(macAddr)
        
        // wake up and connect
        WakeUpAndConnect(uri, completionHandler: {(service, error) -> Void in
            
            completionHandler(service,  error)
        })
        
      Timer.scheduledTimer(timeInterval: timeOut, target: self, selector: #selector(Service.updateWOWAndConnectStarted), userInfo: nil, repeats: false)
        
    }

    
    open func isSecurityModeSupported(completionHandler: @escaping (_ isSupport:Bool, _ error:NSError?) -> Void)
    {
        
        // let test:Bool = Requester.installRootCertificate()
        
        //print("test is\(test)")
        
        if(isSecureModeSupported == SecureModeState.Unknown)
        {
            self.getDeviceInfo(5, completionHandler:
                { (deviceInfo, error) -> Void in
                    
                    if(error != nil)
                    {
                        completionHandler(false, error!)
                    }
                    else
                    {
                        let device = deviceInfo!["device"]
                        let model = device!["model"] as? NSString
                        
                        let yearStr = model?.substring(with: NSRange(location: 0, length: 2))
                        
                        let year =  Int(yearStr!)
                        
                        if(year! >= self.TV_YEAR_15)
                        {
                            self.isSecureModeSupported = SecureModeState.Supported
                            completionHandler(true, error)
                        }
                        else
                        {
                            
                            self.isSecureModeSupported = SecureModeState.NotSupported
                            completionHandler(false, error)
                        }
                    }
            })
        }
    }
}
// MARK: - Service (Internal)

extension Service
{
    internal var host: String
    {
        if  let serviceURL = URL(string: self.uri),
            let host = serviceURL.host
        {
            return host
        }
        
        return "0.0.0.0"
    }
}
public func == (lhs: Service, rhs: Service) -> Bool {
    return lhs.id == rhs.id && lhs.discoveryType == rhs.discoveryType
}
