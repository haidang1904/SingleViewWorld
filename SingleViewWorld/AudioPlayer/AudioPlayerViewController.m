//
//  AudioPlayerViewController.m
//  SingleViewWorld
//
//  Created by samsung on 8/31/15.
//  Copyright (c) 2015 samsung. All rights reserved.
//

#import "AudioPlayerViewController.h"
#import <Foundation/Foundation.h>
#import <MediaPlayer/MPVolumeView.h>

@interface AudioPlayerViewController ()
{
    BOOL isState;
    NSMutableArray *musicItems;
    NSInteger current_idx;
    NSTimer *timer;
    JPSVolumeButtonHandler *volumeHandler;
}
@end

@implementation AudioPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    musicItems = [NSMutableArray array];
    
    //AudioSessionInitialize(NULL, NULL, NULL, NULL);
    //AudioSessionSetActive(true);

    [self loadMusic];
    
    self.musiclist.scrollEnabled =YES;
    self.musiclist.delegate = self;
    self.musiclist.dataSource = self;
    self.musiclist.rowHeight = 100;
    
    [self.musiclist registerNib:[UINib nibWithNibName:@"MusicListTableViewCell" bundle:nil]  forCellReuseIdentifier:@"MusicListTableViewCell"];
    
    //[self initializeVolumeButtonStealer];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    //MPVolumeView *volume = [[MPVolumeView alloc] initWithFrame:CGRectMake(30, 30, 80, 80)];
    //[self.view addSubview:volume];
    
    [self setVolumeButtonListener];
    
}

-(void) setVolumeButtonListener {
    volumeHandler = [JPSVolumeButtonHandler volumeButtonHandlerWithUpBlock:^{
        SVLogTEST(@"UP");
    } downBlock:^{
        SVLogTEST(@"DOWN");
    }];
}


- (void)viewWillDisappear:(BOOL)animated{
    [timer invalidate];
}

//-(void)initializeVolumeButtonStealer
//{
//    Float32 deviceVolume;
//    AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume, volumeListenerCallback, &deviceVolume);
//}

void volumeListenerCallback (
                             void                      *inClientData,
                             AudioSessionPropertyID    inID,
                             UInt32                    inDataSize,
                             const void                *inData
                             ){
    const float *volumePointer = inData;
    float volume = *volumePointer;
    SVLogTEST(@"%f",volume);
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)volumeChanged:(NSNotification *) notif{
    SVLogTEST(@"test - %f",[[[notif userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue]);
}

-(void)updatetime
{
    NSTimeInterval curTime = _audioplayer.currentTime;
    NSTimeInterval duration = _audioplayer.duration;
    SVLogTEST(@"progress value : %f",_musicprogress.progress);
    [_musicprogress setProgress:(curTime/duration)];
    _currlabel.text = [self timetostring:curTime];
}

-(NSString *)timetostring:(NSTimeInterval)time
{
    if(((int)time%60) < 10)
    {
        return [NSString stringWithFormat:@"%d:0%d",(int)(time/60),((int)time%60)];
    }
    else
    {
        return [NSString stringWithFormat:@"%d:%d",(int)(time/60),((int)time%60)];
    }
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)loadMusic
{
    SVLogTEST(@"Loading music...");
    
    MPMediaQuery *query = [MPMediaQuery songsQuery];
    
    [query.items enumerateObjectsUsingBlock:^(MPMediaItem *item, NSUInteger idx, BOOL *stop)
     {
         if (item != nil && item.assetURL != nil)
         {
             SVLogTEST(@"%@",item.assetURL);
             SVLogTEST(@"%@",[item.assetURL absoluteString]);
             [musicItems addObject:item];
         }
     }];
    
    if (musicItems.count >0) {
        [self.musiclist reloadData];
    }
}



- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [_btnPlay setTitle:@"PLAY" forState:UIControlStateNormal];
    SVLogTEST(@"auto next music");
    [timer invalidate];
    [self playnextmusic];
}
/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
}

- (IBAction)prevBtn:(id)sender {
    if(current_idx == 0)
    {
        SVLogTEST(@"first music");
        current_idx = musicItems.count-1;
    }
    else
    {
        SVLogTEST(@"prev music");
        current_idx--;
    }
    [self playmusic];
}

- (IBAction)playBtn:(id)sender {
    
    if(_audioplayer == nil)
    {
        [self playmusic];
        [_btnPlay setTitle:@"PAUSE" forState:UIControlStateNormal];
        return;
    }
    if([_audioplayer isPlaying])
    {
        [_audioplayer pause];
        [_btnPlay setTitle:@"PLAY" forState:UIControlStateNormal];
    }else{
        [_audioplayer play];
        [_btnPlay setTitle:@"PAUSE" forState:UIControlStateNormal];
    }
}

- (IBAction)nextBtn:(id)sender {
    
    SVLogTEST(@"button next music");
    [self playnextmusic];
}

- (IBAction)progressSlider:(id)sender {

    [_audioplayer setVolume:_audioSlider.value];
    SVLogTEST(@"value : %f",_audioSlider.value);
}

-(void) playmusic
{
    MPMediaItem *item;
    item = musicItems[current_idx];
    
    _audioplayer = [[AVAudioPlayer alloc] initWithContentsOfURL:item.assetURL error:nil];
    _audioplayer.delegate = self;
    if([_audioplayer prepareToPlay])
    {
        if([_audioplayer play])
        {
            SVLogTEST(@"Play");
            [_btnPlay setTitle:@"PAUSE" forState:UIControlStateNormal];
            _durationlabel.text = [self timetostring:_audioplayer.duration];
        }
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updatetime) userInfo:nil repeats:YES];
    
    [self.musiclist selectRowAtIndexPath:[NSIndexPath indexPathForRow:current_idx inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
}

-(void) playnextmusic
{
    if(current_idx == (musicItems.count-1))
    {
        SVLogTEST(@"last music");
        current_idx = 0;
    }
    else
    {
        SVLogTEST(@"next music");
        current_idx++;
    }
    [timer invalidate];
    [self playmusic];
}

#pragma mark -
#pragma mark TableView Delegates
/****************************************************************************/
/*                          TableView Delegates                             */
/****************************************************************************/
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"MusicListTableViewCell";
    
    _cell = [self.musiclist dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];

    MPMediaItem *item;
    item = musicItems[indexPath.row];
    
    if(item.artwork != nil){
        _cell.thumbnailImage.image = [item.artwork imageWithSize:_cell.thumbnailImage.frame.size];
    }else{
        _cell.thumbnailImage.image = [UIImage imageNamed:@"ok_image"];
    }
    
    SVLogTEST(@"%@",indexPath);
    _cell.titlelabel.text = [NSString stringWithFormat:@"Title-%@",item.title];
    _cell.artistlabel.text = [NSString stringWithFormat:@"Artist-%@",item.artist];
    _cell.genrelabel.text = [NSString stringWithFormat:@"Genre-%@",item.genre];

    return _cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return musicItems.count;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    current_idx = indexPath.row;
    
    [self playmusic];
}
@end
