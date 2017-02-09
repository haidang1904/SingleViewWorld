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

/// Remote command for click
public let kRemoteControlCommandClick = "Click"
/// remote command for press
public let kRemoteControlCommandPress = "Press"
/// remote command for release
public let kRemoteControlCommandRelease = "Release"

private let kRemoteControlIMEEventStart = "ms.remote.imeStart"
private let kRemoteControlIMEEventEnd = "ms.remote.imeEnd"
private let kRemoteControlIMEEventUpdate = "ms.remote.imeUpdate"
private let kRemoteControlTouchEnable = "ms.remote.touchEnable"
private let kRemoteControlTouchDisable = "ms.remote.touchDisable"

private let kVoiceDataEvent          =   "ms.sendVoiceData"
private let kVoiceAppHideEvent       =   "ms.voiceApp.hide"
private let kVoiceAppRecordingEvent  =   "ms.voiceApp.recording"
private let kVoiceAppProcessingEvent =   "ms.voiceApp.processing"
private let kVoiceAppStandByEvent    =   "ms.voiceApp.standby"

/**
  enum or Click type ex. left or right click.
 */
@objc public enum ClickType: Int
{
    /**
     left click of remote
    */
    case left = 0
    /**
      right click of remote
    */
    case right = 1
}

@objc public enum IMEInputType: Int
{
    /**
     Input type is default.
    */
    case `default` = 0
    /**
      Input type is password.
    */
    case password = 1
}
/**
   enum for voice app status
 */
@objc public enum VoiceAppStatus: Int
{
    /**
     *  Voice app is in hidden state.
    */
    case hidden = 0

    /**
     *  voice app is in Recording state.
    */
    case recording = 1

    /**
     *  voice app is in Processing mode.
    */
    case processing = 2

    /**
     *  voice app is in Standby mode.
    */
    case standby = 3
}

/**
 *  Remote control delegate for connect,disconnect.input start,input end etc.
 */
@objc public protocol RemoteControlDelegate
{
    /// Called when connected device started to accept keyboard input (e.g. when focus moved to some text field).
    @objc optional func onInputStart(_ inputType: IMEInputType)
    
    /// Called when connected device stopped accepting keyboard input (e.g. when a text field lost focus or user exited text input interface).
    @objc optional func onInputEnd()
    
    /// Called when connected device changed text of the currently active input field (e.g. when user entered some text with hardware remote or cleared text field).
    ///
    /// - parameter text: Current text of the input field on connected device.
    ///
    @objc optional func onInputSync(_ text: String)

    /// Called when connected device changes its mode in terms of ability to receive mouse events (mouse pointer movement and clicks).
    ///
    /// - parameter enabled: True if mouse events are enabled, otherwise false.
    ///
    @objc optional func onPointerEnabled(_ enabled: Bool)

    /// Called after finishing connecting to device.
    ///
    /// - parameter error: Error object containing the details about the problem if connection fails, otherwise nil.
    ///
    @objc optional func onConnect(_ error: NSError?)

    /// Called after finishing disconnecting from device.
    ///
    /// - parameter error: Error object containing the details about the problem if disconnection fails, otherwise nil.
    ///
    @objc optional func onDisconnect(_ error: NSError?)
    
    /// Called after status of Voice Control changed.
    ///
    /// - parameter status: Status of voice control enabled app.
    ///
    @objc optional func onVoiceAppChange(_ status: VoiceAppStatus)
    
    @objc optional func onMessage(_ payload: Any, event: String)
}

// MARK: -

/// Allows to send remote control commands to device.
/// RemoteControl instance should be created by calling service.createRemoteControl().
@objc open class RemoteControl: NSObject
{
    /// Delegate to handle remote control events.
    open weak var delegate: RemoteControlDelegate?
    
    /// True if remote control is connected to device and ready to use.
    open fileprivate(set) var connected: Bool = false

    /// True if mouse pointer can be used to control device.
    ///
    /// sendMouseMove and sendMouseClick methods work only when this property has true value.
    ///
    open fileprivate(set) var pointerEnabled: Bool = false
    
    /// True if IME input is currently active (meaning that some text input field is focused on TV and onscreen keyboard is shown).
    open fileprivate(set) var IMEActive: Bool = false

    /// Type of currently active IME text field on TV.
    open fileprivate(set) var IMECurrentType: IMEInputType = .default

    open fileprivate(set) var IMECurrentText: String = ""
    
    open fileprivate(set) var voiceSupported: Bool = false
    
    open fileprivate(set) var gamePadSupported: Bool = false
    
    open fileprivate(set) var smartHubAgreement: Bool = false
    
    open fileprivate(set) var edenSupported: Bool = false
    
    open fileprivate(set) var countryCode: String? = nil
    
    /// Sets the minimum time period for which mouse movement events are sent to device, in milliseconds.
    ///
    /// RemoteControl guarantees that mouse movement events initiated by sendMouseMove will be actually sent to device not more often than given value in milliseconds.
    /// In case sendMouseMove is called more often, the (x,y) delta is accumulated for the mouseEventsMinInterval milliseconds and final delta is sent to device
    /// after the given time interval passes.
    /// Default value is 20 ms.
    ///
    open var mouseEventsMinInterval: UInt = 15
    
    /// The Service object linked with device controlled by the RemoteControl instance.
    open var service: Service
    {
        return self.channel.service
    }
    
    fileprivate var channel: RemoteControlChannel

    fileprivate var handlers: [String: (_ message: Message) -> Void] = [:]
    
    fileprivate var accumulatedMouseDelta: (x: Int, y: Int)? = nil

    internal init(channel: RemoteControlChannel)
    {
        self.channel = channel
        super.init()
        self.channel.delegate = self
        self.channel.completionQueue = DispatchQueue(label: "RemoteCompletionQueue")
        self.voiceSupported = self.service.voiceControlSupported
        self.gamePadSupported = self.service.gamePadSupported
        self.smartHubAgreement = self.service.smartHubAgreement
        self.edenSupported = self.service.edenSupported
        self.countryCode = self.service.countryCode

    }
    
    deinit
    {
        self.channel.disconnect()
    }
    
    /// Connect to device. Any commands can be sent to device only after connection succeeds.
    ///
    /// - parameter attributes: Any attributes you want to associate with the connecting device (client). Currently only "name" attribute is supported,
    ///                         which sets the name of a connecting mobile device to be visible by TV.
    /// - parameter completionHandler: Optional closure to handle connection result.
    ///
    open func connect(withAttributes attributes: [String:String]? = nil, completionHandler: ((_ error: NSError?) -> Void)? = nil)
    {
        self.setupMessageHandlers()
        
        Log.debug("RemoteControl: connecting to channel...")
        self.channel.connect(attributes, completionHandler:
        { (client, error) -> Void in
            
            if client != nil
            {
                self.connected = true
                
                var uri:String = "http://\(self.service.host):8001/remoteControl/"
                
                if(self.channel.securityMode)
                {
                    uri = self.channel.getSecureURL(url: uri)
                }
                
                Requester.doGet(uri, headers: [:], timeout: 3.0, completionHandler:
                { (responseHeaders, data, error) -> Void in
                    
                    self.processInitialConnectionData(data)
                    
                    DispatchQueue.main.async(execute: {
                        completionHandler?(nil)
                    })
                })
            }
            else
            {
                completionHandler?(error)
            }
        })
    }
    
    /// Disconnect from device.
    ///
    /// - parameter completionHandler: Optional closure to handle disconnection result
    ///
    open func disconnect(_ completionHandler: ((_ error: NSError?) -> Void)? = nil)
    {
        self.resetMessageHandlers()
        
        Log.debug("RemoteControl: disconnecting channel...")
        self.channel.disconnect(
        { (client, error) -> Void in
            
            self.resetState()
            completionHandler?(error)
        })
    }
    
    /// Send given key command to device.
    ///
    /// - parameter keyName: The name of the key to be sent.
    /// - parameter command: The type of command to use. Available command types are: "Click", "Press", "Release".
    ///                      Default value is "Click".
    ///
    open func sendRemoteKey(_ keyName: String, command: String = kRemoteControlCommandClick)
    {
        if !self.connected
        {
            return
        }
        
        let params: [String:AnyObject] =
        [
            "TypeOfRemote": "SendRemoteKey" as AnyObject,
            "Cmd": command as AnyObject,
            "DataOfCmd": keyName as AnyObject,
            "Option": false as AnyObject
        ]
        
        self.channel.sendCommand(params)
    }
    
    /// Send given text for currently active input field on the connected device.
    ///
    /// - parameter input: The string to be sent as input.
    ///
    open func sendInputString(_ input: String)
    {
        if !self.connected
        {
            return
        }
        
        if let data: Data = input.data(using: String.Encoding.utf8)
        {
            let base64String = data.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            
            let params: [String:AnyObject] =
            [
                "TypeOfRemote": "SendInputString" as AnyObject,
                "Cmd": base64String as AnyObject,
                "DataOfCmd" : "base64" as AnyObject,
                "Option": false as AnyObject
            ]
            
            self.channel.sendCommand(params)
        }
    }
    
    /// Notify connected device that the input for currently active text field has ended (equivalent to pressing "Done" button).
    open func sendInputEnd()
    {
        if !self.connected
        {
            return
        }
        
        let params: [String:AnyObject] =
        [
            "TypeOfRemote": "SendInputEnd" as AnyObject,
            "Option": false as AnyObject
        ]
        
        self.channel.sendCommand(params)
    }
    
    /// Send mouse movement event to TV.
    ///
    /// This method does nothing if pointerEnabled property is set to false.
    ///
    /// - parameter byX: Delta value to move mouse cursor by X axis.
    /// - parameter byY: Delta value to move mouse cursor by Y axis.
    ///
    open func sendMouseMove(byX: Int, byY: Int)
    {
        if !self.connected || !self.pointerEnabled
        {
            return
        }

        // if there was no events for the period longer than mouseEventsMinInterval milliseconds - nothing was accumulated,
        // so just send the delta immediately
        if self.accumulatedMouseDelta == nil
        {
            self.accumulatedMouseDelta = (x: byX, y: byY)
            commitMouseMovement()
        }
        else
        {
            // last mouse event message was sent less than mouseEventsMinInterval milliseconds ago, 
            // next event commit that was scheduled earlier will fire after mouseEventsMinInterval since previous commit with accumulated value
            self.accumulatedMouseDelta?.x += byX
            self.accumulatedMouseDelta?.y += byY
        }
    }
    
    /// Send mouse click event to TV.
    ///
    /// This method does nothing if pointerEnabled property is set to false.
    ///
    /// - parameter type: One of the values of ClickType enum to specify which button clicked. Default value is Left.
    open func sendMouseClick(_ type: ClickType = .left)
    {
        if !self.connected || !self.pointerEnabled
        {
            return
        }
        
        var typeParam = "LeftClick"
        switch type
        {
            case .left:
                typeParam = "LeftClick"
            
            case .right:
                typeParam = "RightClick"
        }
        
        let params: [String:AnyObject] =
        [
            "TypeOfRemote": "ProcessMouseDevice" as AnyObject,
            "Cmd": typeParam as AnyObject
        ]
        
        self.channel.sendCommand(params)
    }
    
    /// Send voice control command to TV.
    ///
    /// - parameter payload: Raw recorded voice data.
    ///
    open func sendVoice(_ payload: Data)
    {
        let newData = NSMutableData()
        var headByteLen = UInt32(payload.count).bigEndian
        
        newData.append(&headByteLen, length: MemoryLayout<UInt32>.size)
        newData.append(payload)
        Log.debug("Voice data length is \(newData.length), data: \(newData)")
        
        self.channel.publish(event: Channel.ChannelMethod.Voice.rawValue, message: nil, data: newData as Data)
    }
    
    open func setSecurityMode(security: Bool, completionHandler: @escaping (_ isSupport:Bool, _ error:NSError?) -> Void)
    {
        self.channel.setSecurityMode(security: security, completionHandler: completionHandler)
    }
    
    open func isSecurityMode() -> Bool
    {
        return self.channel.securityMode
    }
}

// MARK: - RemoteControl (ChannelDelegate) -

extension RemoteControl: ChannelDelegate
{
    public func onConnect(_ client: ChannelClient?, error: NSError?)
    {
        Log.debug("RemoteControl internal: connected to channel: \(client)")
        
        self.delegate?.onConnect?(error)
    }

    public func onDisconnect(_ client: ChannelClient?, error: NSError?)
    {
        Log.debug("RemoteControl internal: channel disconnected: \(error)")

        self.resetState()
        self.delegate?.onDisconnect?(error)
    }
    
    public func onMessage(_ message: Message)
    {
        if let handler = handlers[message.event] {
            DispatchQueue.main.async {
                handler(message)
            }
        } else {
            delegate?.onMessage?(message.data as Any, event: message.event)
        }
    }
}

// MARK: - RemoteControl (Private) -

extension RemoteControl
{
    fileprivate func setupMessageHandlers()
    {
        self.handlers[kRemoteControlIMEEventStart] =
        { [unowned self] (message: Message) -> Void in
        
            self.onIMEStart(message)
        }

        self.handlers[kRemoteControlIMEEventEnd] =
        { [unowned self] (message: Message) -> Void in
        
            self.onIMEEnd(message)
        }

        self.handlers[kRemoteControlIMEEventUpdate] =
        { [unowned self] (message: Message) -> Void in
        
            self.onIMEUpdate(message)
        }
        
        self.handlers[kRemoteControlTouchEnable] =
        { [unowned self] (message: Message) -> Void in
            
            self.onTouchToggled(message)
        }
        
        self.handlers[kVoiceAppHideEvent] =
        { [unowned self] (message: Message) -> Void in
                
                self.delegate?.onVoiceAppChange?(.hidden)
        }
        
        self.handlers[kVoiceAppRecordingEvent] =
            { [unowned self] (message: Message) -> Void in
                
                self.delegate?.onVoiceAppChange?(.recording)
        }
        
        self.handlers[kVoiceAppProcessingEvent] =
            { [unowned self] (message: Message) -> Void in
                
                self.delegate?.onVoiceAppChange?(.processing)
        }
        
        self.handlers[kVoiceAppStandByEvent] =
            { [unowned self] (message: Message) -> Void in
                
                self.delegate?.onVoiceAppChange?(.standby)
        }
        
        self.handlers[kRemoteControlTouchDisable] = self.handlers[kRemoteControlTouchEnable]
    }
    
    fileprivate func onIMEStart(_ message: Message)
    {
        var inputType = IMEInputType.default
        
        if  let inputTypeString = message.data as? String
            , inputTypeString.lowercased() == "password"
        {
            inputType = .password
        }

        self.IMEActive = true
        self.IMECurrentType = inputType
        self.delegate?.onInputStart?(inputType)
        self.IMECurrentText = ""
    }

    fileprivate func onIMEEnd(_ message: Message)
    {
        self.IMEActive = false
        self.delegate?.onInputEnd?()
        self.IMECurrentText = ""

    }
    
    fileprivate func onIMEUpdate(_ message: Message)
    {
        if let newText = self.decodeBase64String(message.data as? String)
        {
            Log.debug("Remote control sync with string: \(newText)")
            self.IMECurrentText = newText
            self.delegate?.onInputSync?(newText)
        }
        else
        {
            Log.debug("Remote control sync error: cannot get string")
        }
    }
    
    fileprivate func onTouchToggled(_ message: Message)
    {
        self.pointerEnabled = (message.event == kRemoteControlTouchEnable)
        self.delegate?.onPointerEnabled?(self.pointerEnabled)
    }
    
    fileprivate func resetMessageHandlers()
    {
        self.handlers.removeAll()
    }
    
    /// Send accumulated mouse delta to device
    fileprivate func commitMouseMovement()
    {
        var commandSent = false
        
        if let delta = self.accumulatedMouseDelta , delta.x != 0 || delta.y != 0
        {
            let params: [String:AnyObject] =
            [
                "TypeOfRemote": "ProcessMouseDevice" as AnyObject,
                "Cmd": "Move" as AnyObject,
                "Position": ["x": delta.x, "y": delta.y] as AnyObject
            ]
            
            self.channel.sendCommand(params)
            commandSent = true
        }

        // if we actually sent command to TV, make sure next commit will occur not earlier than in mouseEventsMinInterval milliseconds
        if commandSent && self.mouseEventsMinInterval > 0
        {
            self.accumulatedMouseDelta = (x: 0, y: 0)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(UInt64(self.mouseEventsMinInterval) * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC), execute: commitMouseMovement)
        }
        // otherwise, just set accumulated delta to nil, so that next event may be sent immediately
        else
        {
            self.accumulatedMouseDelta = nil
        }
    }
    
    fileprivate func processInitialConnectionData(_ data: Data?)
    {
        if  let data = data,
            let info = JSON.parse(data: data) as? [String : AnyObject]
        {
            if  let touchStatus = info["touchEnable"] as? String
                , touchStatus == "enable"
            {
                self.pointerEnabled = true
            }

            if  let imeStatus = info["imeStatus"] as? String
                , imeStatus == "input" || imeStatus == "password"
            {
                self.IMEActive = true
                
                if imeStatus == "password"
                {
                    self.IMECurrentType = .password
                }
                else
                {
                    self.IMECurrentType = .default
                }
            }
            
            if let imeText = info["imeText"] as? String
            {
                self.IMECurrentText = self.decodeBase64String(imeText) ?? ""
            }
        }
    }
    
    fileprivate func resetState()
    {
        self.connected = false
        self.pointerEnabled = false
        self.IMEActive = false
        self.IMECurrentText = ""
        self.IMECurrentType = .default
        self.voiceSupported = false
    }
    
    fileprivate func decodeBase64String(_ source: String?) -> String?
    {
        if  let encodedData = source,
            let data = Data(base64Encoded: encodedData, options: .ignoreUnknownCharacters),
            let decodedText = String(data: data, encoding: String.Encoding.utf8)
        {
            return decodedText
        }
    
        return nil
    }
}

// MARK: -

internal class RemoteControlChannel: Channel
{
    internal func sendCommand(_ params: [String:AnyObject])
    {
        var envelope = [String:AnyObject]()
        envelope["method"] = Channel.ChannelMethod.RemoteControl.rawValue as AnyObject?
        envelope["params"] = params as AnyObject?

        if let stringMessage = JSON.stringify(envelope as AnyObject)
        {
            self.transport.send(stringMessage)
        }
        else
        {
            Log.error("Unable to serialize the message")
        }
    }
}

extension RemoteControl
{
    open func publishEden(event: String, message: AnyObject?) {
        channel.publish(event: event, message: message as AnyObject?, target: MessageTarget.Host.rawValue as AnyObject)
    }
}
