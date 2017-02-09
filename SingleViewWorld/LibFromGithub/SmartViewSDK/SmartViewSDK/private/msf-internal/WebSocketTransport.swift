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


internal class WebSocketTransport: ChannelTransport
{
    internal fileprivate(set) var isConnecting = false
    internal let url: String
    internal weak var delegate: ChannelTransportDelegate!
    var queue: DispatchQueue? = nil
    fileprivate var socket: WebSocket!

    required init (url: String, service: Service?)
    {
        self.url = url
    }

    internal func close()
    {
        socket?.disconnect()
    }

    internal func close(force: Bool)
    {
        if socket != nil && socket!.isConnected
        {
            socket?.disconnect()
        }
    }

    internal func connectSync(_ options: [String:String]?, security:Bool)
    {
        isConnecting = true
        var optionsString = ""
        if options != nil
        {
            optionsString = "?"
            for (key,value) in options!
            {
                optionsString += "\(key)=\(value)&"
            }
        }
        
        var secureURL:String = url
        
        if url != "samsung.gamepad.control" {
            if(security)
            {
                secureURL = getSecureURL(url: url)
            }
        }
        
        print("secure URL is \(secureURL)")
        
        // let bundle = NSBundle(identifier: Application.BUNDLE_IDENTIFIER)!
        // let rootCertificatePath = bundle.pathForResource("ca_crt", ofType: "cer")!
        
        // let rootCertificatePath = NSBundle.mainBundle().pathForResource("ca_crt", ofType: "cer")!
        //  let data = NSData(contentsOfFile: rootCertificatePath)!
        let endPoint = NSURL(string: NSString(string:  secureURL + optionsString).addingPercentEscapes(using: String.Encoding.utf8.rawValue)!)!
        socket = WebSocket(url: endPoint  as URL)
        
        if socket.supportedSSLSchemes.contains(endPoint.scheme!) {
            socket.disableSSLCertValidation = true
            //////////////////////////
            // Adding certificate to key chain access
            
            let result: UnsafeMutablePointer<AnyObject?>? = nil
            var error = noErr
            
            let bundle = Bundle.main
            
            let rootCertPath = bundle.path(forResource: "ca_crt", ofType: "cer")!
            
            let rootCertData = NSData(contentsOfFile: rootCertPath)!
            let rootCert     = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData)! as SecCertificate
            
            
            let kSecClassValue            = String(format: kSecClass as String)
            let kSecClassCertificateValue = String(format: kSecClassCertificate as String)
            let kSecValueRefValue         = String(format: kSecValueRef as String)
            
            let dict = [ kSecClassValue : kSecClassCertificateValue, kSecValueRefValue : rootCert ] as CFDictionary
            
            error = SecItemAdd(dict, result)
            
            if(error == noErr)
            {
                print("Installed root certificate successfully");
            }
            else if(error == errSecDuplicateItem)
            {
                print("Duplicate root certificate entry");
            }
            else
            {
                print("Install root certificate failure")
            }
            ///////////////////////////
            socket.security = SSLSecurity(certs: [SSLCert(data:rootCertData as Data)], usePublicKeys: false)
        }
        
        if queue != nil {
            socket!.callbackQueue = queue!
        }
        socket!.delegate = self
        socket!.connect()
    }
    
    internal func connect(_ options: [String:String]?, security:Bool)
    {
        queue?.async { [weak self] in
            self?.connectSync(options, security: security)
        }
    }

    internal func send(_ message: String)
    {
        socket?.write(string: message)
    }

    internal func sendData(_ data: Data)
    {
        socket?.write(data: data)
    }
    
    func getSecureURL(url:String) ->String
    {
        var secureURL = url.replacingOccurrences(of: "http", with: "https")
        secureURL = secureURL.replacingOccurrences(of: "8001", with: "8002")
        
        return secureURL
    }
}

// MARK: - WebsocketDelegate -

extension WebSocketTransport: WebSocketDelegate
{
    func websocketDidConnect(_ socket: WebSocket)
    {
        isConnecting = false
        delegate?.didConnect(nil)
    }

    func websocketDidDisconnect(_ socket: WebSocket, error: NSError?)
    {
        if isConnecting
        {
            isConnecting = false
            delegate?.didConnect(error)
        }
        else
        {
            if error != nil && error!.code == 1000
            {
                delegate?.didDisconnect(nil)
            }
            else
            {
                delegate?.didDisconnect(error)
            }
        }
    }

    func websocketDidReceiveMessage(_ socket: WebSocket, text: String)
    {
        delegate.processTextMessage(text)
    }

    func websocketDidReceiveData(_ socket: WebSocket, data: Data)
    {
        delegate.processDataMessage(data)
    }
}

