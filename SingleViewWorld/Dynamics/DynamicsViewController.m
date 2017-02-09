//
//  DynamicsViewController.m
//  SingleViewWorld
//
//  Created by samsung on 8/28/15.
//  Copyright (c) 2015 samsung. All rights reserved.
//

#import "DynamicsViewController.h"

@interface DynamicsViewController ()

@end

@implementation DynamicsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //self.navigationController.navigationBarHidden = YES;
    //self.navigationItem.titleView.alpha = 100;
    
    /*
    [self makeframe];
    
    [self.view addSubview:_redboxView];
    [self.view addSubview:_blueboxView];
    
    [self defaultDynamics];
    
    UIAttachmentBehavior *boxattaachment = [[UIAttachmentBehavior alloc]
                                            initWithItem:_blueboxView attachedToItem:_redboxView];
    
    [_animator addBehavior:boxattaachment];
     */
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self makeframe];
    
    [self.view addSubview:_redboxView];
    [self.view addSubview:_blueboxView];
    
    [self defaultDynamics];
    
    UIAttachmentBehavior *boxattaachment = [[UIAttachmentBehavior alloc]
                                            initWithItem:_blueboxView attachedToItem:_redboxView];
    
    [_animator addBehavior:boxattaachment];
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

- (void) makeframe
{
    CGRect framerect = CGRectMake(10, 120, 80, 80);
    _blueboxView = [[UIView alloc]initWithFrame:framerect];
    _blueboxView.backgroundColor = [UIColor blueColor];
    
    framerect = CGRectMake(150, 120, 60, 60);
    _redboxView = [[UIView alloc]initWithFrame:framerect];
    _redboxView.backgroundColor = [UIColor redColor];
}

- (void) defaultDynamics
{
    _animator = [[UIDynamicAnimator alloc]initWithReferenceView:self.view];
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[_blueboxView,_redboxView]];
    CGVector vector = CGVectorMake(0.0, 1.0);
    [gravity setGravityDirection:vector];
    [_animator addBehavior:gravity];
    
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[_blueboxView,_redboxView]];
    collision.translatesReferenceBoundsIntoBoundary = YES;
    
    [_animator addBehavior:collision];
    
    UIDynamicItemBehavior *behavior = [[UIDynamicItemBehavior alloc] initWithItems:@[_blueboxView,_redboxView]];
    behavior.elasticity = 0.5;
    
    [_animator addBehavior:behavior];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *thetouch = [touches anyObject];
    
    UIOffset offset = UIOffsetMake(20, 20);
    
    _currentLocation = [thetouch locationInView:self.view];
    _attachment = [[UIAttachmentBehavior alloc]
                   initWithItem:_blueboxView
                   offsetFromCenter:offset attachedToAnchor:_currentLocation];

    [_animator addBehavior:_attachment];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *thetouch = [touches anyObject];
    
    _currentLocation = [thetouch locationInView:self.view];
    _attachment.anchorPoint = _currentLocation;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *thetouch = [touches anyObject];
    _currentLocation = [thetouch locationInView:self.view];

    [_animator removeBehavior:_attachment];
}

@end
