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
import SmartView

import XCTest

class ChannelAPITests: XCTestCase {

    let wsHostEndpoint = "ws://127.0.0.1:8001/api/v2/channels/test";
    let wsClientEndpoint = "test";

    let appId = "test"

    var hostService: Service!
    var clientService: Service!
    var serviceId: String!

    var host: Channel!
    var client1: Channel!
    var client2: Channel!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testChannelIntegration() {

        //measureBlock() { [unowned self] in
            self.getServiceByURL()
        //}

        //measureBlock() { [unowned self] in
            self.getServiceById()
        //}

        //measureBlock() { [unowned self] in
            self.connectAsAHost()
        //}

        //measureBlock() { [unowned self] in
            self.connectAsClient1()
        //}

        //measureBlock() { [unowned self] in
            self.emitInvalidEventPrefix()
        //}

        //measureBlock() { [unowned self] in
            self.emitsABinaryEvent()
        //}

        //measureBlock() { [unowned self] in
            self.connectAsClient2()
        //}

        disconnectClient2()

        disconnectClient1()
    }

    func getServiceByURL() {
        //measureBlock() { [unowned self] in
            let messageReceivedExpectation =  self.expectation(description: "got service by id");
            Service.getByURI("http://127.0.0.1:8001/api/v2/", timeout:2, completionHandler: { [unowned self] (service, error) -> Void in
                if service != nil {
                    self.hostService = service!
                    self.serviceId = service!.id
                    assert(!self.hostService.type.isEmpty, "The model string must be set")
                    assert(!self.hostService.name.isEmpty, "The name string must be set")
                    assert(!self.hostService.uri.isEmpty, "The uri string must be set")
                    assert(!self.hostService.version.isEmpty, "The version string must be set")
                    print(service!.name)
                }
                messageReceivedExpectation.fulfill()
            })
            self.waitForExpectations(timeout: 10, handler: { [unowned self] (error) -> Void in

            })
        //}
    }

    func getServiceById() {
        let messageReceivedExpectation =  self.expectation(description: "got service by id")
        
        Service.getById(serviceId, completionHandler:
        { (service, error) -> Void in
            if service != nil {
                self.clientService = service!
                assert(!self.clientService.type.isEmpty, "The model string must be set")
                assert(!self.clientService.name.isEmpty, "The name string must be set")
                assert(!self.clientService.uri.isEmpty, "The uri string must be set")
                assert(!self.clientService.version.isEmpty, "The version string must be set")
            }
            messageReceivedExpectation.fulfill()
        })
        self.waitForExpectations(timeout: 1000, handler: { [unowned self] (error) -> Void in

        })
    }

    func connectAsAHost() {
        let messageReceivedExpectation =  expectation(description: "host ready");
//        host = hostService.createApplication("test", channelURI: "test", args: nil)
        host = hostService.createChannel("test")

        let connectObserver: AnyObject? = host.on(ChannelEvent.Ready.rawValue, performClosure: { (notification) -> Void in
            messageReceivedExpectation.fulfill()
        });

        let readyObserver: AnyObject? = host.on(ChannelEvent.Connect.rawValue, performClosure: { (notification) -> Void in
            var info = notification.userInfo as? [String:AnyObject]
            assert(info != nil, "expected userInfo must not be nil")
            var me = info!["client"] as? ChannelClient
            assert(me != nil, "expected client must not be nil")
            assert(me?.id.isEmpty == false, "the Id must not be empty")
            assert(me?.isHost == true, "this connection end point if for the host")
            print(notification.userInfo)

        })

        host!.connect(["name":UIDevice.current.name])

        waitForExpectations(timeout: 10, handler: { [unowned self] (error) -> Void in
            self.host.off(connectObserver!)
            self.host.off(readyObserver!)
        })
    }

    func connectAsClient1() {
        let clientConnectExpectation =  expectation(description: "client connect");


        var gotReadyEvent = false
        var gotClientConnectEvent = false

        var connectObserver: AnyObject?
        var readyObserver: AnyObject?

        let clientConnect: AnyObject? = host.on(ChannelEvent.ClientConnect.rawValue, performClosure: { (notification) -> Void in
            //assert(gotReadyEvent, "Client1 did not received the ready event")
            if (gotReadyEvent) {
                clientConnectExpectation.fulfill()
            } else {
                gotClientConnectEvent = true
            }
        })

        Service.getByURI("http://localhost:8001/api/v2/", timeout: 2, completionHandler: { [unowned self] (service, error) -> Void in
            self.clientService = service
            self.client1 = self.clientService.createChannel("test")
            connectObserver = self.client1.on(ChannelEvent.Connect.rawValue, performClosure: { (notification) -> Void in
                let channel: Channel? = notification!.object as? Channel
                assert(channel != nil, "expected channel must not be nil")
                let me = channel?.me
                assert(me != nil, "expected client must not be nil")
                assert(me?.id.isEmpty == false, "the Id must not be empty")
                assert(me?.isHost == false, "this connection end point if for the host")
            });

            readyObserver = self.client1.on(ChannelEvent.Ready.rawValue, performClosure: { (notification) -> Void in
                print(notification)
                if (gotClientConnectEvent) {
                    clientConnectExpectation.fulfill()
                } else {
                    gotReadyEvent = true
                }
            })

            self.client1!.connect(["name": UIDevice.current.name])
        })

        waitForExpectations(timeout: 10, handler: { [unowned self] (error) -> Void in
            self.client1.off(connectObserver!)
            self.client1.off(readyObserver!)
            self.host.off(clientConnect!)
        })
    }

    func emitInvalidEventPrefix() {

        let invalidPrefixExpectation =  expectation(description: "client connect");

        let messageObserver: AnyObject? = host.on(ChannelEvent.Error.rawValue, performClosure: { (notification) -> Void in
            let error: NSError? = notification.userInfo!["error"] as? NSError
            assert(error != nil, "prefix error expected")
            invalidPrefixExpectation.fulfill()
        })

        host.publish(event: "ms.channel.anything", message: "this should give an error", target: MessageTarget.Host.rawValue)

        waitForExpectations(timeout: 2, handler: { [unowned self] (error) -> Void in
            self.host.off(messageObserver!)
        })
    }

    func emitsABinaryEvent() {
        let receivedBinaryMessageExpectation =  expectation(description: "client connect");

        let data = "hello_data".data(using: String.Encoding.utf8, allowLossyConversion: false);

        let from = self.host.me.id

        let messageObserver: AnyObject? = client1.on("data", performClosure: { (notification) -> Void in
            let message: Message = notification.userInfo!["message"] as! Message
            let payload: Data =  notification.userInfo!["payload"] as! Data
            assert(message.data is [String:String], "expected a dictionary")
            assert("data" == message.event, "The received event is not 'say'")
            assert(message.from == from, "The sender must be the host")
            assert(payload == data!, "Received data is expected to be equal to sent data")
            receivedBinaryMessageExpectation.fulfill()
        })

        host.publish(event: "data", message: ["key":"value"], data: data!, target: client1.me.id)

        waitForExpectations(timeout: 10, handler: { [unowned self] (error) -> Void in
            self.client1.off(messageObserver!)
        })

    }

    func connectAsClient2() {
        let clientConnectExpectation =  expectation(description: "client connect");
        client2 = clientService.createChannel("test")
        
        var gotReadyEvent = false
        var gotClientConnectHostEvent = false
        var gotClientConnectClient1Event = false

        let connectObserver: AnyObject? = client2.on(ChannelEvent.Connect.rawValue, performClosure: { (notification) -> Void in
            let channel: Channel? = notification!.object as? Channel
            assert(channel != nil, "expected channel must not be nil")
            let me = channel?.me
            assert(me != nil, "expected client must not be nil")
            assert(me?.id.isEmpty == false, "the Id must not be empty")
            assert(me?.isHost == false, "this connection end point if for the host")
        });

        let readyObserver: AnyObject? = client2.on(ChannelEvent.Ready.rawValue, performClosure: { (notification) -> Void in
            print(notification)
            if (gotClientConnectHostEvent && gotClientConnectClient1Event) {
                clientConnectExpectation.fulfill()
            } else {
                gotReadyEvent = true
            }
        })

        let clientConnectHostObserver: AnyObject? = host.on(ChannelEvent.ClientConnect.rawValue, performClosure: { (notification) -> Void in
            //assert(gotReadyEvent, "Client1 did not received the ready event")
            if (gotReadyEvent && gotClientConnectClient1Event) {
                clientConnectExpectation.fulfill()
            } else {
                gotClientConnectHostEvent = true
            }
        })

        let clientConnectClient1Observer: AnyObject? = client1.on(ChannelEvent.ClientConnect.rawValue, performClosure: { (notification) -> Void in
            //assert(gotReadyEvent, "Client1 did not received the ready event")
            if (gotReadyEvent && gotClientConnectHostEvent) {
                clientConnectExpectation.fulfill()
            } else {
                gotClientConnectClient1Event = true
            }
        })


        client2!.connect(["name":UIDevice.current.name])

        waitForExpectations(timeout: 2, handler: { [unowned self] (error) -> Void in
            self.client1.off(clientConnectHostObserver!)
            self.client2.off(connectObserver!)
            self.client2.off(readyObserver!)
            self.host.off(clientConnectHostObserver!)
        })
    }


    func disconnectClient2() {
        let client2DisconnectExpectation =  expectation(description: "disconnect client 2");
        let client1DisconnectObserver: AnyObject? = client1.on(ChannelEvent.ClientDisconnect.rawValue, performClosure: { (notification) -> Void in
            //client2DisconnectExpectation.fulfill()
        })

        client2.disconnect { (client, error) -> Void in
            print("client2.disconnect")
            client2DisconnectExpectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: { [unowned self] (error) -> Void in
            self.client1.off(client1DisconnectObserver!)
        })
    }

    func disconnectClient1() {
        let hostDisconnectExpectation =  expectation(description: "disconnect client 1");
        let client1DisconnectObserver: AnyObject? = client1.on(ChannelEvent.Disconnect.rawValue, performClosure: { (notification) -> Void in
            hostDisconnectExpectation.fulfill()
        })

        client1.disconnect()

        waitForExpectations(timeout: 10, handler: { [unowned self] (error) -> Void in
            self.client1.off(client1DisconnectObserver!)
        })
    }

}
