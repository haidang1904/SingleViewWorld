//
//  movieDiaryPopUpVC.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 09/03/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import UIKit

class movieDiaryPopUpVC: UIViewController {

    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


/*
 //
 //  SVToastPopup.m
 //  Samsung Companion App 2013
 //
 //  Created by Denis Melenevsky on 04/02/2014.
 //  In Samsung Ukraine R&D Center (SURC) under a contract between
 //  LLC "Samsung Electronics Ukraine Company" (Kiev Ukraine) and "Samsung Electronics Co", Ltd (Seuol, Republic of Korea)
 //  Copyright:   Samsung Electronics Co, Ltd 2013-2014. All rights reserved.
 //
 
 #import "SVToastPopup.h"
 
 @interface SVToastPopup ()
 @property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraintLabel;
 @property (nonatomic) UILabel *label;
 @end
 
 
 @implementation SVToastPopup
 
 - (id)initWithFrame:(CGRect)frame
 {
	NSArray *objects = [[UINib nibWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleWithIdentifier:@"com.samsung.SVCoreAPI"]] instantiateWithOwner:nil options:nil];
 self = [objects lastObject];
	if (self)
	{
 self.frame = frame;
 self.label = [self.subviews lastObject];
 self.label.layer.cornerRadius = 4.0;
	}
 return self;
 }
 
 + (void)showToastPopupWithMessage:(NSString *)message onView:(UIView *)containerView
 {
	SVToastPopup *popup = [[self alloc] initWithFrame:containerView.bounds];
	popup.label.text = message;
	[containerView addSubview:popup];
	
	double delayInSeconds = 2.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
	{
 [UIView animateWithDuration:1.0 animations:^{
 popup.alpha = 0.0;
 } completion:^(BOOL finished) {
 if (finished)
 {
 [popup removeFromSuperview];
 }
 }];
	});
 }
 
 + (void)showToastPopupForRCWithMessage:(NSString *)message onView:(UIView *)containerView
 {
 SVToastPopup *popup = [[self alloc] initWithFrame:containerView.bounds];
	popup.label.text = message;
 [popup.constraintLabel setConstant:containerView.frame.size.width];
	[containerView addSubview:popup];
	
	double delayInSeconds = 4.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
 {
 [UIView animateWithDuration:1.0 animations:^{
 popup.alpha = 0.0;
 } completion:^(BOOL finished) {
 if (finished)
 {
 [popup removeFromSuperview];
 }
 }];
 });
 }
 
 
 @end

 */
