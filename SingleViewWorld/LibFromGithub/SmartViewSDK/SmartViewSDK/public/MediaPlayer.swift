/*

Copyright (c) 2015-2016 Samsung Electronics

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


private let kPlayerControlCommand = "playerControl"
private let kChangeContentCommand = "changeContent"
private let kPlayerNoticeEventName = "playerNotice"
private let kPlayerOnConnectError = "kPlayerOnConnectError"
private let kPlayerOnDisconnectError = "kPlayerOnDisconnectError"

private let kMediaPlayer = "media_player"
private let kRunning = "running"
private let kId = "id"
private let kAppVisible = "visible"

private let kPlayerId = "3201412000694"
private let DEFAULT_MEDIA_PLAYER = "samsung.default.media.player"

private let PROPERTY_ISCONTENTS = "isContents"

private let DUMMY_URL_FOREGROUND = "http://DummyUrlToBringAppToForeground.msf"

/// This class is wrapper which handle tv media calls.
/// its basic functionality is to launch DMP on TV and whatever notification comes from TV side it passes on to further module.
@objc open class MediaPlayer: NSObject
{
    /**
    *  Namespace for constants that describe notices from media player on TV.
    */
    public struct PlayerNotice
    {
        /// Player state key
        public static let PlayerStateKey = "state"
        /// Video state key
        public static let VideoStateKey = "Video State"
        /// Error key
        public static let ErrorKey = "error"
        /**
        *  Possible values for PlayerStateKey ("state").
        */
        public struct PlayerState
        {
            public static let Play = "play"
            public static let Pause = "pause"
            public static let Stop = "stop"
            public static let Mute = "mute"
            public static let Unmute = "unMute"
            public static let FF = "ff"
            public static let RWD = "rwd"
            public static let SeekTo = "seekTo"
            public static let SetVolume = "setVolume"
        }
        
        /**
         * Possible values for VideoStateKey ("Video State").
           Some of the values are just prefixes for actual values, e.g. CurrentPlayTime is prefix for "currentplaytime:322".
        */
        public struct VideoState
        {
            public static let StreamCompleted = "streamcompleted"
            public static let CurrentPlayTime = "currentplaytime"
            public static let TotalDuration = "totalduration"
            public static let BufferingStart = "bufferingstart"
            public static let BufferingProgress = "bufferingprogress"
            public static let BufferingComplete = "bufferingcomplete"
            public static let VideoIsCued = "Video is cued"
        }
    }
    /**
     This has different player properties
    
     - CONTENT_URI:                  uri
     - PLAYER_NOTICE_RESPONSE_EVENT: Player Notice
     - PLAYER_TYPE:                  Player Type
     - PLAYER_DATA:                  Player data
     - PLAYER_SUB_EVENT:             Player sub event
     - PLAYER_READY_SUB_EVENT:       Player ready sub event
     - PLAYER_CHANGE_SUB_EVENT:      Player change sub event
     - PLAYER_CONTROL_EVENT:         Player control event
     - PLAYER_CONTENT_CHANGE_EVENT:  Player content change event
     - PLAYER_QUEUE_EVENT:           Player queue event
     - PLAYER_CURRENT_PLAYING_EVENT: Player current playing event
     - PLAYER_ERROR_MESSAGE_EVENT:   Player eror message as event
     - PLAYER_APP_STATUS_EVENT:      Player app status as event
     */
    internal enum PlayerProperty: String
    {
        case CONTENT_URI                           = "uri"
        case PLAYER_NOTICE_RESPONSE_EVENT          = "playerNotice"
        case PLAYER_TYPE                           = "playerType"
        case PLAYER_DATA                           = "data"
        case PLAYER_SUB_EVENT                      = "subEvent"
        case PLAYER_READY_SUB_EVENT                = "playerReady"
        case PLAYER_CHANGE_SUB_EVENT               = "playerChange"
        case PLAYER_CONTROL_EVENT                  = "playerControl"
        case PLAYER_CONTENT_CHANGE_EVENT           = "playerContentChange"
        case PLAYER_QUEUE_EVENT                    = "playerQueueEvent"
        case PLAYER_CURRENT_PLAYING_EVENT          = "currentPlaying"
        case PLAYER_ERROR_MESSAGE_EVENT            = "error"
        case PLAYER_APP_STATUS_EVENT               = "appStatus"
    }
    /**
     Different Player notifications (errors and messages)
    
     - onConnectError:    Connection Error
     - onDisconnectError: Disconnection Error
     - onMessage:         Message
     */
    internal enum PlayerNotification: String
    {
        case onConnectError                 = "onConnectError"
        case onDisconnectError              = "onDisconnectError"
        case onMessage                      = "onMessage"
        case onClientConnect                = "onClientConnect"
        case onClientDisconnect             = "onClientDisconnect"
        case onError                        = "onError"
        case onReady                        = "onReady"
    }    
    
    /**
     *  This struct lists possible status of a DMP player
     */
    internal struct DMPStatus
    {
        var visible:Bool = false
        var dmpRunning:Bool = false
        var running:Bool = false
        var appName:String
    }
    
    ///TV service name
    open fileprivate(set) var service: Service
    
    /// Application Connection Status with TV.
    open fileprivate(set) var connected: Bool = false
    
    fileprivate var application: Application
    
    fileprivate var appRunning: Bool = false
    
    fileprivate var appName:String?
    
    internal var playerContentType: String?
    
    /**
     Needs to be called from the service class. initialization method.     

     - parameter service:service name
     - parameter appName: app name
     */
    internal init(service: Service, appName : String)
    {
        // use placeholder URL to create application object of WebApplication type
        self.application = service.createApplication(URL(string: "http://example.com")! as AnyObject, channelURI: DEFAULT_MEDIA_PLAYER, args: nil)!
        self.service = service
        self.appName = appName
        
        super.init()
        
        self.application.delegate = self
    }
    
//MARK: Need to remove method
    fileprivate func playContent(_ contentURL: URL, completionHandler: ((NSError?) -> Void)? = nil)
    {
        guard self.connected else { return }
        
        self.application.getInfo(
            { (info, error) -> Void in
                if error == nil
                {
                    
                    if(info![kMediaPlayer] as? Bool == true && info![kRunning] as? Bool == true && info![kId] as? String == kPlayerId)
                    {
                        self.application.publish(event: kChangeContentCommand, message: contentURL.absoluteString as AnyObject?)
                    }
                    else
                    {
                        self.application.startPlay(contentURL, completionHandler:
                            { (success, error) -> Void in
                                
                                completionHandler?(error)
                        })
                    }
                }
                else
                {
                    //Error
                }
        })
    }
    
//MARK: Methods to communicate with Application class
    /**
     Connects to the channel. This method will asynchronously call the delegate's onConnect method and post a
     ChannelEvent.Connect notification upon completion.
     When a TV application connects to this channel, the onReady method/notification is also fired
    
    - parameter completionHandler: call back handler
    */
    internal func connect(_ completionHandler: ((_ error: NSError?) -> Void)? = nil)
    {
        self.application.connectChannelOnly(nil, completionHandler:
            { (client, error) -> Void in
                
                if client != nil
                {
                    self.connected = true
                }
                
                completionHandler?(error)
        })
    }
    
    /**
      DisConnects to the channel. This method will asynchronously call the delegate's onDisConnect method and post a ChannelEvent.
     
     - parameter completionHandler: call back handler
     */
    
    internal func disconnect(_ completionHandler: ((_ error: NSError?) -> Void)? = nil)
    {
        self.application.disconnect()
        self.connected = false
    }
    
    /**
       Method  to check if Media Player is running
     
     - parameter completionHandler: call back handler
     */
    
    internal func isMediaPlayerRunning(_ completionHandler: ((_ error: NSError?, _ status:DMPStatus?) -> Void)? = nil)
    {
    
        self.application.getInfo(
            { (info, error) -> Void in
                if error == nil
                {
                    var dmStatus = DMPStatus(visible:false, dmpRunning: false, running: false, appName: "")
                    
                    if(info![kId] as? String == kPlayerId)
                    {
                        if let appName = info![Message.Property.PROPERTY_APP_NAME.rawValue]
                        {
                            dmStatus.appName = appName as! String
                        }
                        
                        let dmpRunning:Bool = (info![kMediaPlayer] as! Bool)
                        dmStatus.dmpRunning = dmpRunning
                        
                        let appVisible:Bool = (info![kAppVisible] as! Bool)
                        dmStatus.visible = appVisible
                        
                        let runStatus:Bool = (info![kRunning] as! Bool)
                        dmStatus.running = runStatus
                        
                        completionHandler?(error, dmStatus)
                    }
                    else
                    {
                        completionHandler?(error, nil)
                    }
                }
                else
                {
                    //Error
                    completionHandler?(error, nil)
                }
        })
    }
    
    //New function to playContent
    /**
       Method to play media content after connection
    */
    internal func playContent(_ jSONData: [String: AnyObject], type: BasePlayer.PlayerTypes, completionHandler: ((NSError?) -> Void)? = nil)
    {
        if !self.application.isConnected
        {
            //Try calling Connect and then on success call startPlay
            connect({ (error) -> Void in
                
                completionHandler?(error)
                
                if error == nil
                {
                    self.startPlay(jSONData, type: type, completionHandler: completionHandler)
                }
                
            })
            
        }
        else
        {
            startPlay(jSONData, type: type, completionHandler: completionHandler)
        }
    }
    
    /**
     Method to publish player property
    */
    internal func publishWith(_ event: PlayerProperty, data: AnyObject?)
    {
        guard self.connected else { return }
        
        self.application.publish(event: event.rawValue, message: data)
    }
    
    /**
       Method to be called to send event to start DMP application
    */
    internal func sendStartDMPApplication(_ type: BasePlayer.PlayerTypes, completionHandler: ((NSError?) -> Void)? = nil)
    {
        var params = self.application.getParams()
        
        if let argss = self.application.args
        {
            params.updateValue(argss as AnyObject, forKey: Message.Property.PROPERTY_ARGS.rawValue)
        }
        
        var contentType:String = type.rawValue
        if(contentType.caseInsensitiveCompare(BasePlayer.PlayerTypes.PHOTO.rawValue) == ComparisonResult.orderedSame)
        {
            contentType = "picture"
        }
        contentType = contentType.lowercased()
        
        
        params.updateValue(contentType as AnyObject, forKey: PROPERTY_ISCONTENTS)
        params.updateValue(DUMMY_URL_FOREGROUND as AnyObject, forKey: Message.Property.PROPERTY_URL.rawValue)
        params[Message.Property.PROPERTY_OS.rawValue] = UIDevice.current.systemVersion as AnyObject?
        params[Message.Property.PROPERTY_LIBRARY.rawValue] = Application.PROPERTY_VALUE_LIBRARY as AnyObject?
        
        let bundle = Bundle(identifier: Application.BUNDLE_IDENTIFIER)!
        params[Message.Property.PROPERTY_VERSION.rawValue] = bundle.infoDictionary?["CFBundleShortVersionString"] as? String as AnyObject?
        params[Message.Property.PROPERTY_MODEL_NUMBER.rawValue] = UIDevice.current.model as AnyObject?
        params[Message.Property.PROPERTY_APP_NAME.rawValue] = self.appName as AnyObject?
        
        let method = Application.ApplicationMethod.Start.fullMethodName(self.application.type)
        
        self.application.sendRPC(method, params: params, handler: { (message) -> Void in
            DispatchQueue.main.async(execute: {
                    completionHandler?(message.error)
            })
        })
    }
    
//MARK: Private Helper Method
    /**
       Method to start playing through DMP
    */
    private func startPlay(_ jSONData: [String: AnyObject], type: BasePlayer.PlayerTypes, completionHandler: ((NSError?) -> Void)? = nil)
    {
        var jSONData = jSONData
        if jSONData.count == 0
        {
            return;
        }
        
        //Check if Media player is running
        //self.application.get
        
        var url: String? = nil
        
        if jSONData[PlayerProperty.CONTENT_URI.rawValue] != nil
        {
            url = jSONData[PlayerProperty.CONTENT_URI.rawValue] as? String
        }
        
        if url == nil
        {
            return
        }
        
        playerContentType = type.rawValue
        
        Log.debug("Content URL is : \(url)")
        
        Log.debug("Content URL is : \(url)")
        
        isMediaPlayerRunning { (error, dmpStatus) -> Void in
            
            if dmpStatus != nil
            {
                Log.debug("dmp appName \(dmpStatus?.appName)")
                Log.debug("dmp visible \(dmpStatus?.visible)")
                Log.debug("dmp running \(dmpStatus?.dmpRunning)")
                
                jSONData.updateValue(BasePlayer.PlayerContentSubEvents.CHANGEPLAYINGCONTENT.rawValue as AnyObject , forKey: PlayerProperty.PLAYER_SUB_EVENT.rawValue)
                jSONData.updateValue(type.rawValue as AnyObject , forKey: PlayerProperty.PLAYER_TYPE.rawValue)
                
                var params = self.application.getParams()
                
                if let argss = self.application.args
                {
                    params.updateValue(argss as AnyObject, forKey: Message.Property.PROPERTY_ARGS.rawValue)
                }
                
                var contentType:String = type.rawValue
                if(contentType.caseInsensitiveCompare(BasePlayer.PlayerTypes.PHOTO.rawValue) == ComparisonResult.orderedSame)
                {
                        contentType = "picture"
                }
                contentType = contentType.lowercased()
                
                
                params.updateValue(contentType as AnyObject, forKey: PROPERTY_ISCONTENTS)
                params.updateValue(url! as AnyObject, forKey: Message.Property.PROPERTY_URL.rawValue)
                params[Message.Property.PROPERTY_OS.rawValue] = UIDevice.current.systemVersion as AnyObject?
                params[Message.Property.PROPERTY_LIBRARY.rawValue] = Application.PROPERTY_VALUE_LIBRARY as AnyObject?
                
                let bundle = Bundle(identifier: Application.BUNDLE_IDENTIFIER)!
                params[Message.Property.PROPERTY_VERSION.rawValue] = bundle.infoDictionary?["CFBundleShortVersionString"] as? String as AnyObject?
                params[Message.Property.PROPERTY_MODEL_NUMBER.rawValue] = UIDevice.current.model as AnyObject?
                params[Message.Property.PROPERTY_APP_NAME.rawValue] = self.appName as AnyObject?
                
                let method = Application.ApplicationMethod.Start.fullMethodName(self.application.type)
                
                //Log.debug("method is \(method)")
                
                if(dmpStatus?.dmpRunning == true && dmpStatus?.running == true)
                {
                    if(dmpStatus?.appName != nil && dmpStatus?.appName.compare(self.appName!) == ComparisonResult.orderedSame)
                    {
                        if(dmpStatus?.visible == true)
                        {
                            self.publishWith(PlayerProperty.PLAYER_CONTENT_CHANGE_EVENT, data: jSONData as AnyObject?)
                        }
                        else
                        {
                            // application is in background (paused state)
                            self.application.sendRPC(method, params: params, handler: { (message) -> Void in
                                DispatchQueue.main.async(execute: {
                                        if((message.error == nil))
                                        {
                                            self.publishWith(PlayerProperty.PLAYER_CONTENT_CHANGE_EVENT, data: jSONData as AnyObject?)
                                        }
                                        
                                        completionHandler?(message.error)
                                })
                            })
                        }
                    }
                    else
                    {
                        // launching content with different app name - another app launched the content
                        // TV will stop the current application and then it will entertain this start DMP request.
                        // start DMP application request
                        self.application.sendRPC(method, params: params, handler: { (message) -> Void in
                            DispatchQueue.main.async(execute: {
                                    if((message.error == nil))
                                    {
                                        self.publishWith(PlayerProperty.PLAYER_CONTENT_CHANGE_EVENT, data: jSONData as AnyObject?)
                                    }
                                    
                                    completionHandler?(message.error)
                            })
                        })

                    }
                }
                else
                {
                    // if DMP is not running , it means we have to start DMP
                    self.application.sendRPC(method, params: params, handler: { (message) -> Void in
                        DispatchQueue.main.async(execute: {
                                if((message.error == nil))
                                {
                                    self.publishWith(PlayerProperty.PLAYER_CONTENT_CHANGE_EVENT, data: jSONData as AnyObject?)
                                }
                                
                                completionHandler?(message.error)
                        })
                    })

                    
                }
            }
            else
            {
                    // error
            }
        }
    }
    /**
       Utility method to remove special characters from given string
     
     - parameter text: gvien string
    
     - returns: string after removal of special characters
     */
    fileprivate func removeSpecialCharsFromString(_ text: String) -> String
    {
        let okayChars : Set<Character> =
        Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-*=(),.:!_".characters)
        return String(text.characters.filter {okayChars.contains($0) })
    }
    
}

// MARK: - MediaPlayer (ChannelDelegate) -
extension MediaPlayer: ChannelDelegate
{
    /**
        Notification of any data received from TV player
     
     - parameter notification: contains player queue event and action
     */
    public func onMessage(_ message: Message)
    {
        if  let paramsString = message.data as? String
            , message.event == kPlayerNoticeEventName,
            let params = JSON.parse(jsonString: paramsString) as? [String : AnyObject]
        {
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: PlayerNotification.onMessage.rawValue), object: self, userInfo: params ))
        }
        else
        {
            Log.debug("MediaPlayer: cannot convert message from player into proper format: message.event=\(message.event), message.data=\(message.data)")
        }
    }
    
    /**
      event occur when connection occur with channel

     - client: The client that is connecting which is yourself
     - error: An error info if connect fails
     */
    public func onConnect(_ client: ChannelClient?, error: NSError?)
    {
        

        if(error != nil)
        {
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: PlayerNotification.onConnectError.rawValue), object: self, userInfo: ["error":error!] ))
        }
        else
        {
            //let params = ["error" : ""] as [String: AnyObject]
            Log.debug("onConnect ---- Error is \(error)")
            
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: PlayerNotification.onConnectError.rawValue), object: self, userInfo: ["error": NSNull()]))
            
        }
    }
    
    /**
        event occur when disconnection occur with channel.
     
     - client: The client that is disconnecting which is yourself
     - error: An error info if disconnect fails
     */
    public func onDisconnect(_ client: ChannelClient?, error: NSError?)
    {
        self.connected = false
        Log.debug("onDisconnect ---- Error is \(error)")
        
        if(error != nil)
        {
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: PlayerNotification.onDisconnectError.rawValue), object: self, userInfo: ["error":error!] ))
        }
        else
        {
//            let params = ["error" : nil] as [String: AnyObject?]
            Log.debug("onConnect ---- Error is \(error)")
            
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: PlayerNotification.onDisconnectError.rawValue), object: self, userInfo: ["error": NSNull()]))
            
        }

    }
 
    public func onClientConnect(_ client: ChannelClient)
    {

        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: PlayerNotification.onClientConnect.rawValue), object: self, userInfo: ["client": client]))
    }
    
    public func onClientDisconnect(_ client: ChannelClient)
    {
        
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: PlayerNotification.onClientDisconnect.rawValue), object: self, userInfo: ["client": client]))
    }
    
    public func onError(_ error: NSError)
    {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: PlayerNotification.onError.rawValue), object: self, userInfo: ["error":error] ))
    }
    
    public func onReady()
    {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: PlayerNotification.onReady.rawValue), object: self, userInfo: [:]))
    }
    
}

