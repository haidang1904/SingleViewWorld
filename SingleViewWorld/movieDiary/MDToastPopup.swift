//
//  MDToastPopup.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 09/03/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import Foundation
import UIKit

class MDToastPopup: UIView {
    
    @IBOutlet weak var label: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
//        let objects = UINib.init(nibName: "MDToastPopup", bundle: Bundle.init(identifier: "com.hyodolski.moviediary")).instantiate(withOwner: nil, options: nil)
//        if (self) {
//            self.frame = frame
//            self.label = self.subviews.last as! UILabel!
//            self.label.layer.cornerRadius = 4.0
//        }
    }
    
    func setup(){
//        self.view = loadView()
//        view.frame = self.bounds
//        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
//        
//        addSubview(view)
    }
    
    func loadView() -> UIView{
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName:"PermissionView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func showToastPopup(message:String, onView containerView:UIView) {
        let popup : MDToastPopup
    }
}
/*
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
