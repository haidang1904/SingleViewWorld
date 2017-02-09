//
//  AudioPlayerViewController.h
//  SingleViewWorld
//
//  Created by samsung on 8/31/15.
//  Copyright (c) 2015 samsung. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MusicListTableViewCell.h"
#import "JPSVolumeButtonHandler.h"

@interface AudioPlayerViewController : UIViewController <AVAudioPlayerDelegate,UITableViewDataSource, UITableViewDelegate>

@property (strong,nonatomic) AVAudioPlayer *audioplayer;
@property (weak, nonatomic) IBOutlet UIButton *btnPlay;
@property (weak, nonatomic) IBOutlet UIButton *btnPrev;
@property (weak, nonatomic) IBOutlet UIButton *btnNext;
@property (weak, nonatomic) IBOutlet UISlider *audioSlider;
@property (weak, nonatomic) IBOutlet UITableView *musiclist;
@property (strong,nonatomic) MusicListTableViewCell *cell;
@property (weak, nonatomic) IBOutlet UIProgressView *musicprogress;
@property (weak, nonatomic) IBOutlet UILabel *durationlabel;
@property (weak, nonatomic) IBOutlet UILabel *currlabel;

- (IBAction)prevBtn:(id)sender;
- (IBAction)playBtn:(id)sender;
- (IBAction)nextBtn:(id)sender;
- (IBAction)progressSlider:(id)sender;
- (void)volumeChanged:(NSNotification *) notif;

@end
