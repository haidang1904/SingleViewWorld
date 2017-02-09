//
//  RecognizerViewController.m
//  SingleViewWorld
//
//  Created by samsung on 8/28/15.
//  Copyright (c) 2015 samsung. All rights reserved.
//

#import "RecognizerViewController.h"

@interface RecognizerViewController ()

@end

@implementation RecognizerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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

- (IBAction)rotationDetacted:(UIGestureRecognizer *)sender {
    CGFloat radian = [(UIRotationGestureRecognizer *)sender rotation];
    CGFloat velocity = [(UIRotationGestureRecognizer *)sender velocity];
    
    NSString *result = [[NSString alloc]initWithFormat:@"rotationDetacted radian %f / velocity %f",radian,velocity];
    
    _label.text = result;
    SVLogTEST(@"%@",result);
}

- (IBAction)pinchDetacted:(UIGestureRecognizer *)sender {
    CGFloat scale = [(UIPinchGestureRecognizer *)sender scale];
    CGFloat velocity = [(UIPinchGestureRecognizer *)sender velocity];
    
    NSString *result = [[NSString alloc]initWithFormat:@"pinchDetacted scale %f / velocity %f",scale,velocity];
    
    _label.text = result;
    SVLogTEST(@"%@",result);
}

- (IBAction)swipeDetacted:(UIGestureRecognizer *)sender {
    _label.text = @"swipeDetacted";
    SVLogTEST(@"swipeDetacted");
}

- (IBAction)longpressDetacted:(UIGestureRecognizer *)sender {
    _label.text = @"longpressDetacted";
    SVLogTEST(@"longpressDetacted");
}

- (IBAction)tabDetacted:(UIGestureRecognizer *)sender {
    _label.text = @"tabDetacted";
    SVLogTEST(@"tabDetacted");
}
@end
