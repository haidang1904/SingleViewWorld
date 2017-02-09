//
//  TextInputViewController.m
//  SingleViewWorld
//
//  Created by samsung on 2015. 11. 26..
//  Copyright © 2015년 samsung. All rights reserved.
//

#import "TextInputViewController.h"
#import "WowMacInfo.h"
#import "BLEdbcore.h"

@interface TextInputViewController (){
    GCDAsyncUdpSocket *udpSocket;
    long tag;
}

@end

@implementation TextInputViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self textFieldInit];
    [self udpinit];
    
    self.macDbTableView.scrollEnabled =YES;
    self.macDbTableView.delegate = self;
    self.macDbTableView.dataSource = self;
    
    [self.macDbTableView registerNib:[UINib nibWithNibName:@"macDbTableViewCell" bundle:nil]  forCellReuseIdentifier:@"macDbTableViewCell"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (IBAction)sendWOWaction:(id)sender {
    [self makeWowPacket];
}

- (IBAction)addListaction:(id)sender {
    WowMacInfo *defaultMac = [[WowMacInfo alloc] init];
    defaultMac.mac1 = self.macAddrInput1.text;
    defaultMac.mac2 = self.macAddrInput2.text;
    defaultMac.mac3 = self.macAddrInput3.text;
    defaultMac.mac4 = self.macAddrInput4.text;
    defaultMac.mac5 = self.macAddrInput5.text;
    defaultMac.mac6 = self.macAddrInput6.text;

    [[BLEdbcore sharedInstance] createData:kEntityNameWowMac object:defaultMac];
    [self.macDbTableView reloadData];
}

- (void)makeWowPacket
{
    //NSString *wakeemac = @"F8:04:2E:EA:72:DE"; // default wireless TV
    //NSString *wakeemac = @"84:a4:66:c5:3a:c2"; // default wired TV
    NSString *destIP = @"255.255.255.255";
    UInt16 destPort = 2016;
    NSMutableData *wowPacket = [[NSMutableData alloc]init];
    
    unsigned int magicPacketId = 255;   // 0xFF
    unsigned int num;
    
    for(int i=0; i<6; i++)
    {
        
        [wowPacket appendBytes:&magicPacketId length:1];
    }
    
    for(int i=0; i<16; i++)
    {
        [[NSScanner scannerWithString:self.macAddrInput1.text] scanHexInt:&num];
        [wowPacket appendBytes:&num length:1];
        [[NSScanner scannerWithString:self.macAddrInput2.text] scanHexInt:&num];
        [wowPacket appendBytes:&num length:1];
        [[NSScanner scannerWithString:self.macAddrInput3.text] scanHexInt:&num];
        [wowPacket appendBytes:&num length:1];
        [[NSScanner scannerWithString:self.macAddrInput4.text] scanHexInt:&num];
        [wowPacket appendBytes:&num length:1];
        [[NSScanner scannerWithString:self.macAddrInput5.text] scanHexInt:&num];
        [wowPacket appendBytes:&num length:1];
        [[NSScanner scannerWithString:self.macAddrInput6.text] scanHexInt:&num];
        [wowPacket appendBytes:&num length:1];
    }
    SVLogTEST(@"length - %lu",(unsigned long)wowPacket.length);
    SVLogTEST(@"%@",wowPacket);
    
    [udpSocket sendData:wowPacket  toHost:destIP port:destPort withTimeout:1.0 tag:tag];
}

- (void)textFieldInit
{
    self.macAddrInput1.delegate = self;
    self.macAddrInput2.delegate = self;
    self.macAddrInput3.delegate = self;
    self.macAddrInput4.delegate = self;
    self.macAddrInput5.delegate = self;
    self.macAddrInput6.delegate = self;
    
    self.macAddrInput1.textAlignment = NSTextAlignmentCenter;
    self.macAddrInput2.textAlignment = NSTextAlignmentCenter;
    self.macAddrInput3.textAlignment = NSTextAlignmentCenter;
    self.macAddrInput4.textAlignment = NSTextAlignmentCenter;
    self.macAddrInput5.textAlignment = NSTextAlignmentCenter;
    self.macAddrInput6.textAlignment = NSTextAlignmentCenter;
    
    self.macAddrInput1.tag = 1;
    self.macAddrInput2.tag = 2;
    self.macAddrInput3.tag = 3;
    self.macAddrInput4.tag = 4;
    self.macAddrInput5.tag = 5;
    self.macAddrInput6.tag = 6;
    
    self.macAddrInput1.text = @"F8";
    self.macAddrInput2.text = @"04";
    self.macAddrInput3.text = @"2E";
    self.macAddrInput4.text = @"EA";
    self.macAddrInput5.text = @"72";
    self.macAddrInput6.text = @"DE";  //F8:04:2E:EA:72:DE
}

- (void)udpinit
{
    NSError *error = nil;
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    if(![udpSocket bindToPort:0 error:&error])
    {
        SVLogTEST(@"bind To Port error!(%@)",error.localizedDescription);
        return;
    }
    
    if(![udpSocket beginReceiving:&error])
    {
        SVLogTEST(@"begin Receiving error!(%@)",error.localizedDescription);
        return;
    }
    [udpSocket setIPv4Enabled:YES];
    [udpSocket setIPv6Enabled:NO];
    if(![udpSocket enableBroadcast:YES error:&error])
    {
        SVLogTEST(@"udpSocket fail! %@",error.localizedDescription);
    }
    else
    {
        SVLogTEST(@"udpSocket init success!");
    }
}

#pragma mark -
#pragma mark GCDAsyncUdpSocket Delegates
/****************************************************************************/
/*                      GCDAsyncUdpSocket Delegates                         */
/****************************************************************************/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    SVLogTEST(@"didConnectToAddress!(%@)",sock);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error
{
    SVLogTEST(@"didNotConnect!(%@)",sock);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    SVLogTEST(@"UDP SendData Success");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    SVLogTEST(@"UDP SendData Error:%@",error.localizedDescription);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    SVLogTEST(@"didReceiveData!(%@)",data);
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error
{
    SVLogTEST(@"udpSocketDidClose!(%@)",sock);
}

#pragma mark -
#pragma mark GCDAsyncUdpSocket Delegates
/****************************************************************************/
/*                         UITextField Delegates                            */
/****************************************************************************/
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL ret_val = YES;
    if(string.length == 0)  // less case
    {
        if(textField.text.length == 1)
        {
            
            switch (textField.tag) {
                case 1:
                    //[self.macAddrInput2 becomeFirstResponder];
                    self.macAddrInput1.text = @"";
                    ret_val = NO;
                    break;
                case 2:
                    [self.macAddrInput1 becomeFirstResponder];
                    self.macAddrInput2.text = @"";
                    ret_val = NO;
                    break;
                case 3:
                    [self.macAddrInput2 becomeFirstResponder];
                    self.macAddrInput3.text = @"";
                    ret_val = NO;
                    break;
                case 4:
                    [self.macAddrInput3 becomeFirstResponder];
                    self.macAddrInput4.text = @"";
                    ret_val = NO;
                    break;
                case 5:
                    [self.macAddrInput4 becomeFirstResponder];
                    self.macAddrInput5.text = @"";
                    ret_val = NO;
                    break;
                case 6:
                    [self.macAddrInput5 becomeFirstResponder];
                    self.macAddrInput6.text = @"";
                    ret_val = NO;
                    break;
                    
                default:
                    break;
            }
        }
    }
    else if( (textField.text.length==1) && (string.length== 1) )  // normal case
    {
        ret_val = NO;
        switch (textField.tag) {
            case 1:
                [self.macAddrInput2 becomeFirstResponder];
                self.macAddrInput1.text = [NSString stringWithFormat:@"%@%@",self.macAddrInput1.text,string];
                break;
            case 2:
                [self.macAddrInput3 becomeFirstResponder];
                self.macAddrInput2.text = [NSString stringWithFormat:@"%@%@",self.macAddrInput2.text,string];
                break;
            case 3:
                [self.macAddrInput4 becomeFirstResponder];
                self.macAddrInput3.text = [NSString stringWithFormat:@"%@%@",self.macAddrInput3.text,string];
                break;
            case 4:
                [self.macAddrInput5 becomeFirstResponder];
                self.macAddrInput4.text = [NSString stringWithFormat:@"%@%@",self.macAddrInput4.text,string];
                break;
            case 5:
                [self.macAddrInput6 becomeFirstResponder];
                self.macAddrInput5.text = [NSString stringWithFormat:@"%@%@",self.macAddrInput5.text,string];
                break;
            case 6:
                [self.sendWOW becomeFirstResponder];
                self.macAddrInput6.text = [NSString stringWithFormat:@"%@%@",self.macAddrInput6.text,string];
                break;
                
            default:
                break;
        }
    }
    else if((textField.text.length>=2) && (string.length== 1))  // over case
    {
        ret_val = YES;
        switch (textField.tag) {
            case 1:
                [self.macAddrInput2 becomeFirstResponder];
                break;
            case 2:
                [self.macAddrInput3 becomeFirstResponder];
                break;
            case 3:
                [self.macAddrInput4 becomeFirstResponder];
                break;
            case 4:
                [self.macAddrInput5 becomeFirstResponder];
                break;
            case 5:
                [self.macAddrInput6 becomeFirstResponder];
                break;
            case 6:
                [self.sendWOW becomeFirstResponder];
                break;
                
            default:
                break;
        }
    }
    
    
    return ret_val;
}

#pragma mark -
#pragma mark UITableViewDataSource Delegates
/****************************************************************************/
/*                    UITableViewDataSource Delegates                       */
/****************************************************************************/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    _wowDB = [[BLEdbcore sharedInstance] readData:kEntityNameWowMac Key:nil value:nil];
    if(_wowDB == nil)
    {
        return 0;
    }
    else
    {
        return _wowDB.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"macDbTableViewCell";
    
    _cell = [self.macDbTableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    if (_cell == nil) {
        _cell = [[macDbTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    WowMacInfo *info = (WowMacInfo*)self.wowDB[indexPath.row];
    _cell.macAddrLabel.text = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@",info.mac1,info.mac2,info.mac3,info.mac4,info.mac5,info.mac6];
    [_cell.deleteDB addTarget:self action:@selector(onClickDeleteBtn:event:) forControlEvents:UIControlEventTouchUpInside];
    
    return _cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WowMacInfo *info = (WowMacInfo*)self.wowDB[indexPath.row];
    self.macAddrInput1.text = info.mac1;
    self.macAddrInput2.text = info.mac2;
    self.macAddrInput3.text = info.mac3;
    self.macAddrInput4.text = info.mac4;
    self.macAddrInput5.text = info.mac5;
    self.macAddrInput6.text = info.mac6;
}

- (void)onClickDeleteBtn:(id)sender event:(id)event
{
    CGPoint point = [[[event allTouches] anyObject] locationInView:self.macDbTableView];
    NSIndexPath *path = [_macDbTableView indexPathForRowAtPoint:point];
    //UIButton *btn = (UIButton *)sender;
    
    WowMacInfo *info = (WowMacInfo*)self.wowDB[path.row];
    
    [[BLEdbcore sharedInstance] deleteData:kEntityNameWowMac Key:nil value:info];
    [self.macDbTableView reloadData];
}
@end
