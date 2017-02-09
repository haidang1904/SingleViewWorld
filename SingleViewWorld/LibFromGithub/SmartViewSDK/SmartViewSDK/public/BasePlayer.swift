/*

Copyright (c) 2015 Samsung Electronics

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

/// The Connection delegate protocol defines the event methods available for channel Connection/DisConnection.
@objc public protocol ConnectionDelegate: class
{
    
//MARK: Optional Callbacks for Connection
    /**
      event occur when connection occur with channel.
    
    - parameter error: connection error
    */
    @objc optional func onConnect(_ error: NSError?)
   
    /**
       event occur when Disconnection occur with channel.
     
     - parameter error: disconnect error.
     */
    @objc optional func onDisconnect(_ error: NSError?)
    
    /**
     event occur when other client connects with channel.
     
     - parameter client: client info.
     */
    @objc optional func onClientConnect(_ client: ChannelClient)
    
    /**
     event occur when other client disconnects with channel.
     
     - parameter client: client info.
     */
    @objc optional func onClientDisconnect(_ client: ChannelClient)
    
    /**
     event occur when a Channel Error is fired
     
     - parameter error: error.
     */
    @objc optional func onError(_ error: NSError)
    
    /**
     event occur when the host app is ready to send or receive messages
     
     */
    @objc optional func onReady()
    
    /**
      Called when media player on target device sends "playerNotice" event to client.
      It may be change of playback status, error message or informative event about video stream state.
      See MediaPlayer.PlayerNotice definition for possible values.
    
    - parameter messageData: information about player events
    */
    @objc optional func onPlayerNotice(_ messageData: [String : AnyObject])
}

/// Base class for audio, video and photo player
@objc open class BasePlayer: NSObject
{
    internal var mPlayer: MediaPlayer
    
    /// The Connection delegate protocol defines the event methods available for channel Connection/DisConnection.
    open weak var connectionDelegate: ConnectionDelegate? = nil
    
    internal var mList: [[String: AnyObject]]?
    
    internal enum PlayerTypes: String
    {
        case AUDIO = "AUDIO"
        case VIDEO = "VIDEO"
        case PHOTO = "PHOTO"
    }
    
    internal enum PlayerControlEvents: String
    {
        case play                           = "play"
        case pause                          = "pause"
        case stop                           = "stop"
        case mute                           = "mute"
        case unMute                         = "unMute"
        case setVolume                      = "setVolume"
        case getVolume                      = "getVolume"
        case previous                       = "previous"
        case next                           = "next"
        case volumeUp                       = "volumeUp"
        case volumeDown                     = "volumeDown"
        case getControlStatus               = "getControlStatus"
        //Video Player Specific Controls
        case FF                             = "FF"
        case RWD                            = "RWD"
        case seekTo                         = "seekTo"
        //Video+Audio Player Specific Controls
        case Repeat                         = "repeat"
        case shuffle                        = "shuffle"
        //Photo player Specific Controls
        case slideTimeout                   = "slideTimeout"
        case playMusic                      = "playMusic"
        case stopMusic                      = "stopMusic"
    }
    
    internal enum PlayerContentSubEvents: String
    {
        case ADDITIONALMEDIAINFO            = "ADDITIONALMEDIAINFO"
        case CHANGEPLAYINGCONTENT           = "CHANGEPLAYINGCONTENT"
    };
    
    internal enum RepeatMode: String
    {
        case repeatOff                  = "repeatOff"
        case repeatSingle               = "repeatSingle"
        case repeatAll                  = "repeatAll"
    }
    
    internal enum PlayerControlStatus:String
    {
        case volume                     = "volume"
        case mute                       = "mute"
        case `repeat`                   = "repeat"
        case shuffle                    = "shuffle"
    }
    
    internal enum PlayerQueueSubEvents: String
    {
        case enqueue                    = "enqueue"
        case dequeue                    = "dequeue"
        case clear                      = "clear"
        case fetch                      = "fetch"
    }
    
    internal enum PlayerApplicationStatusEvents: String
    {
        case suspend = "suspend"
        case resume  = "resume"
    }
    
    internal let PlayerErrorStatus:[Int: String] =
        [
            101 : "PLAYER_ERROR_GENEREIC",                          // GENERIC ERROR
            102 : "PLAYER_ERROR_CONNECTION_FAILED",                 // Network issue
            103 : "PLAYER_ERROR_AUDIO_CODEC_NOT_SUPPORTED",         // Audio codec not supported
            104 : "PLAYER_ERROR_NOT_SUPPORTED_FILE",                // File format not supported
            105 : "PLAYER_ERROR_VIDEO_CODEC_NOT_SUPPORTED",         // Video codeo not supported
            106 : "PLAYER_ERROR_PLAYER_NOT_LOADED",                 // Player is not yet loaded or different player is loaded on TV.
            107 : "PLAYER_ERROR_INVALID_OPERATION",                 // Invalid operation
            108 : "PLAYER_ERROR_INVALID_PARAMETER",                 // Called on invalid parameter
            109 : "PLAYER_ERROR_NO_SUCH_FILE",                      // No such file found
            110 : "PLAYER_ERROR_SEEK_FAILED",                       // Fail to perform seekto operation
            111 : "PLAYER_ERROR_REWIND",                            // Error in Rewind
            112 : "PLAYER_ERROR_FORWARD",                           // Error in Frwd
            113 : "PLAYER_ERROR_RESTORE",                           // FAIL to restore the Player
            114 : "PLAYER_ERROR_RESOURCE_LIMIT",                    // Resource max limit reached
            115 : "PLAYER_ERROR_INVALID_STATE",                     // Player invalid state
            116 : "PLAYER_ERROR_NO_AUTH",                           // Not authorized to play the requested content
            117 : "PLAYER_ERROR_LAST_CONTENT",                      // Can't Dequeue last content from the List
            118 : "PLAYER_ERROR_CURRENT_CONTENT",                   // Can't Dequeue current content from the List
            401 : "PLAYER_ERROR_INVALID_URI",                       // Invalid url
            500 : "PLAYER_ERROR_INTERNAL_SERVER"                    // Internal server error
    ]
    
    /**
       Base player initializer
     
     - parameter mediaplayer: defines player like audioPlayer , videoPlayer or photoPlayer
     
     */
    init(mediaplayer: MediaPlayer)
    {
        mPlayer = mediaplayer
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectionDelegate.onDisconnect(_:)), name: NSNotification.Name(rawValue: MediaPlayer.PlayerNotification.onDisconnectError.rawValue), object: nil)
    
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectionDelegate.onConnect(_:)), name: NSNotification.Name(rawValue: MediaPlayer.PlayerNotification.onConnectError.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectionDelegate.onClientConnect(_:)), name: NSNotification.Name(rawValue: MediaPlayer.PlayerNotification.onClientConnect.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectionDelegate.onClientDisconnect(_:)), name: NSNotification.Name(rawValue: MediaPlayer.PlayerNotification.onClientDisconnect.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectionDelegate.onError(_:)), name: NSNotification.Name(rawValue: MediaPlayer.PlayerNotification.onError.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectionDelegate.onReady), name: NSNotification.Name(rawValue: MediaPlayer.PlayerNotification.onReady.rawValue), object: nil)
    }
    
    /**
       A convenience method to unsubscribe from notifications.
    */
    deinit
    {        
        NotificationCenter.default.removeObserver(self)
    }
    
//MARK: APIs for Common Use, Objective C + Swift
    /**
    
    Connects to the channel. This method will asynchronously call the delegate's onConnect method and post a
    ChannelEvent.
    - parameter completionHandler: callback handler of connect
    */
    @objc fileprivate func connect(_ completionHandler: ((_ error: NSError?) -> Void)? = nil)
    {
        mPlayer.connect(completionHandler)
    }
    
    /**
     Disconnects to the channel. This method will asynchronously call the delegate's onDisconnect method and post a
     ChannelEvent.
     - parameter completionHandler: callback handler of OnDisconnect
     */
    @objc open func disconnect(_ completionHandler: ((_ error: NSError?) -> Void)? = nil)
    {
        mPlayer.disconnect(completionHandler)
    }
    
    /**
       Play last sent media contents.
    */
    @objc open func play()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.play.rawValue as AnyObject?)
    }
    
    /**
      Pause currently playing media.
    */
    @objc open func pause()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.pause.rawValue as AnyObject?)
    }
    
    /**
      Stop currently playing media.
    */
    @objc open func stop()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.stop.rawValue as AnyObject?)
    }
    
    /**
      Mute the volume of player on a connected device.
    */
    @objc open func mute()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.mute.rawValue as AnyObject?)
    }
    
    /**
      UnMute the volume of player on a connected device.
    */
    @objc open func unMute()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.unMute.rawValue as AnyObject?)
    }
    
    /**
      Request the volume of player on a connected device.
    */
    @objc open func getVolume()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.getVolume.rawValue as AnyObject?)
    }
    
    /**
      Request previous to the player on a connected device.
    */
    @objc open func previous()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.previous.rawValue as AnyObject?)
    }
    
    /**
      Request next to the player on a connected device.
    */
    @objc open func next()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.next.rawValue as AnyObject?)
    }
    
    /**
        Set volume on device playing media.
     
      - parameter volume: Integer value between 0 and 100.
    */
    @objc open func setVolume(_ volume: UInt8)
    {
        precondition(volume <= 100, "Volume cannot be more than 100")
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: "setVolume:\(min(100, volume))" as AnyObject?)
    }
    /// Volume Up.
    /**
     increase volume of the player by 1.
    */
    @objc open func volumeUp()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.volumeUp.rawValue as AnyObject?)
    }
    
    /**
     decrease volume of the player by 1.
    */
    @objc open func volumeDown()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.volumeDown.rawValue as AnyObject?)
    }
    
    /**
      get the control status of the player - like volume etc.
     */
    @objc open func getControlStatus()
    {
        mPlayer.publishWith(MediaPlayer.PlayerProperty.PLAYER_CONTROL_EVENT, data: PlayerControlEvents.getControlStatus.rawValue as AnyObject?)
    }
    
    //MARK: Helper Internal Methods
    
    /**
      A convenience method to subscribe for notifications using blocks.
    
      - parameter notificationName: The name of the notification.
      - parameter performClosure:   The notification closure, which will be executed in the main thread.
        Make sure to control the ownership of a variables captured by the closure you provide in this parameter
        (e.g. use [unowned self] or [weak self] to make sure that self is released even if you did not unsubscribe from notification)
    
      - returns: An observer handler for removing/unsubscribing the block from notifications
    */
    internal func on(_ notificationName: String, performClosure:@escaping (Notification!) -> Void) -> AnyObject?
    {
        return NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: notificationName), object: self, queue: OperationQueue.main, using: performClosure)
    }
    
    /**
      A convenience method to unsubscribe from notifications
    
    - parameter observer: The observer object to unregister observations
    */
    internal func off(_ observer: AnyObject)
    {
        NotificationCenter.default.removeObserver(observer)
    }
    
    /**
       event occur when disconnection occur with channel.
     
     - parameter notification: error notification.
    */
    internal func onDisconnect(_ notification: Notification!)
    {
        if  let userInfo = notification.userInfo as? [String:AnyObject]
        {
            if let error = userInfo["error"] as? NSError
            {
                self.connectionDelegate!.onDisconnect?(error)
            }
            else
            {
                self.connectionDelegate!.onDisconnect?(nil)
            }
        }
    }
    
    /**
       event occur when connection occur with channel.
     
     - parameter notification: error notification.
    */
    internal func onConnect(_ notification: Notification!)
    {
        if  let userInfo = notification.userInfo as? [String:AnyObject]
        {
            if let error = userInfo["error"] as? NSError
            {
                self.connectionDelegate?.onConnect?(error)
            }
            else
            {
                self.connectionDelegate?.onConnect?(nil)
            }
        }
    }
    
    
    /**
     event occur when other client connects with channel.
     
     - parameter notification: error notification.
     */
    internal func onClientConnect(_ notification: Notification!)
    {
        if  let userInfo = notification.userInfo as? [String:AnyObject]
        {
            if let client = userInfo["client"] as? ChannelClient
            {
                self.connectionDelegate?.onClientConnect?(client)
            }
        }
    }
    
    /**
     event occur when other client disconnects with channel.
     
     - parameter notification: error notification.
     */
    internal func onClientDisconnect(_ notification: Notification!)
    {
        if  let userInfo = notification.userInfo as? [String:AnyObject]
        {
            if let client = userInfo["client"] as? ChannelClient
            {
                self.connectionDelegate?.onClientDisconnect?(client)
            }
        }
            }
    
    /**
     event occur when a Channel Error is fired
     
     - parameter notification: error notification.
     */
    internal func onError(_ notification: Notification?)
    {
        if  let userInfo = notification?.userInfo as? [String:AnyObject]
        {
            if let error = userInfo["error"] as? NSError
            {
                self.connectionDelegate?.onError!(error)
            }
            }
        }
    
    /**
     event occur when the host app is ready to send or receive messages
     
     */
    internal func onReady()
    {
        self.connectionDelegate?.onReady?()
    }

    
    /**
     This method is called when player throws an error
     
     - parameter code: error code
     
     - returns: error
     */
    internal func errorWithDetail(_ code: Int) -> NSError
    {
        var details = Dictionary<String,String>()
        details[NSLocalizedDescriptionKey] =  PlayerErrorStatus[code]
        return NSError(domain: "PLAYER", code: Int(code), userInfo: details)
    }
    
    /**
     This method is called when player throws an error
     
     - parameter detail: error value
     - parameter code: error code
     
     - returns: error
     */
    internal func errorWith(_ details: Dictionary<String,String>, code: UInt16) -> NSError
    {
        return NSError(domain: "PLAYER", code: Int(code), userInfo: details)
    }
    
}












