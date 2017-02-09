//
//  PhotoListViewController.h
//  SingleViewWorld
//
//  Created by samsung on 8/26/15.
//  Copyright (c) 2015 samsung. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoListViewCell.h"

@interface PhotoListViewController : UIViewController <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>

@property (strong,nonatomic) PhotoListViewCell *cell;
@property (weak, nonatomic) IBOutlet UICollectionView *PhotoListCollectionView;

@end
