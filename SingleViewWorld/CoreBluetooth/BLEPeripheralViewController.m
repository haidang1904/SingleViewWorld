//
//  BLEPeripheralViewController.m
//  SingleViewWorld
//
//  Created by samsung on 2015. 8. 12..
//  Copyright (c) 2015년 samsung. All rights reserved.
//

#import "BLEPeripheralViewController.h"

@interface BLEPeripheralViewController ()

@end

@implementation BLEPeripheralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self peripheralinit];
    self.textfield.text = @"Test mode";
    
    //SVLogTEST(@"viewDidLoad");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    //SVLogTEST(@"viewDidDisappear");
}

- (void)viewWillDisappear:(BOOL)animated
{
    //SVLogTEST(@"viewWillDisappear");
    [self stopadvertising];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark -
- (void) peripheralinit
{
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    [self stopadvertising];
}

- (void) startadvertising
{
    [self addservice];
    [self makeadvertisingdata];

    [_peripheralManager startAdvertising:self.advertisingData];
}

- (void) stopadvertising
{
    SVLogTEST(@"Device advertising stop request - current state %d",[_peripheralManager isAdvertising]);
    if([_peripheralManager isAdvertising] == YES)
    {
        [_peripheralManager stopAdvertising];
    }
}

- (void) addservice
{
    SVLogTEST(@"Device addservice");
    NSUInteger properties = (CBCharacteristicPropertyNotify | CBCharacteristicPropertyRead);
    self.transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID] properties:properties value:nil permissions:CBAttributePermissionsReadable];
    CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID] primary:YES];
    
    transferService.characteristics = @[self.transferCharacteristic];
    [_peripheralManager addService:transferService];
}

- (void) makeadvertisingdata
{
    self.advertisingData = [[NSMutableDictionary alloc]init];
    [self.advertisingData setValue:@"[LHJ]TEST" forKey:CBAdvertisementDataLocalNameKey];
    //[self.advertisingData setValue:[[NSString stringWithFormat:@"Samsung"] dataUsingEncoding:NSUTF8StringEncoding] forKey:CBAdvertisementDataManufacturerDataKey];
    [self.advertisingData setValue:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] forKey:CBAdvertisementDataServiceUUIDsKey];
}

- (IBAction)updateValue:(id)sender {

    _sendingData = [self.textfield.text dataUsingEncoding:NSUTF8StringEncoding];
    _sendDataIndex = 0;
    BOOL didsend = [_peripheralManager updateValue:_sendingData forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
    
    if(didsend)
    {
        SVLogTEST(@"updateValue success %@",_sendingData);
        [self sendData];
    }
    else
    {
        SVLogTEST(@"updateValue fail %@",_sendingData);
    }
}

- (void)sendData {
    
    static BOOL sendingEOM = NO;
    
    // end of message?
    if (sendingEOM) {
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        if (didSend) {
            // It did, so mark it as sent
            sendingEOM = NO;
        }
        // didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're sending data
    // Is there any left to send?
    if (self.sendDataIndex >= self.sendingData.length) {
        // No data left.  Do nothing
        return;
    }
    /*
    // There's data left, so send until the callback fails, or we're done.
    BOOL didSend = YES;
    
    while (didSend) {
        // Work out how big it should be
        NSInteger amountToSend = self.sendingData.length - self.sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.sendingData.bytes+self.sendDataIndex length:amountToSend];
        
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            return;
        }
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"Sent: %@", stringFromData);
        
        // It did send, so update our index
        self.sendDataIndex += amountToSend;
        
        // Was it the last one?
        if (self.sendDataIndex >= self.dataToSend.length) {
            
            // Set this so if the send fails, we'll send it next time
            sendingEOM = YES;
            
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                // It sent, we're all done
                sendingEOM = NO;
                NSLog(@"Sent: EOM");
            }
            
            return;
        }
    }
     */
}

#pragma mark -
#pragma mark CBPeripheralManagerDelegate - required

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if([peripheral state] == CBPeripheralManagerStateUnknown)
    {
        SVLogTEST(@"CBPeripheralManager State Unknown");
    }
    else if([peripheral state] == CBPeripheralManagerStateResetting)
    {
        SVLogTEST(@"CBPeripheralManager State Resetting");
    }
    else if([peripheral state] == CBPeripheralManagerStateUnsupported)
    {
        SVLogTEST(@"CBPeripheralManager State Unsupported");
    }
    else if([peripheral state] == CBPeripheralManagerStateUnauthorized)
    {
        SVLogTEST(@"CBPeripheralManager State Unauthorized");
    }
    else if([peripheral state] == CBPeripheralManagerStatePoweredOff)
    {
        SVLogTEST(@"CBPeripheralManager State PoweredOff");
    }
    else if([peripheral state] == CBPeripheralManagerStatePoweredOn)
    {
        SVLogTEST(@"CBPeripheralManager State PoweredOn");
        [self startadvertising];
    }
}

#pragma mark CBPeripheralManagerDelegate - optional

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if(error == nil)
    {
        SVLogTEST(@"Device advertising start success - error code %@",error);
    }
    else
    {
        SVLogTEST(@"Device advertising start fail - error code %@",error);
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if(error == nil)
    {
        SVLogTEST(@"Device added service success - service code %@",service);
    }
    else
    {
        SVLogTEST(@"Device added service fail - error code %@",error);
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    SVLogTEST(@"didReceiveReadRequest %@",request);
    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    SVLogTEST(@"didSubscribeToCharacteristic %@",characteristic);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    SVLogTEST(@"didUnsubscribeFromCharacteristic %@",characteristic);
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    SVLogTEST(@"peripheralManagerIsReadyToUpdateSubscribers %@",peripheral);
}

@end
