//
//  DynamicsViewController.h
//  SingleViewWorld
//
//  Created by samsung on 8/28/15.
//  Copyright (c) 2015 samsung. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DynamicsViewController : UIViewController

@property CGPoint currentLocation;
@property (strong,nonatomic) UIView *redboxView;
@property (strong,nonatomic) UIView *blueboxView;
@property (strong,nonatomic) UIDynamicAnimator *animator;
@property (strong,nonatomic) UIAttachmentBehavior *attachment;

@end
