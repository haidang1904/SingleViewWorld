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

/// Found new TV on Network.
public let MSDidFindService = "ms.didFindService"
/// TV lost from Network/BLE.
public let MSDidRemoveService = "ms.didRemoveService"
/// Network/BLE Discovery stopped.
public let MSDidStopSearch = "ms.stopSearch"
/// Network Discovery started.
public let MSDidStartSearch = "ms.startSearch"
/// Found new TV on BLE.
public let MSDidFoundUsingBLE = "ms.didFoundUsingBLE"

/**
    Describe Service Search DiscoveryType
*/
@objc public enum ServiceSearchDiscoveryType: Int
{
    /// LAN type
    case LAN
    /// Cloud Type
    case CLOUD
}

// MARK: - ServiceSearchDelegate -

///  This protocol defines the methods for ServiceSearch discovery
@objc public protocol ServiceSearchDelegate: class
{
    /**
       The ServiceSearch will call this delegate method when a service is found
     
       - parameter service: The found service
    */
    @objc optional func onServiceFound(_ service: Service)

    /**
        The ServiceSearch will call this delegate method when a service is lost
     
       - parameter service: The lost service
    */
    @objc optional func onServiceLost(_ service: Service)

    /**
       The ServiceSearch will call this delegate method after stopping the search
    */
    @objc optional func onStop()

    /**
       The ServiceSearch will call this delegate method after the search has started
    */
    @objc optional func onStart()
    /**
       If BLE device is found
    
    - parameter NameOfTV: Name of TV found on Bluetooth
    */
    @objc optional func onFoundOnlyBLE(_ NameOfTV: String)
    /**
      Find other network (other than BLE)
    
    - parameter NameOfTV: Name of TV found on Network
    */
    @objc optional func onFoundOtherNetwork(_ NameOfTV: String)
}

// MARK: - ServiceSearch -

///  This class searches the local network for compatible multiscreen services
@objc open class ServiceSearch: NSObject
{
    /// Set a delegate to receive search events.
    open weak var delegate: ServiceSearchDelegate? = nil

    /// The search status
    open var isSearching: Bool 
    {
        return self.discoveryProviders.reduce(false) { $0 || $1.isSearching }
    }

    fileprivate var discoveryProviders: [ServiceSearchProvider] = []
    
    fileprivate var bleDiscoveryProviders: [ServiceSearchProvider] = []
    
    fileprivate let accessQueue = DispatchQueue(label: "SynchronizedAccess", attributes: [])

    fileprivate var discoveryProvidersTypes: [ServiceSearchProviderBase.Type ] = [MDNSDiscoveryProvider.self, MSFDiscoveryProvider.self]
    
    fileprivate var discoveryBLEProviderType: [ServiceSearchProviderBase.Type ] = [BLEDiscoveryProvider.self]
    
    fileprivate var started = false

    fileprivate var unresolvedServices = Set<String>()

    fileprivate var resolvedServices = Set<String>()

    // The cache list of service
    fileprivate var servicesCache: [Service] = []
    
    // The TV list Only BLE
    fileprivate var TVListOnlyBLE: [String] = []
    // TV List Other network
    fileprivate var TVListOtherNetwork: [String] = []
    
    internal override init()
    {
        super.init()
        setup(nil)
    }

    internal init(id: String)
    {
        super.init()
        setup(id)
    }
    
    /**
       request for TV list found on Network/BLE.
     
     - returns: returns TV List.
     */
    open func getServices() -> [Service]
    {
        return NSArray(array: self.servicesCache) as! [Service]
    }

    /**
     A convenience method to suscribe for notifications using blocks
     
       - parameter notificationName:  The name of the notification
       - parameter performClosure:   The notification block, this block will be executed in the main thread
     
       - returns: An observer handler for removing/unsubscribing the block from notifications
     */
    open func on(_ notificationName: String, performClosure:@escaping (Notification!) -> Void) -> AnyObject
    {
        return NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: notificationName), object: self, queue: OperationQueue.main, using: performClosure)
    }

    /**
        A convenience method to unsuscribe from notifications
     
       - parameter observer: The observer object to unregister observations
     */
    open func off(_ observer: AnyObject)
    {
        NotificationCenter.default.removeObserver(observer)
    }

    /**
      Start discovering TV on Network/Bluetooth
    */
    
    open func start()
    {
        self.accessQueue.async(execute: {
            for provider in self.discoveryProviders
            {
                if !provider.isSearching
                {
                    provider.search()
                }
            }
        })
    }
    
    /**
     check bluetooth searching is on or off
     
     - returns: true if bluetooth discovery on otherwise false
    */
    open func isSearchingBLE() -> Bool
    {
        return self.bleDiscoveryProviders[0].isSearching
    }
    
    /**
       Start BLE Search Process
     
     - returns: returns 'True' if using BLE otherwise 'False'
     */
    open func startUsingBLE() -> Bool
    {
        if (!isSupportBLE() || isSearchingBLE())
        {
            return false;
        }
        
        startDiscoveryUsingBLE()
        
        return true;
    }
    
    
    /**
      Stop BLE Search Process
     
     - returns: True
     */
    open func stopUsingBLE() -> Bool
    {
        stopDiscoveryUsingBLE();
        return true;
    }

    /**
     Stops the Device discovery.
     */
    open func stop()
    {
        self.accessQueue.async(execute: {
            self.resolvedServices.removeAll()
            self.unresolvedServices.removeAll()
        })
        
        self.accessQueue.async(execute: {
            NotificationCenter.default.removeObserver(self)
            
            for provider in self.discoveryProviders
            {
                if provider.isSearching
                {
                    provider.stop()
                }
            }
        })
    }
}

// MARK: - ServiceSearch (Private) -

extension ServiceSearch
{
    fileprivate func setup(_ id: String?)
    {
        for providerType in discoveryProvidersTypes
        {
            let providerInstance = providerType.init(delegate: self, id: id)
            discoveryProviders.append(providerInstance)
        }
        
        for providerType in discoveryBLEProviderType
        {
            let providerInstance = providerType.init(delegate: self, id: id)
            bleDiscoveryProviders.append(providerInstance)
        }
    }

    fileprivate func startDiscoveryUsingBLE()
    {
        self.accessQueue.async(execute: {
            for provider in self.bleDiscoveryProviders
            {
                if !provider.isSearching
                {
                    provider.search()
                }
            }
        })
    }

    fileprivate func stopDiscoveryUsingBLE()
    {
        self.accessQueue.async(execute: {
            NotificationCenter.default.removeObserver(self)
            for provider in self.bleDiscoveryProviders
            {
                if provider.isSearching
                {
                    provider.stop()
                }
            }
        })
    }

    fileprivate func isSupportBLE()->Bool
    {
        /*TO DO: Implementation pending.*/
        return true;
    }
    
    fileprivate func onServiceFound(_ service: Service, discoveryType: ServiceSearchDiscoveryType)
    {
        self.accessQueue.async(execute: {
            if self.servicesCache.contains(service)
            { // ignore the service
                Log.debug("search -> onServiceFound in cache \(service.uri)")
                return
            }
            self.servicesCache.append(service)
            DispatchQueue.main.async(execute: {
                Log.debug("search -> onServiceFound  \(service.uri)")
                self.delegate?.onServiceFound?(service)
                NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: MSDidFindService), object: self, userInfo: ["finder":self,"service":service]))
            })
        })
    }
    
    fileprivate func onFoundOnlyBLE(_ NameOfTV :String)
    {
        self.accessQueue.async(execute: {
            if self.TVListOnlyBLE.contains(NameOfTV)
            {
                return
            }
            else
            {
                self.TVListOnlyBLE.append(NameOfTV)
                
                self.delegate?.onFoundOnlyBLE!(NameOfTV)
            }
            
            DispatchQueue.main.async(execute: {
                self.delegate?.onFoundOnlyBLE?(NameOfTV)
                NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: MSDidFoundUsingBLE), object: self))
            })
        })
    }
    
    fileprivate  func onFoundOtherNetwork(_ NameOfTV :String)
    {
        self.accessQueue.async(execute: {
            if !self.TVListOtherNetwork.contains(NameOfTV)
            {
                self.TVListOtherNetwork.append(NameOfTV)
            }
            DispatchQueue.main.async(execute: {
                self.delegate?.onFoundOtherNetwork?(NameOfTV)
                NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: MSDidFoundUsingBLE), object: self))
            })
        })
    }
}

// MARK: - ServiceSearch (ServiceSearchProviderDelegate) -

extension ServiceSearch: ServiceSearchProviderDelegate
{
    func onServiceFound(_ serviceId: String, serviceURI: String, discoveryType: ServiceSearchDiscoveryType)
    {
        self.accessQueue.async(execute: {

            let endpoint = serviceURI.trimmingCharacters(in: NSCharacterSet.whitespaces).lowercased()
            //Log.debug("\(endpoint) starting \(self.resolvedServices.contains(endpoint)) vs \(self.unresolvedServices.contains(endpoint))")
            
            if !self.resolvedServices.contains(endpoint) && !self.unresolvedServices.contains(endpoint)
            {
                self.unresolvedServices.insert(endpoint)
                Service.getByURI(endpoint, timeout: TimeInterval(5))
                { (service, error) -> Void in
                
                    self.accessQueue.async(execute: {
                        if service != nil
                        {
                            Log.debug("search -> onServiceResolved \(endpoint) \(service!.uri)")
                            self.unresolvedServices.remove(endpoint)
                            self.resolvedServices.insert(endpoint)
                            service!.discoveryType = discoveryType
                            self.onServiceFound(service!, discoveryType: discoveryType)
                        }
                        else
                        {
                            Log.debug("search -> onServiceResolved failed \(endpoint) \(error)")
                            self.unresolvedServices.remove(endpoint)
                            self.resolvedServices.remove(endpoint)
                            
                            for provider in self.discoveryProviders
                            {
                                if provider.isSearching
                                {
                                    provider.serviceResolutionFailed(serviceId, discoveryType: discoveryType)
                                }
                            }
                        }
                    })
                }
            }
            else
            {
                Log.debug("search -> onServiceResolved ignoring \(endpoint)")
            }
        })
    }

    func onServiceLost(_ serviceId: String, discoveryType: ServiceSearchDiscoveryType)
    {
        self.accessQueue.async(execute: {
            let matchingServices = self.servicesCache.filter { $0.id == serviceId && $0.discoveryType == discoveryType }
            
            if matchingServices.count > 0
            {
                let service = matchingServices[0]
                if discoveryType == ServiceSearchDiscoveryType.CLOUD
                {
                    Log.debug("search -> onServiceLost CLOUD \(service.uri)")
                    self.resolvedServices.remove(service.uri)
                    _ = self.servicesCache.removeObject(service)
                    
                    DispatchQueue.main.async(execute: {
                        self.delegate?.onServiceLost?(service)
                        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: MSDidRemoveService), object: self, userInfo: ["finder":self,"service":service]))
                    })
                }
                else
                {
                    service.getDeviceInfo(5, completionHandler:
                    { (deviceInfo, error) -> Void in
                    
                        if error != nil || deviceInfo == nil
                        {
                            Log.debug("search -> onServiceLost LAN \(service.uri)")
                            self.accessQueue.async(execute: {
                                self.resolvedServices.remove(service.uri)
                                _ = self.servicesCache.removeObject(service)
                                
                                DispatchQueue.main.async(execute: {
                                    self.delegate?.onServiceLost?(service)
                                    NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: MSDidRemoveService), object: self, userInfo: ["finder":self,"service":service]))
                                })
                            })
                        }
                    })
                }
            }
        })
    }

    func onStop(_ provider:ServiceSearchProvider)
    {
        self.accessQueue.async(execute: {
            if !self.isSearching
            {
                self.started = false
                self.servicesCache.removeAll(keepingCapacity: false)
                DispatchQueue.main.async(execute: {
                    self.delegate?.onStop?()
                    NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: MSDidStopSearch), object: self))
                })
            }
        })
    }

    func onStart(_ provider:ServiceSearchProvider)
    {
        self.accessQueue.async(execute: {
            if !self.started
            {
                self.started = true
                DispatchQueue.main.async(execute: {
                    self.delegate?.onStart?()
                    NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: MSDidStartSearch), object: self))
                })
            }
        })
    }

    func clearCacheForProvider(_ provider: ServiceSearchProvider)
    {
        self.accessQueue.async(execute: {
            for service in self.servicesCache
            {
                self.onServiceLost(service.id, discoveryType: provider.type)
            }
        })
    }
    
    internal func addTVOnlyBLE(_ NameOfTV: String)
    {
        if (NameOfTV.isEmpty)
        {
            return
        }
        
        self.onFoundOnlyBLE(NameOfTV)
    }
        
    internal func addTVOtherNetwork(_ NameOfTV: String)
    {
        if !NameOfTV.isEmpty
        {
            self.onFoundOtherNetwork(NameOfTV)
        }
    }
}

