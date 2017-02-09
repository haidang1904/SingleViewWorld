/*

Copyright (c) 2015 Samsung Electronics

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

// MARK: - ServiceSearchProviderDelegate -

///  ServiceSearchProvider implementations should use this delegate to
///  consolidate the search results in a ServiceSearch instance
internal protocol ServiceSearchProviderDelegate: class
{
    ///  ServiceSearchProvider will call this delegate method when a service is found
    ///  the delegate object must append the service to the services list if is not
    ///
    ///  - parameter serviceURI: The found service URI
    ///
    ///  - parameter discoveryType: Service Search Discovery Type
    func onServiceFound(_ serviceId: String, serviceURI: String, discoveryType: ServiceSearchDiscoveryType)

    ///  ServiceSearchProvider will call this delegate method when a service is lost
    ///  the delegate object must remove the service if there are not more search
    ///  providers for the service
    ///
    ///  - parameter serviceId: The service id
    ///
    ///  - parameter provider: Service Search Provider
    func onServiceLost(_ serviceId: String, discoveryType: ServiceSearchDiscoveryType)

    ///  The ServiceSearch will call this delegate method after stopping the search
    func onStop(_ provider:ServiceSearchProvider)

    ///   The ServiceSearch will call this delegate method after the search has started
    func onStart(_ provider:ServiceSearchProvider)

    func clearCacheForProvider(_ provider:ServiceSearchProvider)
    
    /// If BLE service name found
    func addTVOnlyBLE(_ NameOfTV : String)
    
    /// Find other network (other than BLE)
    func addTVOtherNetwork(_ NameOfTV : String)
}

// MARK: -

///  Implement this protocol in order to extend the service search functionality
///  with a new discovery mechanism
internal protocol ServiceSearchProvider: class
{
    var type: ServiceSearchDiscoveryType! {get}

    // The status of the search
    var isSearching: Bool {get}

    // The intializer
    init(delegate: ServiceSearchProviderDelegate, id: String?)

    /// Start the search
    func search()

    /// Stops the search
    func stop()

    // report a failure in the service resolution so providers can clean the cache for that service
    func serviceResolutionFailed(_ serviceId: String, discoveryType: ServiceSearchDiscoveryType)
}

// MARK: -

internal class ServiceSearchProviderBase: NSObject, ServiceSearchProvider
{
    // An optional id to parametrize the search
    var id: String?

    var type: ServiceSearchDiscoveryType!

    // The status of the search
    var isSearching: Bool = false

    weak var delegate: ServiceSearchProviderDelegate? = nil

    // The intializer
    required init(delegate: ServiceSearchProviderDelegate, id: String?) {
        self.delegate = delegate
        self.id = id
    }

    /// Start the search
    func search() {}

    /// Stops the search
    func stop() {}

    // report a failure in the service resolution so providers can clean the cache for that service
    func serviceResolutionFailed(_ serviceId: String, discoveryType: ServiceSearchDiscoveryType) {}
}
