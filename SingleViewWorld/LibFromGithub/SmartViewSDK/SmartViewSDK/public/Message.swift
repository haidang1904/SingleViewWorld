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

///  This class encapsulates the message that
@objc open class Message : NSObject
{
    /// The event name
    open let event: String!

    /// The publisher of the event
    open let from: String!

    /// A dictionary containig the message
    open let data: AnyObject?

//    public static let PROPERTY_OS = "os"
//    public static let PROPERTY_LIBRARY = "library"
//    public static let PROPERTY_VERSION = "version"
    
    internal enum Property : String
    {
        case PROPERTY_MESSAGE               = "message"
        case PROPERTY_METHOD                = "method"
        case PROPERTY_PARAMS                = "params"
        case PROPERTY_ID                    = "id"
        case PROPERTY_URL                   = "url"
        case PROPERTY_ARGS                  = "args"
        case PROPERTY_EVENT                 = "event"
        case PROPERTY_DATA                  = "data"
        case PROPERTY_TO                    = "to"
        case PROPERTY_FROM                  = "from"
        case PROPERTY_CLIENTS               = "clients"
        case PROPERTY_RESULT                = "result"
        case PROPERTY_ERROR                 = "error"
        case PROPERTY_OS                    = "os"
        case PROPERTY_LIBRARY               = "library"
        case PROPERTY_VERSION               = "version"
        case PROPERTY_MODEL_NUMBER          = "modelNumber"
        case PROPERTY_DEVICE_NAME           = "deviceName"
        case PROPERTY_APP_NAME              = "appName"
    }
    
    
    /**
        The initializer
     
       - parameter message: A dictionary containing the message
     
       - returns: A Message instance
     */
    internal init?(messageData: [String:AnyObject])
    {
        let eventName = messageData["event"] as? String
        
        if eventName != nil && NSString(string: eventName!).hasPrefix("ms.")
        {
            self.from = ""
        }
        else
        {
            self.from = (messageData["from"] as? String) ?? ""
        }
        
        self.event = eventName
        self.data = messageData["data"]
        
        super.init()

        if self.event == nil
        {
            return nil
        }
    }

}
