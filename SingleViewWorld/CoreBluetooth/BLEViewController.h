#ifndef BLEVIEWCONTROLLER_H
#define BLEVIEWCONTROLLER_H

//
//  ViewController.h
//  SingleViewWorld
//
//  Created by samsung on 2015. 8. 3..
//  Copyright (c) 2015년 samsung. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "AppDelegate.h"
#import "BLETableViewCell.h"
#import "PeripheralInfo.h"
#import "BLEDetailViewController.h"
#import "BLEdbcore.h"


@interface BLEViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong,nonatomic) BLETableViewCell *cell;
@property (weak, nonatomic) IBOutlet UITableView *BLETableView;

@end

#endif