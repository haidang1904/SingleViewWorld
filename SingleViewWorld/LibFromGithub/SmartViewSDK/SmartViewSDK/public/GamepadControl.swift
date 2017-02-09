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


private let kGamepadControlChannelName = "samsung.gamepad.control"
private let kGamepadControlHTTPREQUEST = "gamepadControl";
private let kGamepadControlMETHOD = "ms.gamepad.control";

/**
   Gamepad Valid Key Values expected from USER of Application
*/
@objc public enum GamepadkeyValue: Int
{
    case abs_X = 0,
    abs_Y,
    abs_Z,
    abs_RX,
    abs_RY,
    abs_RZ,
    abs_HAT0X,
    abs_HAT0Y,
    btn_1,
    btn_A,
    btn_B,
    btn_C,
    btn_X,
    btn_Y,
    btn_Z,
    btn_L1,
    btn_R1,
    btn_LB,
    btn_RB,
    btn_LT,
    btn_RT,
    btn_SELECT,
    btn_START,
    btn_MODE,
    btn_BACK,
    btn_TUMBL,
    btn_TUMBR
}

/**
   Gamepad Valid Key Event Types.
*/
@objc public enum GamepadkeyEventTypes: Int {
    case gamepad_key = 0,
    gamepad_abs,
    gamepad_left,
    gamepad_right

}

private let GamepadkeyToValue =
[
    "ABS_X",
    "ABS_Y",
    "ABS_Z",
    "ABS_RX",
    "ABS_RY",
    "ABS_RZ",
    "ABS_HAT0X",
    "ABS_HAT0Y",
    "BTN_1",
    "BTN_A",
    "BTN_B",
    "BTN_C",
    "BTN_X",
    "BTN_Y",
    "BTN_Z",
    "BTN_L1",
    "BTN_R1",
    "BTN_LB",
    "BTN_RB",
    "BTN_LT",
    "BTN_RT",
    "BTN_SELECT",
    "BTN_START",
    "BTN_MODE",
    "BTN_BACK",
    "BTN_TUMBL",
    "BTN_TUMBR"
]

/**
 *  Protocol for Gamepad with optional connection and disconnet function
 */
@objc public protocol GamepadControlDelegate
{
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
}

/// Gamepad Control Class provides handle to the USER through which keys/events can be send to the Game on the TV
@objc open class GamepadControl: NSObject
{
    open weak var delegate: GamepadControlDelegate?
    
    open fileprivate(set) var connected: Bool = false
    
    fileprivate(set) var clientID: String?
    
    fileprivate var accumulatedMouseDeltaL: (x: Int, y: Int)? = nil
    
    fileprivate var accumulatedMouseDeltaR: (x: Int, y: Int)? = nil
    
    open var mouseEventsMinInterval: UInt = 15
    
    open var service: Service
    {
        return self.channel.service
    }
    
    fileprivate var channel: GamepadControlChannel
    
    internal init(channel: GamepadControlChannel)
    {
        self.channel = channel
        super.init()
        self.channel.delegate = self
        self.channel.completionQueue = DispatchQueue(label: "GamePadCompletionQueue")
    }
    
    /**
     Deinitialisation of the class
     */
    deinit
    {
        self.channel.disconnect()
    }
    
     /**
     Method to connect to the TV on which Game is played
     
     - parameter attributes:        Optional - Dictionary with phone details
     - parameter completionHandler: callback handler to check for error or successful runs
     */
    open func connect(withAtributes attributes: [String:String]? = nil, completionHandler: ((_ error: NSError?) -> Void)? = nil)
    {
        Log.debug("GamepadControl: connecting to channel...")
        
        self.channel.connect(attributes, completionHandler:
        { (client, error) -> Void in
            
            if client != nil
            {
                self.connected = true
                self.clientID = client?.id
                
                Requester.doGet("http://\(self.service.host):8001/" + kGamepadControlHTTPREQUEST + "/", headers: [:], timeout: 3.0, completionHandler:
                    { (responseHeaders, data, error) -> Void in
                        
                        //self.processInitialConnectionData(data)
                        
                        Log.debug("GamepadControl: connected to channel...")
                        
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
    
    /**
     Disconnect the TV
     
     - parameter completionHandler: <#completionHandler description#>
     */
    open func disconnect(_ completionHandler: ((_ error: NSError?) -> Void)? = nil)
    {
        
        Log.debug("GamepadControl: disconnecting channel...")
        self.channel.disconnect(
            { (client, error) -> Void in
                
                self.resetState()
                completionHandler?(error)
        })
    }
    
    fileprivate func resetState()
    {
        self.connected = false
    }
    
    /**
     API to send Gamepad keys with there Event types
     
     - parameter key:          Gamepad key Value.
     - parameter event:        Gamepad key Event Types.
     - parameter keyOperation: key Operation.
     */
    open func sendGamepadKey(_ key: GamepadkeyValue, event: GamepadkeyEventTypes, keyOperation: Int)
    {
        if !self.connected
        {
            return
        }
        
        let point: [String: AnyObject] =
        [
            "x": keyOperation as AnyObject,
            "y": "" as AnyObject,
            "Time": "" as AnyObject
        ]
        
        let params: [String:AnyObject] =
        [
            "TypeOfRemote": "SendGamepadKey" as AnyObject,
            "Cmd": eventToStr(event) as AnyObject,
            "DataOfCmd": GamepadkeyToValue[key.rawValue] as AnyObject,
            "Option": self.clientID! as AnyObject,
            "Position": point as AnyObject
        ]
        
        self.channel.sendCommand(params)
    }
    
    /**
     API to send joystick coordinates for both left and right joystick
     
     - parameter byX:   X movement
     - parameter byY:   Y movement
     - parameter event: Gamepad key Event Types
     */
    open func sendGamepadMove(byX: Int, byY: Int, event: GamepadkeyEventTypes)
    {
        if !self.connected
        {
            return
        }
        
        // if there was no events for the period longer than mouseEventsMinInterval milliseconds - nothing was accumulated,
        // so just send the delta immediately
        if event == GamepadkeyEventTypes.gamepad_left
        {
            if self.accumulatedMouseDeltaL == nil
            {
                self.accumulatedMouseDeltaL = (x: byX, y: byY)
                commitMouseMovement(event)
            }
            else
            {
                // last mouse event message was sent less than mouseEventsMinInterval milliseconds ago,
                // next event commit that was scheduled earlier will fire after mouseEventsMinInterval since previous commit with accumulated value
                self.accumulatedMouseDeltaL?.x += byX
                self.accumulatedMouseDeltaL?.y += byY
            }
        }
        else if event == GamepadkeyEventTypes.gamepad_right
        {
            if self.accumulatedMouseDeltaR == nil
            {
                self.accumulatedMouseDeltaR = (x: byX, y: byY)
                commitMouseMovement(event)
            }
            else
            {
                // last mouse event message was sent less than mouseEventsMinInterval milliseconds ago,
                // next event commit that was scheduled earlier will fire after mouseEventsMinInterval since previous commit with accumulated value
                self.accumulatedMouseDeltaR?.x += byX
                self.accumulatedMouseDeltaR?.y += byY
            }
        }
        
    }
    
    
    fileprivate func commitMouseMovement(_ event: GamepadkeyEventTypes)
    {
        var commandSent = false
        
        if event == GamepadkeyEventTypes.gamepad_left
        {
            let currentTime = Date().timeIntervalSince1970 * 1000
            //var timeString = NSString(format:@"f", currentTime)
            
            let params: [String:AnyObject] =
            [
                "TypeOfRemote": "SendGamepadMove" as AnyObject,
                "Cmd": eventToStr(event) as AnyObject,
                "Option": self.clientID! as AnyObject,
                "Position": ["x": self.accumulatedMouseDeltaL!.x, "y": self.accumulatedMouseDeltaL!.y, "Time": String(format:"%f", currentTime) ] as AnyObject
            ]
            
            self.channel.sendCommand(params)
            
            if self.accumulatedMouseDeltaL?.x != 0 || self.accumulatedMouseDeltaL?.y != 0
            {
                commandSent = true
            }
            
            // if we actually sent command to TV, make sure next commit will occur not earlier than in mouseEventsMinInterval milliseconds
            if commandSent && self.mouseEventsMinInterval > 0
            {
                self.accumulatedMouseDeltaL = (x: 0, y: 0)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(UInt64(self.mouseEventsMinInterval) * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC),
                execute: {
                        self.commitMouseMovement(event)
                })
                
            }
                // otherwise, just set accumulated delta to nil, so that next event may be sent immediately
            else
            {
                self.accumulatedMouseDeltaL = nil
            }
        }
        else if event == GamepadkeyEventTypes.gamepad_right
        {
            
            let currentTime = Date().timeIntervalSince1970 * 1000
            //var timeString = NSString(format:@"f", currentTime)
            
            let params: [String:AnyObject] =
            [
                "TypeOfRemote": "SendGamepadMove" as AnyObject,
                "Cmd": eventToStr(event) as AnyObject,
                "Option": self.clientID! as AnyObject,
                "Position": ["x": self.accumulatedMouseDeltaR!.x, "y": self.accumulatedMouseDeltaR!.y, "Time": String(format:"%f", currentTime) ] as AnyObject
            ]
            
            self.channel.sendCommand(params)
            
            if self.accumulatedMouseDeltaR?.x != 0 || self.accumulatedMouseDeltaR?.y != 0
            {
                commandSent = true
            }
            
            // if we actually sent command to TV, make sure next commit will occur not earlier than in mouseEventsMinInterval milliseconds
            if commandSent && self.mouseEventsMinInterval > 0
            {
                self.accumulatedMouseDeltaR = (x: 0, y: 0)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(UInt64(self.mouseEventsMinInterval) * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC),
                execute: {
                        self.commitMouseMovement(event)
                })
                
            }
                // otherwise, just set accumulated delta to nil, so that next event may be sent immediately
            else
            {
                self.accumulatedMouseDeltaR = nil
            }
        }
        
        
    }
    
    fileprivate func eventToStr(_ event: GamepadkeyEventTypes) ->String
    {
        var event_str = ""
        
        switch event
        {
            case GamepadkeyEventTypes.gamepad_key:
                event_str = "gamepad_key"
                
            case GamepadkeyEventTypes.gamepad_abs:
                event_str = "gamepad_abs"
                
            case GamepadkeyEventTypes.gamepad_left:
                event_str = "gamepad_left"
                
            case GamepadkeyEventTypes.gamepad_right:
                event_str = "gamepad_right"
            
        }
        
        return event_str
    }
    
    
    
}

// MARK: - Protocol for Gamepad with optional connection and disconnet function
extension GamepadControl: ChannelDelegate
{
 
     /**
        Event Recieved after finishing connecting to channel.
     
     - parameter _client: channel client
     - parameter error:  error object containing the details about the problem if connection fails, otherwise nil.
     */
    public func onConnect(_ client: ChannelClient?, error: NSError?)
    {
        Log.debug("GamepadControl internal: connected to channel: \(client)")
        
        self.delegate?.onConnect?(error)
    }

    /**
     Event Recieved after disconnection from channel.
     
     - parameter _client: channel client
     - parameter error:  error object containing the details about the problem if connection fails, otherwise nil.
     */
    public func onDisconnect(_ client: ChannelClient?, error: NSError?)
    {
        Log.debug("GamepadControl internal: channel disconnected: \(error)")
        
        self.resetState()
        self.delegate?.onDisconnect?(error)
    }
    
}


// MARK: - GamepadControlChannel

internal class GamepadControlChannel: Channel
{
    internal func sendCommand(_ params: [String:AnyObject])
    {
        var envelope = [String:AnyObject]()
        envelope["method"] = Channel.ChannelMethod.GamepadControl.rawValue as AnyObject?
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



