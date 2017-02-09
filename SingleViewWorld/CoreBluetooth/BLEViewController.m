 //
 //  ViewController.m
 //  SingleViewWorld
 //
 //  Created by samsung on 2015. 8. 3..
 //  Copyright (c) 2015년 samsung. All rights reserved.
 //

#import <Foundation/Foundation.h>

#import "BLEViewController.h"
#import "BLESingleton.h"


@interface BLEViewController () <BLESingletonDelegate>

@property (strong,nonatomic) BLESingleton *BLECore;

@end

@implementation BLEViewController
{

}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization

    }
    return self;
}

#pragma mark -
#pragma mark View lifecycle
/****************************************************************************/
/*                              View Lifecycle                              */
/****************************************************************************/
- (void) viewDidLoad
{
    //SVLogTEST(@"BLEView viewDidLoad");
    [super viewDidLoad];
    
    self.BLECore = [BLESingleton defaultBLECore];
    self.BLECore.delegate = self;
  
    self.title = @"result";
    self.navigationController.navigationBar.backgroundColor=[UIColor redColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"refresh" style:UIBarButtonItemStylePlain target:self action:@selector(refresh:)];
    
    self.BLETableView.scrollEnabled =YES;
    self.BLETableView.delegate = self;
    self.BLETableView.dataSource = self;
    
    [self.BLETableView registerNib:[UINib nibWithNibName:@"BLETableViewCell" bundle:nil]  forCellReuseIdentifier:@"BLETableViewCell"];
}

-(void) viewWillAppear:(BOOL)animated
{
    //SVLogTEST(@"BLEView viewWillAppear");
    
    self.BLECore = [BLESingleton defaultBLECore];
    self.BLECore.delegate = self;
    
    if([self.BLECore.myCenter state] != CBCentralManagerStatePoweredOn)
    {
        SVLogTEST(@"state is not ready!! %ld",(long)[self.BLECore.myCenter state]);
    }
}

- (void) viewDidUnload
{
    //SVLogTEST(@"BLEView viewDidUnload");
    [super viewDidUnload];
}

- (void) viewDidDisappear:(BOOL)animated
{
    SVLogTEST(@"BLEView viewDidDisappear");
    [super viewDidDisappear:animated];

    [self.BLECore stopBTscan];
    [self.BLECore removeCenterDelegate];
}

- (void)didEnterBackgroundNotification:(NSNotification*)notification
{
    //SVLogTEST(@"Entered background notification called.");
}

- (void)didEnterForegroundNotification:(NSNotification*)notification
{
    //SVLogTEST(@"Entered foreground notification called.");
}

- (void)refresh:(id)sender
{
    SVLogTEST(@"refresh button click event!");
    [self.BLECore stopBTscan];
    [self.BLECore startBTscan:5];
    
    [self.BLETableView reloadData];
}

#pragma mark -
#pragma mark BLESingletonDelegate
/****************************************************************************/
/*                         BLESingleton Delegates                           */
/****************************************************************************/
-(void)didFoundPeripheral
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.BLETableView reloadData];
    });
}

-(void)didUpdateState:(CBCentralManager *)central;
{
    if ([central state] == CBCentralManagerStatePoweredOn) {
        [self.BLECore startBTscan:5];
    }
}

-(void)willAddPeripheral:(PeripheralInfo *)peripheral
{
}

-(void)didDisconnected
{
    //SVLogTEST(@"disconnected delegate %@",self.BLECore.selectedPeripheral.peripheral.services);
}

-(void)didConnected
{
}

#pragma mark -
#pragma mark TableView Delegates
/****************************************************************************/
/*                          TableView Delegates                             */
/****************************************************************************/
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PeripheralInfo *pi = self.BLECore.discoveredPeripherals[indexPath.row];
    static NSString *cellID = @"BLETableViewCell";
    
    _cell = [self.BLETableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    if (_cell == nil) {
        _cell = [[BLETableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    _cell.index.text = [[NSNumber numberWithInteger:indexPath.row] stringValue];
    _cell.devicename.text = pi.name;
    
    if((pi.fakeName == nil) || [pi.fakeName isEqualToString:@""]){
        _cell.devicelocalname.text = pi.localName;
        _cell.devicelocalname.textColor = [UIColor blackColor];
    }else{
        _cell.devicelocalname.text = pi.fakeName;
        _cell.devicelocalname.textColor = [UIColor redColor];
    }
    _cell.deviceuuid.text = pi.uuid;
    _cell.rssi.text = [pi.RSSI stringValue];
    _cell.rssi.textColor = [UIColor redColor];
    
    return _cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (self.BLECore.discoveredPeripherals.count);
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.BLECore.selectedPeripheral = self.BLECore.discoveredPeripherals[indexPath.row];
    
    //[_BLECore connectBTperipheral:self.BLECore.selectedPeripheral];
    BLEDetailViewController *BLEDeail = [[BLEDetailViewController alloc] initWithNibName:@"BLEDetailViewController" bundle:nil];
    [self.navigationController pushViewController:BLEDeail animated:YES];
    
}
@end