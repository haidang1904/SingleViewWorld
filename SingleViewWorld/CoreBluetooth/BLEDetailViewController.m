//
//  BLEDetailViewController.m
//  SingleViewWorld
//
//  Created by samsung on 2015. 8. 17..
//  Copyright (c) 2015년 samsung. All rights reserved.
//

#import "BLEDetailViewController.h"
#import "BLESingleton.h"

@interface BLEDetailViewController () <UIAlertViewDelegate,BLESingletonDelegate>

@property (strong,nonatomic) BLESingleton *BLECore;

@end

@implementation BLEDetailViewController


- (void)viewDidLoad {
    
    //SVLogTEST(@"BLEDetailView viewDidLoad");
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    
    _BLECore = [BLESingleton defaultBLECore];
    _BLECore.delegate = (id)self;
    
    _pi = _BLECore.selectedPeripheral;
    is_connected = (conn_state)_pi.peripheral.state;
    current_view = SERVICE_VIEW;
    
    self.title = @"details..";
    self.navigationController.navigationBar.backgroundColor=[UIColor redColor];
    //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"refresh" style:UIBarButtonItemStylePlain target:self action:@selector(refreshDetailData)];
    [_btnReadValue setTitle:@"BACK" forState:UIControlStateNormal];
    
    _BLEservicestable.delegate = self;
    _BLEservicestable.dataSource = self;
    _BLEservicestable.rowHeight = 80;
    [_BLEservicestable registerNib:[UINib nibWithNibName:@"BLEDetailViewCell" bundle:nil]  forCellReuseIdentifier:@"BLEDetailViewCell"];
}

-(void) viewWillAppear:(BOOL)animated
{
    //SVLogTEST(@"BLEDetailView viewWillAppear");
    [self refreshDetailData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    //SVLogTEST(@"BLEDetailView viewWillDisappear");
    [super viewWillDisappear:animated];
    
    [_BLECore disconnectBTperipheral:self.pi];
    [_BLECore removeCenterDelegate];
    is_connected = DISCONNECTED;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) refreshDetailData{

    if(is_connected == CONNECTED){
        [_btnConnect setTitle:@"DISCONNECT" forState:UIControlStateNormal];
        _btnReadValue.hidden = NO;
    }else if(is_connected == CONNECTING){
        [_btnConnect setTitle:@"CANCEL" forState:UIControlStateNormal];
        _btnReadValue.hidden = YES;
    }else{
        [_btnConnect setTitle:@"CONNECT" forState:UIControlStateNormal];
        _btnReadValue.hidden = YES;
    }

    _labelMname.text = _pi.name;
    _labelUuid.text = _pi.uuid;
    
    if((_pi.fakeName == nil) || [_pi.fakeName isEqualToString:@""]){
        _labelLname.text = _pi.localName;
        _labelLname.textColor = [UIColor blackColor];
    }else{
        _labelLname.text = _pi.fakeName;
        _labelLname.textColor = [UIColor redColor];
    }
    
    if(current_view == CHARACTERISTIC_VIEW){
        _labelService.text = [self getGATTName:_BLECore.selectedSevice.UUID];
        _labelValue.text = [self getGATTValue];
    }else{
        _labelService.text = [NSString stringWithFormat:@""];
        _labelValue.text = [NSString stringWithFormat:@""];
        _btnReadValue.hidden = YES;
    }
    
    [_BLEservicestable reloadData];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onBtnConnect:(id)sender {
    
    if(_BLECore.myCenter.delegate == nil)
    {
        [_BLECore addCenterDelegate];
    }
    
    if(is_connected == DISCONNECTED)
    {
        [_BLECore connectBTperipheral:self.pi];
        is_connected = CONNECTING;
    }
    else if(is_connected == CONNECTING)
    {
        [_BLECore disconnectBTperipheral:self.pi];
        is_connected = DISCONNECTED;
    }
    else
    {
        [_BLECore disconnectBTperipheral:self.pi];
        is_connected = DISCONNECTED;
    }
    [self refreshDetailData];
}
- (IBAction)onBtnEdit:(id)sender {
    
    UIAlertView *changealert = [[UIAlertView alloc] initWithTitle:@"이름변경" message:@"변경할 이름을 입력하세요 \n 아무입력없이 'OK' 버튼을 누르면 지워집니다" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    changealert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    [changealert show];
}

- (IBAction)onBtnReadvalue:(id)sender {
    
    if(current_view == CHARACTERISTIC_VIEW)
    {
        current_view = SERVICE_VIEW;
    }
    [self refreshDetailData];
}

- (UInt16) CBUUIDToInt:(CBUUID *) UUID {
    char b1[16];
    [UUID.data getBytes:b1 length:16];
    return ((b1[0] << 8) | b1[1]);
}

- (NSString *)getGATTName:(CBUUID *)UUID{
    UInt16 _uuid = [self CBUUIDToInt:UUID];
    switch(_uuid)
    {
        case 0x1800: return @"Generic Access"; break;
        case 0x1801: return @"Generic Attribute"; break;
        case 0x1802: return @"Immediate Alert"; break;
        case 0x1803: return @"Link Loss"; break;
        case 0x1804: return @"Tx Power"; break;
        case 0x1805: return @"Current Time Service"; break;
        case 0x1806: return @"Reference Time Update Service"; break;
        case 0x1807: return @"Next DST Change Service"; break;
        case 0x1808: return @"Glucose"; break;
        case 0x1809: return @"Health Thermometer"; break;
        case 0x180A: return @"Device Information"; break;
        case 0x180B: return @"Network Availability Service"; break;
        case 0x180C: return @"Watchdog"; break;
        case 0x180D: return @"Heart Rate"; break;
        case 0x180E: return @"Phone Alert Status Service"; break;
        case 0x180F: return @"Battery Service"; break;
        case 0x1810: return @"Blood Pressure"; break;
        case 0x1811: return @"Alert Notification Service"; break;
        case 0x1812: return @"Human Interface Device"; break;
        case 0x1813: return @"Scan Parameters"; break;
        case 0x1814: return @"RUNNING SPEED AND CADENCE"; break;
        case 0x1815: return @"Automation IO"; break;
        case 0x1816: return @"Cycling Speed and Cadence"; break;
        case 0x1817: return @"Pulse Oximeter"; break;
        case 0x1818: return @"Cycling Power Service"; break;
        case 0x1819: return @"Location and Navigation Service"; break;
        case 0x181A: return @"Continous Glucose Measurement Service"; break;
        case 0x2A00: return @"Device Name"; break;
        case 0x2A01: return @"Appearance"; break;
        case 0x2A02: return @"Peripheral Privacy Flag"; break;
        case 0x2A03: return @"Reconnection Address"; break;
        case 0x2A04: return @"Peripheral Preferred Connection Parameters"; break;
        case 0x2A05: return @"Service Changed"; break;
        case 0x2A06: return @"Alert Level"; break;
        case 0x2A07: return @"Tx Power Level"; break;
        case 0x2A08: return @"Date Time"; break;
        case 0x2A09: return @"Day of Week"; break;
        case 0x2A0A: return @"Day Date Time"; break;
        case 0x2A0B: return @"Exact Time 100"; break;
        case 0x2A0C: return @"Exact Time 256"; break;
        case 0x2A0D: return @"DST Offset"; break;
        case 0x2A0E: return @"Time Zone"; break;
        case 0x2A0F: return @"Local Time Information"; break;
        case 0x2A10: return @"Secondary Time Zone"; break;
        case 0x2A11: return @"Time with DST"; break;
        case 0x2A12: return @"Time Accuracy"; break;
        case 0x2A13: return @"Time Source"; break;
        case 0x2A14: return @"Reference Time Information"; break;
        case 0x2A15: return @"Time Broadcast"; break;
        case 0x2A16: return @"Time Update Control Point"; break;
        case 0x2A17: return @"Time Update State"; break;
        case 0x2A18: return @"Glucose Measurement"; break;
        case 0x2A19: return @"Battery Level"; break;
        case 0x2A1A: return @"Battery Power State"; break;
        case 0x2A1B: return @"Battery Level State"; break;
        case 0x2A1C: return @"Temperature Measurement"; break;
        case 0x2A1D: return @"Temperature Type"; break;
        case 0x2A1E: return @"Intermediate Temperature"; break;
        case 0x2A1F: return @"Temperature in Celsius"; break;
        case 0x2A20: return @"Temperature in Fahrenheit"; break;
        case 0x2A21: return @"Measurement Interval"; break;
        case 0x2A22: return @"Boot Keyboard Input Report"; break;
        case 0x2A23: return @"System ID"; break;
        case 0x2A24: return @"Model Number String"; break;
        case 0x2A25: return @"Serial Number String"; break;
        case 0x2A26: return @"Firmware Revision String"; break;
        case 0x2A27: return @"Hardware Revision String"; break;
        case 0x2A28: return @"Software Revision String"; break;
        case 0x2A29: return @"Manufacturer Name String"; break;
        case 0x2A2A: return @"IEEE 11073-20601 Regulatory Certification Data List"; break;
        case 0x2A2B: return @"Current Time"; break;
        case 0x2A2C: return @"Elevation"; break;
        case 0x2A2D: return @"Latitude"; break;
        case 0x2A2E: return @"Longitude"; break;
        case 0x2A2F: return @"Position 2D"; break;
        case 0x2A30: return @"Position 3D"; break;
        case 0x2A31: return @"Scan Refresh"; break;
        case 0x2A32: return @"Boot Keyboard Output Report"; break;
        case 0x2A33: return @"Boot Mouse Input Report"; break;
        case 0x2A34: return @"Glucose Measurement Context"; break;
        case 0x2A35: return @"Blood Pressure Measurement"; break;
        case 0x2A36: return @"Intermediate Cuff Pressure"; break;
        case 0x2A37: return @"Heart Rate Measurement"; break;
        case 0x2A38: return @"Body Sensor Location"; break;
        case 0x2A39: return @"Heart Rate Control Point"; break;
        case 0x2A3A: return @"Removable"; break;
        case 0x2A3B: return @"Service Required"; break;
        case 0x2A3C: return @"Scientific Temperature in Celsius"; break;
        case 0x2A3D: return @"String"; break;
        case 0x2A3E: return @"Network Availability"; break;
        case 0x2A3F: return @"Alert Status"; break;
        case 0x2A40: return @"Ringer Control Point"; break;
        case 0x2A41: return @"Ringer Setting"; break;
        case 0x2A42: return @"Alert Category ID Bit Mask"; break;
        case 0x2A43: return @"Alert Category ID"; break;
        case 0x2A44: return @"Alert Notification Control Point"; break;
        case 0x2A45: return @"Unread Alert Status"; break;
        case 0x2A46: return @"New Alert"; break;
        case 0x2A47: return @"Supported New Alert Category"; break;
        case 0x2A48: return @"Supported Unread Alert Category"; break;
        case 0x2A49: return @"Blood Pressure Feature"; break;
        case 0x2A4A: return @"HID Information"; break;
        case 0x2A4B: return @"Report Map"; break;
        case 0x2A4C: return @"HID Control Point"; break;
        case 0x2A4D: return @"Report"; break;
        case 0x2A4E: return @"Protocol Mode"; break;
        case 0x2A4F: return @"Scan Interval Window"; break;
        case 0x2A50: return @"PnP ID"; break;
        case 0x2A51: return @"Glucose Features"; break;
        case 0x2A52: return @"Record Access Control Point"; break;
        case 0x2A53: return @"RSC Measurement"; break;
        case 0x2A54: return @"RSC Feature"; break;
        case 0x2A55: return @"SC Control Point"; break;
        case 0x2A56: return @"Digital Input"; break;
        case 0x2A57: return @"Digital Output"; break;
        case 0x2A58: return @"Analog Input"; break;
        case 0x2A59: return @"Analog Output"; break;
        case 0x2A5A: return @"Aggregate Input"; break;
        case 0x2A5B: return @"CSC Measurement"; break;
        case 0x2A5C: return @"CSC Feature"; break;
        case 0x2A5D: return @"Sensor Location"; break;
        case 0x2A5E: return @"Pulse Oximetry Spot-check Measurement"; break;
        case 0x2A5F: return @"Pulse Oximetry Continuous Measurement"; break;
        case 0x2A60: return @"Pulse Oximetry Pulsatile Event"; break;
        case 0x2A61: return @"Pulse Oximetry Features"; break;
        case 0x2A62: return @"Pulse Oximetry Control Point"; break;
        case 0x2A63: return @"Cycling Power Measurement Characteristic"; break;
        case 0x2A64: return @"Cycling Power Vector Characteristic"; break;
        case 0x2A65: return @"Cycling Power Feature Characteristic"; break;
        case 0x2A66: return @"Cycling Power Control Point Characteristic"; break;
        case 0x2A67: return @"Location and Speed Characteristic"; break;
        case 0x2A68: return @"Navigation Characteristic"; break;
        case 0x2A69: return @"Position Quality Characteristic"; break;
        case 0x2A6A: return @"LN Feature Characteristic"; break;
        case 0x2A6B: return @"LN Control Point Characteristic"; break;
        case 0x2A6C: return @"CGM Measurement Characteristic"; break;
        case 0x2A6D: return @"CGM Features Characteristic"; break;
        case 0x2A6E: return @"CGM Status Characteristic"; break;
        case 0x2A6F: return @"CGM Session Start Time Characteristic"; break;
        case 0x2A70: return @"Application Security Point Characteristic"; break;
        case 0x2A71: return @"CGM Specific Ops Control Point Characteristic"; break;
        default:
            return [NSString stringWithFormat:@"Customized (0x%x)",_uuid];
            break;
    }
}

- (NSString *)getGATTValue
{
    NSString *returnString = nil;
    NSString *characterisic = [self getGATTName:_BLECore.selectedCharacteristic.UUID];
    
    if([characterisic isEqualToString:@"Battery Level"])
    {
        char *p = (char*)_BLECore.selectedCharacteristic.value.bytes;
        returnString = [NSString stringWithFormat:@"%i",p[0]];
    }
    else if([characterisic isEqualToString:@"Current Time"] )
    {
        SVLogTEST(@"getGATTValue %@ - %lu",characterisic,_BLECore.selectedCharacteristic.value.length);
        
        char *p = (char*)_BLECore.selectedCharacteristic.value.bytes;
        NSInteger len = [_BLECore.selectedCharacteristic.value length];
        NSMutableString *str = [NSMutableString string];
        //[NSScanner scannerWithString:str]
        for (int i=0 ; i < len;i++) {
            SVLogTEST(@"%i",p[i]);
            [str appendString:[NSString stringWithFormat:@"%i",p[i]]];
        }
        returnString = str;
    }
    else if([characterisic isEqualToString:@"Manufacturer Name String"] ||
            [characterisic isEqualToString:@"Model Number String"] ||
            [characterisic isEqualToString:[NSString stringWithFormat:@"Customized (0x%x)",[self CBUUIDToInt:_BLECore.selectedCharacteristic.UUID]]])
    {
        returnString = [[NSString alloc] initWithData:_BLECore.selectedCharacteristic.value encoding:NSUTF8StringEncoding];
    }
    else
    {
        returnString = [NSString stringWithFormat:@"%@",_BLECore.selectedCharacteristic.value];
    }
    
    
    return returnString;
}

#pragma mark -
#pragma mark table delegate
/****************************************************************************/
/*                           tableView Delegates                            */
/****************************************************************************/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger ret;
    if(current_view == SERVICE_VIEW)
    {
        ret = [_pi.peripheral.services count];
    }else   //CHARACTERISTIC_VIEW
    {
        ret = [_BLECore.selectedSevice.characteristics count];
    }
    
    return ret;
    
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(current_view == SERVICE_VIEW)
    {
        current_view = CHARACTERISTIC_VIEW;
        
        _BLECore.selectedSevice = _pi.peripheral.services[indexPath.row];
        _labelValue.hidden = YES;
    
    }else   //CHARACTERISTIC_VIEW
    {
        _BLECore.selectedCharacteristic = _BLECore.selectedSevice.characteristics[indexPath.row];
        _labelValue.hidden = NO;
    }
    [self refreshDetailData];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"BLEDetailViewCell";
    
    _cell = [self.BLEservicestable dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    if (_cell == nil) {
        _cell = [[BLEDetailViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    if(current_view == SERVICE_VIEW)
    {
        CBService *ser = _pi.peripheral.services[indexPath.row];
        _cell.uuidlabel.text = [self getGATTName:ser.UUID];
    }else   //CHARACTERISTIC_VIEW
    {
        CBCharacteristic *cha = _BLECore.selectedSevice.characteristics[indexPath.row];
        _cell.uuidlabel.text = [self getGATTName:cha.UUID];
    }
    _cell.sublabel.hidden = YES;
    return _cell;
}

#pragma mark -
#pragma mark BLESingletonDelegate
/****************************************************************************/
/*                         BLESingleton Delegates                           */
/****************************************************************************/
-(void)didConnected
{
    SVLogTEST(@"nil:%@",_pi.peripheral.services);
    
    is_connected = CONNECTED;
    [self refreshDetailData];
}
-(void)didDisconnected
{
    is_connected = DISCONNECTED;
    current_view = SERVICE_VIEW;
    [self refreshDetailData];
}

-(void)didReadvalue
{
    [self refreshDetailData];
}

#pragma mark -
#pragma mark UIAlertViewDelegate
/****************************************************************************/
/*                     UIAlertViewDelegate Delegates                        */
/****************************************************************************/
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    UITextField *textfield = [alertView textFieldAtIndex:0];
    
    if(buttonIndex == [alertView firstOtherButtonIndex])
    {
        if(textfield.text != nil)
        {
            self.BLECore.selectedPeripheral.fakeName = textfield.text;
            SVLogTEST(@"fakeName saved text:%@",textfield.text);
            [[BLEdbcore sharedInstance] updateData:kEntityNameLocal object:self.BLECore.selectedPeripheral];
        }
        else
        {
            SVLogTEST(@"nil:%@",textfield.text);
        }
    }
    [self refreshDetailData];
}

@end
