//
//  HomeViewController.m
//  SingleViewWorld
//
//  Created by samsung on 2015. 7. 21..
//  Copyright (c) 2015년 samsung. All rights reserved.
//

#import "HomeViewController.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "SingleViewWorld-Swift.h"

NSString *const kKeyMenuName = @"name";
NSString *const kKeyMenuString = @"string";

typedef enum{
    BLE_CENTRAL_MODE = 0,
    BLE_PERIPHERAL_MODE,
    PHOTOLIBRARY_MODE,
    GESTURE_MODE,
    UIKIT_DYNAMICS_MODE,
    AUDIO_PLAYER_MODE,
    UDP_SOCKET_MODE,
    LOCAL_NOTIFICATION_MODE,
    SDK_TEST_MODE,
    //SDK_PRIVATE_TEST_MODE,
    SPRITE_KIT_MODE,
    //CARD_GAME_MODE,
    URL_SCHEME_TEST,
    CANDY_CRUSH_GAME,
    VARIETY_TEST_MODE,
    MOVIE_DIARY,
    MENU_MAX,
}MAIN_MENU;

struct{
    int16_t test;
}a;

@interface HomeViewController () 

@end

@implementation HomeViewController

static NSString *cellID = @"MenuCollectionViewCell";

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.

    _arrMenu = @[
                 @{kKeyMenuName : [NSNumber numberWithInt:BLE_CENTRAL_MODE],      kKeyMenuString : @"BLE CENTRAL"},
                 @{kKeyMenuName : [NSNumber numberWithInt:BLE_PERIPHERAL_MODE],   kKeyMenuString : @"BLE PERIPHERAL"},
                 @{kKeyMenuName : [NSNumber numberWithInt:PHOTOLIBRARY_MODE],    kKeyMenuString : @"PHOTO LIBRARY"},
                 @{kKeyMenuName : [NSNumber numberWithInt:GESTURE_MODE],         kKeyMenuString : @"GESTURE RECOGNIZER"},
                 @{kKeyMenuName : [NSNumber numberWithInt:UIKIT_DYNAMICS_MODE],        kKeyMenuString : @"UIKIT DYNAMICS"},
                 @{kKeyMenuName : [NSNumber numberWithInt:AUDIO_PLAYER_MODE],     kKeyMenuString : @"AUDIO PLAYER"},
                 @{kKeyMenuName : [NSNumber numberWithInt:UDP_SOCKET_MODE],       kKeyMenuString : @"UDP SOCKET"},
                 @{kKeyMenuName : [NSNumber numberWithInt:LOCAL_NOTIFICATION_MODE],       kKeyMenuString : @"Local Notification"},
                 @{kKeyMenuName : [NSNumber numberWithInt:SDK_TEST_MODE],       kKeyMenuString : @"SmartViewSDK TEST"},
                 //@{kKeyMenuName : [NSNumber numberWithInt:SDK_PRIVATE_TEST_MODE],       kKeyMenuString : @"SmartViewSDK Private TEST"},
                 @{kKeyMenuName : [NSNumber numberWithInt:SPRITE_KIT_MODE],       kKeyMenuString : @"SpriteKit TEST"},
                 //@{kKeyMenuName : [NSNumber numberWithInt:CARD_GAME_MODE],       kKeyMenuString : @"CARD GAME"},
                 @{kKeyMenuName : [NSNumber numberWithInt:URL_SCHEME_TEST],       kKeyMenuString : @"go to SmartView App"},
                 @{kKeyMenuName : [NSNumber numberWithInt:CANDY_CRUSH_GAME],       kKeyMenuString : @"Candy Crush Game"},
                 @{kKeyMenuName : [NSNumber numberWithInt:VARIETY_TEST_MODE],       kKeyMenuString : @"Variety TEST"},
                 @{kKeyMenuName : [NSNumber numberWithInt:MOVIE_DIARY],       kKeyMenuString : @"Movie Diary"},
                 ];
    
    self.title = @"Module test";
    //self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"back" style:UIBarButtonItemStylePlain target:nil action:nil];

    // collection view init
    self.MenuView.scrollEnabled =YES;
    self.MenuView.delegate = self;
    self.MenuView.dataSource = self;
    self.MenuView.backgroundColor = [UIColor whiteColor];
    [self.MenuView registerNib:[UINib nibWithNibName:cellID bundle:nil] forCellWithReuseIdentifier:cellID];
    
    [self.btnChangeAP setTitle:[self currentWifiSSID] forState:UIControlStateNormal];
    
    self.btnReserved.enabled = YES;
    self.btnCameraApp.enabled = YES;
    self.btnChangeAP.enabled = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource

//-(void)
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _arrMenu.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    _cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    if (_cell == nil) {
        _cell = [[MenuCollectionViewCell alloc] init];
    }
    
    _cell.backgroundColor = [UIColor lightGrayColor];
    _cell.label.text = [self dispMenu:indexPath.row];
    
    //CALayer *mylayer = [_cell layer];
    //[mylayer setCornerRadius:10];
   
    return _cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectMenu:indexPath.row];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    CGSize cellsize = CGSizeMake(collectionView.frame.size.width * 0.3, collectionView.frame.size.height * 0.1);
    
    return cellsize;
    
}

#pragma mark - UIImagePickerControllerDelegate, UINavigationControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(nullable NSDictionary<NSString *,id> *)editingInfo NS_DEPRECATED_IOS(2_0, 3_0){

}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
   
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if([mediaType isEqualToString:(NSString *)kUTTypeImage]){
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        
        self.cameraView.image = image;
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:finishedSavingWithError:contextInfo:), nil);
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -

- (IBAction)ChangeAPBtn:(id)sender {
    
    #warning This is Private API
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=WIFI"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    SVLogTEST(@"ChangeAP mode Button Click event!!");
}
- (IBAction)CameraAppBtn:(id)sender {
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
        imagePicker.allowsEditing = NO;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}

- (IBAction)ReservedBtn:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    SVLogTEST(@"Reserved mode Button Click event!!");
}

//

- (void)selectMenu:(NSInteger)index
{
    UIViewController *function_view;
    UIStoryboard* sb;
    
    switch (index)
    {
        case BLE_CENTRAL_MODE:
            function_view = [[BLEViewController alloc] initWithNibName:@"BLEViewController" bundle:nil];
            break;
        case BLE_PERIPHERAL_MODE:
            function_view = [[BLEPeripheralViewController alloc] initWithNibName:@"BLEPeripheralViewController" bundle:nil];
            break;
        case PHOTOLIBRARY_MODE:
            function_view = [[PhotoListViewController alloc] initWithNibName:@"PhotoListViewController" bundle:nil];
            break;
        case GESTURE_MODE:
            function_view = [[RecognizerViewController alloc] initWithNibName:@"RecognizerViewController" bundle:nil];
            break;
        case UIKIT_DYNAMICS_MODE:
            function_view = [[DynamicsViewController alloc] init];
            break;
        case AUDIO_PLAYER_MODE:
            function_view = [[AudioPlayerViewController alloc] initWithNibName:@"AudioPlayerViewController" bundle:nil];
            break;
        case UDP_SOCKET_MODE:
            function_view = [[TextInputViewController alloc] initWithNibName:@"TextInputViewController" bundle:nil];
            break;
        case LOCAL_NOTIFICATION_MODE:
            function_view = [[LocalNotificationVC alloc] initWithNibName:@"LocalNotificationView" bundle:nil];
            break;
        case SDK_TEST_MODE:
            function_view = [[SDKTestViewController alloc] initWithNibName:@"SDKTestViewController" bundle:nil];
            break;
//        case SDK_PRIVATE_TEST_MODE:
//            function_view = [[SDKPriavteTestVC alloc] initWithNibName:@"SDKPrivateTestViewController" bundle:nil];
//            break;
        case SPRITE_KIT_MODE:
            sb = [UIStoryboard storyboardWithName:@"SpriteKit" bundle:nil];
            function_view = (SpriteKitVC *)[sb instantiateViewControllerWithIdentifier:@"SpriteKitVC"];
            //function_view = [Spri]
            break;
        //case CARD_GAME_MODE:
        //    sb = [UIStoryboard storyboardWithName:@"SpriteKit" bundle:nil];
        //    function_view = (SpriteKitVC *)[sb instantiateViewControllerWithIdentifier:@"SpriteKitVC"];
        //    break;
        case URL_SCHEME_TEST:
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"smartview2://"]]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"smartview2://"]];
            }
            break;
        case CANDY_CRUSH_GAME:
            function_view = [[CandyCrushVC alloc] initWithNibName:@"CandyCrushVC" bundle:nil];
            break;
        case VARIETY_TEST_MODE:
            function_view = [[VarietyTestVC alloc] initWithNibName:@"VarietyTestVC" bundle:nil];
            break;
        case MOVIE_DIARY:
            function_view = (movieDiaryBaseVC *) [[UIStoryboard storyboardWithName:@"movieDiarySB" bundle:nil] instantiateInitialViewController];
            break;
        default:
            break;
    }
    [self.navigationController pushViewController:function_view animated:NO];
}

-(NSString*)dispMenu:(NSInteger)index
{
    if(_arrMenu.count > index)
    {
        return [[self.arrMenu objectAtIndex:index] valueForKey:kKeyMenuString];
    }
    else
    {
        return @"NO DATA";
    }
}

- (NSString *)currentWifiSSID
{
    NSString *ssid = nil;
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    SVLogTEST(@"ifs - %@",ifs);
    
    if (ifs == nil) {
        return @"no AP";
    }
    
    for (NSString *ifnam in ifs)
    {
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        //NSData *data = [info objectForKey:(NSString *)kCNNetworkInfoKeySSIDData];
        //SVLogTEST(@"DATA - %@",data);
        //SVLogTEST(@"DATA string - %@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
        if (info[@"SSID"])
        {
            ssid = info[@"SSID"];
        }
        SVLogTEST(@"%@",info);
    }
    return ssid;
}

-(void)image:(UIImage *)image finishedSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    if(error){
        SVLogTEST(@"save failed");
    }
}
@end
