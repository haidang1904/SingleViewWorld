//
//  JsonParserViewController.m
//  SingleViewWorld
//
//  Created by samsung on 2016. 5. 4..
//  Copyright © 2016년 samsung. All rights reserved.
//

#import "JsonParserViewController.h"

@import UserNotifications;

@interface JsonParserViewController ()
{
    NSTimer *timer;
}
@end

@implementation JsonParserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _timeLabel.text = @"";
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(printCurrentTime) userInfo:nil repeats:YES];
    //self.getBtn.titleLabel.font.labelFontSize
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [timer invalidate];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)printCurrentTime {
    NSDate *now = [NSDate date];
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    dateformatter.dateFormat = @"YYYY년MM월dd일-hh:mm:ss";
    [dateformatter setTimeZone:[NSTimeZone systemTimeZone]];
    SVLogTEST(@"Current Time is %@",[dateformatter stringFromDate:now]);
    _timeLabel.text = [dateformatter stringFromDate:now];
}

- (IBAction)getBtnAction:(id)sender {
    
    /*
    NSString *uri = [NSString stringWithFormat:@"http://192.168.0.253:8001/api/v2/"];
    uri = [uri stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:uri];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    NSError *error;
    
    NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&error];
    if(error)
    {
        SVLogTEST(@"data error:%@",error.localizedDescription);
    }
    else
    {
        NSDictionary *dic;
        dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
        if(error)
        {
        }
        else
        {
            SVLogTEST(@"dic : %@",[[dic objectForKey:@"device"] objectForKey:@"wifiMac"]);
        }
    }
     */
    
    
    NSDate *alert = [[NSDate date] dateByAddingTimeInterval:10];
    
    UIUserNotificationSettings *settings = [[UIUserNotificationSettings alloc] init];
    UILocalNotification *noti = [[UILocalNotification alloc] init];
    if(noti)
    {
        
        noti.fireDate = alert;
        noti.timeZone = [NSTimeZone systemTimeZone];
        noti.repeatInterval = 0;
        noti.alertBody = @"10 Seconds later";
        noti.alertAction = @"GOGO";
        [[UIApplication sharedApplication] scheduleLocalNotification:noti];
    }
}
@end
