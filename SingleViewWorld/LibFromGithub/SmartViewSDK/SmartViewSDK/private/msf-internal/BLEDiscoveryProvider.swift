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

import UIKit
import CoreBluetooth

typealias BLERequestCompletionHandler = (_ response: String?, _ data: Data?, _ error: NSError?) -> Void

internal struct BluetoothService : Equatable
{
    var name:String
    var id:String
    var expires: Int64
    
    init(aName:String, aId:String, aexpires:Int64)
    {
        name = aName
        id = aId
        expires = aexpires
    }
    
}

internal func == (lhs: BluetoothService, rhs: BluetoothService) -> Bool
{
    return lhs.id == rhs.id
}

internal class BLEDiscoveryProvider: ServiceSearchProviderBase, CBCentralManagerDelegate, CBPeripheralDelegate
{
    fileprivate enum DeviceType: String
    {
        case Unknown =  "00"
        case TV =       "01"
        case Mobile =   "02"
        case PXD =      "03"
        case AVDevice = "04"
    }
    
    fileprivate let SAMSUNG_MANUFACTURE_ID  = "75"
    fileprivate let SAMSUNG_CLOUD_SERVER = "http://multiscreen.samsung.com/discoveryservice/v2/devices/"
    
    fileprivate let KEY_URI = "serviceUri"
    fileprivate let CLOUD_SERVER_TIMEOUT = 8
    fileprivate let GETSERVICE_TIMEOUT = 6
    
    fileprivate let BLE_RSSI_MINIMUM = -80
    fileprivate let MAC_START_INDEX = 15
    fileprivate let MAC_LENGTH = 12
    
    fileprivate var devices:[BluetoothService] = []
    fileprivate var discoveredPeripheralIDs = Set<UUID>()
    
    let accessQueue = DispatchQueue(label: "BLEDiscoveryProviderQueue", attributes: [])
   
    let services: [CBUUID] = []
    var timer: Timer!
    var manager: CBCentralManager!
    
    var resolvedServices = NSMutableDictionary(capacity: 0)
    
    required init(delegate: ServiceSearchProviderDelegate, id: String?)
    {
        super.init(delegate: delegate, id: id)
        type = ServiceSearchDiscoveryType.LAN
        
        Log.debug("BLE init")
        
        if id != nil {
            return // search by id is not suported for BLE
        }
        self.delegate = delegate
    }

    // start the search
    override func search()
    {
        if !isSearching
        {
            Log.debug("starting BLE search...")
            isSearching = true
            manager = CBCentralManager(delegate: self, queue: accessQueue, options: [CBCentralManagerOptionShowPowerAlertKey: false])
        }
        else
        {
            Log.debug("BLE already searching")
        }
    }

    override func stop()
    {
        if isSearching
        {
            Log.debug("stopping BLE search...")
            timer?.invalidate()
            manager.stopScan()
            manager = nil
            resolvedServices.removeAllObjects()
            isSearching = false
        }
        else
        {
            Log.debug("BLE search alreday stopped")
        }
    }

    override func serviceResolutionFailed(_ serviceId: String, discoveryType: ServiceSearchDiscoveryType)
    {
        Log.debug("BLE serviceResolutionFailed")
        
        if discoveryType == type
        {
            // delay de service removal for 3 seconds
            let delayTime = DispatchTime.now() + Double(Int64(3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            self.accessQueue.asyncAfter(deadline: delayTime,
            execute: {
                self.resolvedServices.removeObject(forKey: serviceId)
            })
        }
    }

    func evaluateDidLostService()
    {
        self.accessQueue.async(execute: {
            let now = Date()
            let keys = NSArray(array: self.resolvedServices.allKeys) as! [String]
            for key in keys
            {
                if (self.resolvedServices[key]! as AnyObject).compare(now) == ComparisonResult.orderedAscending {
                    Log.debug("BLE -> onServiceLost \(key)")
                    self.resolvedServices.removeObject(forKey: key)
                    self.delegate?.onServiceLost(key, discoveryType: ServiceSearchDiscoveryType.LAN)
                }
            }
        })
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        let stateDescription = [.unknown: "Unknown", .resetting: "Resetting", .unsupported: "Unsupported",
            .unauthorized: "Unauthorized", .poweredOff: "PoweredOff", .poweredOn: "PoweredOn"][central.state]
        Log.debug("centralManagerDidUpdateState: BLE state \(stateDescription)")
        
        if central.state == .poweredOn
        {
            manager.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        }
        else if central.state == .poweredOff
        {
            stop()
        }
    }
    
    func currentTimeMillis() -> Int64
    {
        let nowDouble = Date().timeIntervalSince1970
        return Int64(nowDouble*1000)
    }
    
    func  updateAlive(_ name:String , uuid: String)
    {
        var ttl: Int64 = currentTimeMillis()
        ttl = ttl + 5000
        
        Log.debug("BLE TTL :[\(ttl)]")
        let bService = BluetoothService(aName: name, aId: uuid, aexpires: ttl)
        
        if !self.devices.contains(bService)
        {
            Log.debug("not found append in device")
            devices.append(bService)
        }
        else
        {
            Log.debug("already present in device")
        }
    }

    func reapService()
    {
        let now:Int64 = currentTimeMillis()
        
        let timestamp = TimeInterval(now)
        let curDatenow = Date(timeIntervalSinceReferenceDate: timestamp)
        Log.debug("curdate is \(curDatenow)")
        Log.debug("devices count is \(devices.count)")
        
        for device in devices
        {
            if (device.expires < now)
            {
                _ = devices.removeObject(device)
                self.delegate?.onServiceLost(device.id, discoveryType: ServiceSearchDiscoveryType.LAN)
                Log.debug("device \(device) removed by expiration date")
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        Log.debug("BLE didDiscoverPeripheral")

        guard !self.discoveredPeripheralIDs.contains(peripheral.identifier) else
        {
            return
        }
        
        self.discoveredPeripheralIDs.insert(peripheral.identifier)
        
        if  let deviceName = peripheral.name,
            let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
            , manufacturerData.count > 0
        {
            Log.debug("BLE peripheral name is:[\(peripheral.name)] : [\(RSSI)] dbm")
            
            let manufacturerDataStr = manufacturerData.description
            let woManufacturedStr = removeSpaceFromString(manufacturerDataStr as NSString)
            Log.debug(" BLE woManufacturedStr string \(woManufacturedStr)")

            let uuid = getTVUUID(woManufacturedStr)

            if uuid.isEmpty
            {
                return
            }

            Log.debug("TV id is:[\(uuid)]")

            let found = self.devices.contains(where: { $0.id == uuid })

            if !found && isTV(woManufacturedStr as NSString)
            {
                updateAlive(deviceName, uuid: uuid)
                
                if RSSI.intValue >= BLE_RSSI_MINIMUM
                {
                    Log.debug("Calling addTVOnlyBLE for [\(deviceName)]...")
                    self.delegate?.addTVOnlyBLE(deviceName)
                }
            }

            reapService()
        }
        
    }
    
    func removeSpaceFromString(_ dataString: NSString) -> String
    {
        var wospace: String = ""
        if(dataString.range(of: " ").location != NSNotFound)
        {
            wospace = dataString.replacingOccurrences(of: " ", with: "", options: NSString.CompareOptions.literal, range: NSMakeRange(0, dataString.length))
        }
        
        return wospace
    }

    func isTV(_ manufacturedData: NSString) ->Bool
    {
        var isCheckTV:Bool = false
        
        if (manufacturedData.length > 0)
        { //CBAdvertisementDataManufacturerDataKey
            let manufacturedIDStr = manufacturedData.substring(with: NSRange(location: 1, length: 2))
            
            if (manufacturedIDStr == SAMSUNG_MANUFACTURE_ID)
            {
                var versionStr:String
                var serviceIdStr:String
                var deviceType:String
                var deviceStatus:String
                
                versionStr = manufacturedData.substring(with: NSRange(location:5, length: 2))
                serviceIdStr = manufacturedData.substring(with: NSRange(location: 7, length: 2))
                deviceType = manufacturedData.substring(with: NSRange(location: 9, length: 2))
                deviceStatus = manufacturedData.substring(with: NSRange(location: 11, length: 2))
                
                Log.debug("versionStr string \(versionStr)")
                Log.debug("serviceIdStr string \(serviceIdStr)")
                Log.debug("deviceType string \(deviceType)")
                Log.debug("deviceStatus string \(deviceStatus)")
                
                if ((deviceType == DeviceType.TV.rawValue) && (deviceStatus == "01"))
                {
                    isCheckTV = true
                }
            }
        }
        return isCheckTV
    }
    
    func getTVUUID(_ manufacturedData: String) -> String
    {
        let colon: Character = ":"
        var uuid : String = ""
        
        if (manufacturedData.characters.count > MAC_START_INDEX + MAC_LENGTH) {
            let startIndex = manufacturedData.characters.index(manufacturedData.startIndex, offsetBy: MAC_START_INDEX)
            let endIndex = manufacturedData.characters.index(manufacturedData.startIndex, offsetBy: MAC_START_INDEX + MAC_LENGTH)
            let range = startIndex..<endIndex
            uuid = manufacturedData.substring(with: range)
        }

        if uuid.isEmpty
        {
            Log.debug("BLE uuid is empty.")
            
            return ""
        }
        
         Log.debug("uuid is \(uuid)")
        
         uuid = uuid.uppercased()
        
         Log.debug("upper case uuid is \(uuid)")
        //Inserting colon after every octect
        
        uuid.insert(colon, at: uuid.characters.index(uuid.startIndex, offsetBy: 2))
        uuid.insert(colon, at: uuid.characters.index(uuid.startIndex, offsetBy: 5))
        uuid.insert(colon, at: uuid.characters.index(uuid.startIndex, offsetBy: 8))
        uuid.insert(colon, at: uuid.characters.index(uuid.startIndex, offsetBy: 11))
        uuid.insert(colon, at: uuid.characters.index(uuid.startIndex, offsetBy: 14))
        
        return uuid
    }

}


