//
//  MusicListTableViewCell.h
//  SingleViewWorld
//
//  Created by samsung on 9/1/15.
//  Copyright (c) 2015 samsung. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MusicListTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImage;
@property (weak, nonatomic) IBOutlet UILabel *titlelabel;
@property (weak, nonatomic) IBOutlet UILabel *artistlabel;
@property (weak, nonatomic) IBOutlet UILabel *genrelabel;

@end
