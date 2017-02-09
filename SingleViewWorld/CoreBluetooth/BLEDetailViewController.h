#ifndef BLEDETAILVIEWCONTROLLER_H
#define BLEDETAILVIEWCONTROLLER_H

//
//  BLEDetailViewController.h
//  SingleViewWorld
//
//  Created by samsung on 2015. 8. 17..
//  Copyright (c) 2015년 samsung. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "AppDelegate.h"
#import "PeripheralInfo.h"
#import "BLEViewController.h"
#import "BLEDetailViewCell.h"

typedef enum{
    DISCONNECTED=0,
    CONNECTED=1,
    CONNECTING=2,
    UNKNOWN =3,
}conn_state;

typedef  enum{
    SERVICE_VIEW,
    CHARACTERISTIC_VIEW
}view_state;

@interface BLEDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    conn_state is_connected;
    view_state current_view;
}

@property (strong,nonatomic) PeripheralInfo *pi;

@property (weak, nonatomic) IBOutlet UILabel *labelMname;
@property (weak, nonatomic) IBOutlet UILabel *labelLname;
@property (weak, nonatomic) IBOutlet UILabel *labelUuid;
@property (weak, nonatomic) IBOutlet UILabel *labelService;
@property (weak, nonatomic) IBOutlet UILabel *labelValue;
@property (weak, nonatomic) IBOutlet UIButton *btnConnect;
@property (weak, nonatomic) IBOutlet UIButton *btnEdit;
@property (weak, nonatomic) IBOutlet UIButton *btnReadValue;
- (IBAction)onBtnConnect:(id)sender;
- (IBAction)onBtnEdit:(id)sender;
- (IBAction)onBtnReadvalue:(id)sender;

@property (strong,nonatomic) BLEDetailViewCell *cell;
@property (weak, nonatomic) IBOutlet UITableView *BLEservicestable;

@end

#endif