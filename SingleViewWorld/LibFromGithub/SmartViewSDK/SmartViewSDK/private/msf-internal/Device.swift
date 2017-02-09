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

// currently unused
private class Device : NSObject {
    fileprivate var deviceInfo: [String:String]
    
    var duid: String {
        return deviceInfo["duid"]!
    }
    
    var model: String {
        return deviceInfo["model"]!
    }
    
    override var description: String {
        return deviceInfo["description"]!
    }
    
    var networkType: String {
        return deviceInfo["networkType"]!
    }

    var ssid: String {
        return deviceInfo["ssid"]!
    }

    var ip: String {
        return deviceInfo["ip"]!
    }
    
    var firmwareVersion: String {
        return deviceInfo["firmwareVersion"]!
    }

    var name: String {
        return deviceInfo["name"]!
    }

    var id: String {
        return deviceInfo["id"]!
    }

    var udn: String {
        return deviceInfo["udn"]!
    }

    var resolution: String {
        return deviceInfo["resolution"]!
    }
    
    var countryCode: String {
        return deviceInfo["countryCode"]!
    }
    
    var macAdr: String {
        return deviceInfo["wifiMac"]!
    }
    
    init (info: Dictionary<String,String>) {
        deviceInfo = info
    }
    
}
