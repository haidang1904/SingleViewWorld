
//
//  BLESingleton.m
//  SingleViewWorld
//
//  Created by samsung on 2015. 8. 20..
//  Copyright (c) 2015년 samsung. All rights reserved.
//

#import "BLESingleton.h"

@implementation BLESingleton
{
    BOOL inited;
    NSTimer *scantimer;
}

static BLESingleton* _defaultBLECore = nil;

+(BLESingleton *)defaultBLECore
{
    if (nil == _defaultBLECore) {
        
        _defaultBLECore = [[BLESingleton alloc]init];
        
        [_defaultBLECore initBLE];
    }
    
    if(nil == _defaultBLECore.myCenter.delegate)
    {
        [_defaultBLECore addCenterDelegate];
    }
    
    return _defaultBLECore;
}

-(void)initBLE
{
    if (inited) {
        return;
    }
    inited = TRUE;
    self.delegate = nil;
    self.discoveredPeripherals = [NSMutableArray array];
    self.selectedPeripheral = nil;
    
    _myCenter = [[CBCentralManager alloc]
                initWithDelegate:self
                queue:nil
                options:nil]; // TODO: options
    
    SVLogTEST(@"init bt server ........");

}

-(void)addCenterDelegate
{
    SVLogTEST(@"add Center Delegate");
    _myCenter.delegate = self;
}

-(void)removeCenterDelegate
{
    SVLogTEST(@"remove Center Delegate");
    _myCenter.delegate = nil;
}

#pragma mark -
- (void)startBTscan:(int)time
{
    [self.discoveredPeripherals removeAllObjects];
    //[self.myCenter scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:nil];
    [self.myCenter scanForPeripheralsWithServices:nil options:nil];
    
    SVLogTEST(@"Scan started - Scanning time is %d",time);
    scantimer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(stopBTscan) userInfo:nil repeats:NO];
}

- (void)stopBTscan
{
    if(scantimer.valid == YES)
    {
        SVLogTEST(@"Timer stop!!");
        [scantimer invalidate];
    }
    [self.myCenter stopScan];
    
    if (self.delegate) {
        if([(id)self.delegate respondsToSelector:@selector(didStopScan)]){
            [self.delegate didStopScan];
        }
    }
}

- (void)addPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary*)advertisementData RSSI:(NSNumber*)RSSI
{
    PeripheralInfo *pi = [[PeripheralInfo alloc]init];
    
    pi.peripheral = peripheral;
    pi.uuid = [peripheral.identifier UUIDString];
    pi.name = peripheral.name;

    if (self.delegate) {
        if([(id)self.delegate respondsToSelector:@selector(willAddPeripheral:)]){
            [self.delegate willAddPeripheral:pi];
        }
    }
    
    pi.fakeName = (NSString *)[[BLEdbcore sharedInstance] readData:kEntityNameLocal Key:@"uuid" value:pi.uuid];
    
    if (advertisementData) {
        NSArray *array = [advertisementData objectForKey:CBAdvertisementDataServiceUUIDsKey];
        NSData *dat = [advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey];
        UInt16 manufactureID = 0x0000;
        UInt8 p2pmac[6];// = [Uint8];
        UInt8 bdAddr[6];// = [Uint8];
        
        pi.localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
        pi.serviceUUIDS = [array componentsJoinedByString:@";"];

        [dat getBytes:&manufactureID range:NSMakeRange(0, 2)];
        if ((manufactureID == 0x7500 || manufactureID == 0x0075) && (dat.length > 20)) {
            
            [dat getBytes:bdAddr range:NSMakeRange(7, 6)];
            [dat getBytes:p2pmac range:NSMakeRange(13, 6)];
            
            pi.bdaddr = [self stringFromMacAddress:bdAddr];
            pi.p2pmac = [self stringFromMacAddress:p2pmac];
            SVLogTEST(@"Samsung TV bdAddr is : %@",[self stringFromMacAddress:bdAddr]);
            SVLogTEST(@"Samsung TV p2pmac is : %@",[self stringFromMacAddress:p2pmac]);
        } else {
            //SVLogTEST(@"What is this device : %hu",manufactureID);
        }

    }

//    { //CBAdvertisementDataManufacturerDataKey
//        var manufactureID: UInt16 = 0x0000
//        let manufacturerData: Data = advertisementData["kCBAdvDataManufacturerData"] as! Data
//        (manufacturerData as NSData).getBytes(&manufactureID, range: NSRange(location: 0, length: 1))
//        manufactureID = manufactureID.byteSwapped;
//        if (manufactureID == 0x7500 || manufactureID == 0x0075
//            ) { // WE got a Samsung Device
//            tv = BLERecord()
//            var version: UInt8 = 0x00
//            var serviceId: UInt8 = 0x00
//            var deviceType: UInt8 = 0x00
//            var deviceStatus: UInt8 = 0x00
//            var availableService: UInt8 = 0x00
//            
//            (manufacturerData as NSData).getBytes(&version, range: NSRange(location: 2, length: 1))
//            (manufacturerData as NSData).getBytes(&serviceId, range: NSRange(location: 3, length: 1))
//            
//            if version == 0x42 && serviceId == 0x04 { //
//                (manufacturerData as NSData).getBytes(&deviceType, range: NSRange(location: 4, length: 1))
//                if deviceType == 0x01 { // WE got a Samsung TV
//                    (manufacturerData as NSData).getBytes(&deviceStatus, range: NSRange(location: 5, length: 1))
//                    (manufacturerData as NSData).getBytes(&availableService, range: NSRange(location: 6, length: 1))
//                    var bdAddr = [UInt8](repeating: 0x00, count: 6)
//                    var p2pMac = [UInt8](repeating: 0x00, count: 6)
//                    var p2pListenChannel: UInt8 = 0x00
//                    var registeredDevices = [UInt8](repeating: 0x00, count: 6)
//                    (manufacturerData as NSData).getBytes(&bdAddr, range: NSRange(location: 7, length: 6))
//                    (manufacturerData as NSData).getBytes(&p2pMac, range: NSRange(location: 13, length: 6))
//                    (manufacturerData as NSData).getBytes(&p2pListenChannel, range: NSRange(location: 19, length: 1))
//                    (manufacturerData as NSData).getBytes(&registeredDevices, range: NSRange(location: 20, length: 6))
//                    tv.mac =  BLERecord.macString(p2pMac)
//                    tv.uuid = BLERecord.macString(bdAddr)
//                    if tv.mac == "00:00:00:00:00:00" || tv.uuid == "00:00:00:00:00:00" {
//                        return nil
//                    }
//                    tv.bleData.version = version
//                    tv.bleData.serviceId = serviceId
//                    tv.bleData.deviceType = deviceType
//                    tv.bleData.deviceStatus = deviceStatus
//                    tv.bleData.availableService = availableService
//                    //                            if tv.mac == "C2:97:27:2D:CA:16" {
//                    //                                Log.print(availableService)
//                    //                            }
//                    tv.bleData.bdAddr = bdAddr
//                    tv.bleData.p2pMac = p2pMac
//                    tv.bleData.p2pListenChannel = p2pListenChannel
//                    tv.bleData.registeredDevices = registeredDevices
//                    
//                }
//            }
//        }
//    }
    
    
    if (RSSI) {
        pi.RSSI = RSSI;
    }

    [self addPeripheralInfo:pi];
}

- (NSString *) stringFromMacAddress:(UInt8 *)mac {

    return [[NSString alloc] initWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",mac[0],mac[1],mac[2],mac[3],mac[4],mac[5]];
}

- (void)addPeripheralInfo:(PeripheralInfo *)peripheralInfo
{
    
    for(int i=0;i<self.discoveredPeripherals.count;i++){
        PeripheralInfo *pi = self.discoveredPeripherals[i];
        
        if([peripheralInfo.uuid isEqualToString:pi.uuid]){
            //SVLogTEST(@"==already added uuid!!");
            [self.discoveredPeripherals replaceObjectAtIndex:i withObject:peripheralInfo];
            return;
        }
    }
    //SVLogTEST(@"==not added uuid");
    [self.discoveredPeripherals addObject:peripheralInfo];
    
    
    if (self.delegate) {
        if([(id)self.delegate respondsToSelector:@selector(didFoundPeripheral)]){
            [self.delegate didFoundPeripheral];
        }
    }
}

- (void)connectBTperipheral:(PeripheralInfo *)peripheralInfo
{
    SVLogTEST(@"Connecting to peripheral %@", peripheralInfo.peripheral.name);
    [self.myCenter connectPeripheral:peripheralInfo.peripheral options:nil];
}

- (void)disconnectBTperipheral:(PeripheralInfo *)peripheralInfo
{
    SVLogTEST(@"Disconnecting to peripheral %@", peripheralInfo.peripheral.name);
    [self.myCenter cancelPeripheralConnection:peripheralInfo.peripheral];
}

#pragma mark -
#pragma mark CBCentralManagerDelegate - required
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // Determine the state of the peripheral
    if ([central state] == CBCentralManagerStatePoweredOff) {
        SVLogTEST(@"CoreBluetooth BLE hardware is powered off");
    }
    else if ([central state] == CBCentralManagerStatePoweredOn) {
        SVLogTEST(@"CoreBluetooth BLE hardware is powered on and ready");
        //[self startBTscan:5];
    }
    else if ([central state] == CBCentralManagerStateUnauthorized) {
        SVLogTEST(@"CoreBluetooth BLE state is unauthorized");
    }
    else if ([central state] == CBCentralManagerStateUnknown) {
        SVLogTEST(@"CoreBluetooth BLE state is unknown");
    }
    else if ([central state] == CBCentralManagerStateUnsupported) {
        SVLogTEST(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
    
    if (self.delegate) {
        if([(id)self.delegate respondsToSelector:@selector(didUpdateState:)]){
            [self.delegate didUpdateState:central];
        }
    }

}

#pragma mark CBCentralManagerDelegate - optional
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if(([RSSI intValue] == 127) || (peripheral.name == nil))
    {
        SVLogTEST(@"==========weak signal or unknown name!!==========");
        return;
    }
    
    if([[advertisementData objectForKey:CBAdvertisementDataIsConnectable] intValue] == 0)
    {
        SVLogTEST(@"==========%@ Is not Connectable!!==========",peripheral.name);
        //return;
    }
    
    SVLogTEST(@"discover peripheral: %@; \nAdvertisement Data: %@", peripheral.name, advertisementData);
    

    [self addPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    SVLogTEST(@"didFailToConnectPeripheral to peripheral %@", [error localizedDescription]);
    
    if (self.delegate) {
        if([(id)self.delegate respondsToSelector:@selector(didDisconnected)]){
            [self.delegate didDisconnected];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self stopBTscan];
    
    self.selectedPeripheral.peripheral = peripheral;
    self.selectedPeripheral.peripheral.delegate  = self;
    
    [self.selectedPeripheral.peripheral  discoverServices:nil];

}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    SVLogTEST(@"didDisConnected peripheral error: %@",error);
    
    if (self.delegate) {
        if([(id)self.delegate respondsToSelector:@selector(didDisconnected)]){
            [self.delegate didDisconnected];
        }
    }
}

#pragma mark -
#pragma mark CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        SVLogTEST(@"didDiscoverServices error: %@",error);
        return;
    }
    
    for(CBService *services in peripheral.services)
    {
        [peripheral discoverCharacteristics:nil forService:services];
    }
    
    if (self.delegate) {
        if([(id)self.delegate respondsToSelector:@selector(didConnected)]){
            [self.delegate didConnected];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        SVLogTEST(@"didDiscoverCharacteristicsForService Error %@ \n%@",error,service);
        return;
    }
    
    //SVLogTEST(@"didDiscoverCharacteristicsForService services: %@",service);
    //SVLogTEST(@"didDiscoverCharacteristicsForService Characteristics: %@",service.characteristics);
    

    for (CBCharacteristic *characteristic in service.characteristics) {
            [peripheral readValueForCharacteristic:characteristic];
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            SVLogTEST(@"setNotifyValue %@",characteristic);
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        SVLogTEST(@"didUpdateValueForCharacteristic Error %@ \n%@",error,characteristic);
        return;
    }
    SVLogTEST(@"%@",characteristic);
    
    if (self.delegate) {
        if([(id)self.delegate respondsToSelector:@selector(didReadvalue)]){
            [self.delegate didReadvalue];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (error) {
        SVLogTEST(@"didDiscoverDescriptorsForCharacteristic Error %@ \n%@",error,characteristic);
        return;
    }
    SVLogTEST(@"%@",characteristic.descriptors);
}

@end

