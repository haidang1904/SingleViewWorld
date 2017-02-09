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
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}
/**
This emumeration defines the target option for the emit methods, use this
definitions in addition to the client id or a collection of client ids
*/

public enum MessageTarget: String
{
    /// Target all the clients including the host and the sender
    case All = "all"
    /// Target only the host
    case Host = "host"
    ///Target all the clients including the host and the sender
    case Broadcast = "broadcast"
}

/**
  This emumeration defines the notification options for a channel, this is an
  alternative to the ChannelDelegate protocol.

  Use this channel event enumeration in conjunction with the channel.on(...) and channel.off(...)
  methods in order to receive the notifications in a closure in the main thread
*/
public enum ChannelEvent : String
{
    /// The on connect event
    case Connect = "ms.channel.connect"
    /// The on disconnect event
    case Disconnect = "ms.channel.disconnect"
    /// A client connect event
    case ClientConnect = "ms.channel.clientConnect"
    ///  client disconnect event
    case ClientDisconnect = "ms.channel.clientDisconnect"
    /// A text message was received
    case Message = "ms.channel.message"
    /// A binary data message was received
    case Data = "ms.channel.data"
    /// Connection to channel failed due to authorization issue (for some specific channels)
    case Unauthorized = "ms.channel.unauthorized"
    /// C0nnection time out
    case Timeout = "ms.channel.timeOut"
    /// An error happened
    case Error = "ms.error"
    /// The host app is ready to send or receive messages
    case Ready = "ms.channel.ready"
    /// The Channel Ping event
    case Ping = "ms:channel.ping"
}

/// RPCResultHandler is a container class for the result callback of RPC invocations
internal class RPCResultHandler
{
    var handler: ((_ message: RPCMessage) -> Void)
    init (handler: @escaping ((_ message: RPCMessage) -> Void))
    {
        self.handler = handler
    }
}

// MARK: - ChannelDelegate -

///  The channel delegate protocol defines the event methods available for a channel
@objc public protocol ChannelDelegate: class
{
    /**
        Called when the Channel is connected
    
      - parameter client: The Client that just connected to the Channel
      - parameter error: An error info if any
    */
    ///  - parameter error: An error info if any
    @objc optional func onConnect(_ client: ChannelClient?, error: NSError?)

    /**
      Called when the host app is ready to send or receive messages
    */
    ///
    @objc optional func onReady()

    /**
      Called when the Channel is disconnected
    
    - parameter client: The Client that just disconnected from the Channel
    - parameter error: An error info if any
    */
    ///  - parameter error: An error info if any
    @objc optional func onDisconnect(_ client: ChannelClient?, error: NSError?)

    /**
        Called when the Channel receives a text message
    
      - parameter message: Text message received
    */
    @objc optional func onMessage(_ message: Message)

    /**
       Called when the Channel receives a binary data message
    
     - parameter message: Text message received
     - parameter payload: Binary payload data
    */
    @objc optional func onData(_ message: Message, payload: Data)

    /**
        Called when a client connects to the Channel
     
      - parameter client: The Client that just connected to the Channel
    */
    @objc optional func onClientConnect(_ client: ChannelClient)

    /**
       Called when a client disconnects from the Channel
     
     - parameter client: The Client that just disconnected from the Channel
    */
    @objc optional func onClientDisconnect(_ client: ChannelClient)

    /**
      Called when a Channel Error is fired
    
    - parameter error: The error
    */
    @objc optional func onError(_ error: NSError)
}

// MARK: - Channel (Public) -

///  A Channel is a discreet connection where multiple clients can communicate
@objc open class Channel: NSObject
{
    /**
      The availble methods for the channel
    
    - Emit: The method to emit an event
    */
    internal enum ChannelMethod : String
    {
        case Emit = "ms.channel.emit"
        case RemoteControl = "ms.remote.control"
        case Voice = "ms.voice.control"
        case GamepadControl = "ms.gamepad.control"
    }

    /// The connection status of the channel
    open fileprivate(set) var isConnected: Bool = false

    /// The uri of the channel ('chat')
    open fileprivate(set) var uri: String! = nil

    /// the service that is suplaying the channel connection
    open fileprivate(set) var service : Service! = nil

    /// The client that owns this channel instance
    open var me: ChannelClient!
    
    open var completionQueue: DispatchQueue? = nil

    /// The delegate for handling channel events
    weak open var delegate: ChannelDelegate? = nil
    
    var securityMode: Bool = false
    
    /// The timeout for channel transport connection.
    /// The connection will be closed if no ping is received within the defined timeout
    open var connectionTimeout: TimeInterval = 5
    {
        didSet
        {
            stopConnectionAliveCheck()
            startConnectionAliveCheck()
        }
    }

    /// The collection of clients currently connected to the channel
    internal var clients: [ChannelClient] = []

    // The transport used for the channel connection
    internal fileprivate(set) var transport: ChannelTransport! = nil
    
    // The collection of result handlers for RPC invocations
    fileprivate var rpcHandlers = [String: RPCResultHandler]()

    fileprivate var pingTimer: Timer? = nil

    fileprivate var lastPingDate: TimeInterval? = nil

    /**
       Internal initializer
    
     - parameter url:     The endpoint for the channel
     - parameter service: The serivice providing the connectivity

     - returns: A channel instance
    */
    internal init(uri: String, service :Service)
    {
        super.init()
        self.uri = uri
        self.service = service
        self.completionQueue = DispatchQueue(label: "\(uri)")
        let channelURL = service.uri + "channels/" + self.uri
        transport = ChannelTransportFactory.channelTrasportForType(channelURL, service: service)
        transport.delegate = self
    }

    /**
      Connects to the channel. This method will asynchronously call the delegate's onConnect method and post a
      ChannelEvent.Connect notification upon completion.
      When a TV application connects to this channel, the onReady method/notification is also fired
    */
    open func connect()
    {
        connect(nil)
    }

    /**
      Connects to the channel. This method will asynchronously call the delegate's onConnect method and post a
      ChannelEvent.Connect notification upon completion.
      When a TV application connects to this channel, the onReady method/notification is also fired
    
    - parameter attributes: Any attributes you want to associate with the client (ie. ["name":"FooBar"])
    */
    open func connect(_ attributes: [String:String]?)
    {
        connect(attributes, completionHandler: nil)
    }

    /**
       Connects to the channel. This method will asynchronously call the delegate's onConnect method and post a
       ChannelEvent.Connect notification upon completion.
       When a TV application connects to this channel, the onReady method/notification is also fired
     
       - parameter attributes:        Any attributes you want to associate with the client (ie. ["name":"FooBar"])
       - parameter completionHandler: The callback handler
     
    */
    open func connect(_ attributes: [String:String]?, completionHandler: ((_ client: ChannelClient?, _ error: NSError?) -> Void)?)
    {
        var observer: AnyObject!
        if let completionHandler = completionHandler
        {
            observer = on(ChannelEvent.Connect.rawValue)
            { [unowned self] (notification) -> Void in

                self.off(observer)
                observer = nil // important - break ownership cycle to make sure completionHandler provided by client does not have to take care about 'self' capturing

                let userInfo = (notification! as NSNotification).userInfo as! [String:AnyObject]
                let client = userInfo["client"] as? ChannelClient
                let error = userInfo["error"] as? NSError
                completionHandler(client, error)
            }
        }
        if completionQueue != nil {
            transport.queue = completionQueue
        }
        transport.connect(attributes, security: securityMode)
    }

    /**
       Disconnects from the channel. This method will asynchronously call the delegate's onDisconnect and post a
       ChannelEvent.Disconnect notification upon completion.
     
       - parameter completionHandler: The callback handler
     
       - client: The client that is disconnecting which is yourself
       - error: An error info if disconnect fails
    */
    open func disconnect(_ completionHandler: ((_ client: ChannelClient?, _ error: NSError?) -> Void)?)
    {
        if let completionHandler = completionHandler
        {
            var observer: AnyObject!
            observer = on(ChannelEvent.Disconnect.rawValue)
            { [unowned self] (notification) -> Void in

                self.off(observer)
                observer = nil // important - break ownership cycle to make sure completionHandler provided by client does not have to take care about 'self' capturing
                
                let userInfo: [String:AnyObject] = (notification! as NSNotification).userInfo as! [String:AnyObject]
                let client: ChannelClient = userInfo["client"] as! ChannelClient
                let error: NSError? = (notification! as NSNotification).userInfo?["error"] as? NSError
                
                completionHandler(client, error)
            }
        }
        
        transport.close()
    }

    /**
      Disconnects from the channel. This method will asynchronously call the delegate's onDisconnect and post a
      ChannelEvent.Disconnect notification upon completion.
    */
    open func disconnect()
    {
        disconnect(nil)
    }

    /**
      Publish an event containing a text message payload
    
    - parameter event:   The event name
    - parameter message: A JSON serializable message object
    */
    open func publish(event: String, message: AnyObject?)
    {
        emit(event: event, message: message, target: MessageTarget.Broadcast.rawValue as AnyObject, data: nil)
    }

    /**
        Publish an event containing a text message and binary payload
     
      - parameter event:   The event name
      - parameter message: A JSON serializable message object
      - parameter data:    Any binary data to send with the message
    */
    open func publish(event: String, message: AnyObject?, data: Data)
    {
        emit(event: event, message: message, target: MessageTarget.Broadcast.rawValue as AnyObject, data: data)
    }

    /**
        Publish an event with text message payload to one or more targets
     
      - parameter event:   The event name
      - parameter message: A JSON serializable message object
      - parameter target:  The target recipient(s) of the message.Can be a string client id, a collection of ids or a string MessageTarget (like MessageTarget.All.rawValue)
    */
    open func publish(event: String, message: AnyObject?, target: AnyObject)
    {
        emit(event: event, message: message, target: target, data: nil)
    }

   /**
         Publish an event containing a text message and binary payload to one or more targets
     
       - parameter event:   The event name
       - parameter message: A JSON serializable message object
       - parameter data:    Any binary data to send with the message
       - parameter target:  The target recipient(s) of the message.Can be a string client id, a collection of ids or a string MessageTarget (like MessageTarget.All.rawValue)
    */
    open func publish(event: String, message: AnyObject?, data: Data, target: AnyObject )
    {
        emit(event: event, message: message, target: target, data: data)
    }

    /**
      A snapshot of the list of clients currently connected to the channel
    
    - returns: list of clients currently connected to the channel
    */
    open func getClients() -> [ChannelClient]
    {
        let clientList = NSArray(array: clients)
        return clientList as! [ChannelClient]
    }

    /**
       A convenience method to subscribe for notifications using blocks.
    
       - parameter notificationName: The name of the notification.
       - parameter performClosure:   The notification closure, which will be executed in the main thread.
                                     Make sure to control the ownership of a variables captured by the closure you provide in this parameter
                                     (e.g. use [unowned self] or [weak self] to make sure that self is released even if you did not unsubscribe from notification)
     
       - returns: An observer handler for removing/unsubscribing the block from notifications
    */
    open func on(_ notificationName: String, performClosure:@escaping (Notification!) -> Void) -> AnyObject?
    {
        return NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: notificationName), object: self, queue: OperationQueue.main, using: performClosure)
    }

    /**
      A convenience method to unsubscribe from notifications
    
    - parameter observer: The observer object to unregister observations
    */
    open func off(_ observer: AnyObject)
    {
        NotificationCenter.default.removeObserver(observer)
    }

    /// The description of the client
    open override var description: String
    {
        return "\(type(of: self)): { URI: \(self.uri) }"
    }
    
    open func setSecurityMode(security: Bool, completionHandler: @escaping (_ isSupport:Bool, _ error:NSError?) -> Void)
    {
        if(security)
        {
            self.service.isSecurityModeSupported(completionHandler: {(isSupport, error) -> Void in
                
                self.securityMode = isSupport
                
                completionHandler(isSupport, error)
                
            })
        }
        else
        {
            completionHandler(false, nil)
            
            self.securityMode = false
        }
    }

    func getSecureURL(url:String) ->String
    {
        var secureURL = url.replacingOccurrences(of: "http", with: "https")
        secureURL = secureURL.replacingOccurrences(of: "8001", with: "8002")
        
        return secureURL
    }

}

// MARK: - Channel (Internal) -

internal extension Channel
{
    /**
       sendRPC invokes a remote method
     
     - parameter method:  The method to be invoked
     - parameter params:  The parameters for the remote procedure
     - parameter handler: The response/result closure
    */
    internal func sendRPC(_ method: String, params: [String:AnyObject]?, handler: @escaping ((_ message: RPCMessage) -> Void))
    {
        let uuid = UUID().uuidString
        var messageEnvelope = [String:AnyObject]()
        messageEnvelope["id"] = uuid as AnyObject?
        messageEnvelope["method"] = method as AnyObject?
        if params != nil
        {
            messageEnvelope["params"] = params as AnyObject?
        }
        if let stringMessage = JSON.stringify(messageEnvelope as AnyObject) {
            transport.send(stringMessage)
            rpcHandlers[uuid] = RPCResultHandler(handler: handler)
        }
    }
    
    /**
       Publish an event containing a text message and binary payload to one or more targets
     
     - parameter event:   The event name
     - parameter message: A JSON serializable message object
     - parameter data:    Any binary data to send with the message
     - parameter target:  The target recipient(s) of the message.Can be a string client id, a collection of ids or a string MessageTarget (like MessageTarget.All.rawValue)
     */
    internal func emit(event: String, message: AnyObject?, target: AnyObject, data: Data?)
    {
        var method = ChannelMethod.Emit
        
        if event == "ms.voice.control"
        {
            method = ChannelMethod.Voice
        }

        if let messageEnvelope = getMessageEnvelope(method.rawValue, event: event, message: message, target: target)
        {
            if let stringMessage = JSON.stringify(messageEnvelope as AnyObject)
            {
                if data == nil
                {
                    transport.send(stringMessage)
                }
                else
                {
                    transport.sendData(encodeMessage(stringMessage, payload: data!))
                }
            }
            else
            {
                //TODO: report an error
                Log.error("Unable to serialize the message")
            }
        }
    }

    /**
       process received message by id and assign it to handler
     
     - parameter message: RPC message
     */
    internal func processRPCMessage(_ message: RPCMessage)
    {
        if let handler = rpcHandlers[ message.id ]
        {
            handler.handler(message)
            rpcHandlers.removeValue(forKey: message.id)
        }
    }

    internal func processMessage(_ message: Message)
    {
        if let event = ChannelEvent(rawValue: message.event)
        {
            switch event
            {
                case .Connect:
                    let id = message.data!.value(forKeyPath: "id") as? String
                    let clientsArray: [[String:AnyObject]]! = message.data!.value(forKeyPath: "clients") as? [[String:AnyObject]]
                    for clientDictionary in clientsArray
                    {
                        if let client = ChannelClient(clientInfo: clientDictionary)
                        {
                            if id == client.id
                            {
                                me = client
                            }
                            
                            clients.append(client)
                        }
                    }
                    
                    isConnected = true
                    startConnectionAliveCheck()
                    delegate?.onConnect?(me, error: nil)
                    NotificationCenter.default.post(Notification(name: NSNotification.Name(message.event), object: self, userInfo: ["client": me] ))
                
                case .ClientConnect:
                    if  let clientInfo = message.data as? [String:AnyObject],
                        let client = ChannelClient(clientInfo: clientInfo)
                    {
                        clients.append(client)
                        NotificationCenter.default.post(Notification(name: NSNotification.Name(message.event), object: self, userInfo: ["client": client]))
                        delegate?.onClientConnect?(client)
                    }
                
                case .ClientDisconnect:
                    let clientId = message.data!["id"] as! String
                    let found = self.clients.filter{$0.id == clientId}
                    if found.count > 0
                    {
                        let client = found[0]
                        _ = clients.removeObject(client)
                        delegate?.onClientDisconnect?(client)
                        NotificationCenter.default.post(Notification(name: NSNotification.Name(message.event), object: self, userInfo: ["client":client]))
                    }
                
                case .Ping:
                    let Date = Foundation.Date()
                    lastPingDate = Date.timeIntervalSince1970
                
                case .Ready:
                    delegate?.onReady?()
                    NotificationCenter.default.post(Notification(name: NSNotification.Name(message.event), object: self))
                
                case .Error:
                    let channelError = NSError(domain: "Channel Error", code: -1, userInfo: [NSLocalizedDescriptionKey:message.data!["message"] as! String])
                    delegate?.onError?(channelError)
                    NotificationCenter.default.post(Notification(name: NSNotification.Name(message.event), object: self, userInfo: ["error":channelError]))
                
                case .Unauthorized:
                    let authError = NSError(domain: "Channel Error", code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Device did not authorize connection to channel"])
                    delegate?.onConnect?(nil, error: authError)
                    NotificationCenter.default.post(
                        Notification(name: Notification.Name(rawValue: ChannelEvent.Connect.rawValue), object: self, userInfo: ["error": authError]))
                    self.disconnect()
                
                case .Timeout:
                    let timeoutError = NSError(domain: "Channel Error", code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "Connection authorization timeout"])
                    delegate?.onConnect?(nil, error: timeoutError)
                    NotificationCenter.default.post(
                        Notification(name: Notification.Name(rawValue: ChannelEvent.Connect.rawValue), object: self, userInfo: ["error": timeoutError]))
                    self.disconnect()
                
                 //Disconnect in case we get disconnect client request from DMP
                case .Disconnect:
                    self.disconnect()
                
                default:
                    Log.error("Unhandled message event: \(event)")
            }
        }
        else
        {
            NotificationCenter.default.post(Notification(name: NSNotification.Name(message.event), object: self, userInfo: ["message":message]))
            delegate?.onMessage?(message)
        }
    }

    
}

// MARK: - Channel (Private) -

internal extension Channel
{
    fileprivate func getMessageEnvelope(_ method: String, event: String, message: AnyObject?, target: AnyObject, id: String? = nil) -> [String:AnyObject]?
    {
        let convertedTarget = self.convertTarget(target)
        
        if convertedTarget == nil
        {
            return nil
        }
        
        var envelope = [String:AnyObject]()
        envelope["method"] = method as AnyObject?

        if id != nil && id?.lengthOfBytes(using: String.Encoding.utf8) > 0
        {
            envelope["id"] = id as AnyObject?
        }

        var params = [String:AnyObject]()
        params["to"] = convertedTarget!
        params["event"] = event as AnyObject?

        if message != nil
        {
            params["data"] =  message!
        }

        envelope["params"] = params as AnyObject?

        return envelope
    }
    
    /**
     target may me a string, an array of string, a ChannelClient instance or an array of them - convert it to string or array of strings
    */
    fileprivate func convertTarget(_ target: AnyObject) -> AnyObject?
    {
        var convertedTarget: AnyObject? = nil
        
        switch target
        {
            case let idTarget as String:
                convertedTarget = idTarget as AnyObject?
            
            case let arrayTarget as [String]:
                if arrayTarget.count < 0
                {
                    convertedTarget = arrayTarget as AnyObject?
                }
            
            case let clientTarget as ChannelClient:
                convertedTarget = clientTarget.id as AnyObject?
            
            case let clientsTarget  as [ChannelClient]:
                if clientsTarget.count < 0
                {
                    var clientIds = [String]()
                    for client in clientsTarget
                    {
                        clientIds.append(client.id)
                    }
                    convertedTarget = clientIds as AnyObject?
                }
            
            default: break
        }
        
        return convertedTarget
    }
    
    fileprivate func encodeMessage(_ message: String, payload: Data) -> Data
    {
        let head: Data = message.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let data: NSMutableData = NSMutableData()
        var headByteLen = UInt16(head.count).bigEndian
        data.append(&headByteLen, length: MemoryLayout<UInt16>.size)
        data.append(head)
        data.append(payload)
        return data as Data
    }

    fileprivate func decodeMessage(_ data: Data) -> [String:AnyObject]?
    {
        var headByteLen: UInt16 = 0; (data as NSData).getBytes(&headByteLen, length: MemoryLayout<UInt16>.size)
        let headLen =  Int(UInt16(bigEndian: headByteLen))
        //let messageData = data.subdata(in: NSMakeRange(2, headLen))
        let messageData = data.subdata(in: 2..<headLen)
        if let message = NSString(data: messageData, encoding: String.Encoding.utf8.rawValue)
        {
            //let payload = data.subdata(in: NSMakeRange(headLen + 2, data.count - 2 - headLen ))
            let start = headLen - 2
            let length = data.count - 2 - headLen
            let payload = data.subdata(in: start..<length)
            return ["message": message, "payload": payload as AnyObject]
        }
        else
        {
            return nil
        }
    }
    
    fileprivate func startConnectionAliveCheck()
    {
        if isConnected && self.me != nil
        {
            lastPingDate = nil
            DispatchQueue.main.async(execute: {
                self.pingTimer = Timer.scheduledTimer(timeInterval: self.connectionTimeout, target: self, selector: #selector(Channel.checkConnectionAlive(_:)), userInfo: nil, repeats: true)
                self.emit(event: ChannelEvent.Ping.rawValue, message: "msfVersion2" as AnyObject?, target: self.me, data: nil)
            })
        }
    }
    
    fileprivate func stopConnectionAliveCheck()
    {
        if pingTimer != nil
        {
            pingTimer?.invalidate()
            pingTimer = nil
        }
    }

    // NOTE: this method should be declared 'internal' since making it private causes runtime error
    internal func checkConnectionAlive(_ timer: Timer)
    {
        if lastPingDate == nil
        {
            stopConnectionAliveCheck()
//            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
            DispatchQueue.global(qos: .background).async(execute: {
                self.transport.close(force: true)
				self.disconnect()
            })
        }
        else
        {
            if isConnected && me != nil
            {
				let currentDate = Date()
				if ((currentDate.timeIntervalSince1970 - lastPingDate!) > 15 )
				{
					lastPingDate = nil
				}
                
                emit(event: ChannelEvent.Ping.rawValue, message: "" as AnyObject?, target: me, data: nil)
            }
        }
    }
}

// MARK: - Channel (ChannelTransportDelegate) -

extension Channel: ChannelTransportDelegate
{
    internal func processTextMessage(_ message: String)
    {
        if let result: [String:AnyObject] = JSON.parse(jsonString: message) as? [String:AnyObject]
        {
            if (result["id"] != nil)
            {
                let message = RPCMessage(message: result)
                processRPCMessage(message)
            }
            else
            {
                if let message = Message(messageData: result)
                {
                    processMessage(message)
                }
                else
                {
                    Log.error("ERROR: unable to create Message")
                }
            }
        }
    }

    internal func processDataMessage(_ data: Data)
    {
        if let unwrappedData = decodeMessage(data)
        {
            let payload = unwrappedData["payload"]! as! Data
            let message = unwrappedData["message"]! as! String
            if  let result = JSON.parse(jsonString: message) as? [String:AnyObject],
                let messageObject = Message(messageData: result)
            {
                delegate?.onData?(messageObject, payload: payload)
                NotificationCenter.default.post(Notification(name: NSNotification.Name(messageObject.event), object: self, userInfo: ["message":messageObject,"payload":payload]))
            }
        }
        else
        {
            //TODO: add an error definition for malformed binary envelope exception
        }
    }

    internal func didConnect(_ error: NSError?)
    {
        if error != nil
        {
            delegate?.onConnect?(nil, error: error)
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: ChannelEvent.Connect.rawValue), object: self, userInfo: ["client": NSNull()] ))
        }
		startConnectionAliveCheck()
    }

    internal func didDisconnect(_ error: NSError?)
    {
        if isConnected
        {
            stopConnectionAliveCheck()
            clients.removeAll(keepingCapacity: false)
            isConnected = false
            
            DispatchQueue.main.async(execute: {
                self.delegate?.onDisconnect?(self.me, error: error)
            })
            
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: ChannelEvent.Disconnect.rawValue), object: self, userInfo: ["client":me]))
            me = nil
        }
    }

    /**
       Event Recieved when Audio/Video/Photo Player Error is occurred
     
     - parameter error: The Error
    */
    internal func onError(_ error: NSError)
    {
        // TBD
    }

}
