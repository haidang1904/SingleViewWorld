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

internal protocol ChannelTransportDelegate: class
{
    func processTextMessage(_ message: String)
    func processDataMessage(_ data: Data)
    func didConnect(_ error: NSError?)
    func didDisconnect(_ error: NSError?)
    func onError(_ error: NSError)
}

internal protocol ChannelTransport
{
    weak var delegate: ChannelTransportDelegate! {get set}
    var queue: DispatchQueue? {get set}
    init (url: String, service: Service?)
    func close()
    func close(force: Bool)
    func connect(_ options: [String:String]?, security:Bool)
    func send(_ message: String)
    func sendData(_ data: Data)
}

internal enum ChannelTransportType
{
    case webSocket
}

internal class ChannelTransportFactory
{
    /**
     Method channelTrasportForType
     
     - parameter url:
     - parameter service:
     
     - returns:
     */
    class func channelTrasportForType(_ url: String, service: Service?) -> ChannelTransport
    {
        if let service = service
        {
            switch service.transportType
            {
                case .webSocket:
                    return  WebSocketTransport(url: url, service: service)
            }
        }
        else
        {
            return  WebSocketTransport(url: url, service: service)
        }
    }
}

