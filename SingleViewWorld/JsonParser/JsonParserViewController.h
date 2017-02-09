//
//  JsonParserViewController.h
//  SingleViewWorld
//
//  Created by samsung on 2016. 5. 4..
//  Copyright © 2016년 samsung. All rights reserved.
//

#import <UIKit/UIKit.h>

@import UserNotifications;

@interface JsonParserViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *getBtn;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
- (IBAction)getBtnAction:(id)sender;

@end
