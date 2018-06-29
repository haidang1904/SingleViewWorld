//
//  TextInputViewController.h
//  SingleViewWorld
//
//  Created by samsung on 2015. 11. 26..
//  Copyright © 2015년 samsung. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "macDbTableViewCell.h"
#import <SmartView/SmartView.h>
#import "GCDAsyncUdpSocket.h"

@interface TextInputViewController : UIViewController <GCDAsyncUdpSocketDelegate,UITextFieldDelegate,UITableViewDataSource, UITableViewDelegate>


@property (strong,nonatomic) macDbTableViewCell *cell;
@property (weak, nonatomic) IBOutlet UITableView *macDbTableView;


@property (weak, nonatomic) IBOutlet UILabel *outputLabel;

@property (weak, nonatomic) IBOutlet UIView *wowView;
@property (weak, nonatomic) IBOutlet UITextField *macAddrInput1;
@property (weak, nonatomic) IBOutlet UITextField *macAddrInput2;
@property (weak, nonatomic) IBOutlet UITextField *macAddrInput3;
@property (weak, nonatomic) IBOutlet UITextField *macAddrInput4;
@property (weak, nonatomic) IBOutlet UITextField *macAddrInput5;
@property (weak, nonatomic) IBOutlet UITextField *macAddrInput6;
@property (weak, nonatomic) IBOutlet UIButton *sendWOW;
- (IBAction)sendWOWaction:(id)sender;
- (IBAction)addListaction:(id)sender;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *wowViewTopConstraint;

@property (strong,nonatomic) NSArray *wowDB;

@end
