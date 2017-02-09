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

///  A client currently connected to the channel
@objc open class ChannelClient:  NSObject
{
    fileprivate var clientInfo: [String:AnyObject]

    /// The id of the client
    open var id: String
    {
        return clientInfo["id"] as! String
    }

    /// The time which the client connected in epoch milliseconds
    lazy open fileprivate(set) var connectTime: Date? =
    {
        if let connectTime = (self.clientInfo["connectTime"] as? Int)
        {
            return Date(timeIntervalSince1970: TimeInterval(connectTime))
        }
        
        return nil
    }()

    /// A dictionary of attributes passed by the client when connecting
    open var attributes: AnyObject?
    {
        return clientInfo["attributes"]
    }

    /// Flag for determining if the client is the host
    open var isHost: Bool
    {
        return (clientInfo["isHost"] as? Bool ?? false)
    }

    /// The description of the client
    override open var description: String
    {
        return "ClientInfo: { id: \(id), isHost: \(isHost) }"
    }
    
    /**
       The initializer
     
       - parameter clientInfo: A dictionary with the client information
     
       - returns: A ChannelClient instance or nil if clientInfo does not contain ID
     */
    internal init?(clientInfo: [String:AnyObject])
    {
        self.clientInfo = clientInfo
        super.init()
        
        if (clientInfo["id"] as? String) == nil
        {
            return nil
        }
    }
}

public func == (lhs: ChannelClient, rhs: ChannelClient) -> Bool
{
    return lhs.id == rhs.id
}
