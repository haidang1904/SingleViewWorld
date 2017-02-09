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

/// An Application represents an application on the TV device.
/// Use this class to control various aspects of the application such as launching the app or getting information
@objc open class Application: Channel
{
    /**
     Defines the type of application
     
     - Application: native application installed on TV
     - WebApplication: cloud application installed on cloud
     */
    enum ApplicationType: String
    {
        case Application = "ms.application"
        case WebApplication = "ms.webapplication"
    }
    
    /**
     Methods to access application
     
     - Get:   Retrieves information about the Application on the TV
     - Start: Launches the application on the remote device
     - Stop:  Stops the application on the TV
     - Install: Starts the application install on the TV
     */
    enum ApplicationMethod : String
    {
        case Get = "get"
        case Start = "start"
        case Stop = "stop"
        case Install = "install"
        
        func fullMethodName(_ type: ApplicationType) -> String
        {
            return "\(type.rawValue).\(self.rawValue)"
        }
    }
    
    fileprivate var clientDisconnectObserver: AnyObject?
    
    internal var type = ApplicationType.Application
    
    /// set type based on application types
    fileprivate var restEndpoint: String!
    {
        if type == .Application
        {
            return "\(service.uri)applications/\(self.id)"
        }
        else
        {
            return "\(service.uri)webapplication/"
        }
    }
    
    fileprivate var disconnectCompletionHandler: ( (_ client: ChannelClient, _ error: NSError?) -> Void)! = nil
    
    /// The id of the channel
    open fileprivate(set) var id: String!
    
    /// start arguments
    open fileprivate(set) var args: [String:AnyObject]? = nil
    
     /// Bundle Indentifier
    open static let BUNDLE_IDENTIFIER = "com.samsung.sta.multiscreen.MSF"
     /// property value library
    open static let PROPERTY_VALUE_LIBRARY = "IOS SDK";
    
    /**
     Application constructor
     
     - parameter appId:      application id
     - parameter channelURI: channel uri
     - parameter service:    TV service
     - parameter args:       start arguments
     */
    internal init(appId: AnyObject, channelURI: String, service: Service, args:[String:AnyObject]?)
    {
        self.args = args
        switch appId
        {
            case let url as URL:
                id = url.absoluteString
                type = .WebApplication
            
            case let installedId as String:
                id = installedId
                type = .Application
            
            default:
                break
        }
        
        super.init(uri: channelURI, service: service)
        clientDisconnectObserver = on(ChannelEvent.ClientDisconnect.rawValue, performClosure: clientDisconnect)
    }
    
    /**
     removes client observer when application scope ends
    */
    deinit
    {
        if clientDisconnectObserver != nil
        {
            off(clientDisconnectObserver!)
        }
    }
    /**
      Retrieves information about the Application on the TV
    
    - parameter completionHandler: The callback handler with the status dictionary and an error if any
    */
    open func getInfo(_ completionHandler: @escaping (_ info: [String:AnyObject]?, _ error: NSError?) -> Void)
    {
        var params = [String:AnyObject]()
        switch type
        {
            case .Application:
                params["id"] = id as AnyObject?
            case .WebApplication:
                params["url"] = id as AnyObject?
        }
        
        var secureURL:String = restEndpoint
        if(self.securityMode)
        {
            _ = secureURL = getSecureURL(url: restEndpoint)
        }
        Requester.doGet(secureURL, headers: nil, timeout: 2)
        { (responseHeaders, data, error) -> Void in
        
            DispatchQueue.main.async(execute: {
                if error != nil
                {
                    if data != nil
                    {
                        let message = JSON.parse(data: data!) as! [String:AnyObject]
                        completionHandler(message, error)
                    }
                    else
                    {
                        completionHandler([:], error)
                    }
                }
                else
                {
                    let message = JSON.parse(data: data!) as! [String:AnyObject]
                    completionHandler(message, nil)
                }
            })
        }
    }
    
    /**    
       Launches the application on the remote device, if the application is already running it returns success = true.
       If the startOnConnect is set to false this method needs to be called in order to start the application
     
     - parameter completionHandler: The callback handler
    */
    open func start(_ completionHandler: ((_ success: Bool, _ error: NSError?) -> Void)?)
    {
       	let method = ApplicationMethod.Start.fullMethodName(type)
        var params = [String:AnyObject]()
        switch type
        {
        case .Application:
            params["id"] = id as AnyObject?
        case .WebApplication:
            params["url"] = id as AnyObject?
        }
        if args != nil
        {
            params["data"] = args as AnyObject?
        }
        params["isContents"] = "false" as AnyObject?
        
        params[Message.Property.PROPERTY_OS.rawValue] = UIDevice.current.systemVersion as AnyObject?
        params[Message.Property.PROPERTY_LIBRARY.rawValue] = Application.PROPERTY_VALUE_LIBRARY as AnyObject?
        
        let bundle = Bundle(identifier: Application.BUNDLE_IDENTIFIER)!
        params[Message.Property.PROPERTY_VERSION.rawValue] = bundle.infoDictionary?["CFBundleShortVersionString"] as? String as AnyObject?
        
        sendRPC(method, params: params, handler:
            { (message) -> Void in
                
                DispatchQueue.main.async(execute: {
                        completionHandler?(message.error == nil, message.error)
                })
        })
    }
    
    /**
     retrieves application info in params dictionary
     
     - returns: application properties parameters
     */
    internal func getParams() -> [String:AnyObject]
    {
        var params = [String:AnyObject]()
        switch type
        {
        case .Application:
            params["id"] = id as AnyObject?
        case .WebApplication:
            params["url"] = id as AnyObject?
        }
        
        if args != nil
        {
            params["data"] = args as AnyObject?
        }
        
        return params
    }

    /**
       Stops the application on the TV
     
     - parameter completionHandler: The callback handler
    */
    open func stop(_ completionHandler: ((_ success: Bool, _ error: NSError?) -> Void)?)
    {
        let method = ApplicationMethod.Stop.fullMethodName(type)
        var params = [String:AnyObject]()
        switch type
        {
            case .Application:
                params["id"] = id as AnyObject?
            case .WebApplication:
                params["url"] = id as AnyObject?
        }
        
        sendRPC(method, params: params, handler:
        { (message) -> Void in
            DispatchQueue.main.async(execute: {
                completionHandler?(message.error == nil, message.error)
            })
        })
    }
    
    /**
        Starts the application install on the TV, this method will fail for cloud applications
     
      - parameter completionHandler: The callback handler
    */
    open func install(_ completionHandler: ((_ success: Bool, _ error: NSError?) -> Void)?)
    {
        var params = [String:AnyObject]()
        switch type
        {
            case .Application:
                params["id"] = id as AnyObject?
            
            case .WebApplication:
                DispatchQueue.main.async(execute: {
                    let applicationError = NSError(domain: "Application Error", code: -1,
                        userInfo: [NSLocalizedDescriptionKey:"Install a web application is not supported"])
                    completionHandler?(false, applicationError)
                })
        }
        
        Requester.doPut( restEndpoint , payload: nil, headers: [:], timeout: TimeInterval(10), completionHandler:
        { (responseHeaders, data, error) -> Void in
        
            DispatchQueue.main.async(execute: {
                completionHandler?(error == nil, error)
            })
        })
        
    }
    
    /**
       override channel connect.
       connects your client with the host TV app
     - parameter attributes: Any attributes you want to associate with the client (ie. ["name":"FooBar"])
     - parameter completionHandler: The callback handler
    */
    open override func connect(_ attributes: [String : String]?, completionHandler: ((_ client: ChannelClient?, _ error: NSError?) -> Void)?)
    {
        self.superConnect(attributes, completionHandler:
            { (client, error) -> Void in
                if(error != nil)
                {
                    completionHandler?(nil, error)
                }
                else
                {
                    self.start(
                        { (success, error) -> Void in
                            if error != nil
                            {
                                DispatchQueue.main.async
                                {
                                    completionHandler?(nil, error)
                                    self.delegate?.onConnect?(nil, error: error)
                                    NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: ChannelEvent.Connect.rawValue), object: self, userInfo: ["client": NSNull(), "error": error!] ))
                                }
                            }
                            else
                            {
                                completionHandler?(client, nil)
                            }
                    })
                    
                    
                }
                
        })
        
    }
    
    /**
        Disconnects your client with the host TV app
     
      - parameter leaveHostRunning: True leaves the TV app running ,False stops the TV app if yours is the last client
      - parameter completionHandler: The callback handler
    */
    open func disconnect(leaveHostRunning: Bool, completionHandler: ((_ client: ChannelClient?, _ error: NSError?) -> Void)?)
    {
        if !leaveHostRunning
        {
            disconnect(completionHandler)
        }
        else
        {
            super.disconnect(completionHandler)
        }
    }
    
    /**
       Disconnect from the channel and leave the host application running if leaveHostRunning is set to true and you are the last client
     
      - parameter leaveHostRunning: True leaves the TV app running False stops the TV app if yours is the last client
    */
    open func disconnect(leaveHostRunning: Bool)
    {
        disconnect(leaveHostRunning: leaveHostRunning, completionHandler: nil)
    }
    
    /**
       Disconnect from the channel and terminate the host application if you are the last client
    
     - parameter completionHandler: The callback handler
    */
    open override func disconnect(_ completionHandler: ((_ client: ChannelClient?, _ error: NSError?) -> Void)?)
    {
        if !isConnected
        {
            let applicationError = NSError(domain: "Application Error", code: -1, userInfo: [NSLocalizedDescriptionKey:"The Application is not connected"])
            DispatchQueue.main.async
            {
                completionHandler?(self.me, applicationError)
            }
        }
        else if clients.count < 3
        {
            if disconnectCompletionHandler != nil
            {
                let applicationError = NSError(domain: "Application Error", code: -1, userInfo: [NSLocalizedDescriptionKey:"Disconnect was called already"])
                DispatchQueue.main.async(execute: {
                    completionHandler?(self.me, applicationError)
                })
            }
            else
            {
                disconnectCompletionHandler = completionHandler
            }
            
            self.stop(nil)
        }
        else
        {
            super.disconnect(completionHandler)
        }
    }
    
}

// MARK: - Application (Internal) -

extension Application
{
    /**
       Connect to channel without starting the application first.
     
     - parameter attributes:        Any attributes you want to associate with the client (ie. ["name":"FooBar"])
     - parameter completionHandler: callback handler
     */
    internal func connectChannelOnly(_ attributes: [String : String]?, completionHandler: ((_ client: ChannelClient?, _ error: NSError?) -> Void)?)
    {
        super.connect(attributes, completionHandler: completionHandler)
    }
    
    /**
       Start playback of media at the given URL.
    
     - parameter contentURL:        content url
     - parameter completionHandler: completion call back with success and error.
     */
    internal func startPlay(_ contentURL: URL, completionHandler: ((_ success: Bool, _ error: NSError?) -> Void)?)
    {
        let method = ApplicationMethod.Start.fullMethodName(type)
        var params = [String:AnyObject]()
        params["url"] = contentURL.absoluteString as AnyObject?
        params["isContents"] = "true" as AnyObject?
        
        params[Message.Property.PROPERTY_OS.rawValue] = UIDevice.current.systemVersion as AnyObject?
        params[Message.Property.PROPERTY_LIBRARY.rawValue] = Application.PROPERTY_VALUE_LIBRARY as AnyObject?
        
        let bundle = Bundle(identifier: Application.BUNDLE_IDENTIFIER)!
        params[Message.Property.PROPERTY_VERSION.rawValue] = bundle.infoDictionary?["CFBundleShortVersionString"] as? String as AnyObject?
       
        sendRPC(method, params: params, handler:
        { (message) -> Void in
        
            DispatchQueue.main.async(execute: {
                completionHandler?(message.error == nil, message.error)
            })
        })
    }
    
    /**
     Calls when any client gets disconnects
     
     - parameter notification: contains client info
    */
    internal func clientDisconnect(_ notification: Notification!)
    {
        if  let userInfo = notification.userInfo as? [String:ChannelClient],
            let isHost = userInfo["client"]?.isHost
        {
            if isHost
            {
                super.disconnect(nil)
            }
        }
    }
    
    /**
       workaround wrapper due to inability to call super.someMethod() inside a closure with [unowned self]
     
     - parameter attributes: Any attributes you want to associate with the client (ie. ["name":"FooBar"])
     - parameter completionHandler: callback handler
     */
    fileprivate func superConnect(_ attributes: [String : String]?, completionHandler: ((_ client: ChannelClient?, _ error: NSError?) -> Void)!)
    {
        super.connect(attributes, completionHandler: completionHandler)
    }
    
    /**
     
     calls when channel gets disconnect
     - parameter error: provides any error or nil if no error
     */
    override func didDisconnect(_ error: NSError?)
    {
        super.didDisconnect(error)
        if disconnectCompletionHandler != nil
        {
            //disconnectCompletionHandler(me, error)
            disconnectCompletionHandler = nil
        }
    }
}

