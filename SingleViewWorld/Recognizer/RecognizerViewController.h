//
//  RecognizerViewController.h
//  SingleViewWorld
//
//  Created by samsung on 8/28/15.
//  Copyright (c) 2015 samsung. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecognizerViewController : UIViewController
- (IBAction)rotationDetacted:(UIRotationGestureRecognizer *)sender;
- (IBAction)pinchDetacted:(UIPinchGestureRecognizer *)sender;
- (IBAction)swipeDetacted:(UISwipeGestureRecognizer *)sender;
- (IBAction)longpressDetacted:(UILongPressGestureRecognizer *)sender;
- (IBAction)tabDetacted:(UITapGestureRecognizer *)sender;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end
