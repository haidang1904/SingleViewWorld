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

internal class MSFDiscoveryProvider: ServiceSearchProviderBase
{
    fileprivate enum MSFDMessageType: String
    {
        case Up =       "up"
        case Alive =    "alive"
        case Dowm =     "down"
        case Discover = "discover"
    }

    fileprivate let MULTICAST_ADDRESS   = "224.0.0.7"
    fileprivate let MULTICAST_TTL       = 1
    fileprivate let MULTICAST_PORT:UInt16   = 8001
    fileprivate let MAX_MESSAGE_LENGTH:UInt16  = 2000
    fileprivate let TBEAT_INTERVAL = TimeInterval(1)
    fileprivate let RETRY_COUNT = 3
    fileprivate let RETRY_INTERVAL = 1

    fileprivate var udpSearchSocket: GCDAsyncUdpSocket!
    fileprivate var udpListeningSocket: GCDAsyncUdpSocket!

    //private var unresolvedServices = NSMutableSet(capacity: 0)
    fileprivate var services = NSMutableDictionary(capacity: 0)
    fileprivate var timer: Timer!

    fileprivate var isRestarting = false

    fileprivate let accessQueue = DispatchQueue(label: "MSFDiscoveryProviderQueue", attributes: [])
    // The intializer
    required init(delegate: ServiceSearchProviderDelegate, id: String?)
    {
        super.init(delegate: delegate, id: id)
        type = ServiceSearchDiscoveryType.LAN
    }

    /// Start the search
    override func search()
    {
        self.accessQueue.async(execute: {
            var error: NSError? = nil

            self.udpListeningSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: self.accessQueue)
            self.udpListeningSocket.setIPv6Enabled(false)
            self.udpListeningSocket.setMaxReceiveIPv4BufferSize(self.MAX_MESSAGE_LENGTH)

            do {
                try self.udpListeningSocket.bind(toPort: self.MULTICAST_PORT)
            } catch let error1 as NSError {
                error = error1
                Log.error("udpListeningSocket bindToPort \(error)")
            } catch {
                Log.error("udpListeningSocket bindToPort: unknown error")
                return
            }

            do {
                try self.udpListeningSocket.joinMulticastGroup(self.MULTICAST_ADDRESS)
            } catch let error1 as NSError {
                error = error1
                Log.error("udpListeningSocket joinMulticastGroup \(error)")
            } catch {
                Log.error("udpListeningSocket joinMulticastGroup: unknown error")
                return
            }

            do {
                try self.udpListeningSocket.beginReceiving()
            } catch let error1 as NSError {
                error = error1
                Log.error("udpListeningSocket  beginReceiving \(error)")
            } catch {
                Log.error("udpListeningSocket  beginReceiving: unknown error")
                return
            }

            self.udpSearchSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: self.accessQueue)
            self.udpSearchSocket.setIPv6Enabled(false)
            self.udpSearchSocket.setMaxReceiveIPv4BufferSize(self.MAX_MESSAGE_LENGTH)

            do {
                try self.udpSearchSocket.bind(toPort: 0)
            } catch let error1 as NSError {
                error = error1
                Log.error("udpSearchSocket  bindToPort \(error)")
            } catch {
                Log.error("udpSearchSocket  bindToPort: unknown error")
                return
            }

            do {
                try self.udpSearchSocket.beginReceiving()
            } catch let error1 as NSError {
                error = error1
                Log.error("udpSearchSocket  beginReceiving \(error)")
            } catch {
                Log.error("udpSearchSocket  beginReceiving: unknown error")
                return
            }

            self.udpSearchSocket.send(self.getMessageEnvelope(), toHost: self.MULTICAST_ADDRESS, port: self.MULTICAST_PORT, withTimeout: TimeInterval(-1), tag: 0)

            // if not searching by id
            if self.id == nil
            {
                DispatchQueue.main.async(execute: {
                    self.timer = Timer.scheduledTimer(timeInterval: self.TBEAT_INTERVAL, target: self, selector: #selector(MSFDiscoveryProvider.update(_:)), userInfo: nil, repeats: true)
                })
            }
            self.isSearching = true
        })
    }

    // NOTE: this method should be declared 'internal' since making it private causes runtime error
    internal func update(_ timer: Timer)
    {
        self.accessQueue.async(execute: {
            let now = Date()
            let keys = NSArray(array: self.services.allKeys) as! [String]
            for key in keys
            {
                if (self.services[key] as! Date).compare(now) == ComparisonResult.orderedAscending
                {
                    self.services.removeObject(forKey: key)
                    Log.debug("MSFD -> self.services \(key) \(self.services)")
                    self.delegate?.onServiceLost(key, discoveryType: self.type)
                }
            }
        })
    }

    /// Stops the search
    override func stop()
    {
        self.accessQueue.sync(execute: {
            if self.isSearching
            {
                self.isSearching = false
                if self.timer != nil
                {
                    self.timer.invalidate()
                    self.timer = nil
                }

                do {
                    try self.udpListeningSocket.leaveMulticastGroup(self.MULTICAST_ADDRESS)
                } catch let error as NSError {
                    Log.error("\(error)")
                } catch {
                    fatalError()
                }
                
                self.udpListeningSocket = nil
                self.udpSearchSocket = nil
                self.services.removeAllObjects()
                //self.unresolvedServices.removeAllObjects()

                //delegate?.onStop(self)
            }
        })
    }

    override func serviceResolutionFailed(_ serviceId: String, discoveryType: ServiceSearchDiscoveryType)
    {
        if discoveryType == type
        {
            self.accessQueue.async(execute: {
                self.services.removeObject(forKey: serviceId)
            })
        }
    }

    /**
    * Called when the datagram with the given tag has been sent.
    **/
    func udpSocket(_ sock: GCDAsyncUdpSocket!, didSendDataWithTag tag: Int) {

    }

    /**
    * Called if an error occurs while trying to send a datagram.
    * This could be due to a timeout, or something more serious such as the data being too large to fit in a sigle packet.
    **/
    func udpSocket(_ sock: GCDAsyncUdpSocket!, didNotSendDataWithTag tag: Int, dueToError error: NSError!) {

    }

    /**
    * Called when the socket has received the requested datagram.
    **/
    func udpSocket(_ sock: GCDAsyncUdpSocket!, didReceiveData data: Data!, fromAddress address: Data!, withFilterContext filterContext: AnyObject!)
    {
        if  let msg = JSON.parse(data: data) as? [String:AnyObject],
            let type = MSFDMessageType(rawValue: msg["type"] as! String)
            , type == .Up || type == .Alive
        {
            serviceFound(msg as NSDictionary)
        }
    }

    /**
    * Called when the socket is closed.
    **/
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket!, withError error: NSError!)
    {
        if isSearching
        {
            isRestarting = true
            self.stop()
            self.delegate?.clearCacheForProvider(self)
            self.search()
        }
        else if !isRestarting
        {
            isSearching = false
            delegate?.onStop(self)
        }
    }

    fileprivate func serviceFound(_ msg: NSDictionary)
    {
        let sid = msg["sid"] as? String
        
        if (sid != nil && ((id != nil && id == sid) || (id == nil)))
        {
            let uri = ((msg.object(forKey: "data") as! NSDictionary).object(forKey: "v2") as! NSDictionary).object(forKey: "uri") as? String
        
            let ttl = msg["ttl"] as! Double
            if services[sid!] == nil
            {
                Log.debug("MSFD -> serviceFound \(sid) \(uri)")
                services[sid!] = Date(timeIntervalSinceNow: TimeInterval(ttl/1000.0))
                delegate?.onServiceFound(sid!, serviceURI: uri!, discoveryType: ServiceSearchDiscoveryType.LAN)
            }
            else
            {
                self.services[sid!] = Date(timeIntervalSinceNow: TimeInterval(ttl/1000.0))
            }
        }
    }

    fileprivate func getMessageEnvelope() -> Data
    {
        let msg: [String: AnyObject] = [
            "type": MSFDMessageType.Discover.rawValue as AnyObject,
            "data": [:] as AnyObject,
            "cuid":  UUID().uuidString as AnyObject
        ]
        return JSON.jsonDataForObject(msg as AnyObject)!
    }



}
