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

private let kDefaultResolveTime = 3.0
private let kServiceDomain = "local."
private let kServiceType = "_samsungmsf._tcp."


internal class MDNSDiscoveryProvider: ServiceSearchProviderBase
{
    // The raw network service (since the NetServices delegation methods are call in the main thread there is no need for a thread safe array)
    fileprivate var netServices = [NetService]()

    fileprivate var retryResolve = Set<String>()

    // The service browser
    fileprivate let serviceBrowser = NetServiceBrowser()

    required init(delegate: ServiceSearchProviderDelegate, id: String?)
    {
        super.init(delegate: delegate, id: id)
        type = ServiceSearchDiscoveryType.LAN
        serviceBrowser.delegate = self
    }

    // The deinitializer
    deinit
    {
        serviceBrowser.delegate = nil
    }

    // Start the search
    override func search()
    {
        // Cancel the previous search if any
        if isSearching
        {
            serviceBrowser.stop()
        }

        if id == nil
        {
            serviceBrowser.searchForServices(ofType: kServiceType, inDomain: kServiceDomain)
        }
        else
        {
            DispatchQueue.main.async(execute: {
                let aNetService = NetService(domain: kServiceDomain, type: kServiceType, name: self.id!)
                self.netServiceBrowser(self.serviceBrowser, didFind: aNetService, moreComing: false)
            })
        }
    }

    // Stops the search
    override func stop()
    {
        isSearching = false
        serviceBrowser.stop()
    }

    // MARK: - Private -

    fileprivate func removeService(_ aNetService: NetService!)
    {
        _ = netServices.removeObject(aNetService)
    }

}

// MARK: - NSNetServiceBrowserDelegate  -

extension MDNSDiscoveryProvider: NetServiceBrowserDelegate
{
    func netServiceBrowserWillSearch(_ aNetServiceBrowser: NetServiceBrowser)
    {
        isSearching = true
        delegate?.onStart(self)
    }

    func netServiceBrowserDidStopSearch(_ aNetServiceBrowser: NetServiceBrowser)
    {
        delegate?.clearCacheForProvider(self)
        netServices.removeAll(keepingCapacity: false) // clear the cache
        if isSearching
        {
            search()
        }
        else
        {
            delegate?.onStop(self)
        }
    }

    func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber])
    {
        serviceBrowser.stop()
        netServiceBrowserDidStopSearch(aNetServiceBrowser)
    }

    func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didFind aNetService: NetService, moreComing: Bool)
    {
        if let found = netServices.index(of: aNetService)
        {
            Log.debug("ignoring \(netServices[found].name)")
        }
        else
        {
            aNetService.delegate = self
            aNetService.resolve(withTimeout: kDefaultResolveTime)
            netServices.append(aNetService)
        }
    }

    func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didRemove aNetService: NetService, moreComing: Bool)
    {
        aNetService.stop()
        aNetService.delegate = nil
        removeService(aNetService)
        delegate?.onServiceLost(aNetService.name, discoveryType: self.type)
    }
}

// MARK: - NSNetServiceDelegate  -

extension MDNSDiscoveryProvider: NetServiceDelegate
{
    func netService(_ aNetService: NetService, didNotResolve errorDict: [String : NSNumber])
    {
        if id != nil
        {
            delegate?.onStop(self)
        }
        else if retryResolve.contains(aNetService.name)
        {
            retryResolve.remove(aNetService.name)
            removeService(aNetService)
        }
        else
        {
            retryResolve.insert(aNetService.name)
            aNetService.resolve(withTimeout: TimeInterval(15))
        }
    }

    func netServiceDidResolveAddress(_ aNetService: NetService)
    {
        //The text record have the API root URI so the implementer can contruct the REST endpoint for App management
        if aNetService.addresses!.count > 0
        {
            let txtRecord : NSDictionary = NetService.dictionary(fromTXTRecord: aNetService.txtRecordData()!) as NSDictionary
            
            if let endpointData = txtRecord["se"] as? Data
            {
                let endpoint: String = NSString(bytes: (endpointData as NSData).bytes, length: endpointData.count, encoding: String.Encoding.utf8.rawValue) as! String
                let uuidData = txtRecord["id"] as! Data
                let uuid: String = NSString(bytes: (uuidData as NSData).bytes, length: uuidData.count, encoding: String.Encoding.utf8.rawValue) as! String
                delegate!.onServiceFound(uuid, serviceURI: endpoint, discoveryType: ServiceSearchDiscoveryType.LAN)
            }
        }
        
        //release resources
        aNetService.delegate = nil
        removeService(aNetService)
    }
}
