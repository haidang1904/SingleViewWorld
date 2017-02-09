#ifndef BLESINGLETON_H
#define BLESINGLETON_H
//
//  BLESingleton.h
//  SingleViewWorld
//
//  Created by samsung on 2015. 8. 20..
//  Copyright (c) 2015년 samsung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "PeripheralInfo.h"
#import "BLEdbcore.h"

@protocol BLESingletonDelegate

@required
-(void)didDisconnected;

@optional
-(void)didStopScan;
-(void)didFoundPeripheral;
-(void)didReadvalue;
-(void)didConnected;
-(void)willAddPeripheral:(PeripheralInfo *)peripheral;
-(void)didUpdateState:(CBCentralManager *)central;

@end

@interface BLESingleton : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (assign, nonatomic) id<BLESingletonDelegate> delegate;

@property (strong,nonatomic) CBCentralManager *myCenter;
@property (strong,nonatomic) PeripheralInfo *selectedPeripheral;
@property (strong,nonatomic) NSMutableArray *discoveredPeripherals;
@property (strong,nonatomic) CBService *selectedSevice;
@property (strong,nonatomic) CBCharacteristic *selectedCharacteristic;

+(BLESingleton *)defaultBLECore;

- (void)initBLE;
- (void)startBTscan:(int)time;
- (void)stopBTscan;
- (void)addPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary*)advertisementData RSSI:(NSNumber*)RSSI;
- (void)addPeripheralInfo:(PeripheralInfo *)peripheralInfo;
- (void)connectBTperipheral:(PeripheralInfo *)peripheralInfo;
- (void)disconnectBTperipheral:(PeripheralInfo *)peripheralInfo;
- (void)removeCenterDelegate;
- (void)addCenterDelegate;

@end


#endif