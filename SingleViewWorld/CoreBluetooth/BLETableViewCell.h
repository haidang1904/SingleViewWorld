//
//  BLETableViewCell.h
//  SingleViewWorld
//
//  Created by samsung on 2015. 8. 3..
//  Copyright (c) 2015년 samsung. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BLETableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *devicename;
@property (weak, nonatomic) IBOutlet UILabel *devicelocalname;
@property (weak, nonatomic) IBOutlet UILabel *deviceuuid;
@property (weak, nonatomic) IBOutlet UILabel *index;
@property (weak, nonatomic) IBOutlet UILabel *rssi;

@end
