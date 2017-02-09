//
//  BLEPeripheralViewController.h
//  SingleViewWorld
//
//  Created by samsung on 2015. 8. 12..
//  Copyright (c) 2015년 samsung. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "PeripheralInfo.h"

#define TRANSFER_SERVICE_UUID           @"2A3D"  //String
#define TRANSFER_CHARACTERISTIC_UUID    @"FFFF"

@interface BLEPeripheralViewController : UIViewController <CBPeripheralManagerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *PeripheralMode;

@property (strong,nonatomic) CBPeripheralManager *peripheralManager;
@property (strong,nonatomic) CBMutableCharacteristic *transferCharacteristic;
@property (strong,nonatomic) NSData *sendingData;
@property (nonatomic,readwrite) NSUInteger sendDataIndex;
@property (strong,nonatomic) NSMutableDictionary *advertisingData;
@property (weak, nonatomic) IBOutlet UITextField *textfield;
- (IBAction)updateValue:(id)sender;


@end
