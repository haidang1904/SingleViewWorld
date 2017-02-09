//
//  HomeViewController.h
//  SingleViewWorld
//
//  Created by samsung on 2015. 7. 21..
//  Copyright (c) 2015년 samsung. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEViewController.h"
#import "BLEPeripheralViewController.h"
#import "PhotoListViewController.h"
#import "MenuCollectionViewCell.h"
#import "RecognizerViewController.h"
#import "DynamicsViewController.h"
#import "AudioPlayerViewController.h"
#import "TextInputViewController.h"

@import SmartView;

@interface HomeViewController : UIViewController <UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnChangeAP;
@property (weak, nonatomic) IBOutlet UIButton *btnCameraApp;
@property (weak, nonatomic) IBOutlet UIButton *btnReserved;

@property (weak, nonatomic) IBOutlet UICollectionView *MenuView;
@property (weak, nonatomic) IBOutlet UIImageView *cameraView;
@property (strong,nonatomic) MenuCollectionViewCell *cell;

@property (strong, nonatomic) NSArray *arrMenu;
@property (strong, nonatomic) NSArray *arrMenuString;


- (IBAction)ChangeAPBtn:(id)sender;
- (IBAction)CameraAppBtn:(id)sender;
- (IBAction)ReservedBtn:(id)sender;

@end
