//
//  ODSVersionViewController.m
//  OneDaySeries
//
//  Created by TaoXinle on 16/7/1.
//  Copyright © 2016年 cn.com.uzero. All rights reserved.
//

#import "ODSVersionViewController.h"
#import <MessageUI/MessageUI.h>
//#import "OSDWebViewController.h"
#import "sys/utsname.h"
#import <SafariServices/SafariServices.h>
#define NaviH  64.f

#define MyLocal(x, ...) NSLocalizedString(x, nil)

@interface ODSVersionViewController ()<MFMailComposeViewControllerDelegate>
{
//    UIImageView * bgImgV;
}
@end

@implementation ODSVersionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    
    self.title = MyLocal(@"feedback",ni);
    

    
    UIImageView *logImageView = [[UIImageView alloc] initWithFrame:CGRectMake((ODSScreenWidth-80)/2.0f,40+NaviH, 80, 80)];
    logImageView.image = [UIImage imageNamed:@"AppIcon60x60"];
    [self.view addSubview:logImageView];
    logImageView.layer.cornerRadius = 10;
    logImageView.layer.masksToBounds = YES;
    

    
    NSString *logStr = [NSString stringWithFormat:@"%@ %@",MyLocal(@"appname",nil),CurrentVersion];
    UILabel *logLable = [[UILabel alloc] initWithFrame:CGRectMake((ODSScreenWidth-160)/2.0f, 40+80+30+NaviH, 160, 30)];
    logLable.textColor = [UIColor lightGrayColor];
    logLable.font = [UIFont systemFontOfSize:17];
    logLable.backgroundColor = [UIColor clearColor];
    [logLable setTextAlignment:NSTextAlignmentCenter];
    logLable.text = logStr;
    [self.view addSubview:logLable];

    
    UIImageView *topMiddleImageView = [[UIImageView alloc] initWithFrame:CGRectMake((ODSScreenWidth-280)/2.0f,ODSScreenHeight - 290 +NaviH, 280, 1)];
    topMiddleImageView.backgroundColor = [UIColor colorWithRed:219/255.f green:219/255.f blue:219/255.f alpha:1];
//    topMiddleImageView.image = [UIImage imageNamed:@"secion_c_Line.png"];
    [self.view addSubview:topMiddleImageView];
    
    UIImageView *topBottomImageView = [[UIImageView alloc] initWithFrame:CGRectMake((ODSScreenWidth-280)/2.0f,ODSScreenHeight - 240 +NaviH, 280, 1)];
//    topBottomImageView.image = [UIImage imageNamed:@"secion_c_Line.png"];
    topBottomImageView.backgroundColor = [UIColor colorWithRed:219/255.f green:219/255.f blue:219/255.f alpha:1];
    [self.view addSubview:topBottomImageView];
    
    
    
    UILabel *phoneLable = [[UILabel alloc] initWithFrame:CGRectMake((ODSScreenWidth-280)/2.0f, ODSScreenHeight - 280+NaviH, 100, 30)];
    phoneLable.textColor = [UIColor lightGrayColor];
    phoneLable.font = [UIFont systemFontOfSize:15];
    phoneLable.backgroundColor = [UIColor clearColor];
    phoneLable.text = MyLocal(@"feedback",ni);
    [self.view addSubview:phoneLable];
    
    
    UIButton *phoneNumBtn = [[UIButton alloc] initWithFrame:CGRectMake(ODSScreenWidth-(ODSScreenWidth-280)/2.0f-180, ODSScreenHeight - 280+NaviH, 180, 30)];
    [phoneNumBtn setTitleColor:[UIColor colorWithRed:93/255.f green:159/255.f blue:60/255.f alpha:1] forState:UIControlStateNormal];
    phoneNumBtn.titleLabel.font= [UIFont systemFontOfSize:15];
    phoneNumBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    [phoneNumBtn setTitle:MyLocal(@"clickfeedback",ni) forState:UIControlStateNormal];
    [phoneNumBtn addTarget:self action:@selector(suggestionVC) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:phoneNumBtn];
    
    
//    UILabel *bottomLable = [[UILabel alloc] initWithFrame:CGRectMake((ODSScreenWidth-260)/2, ODSScreenHeight - 210, 260, 20)];
//    bottomLable.textColor = [UIColor lightGrayColor];
//    bottomLable.font = [UIFont systemFontOfSize:14];
//    bottomLable.backgroundColor = [UIColor clearColor];
//    bottomLable.textAlignment = NSTextAlignmentCenter;
//    bottomLable.text =[[NSString stringWithFormat:@"版权所有:%@",CurrentAPPName] s2tChinese];
//    [self.view addSubview:bottomLable];
    
    UIButton * kaiyuanBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [kaiyuanBtn setFrame:CGRectMake((ODSScreenWidth-260)/2, ODSScreenHeight - 210+NaviH, 260, 30)];
    [kaiyuanBtn setBackgroundColor:[UIColor clearColor]];
    [kaiyuanBtn.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [self.view addSubview:kaiyuanBtn];
    [kaiyuanBtn setTitle:MyLocal(@"opensource",nil) forState:UIControlStateNormal];
    [kaiyuanBtn setTitleColor:[UIColor colorWithRed:0.027 green:0.58 blue:0.757 alpha:0.8] forState:UIControlStateNormal];
    [kaiyuanBtn addTarget:self action:@selector(toKaiyuanPage) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton * adBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [adBtn setFrame:CGRectMake((ODSScreenWidth-260)/2, ODSScreenHeight - 150+NaviH, 260, 30)];
    [adBtn setBackgroundColor:[UIColor colorWithRed:0.027 green:0.58 blue:0.757 alpha:0.8]];
    [adBtn.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [self.view addSubview:adBtn];
    adBtn.layer.cornerRadius = 5;
    adBtn.layer.masksToBounds = YES;
    [adBtn setTitle:MyLocal(@"followweibo",nil) forState:UIControlStateNormal];
    [adBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [adBtn addTarget:self action:@selector(focusAuthorWeibo) forControlEvents:UIControlEventTouchUpInside];

    // Do any additional setup after loading the view.
}

-(void)toAuthorPage
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9) {
        SFSafariViewController * sv = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"http://weibo.com/u/1860159237"]];
        //        sv.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        [self presentViewController:sv animated:YES completion:^{
            
        }];
    }
}


-(void)focusAuthorWeibo
{
    NSURL * url = [NSURL URLWithString:@"weibo://userinfo?uid=1860159237"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
    else
    {
        [self toAuthorPage];
    }
}


-(void)suggestionVC
{
//    OSDWebViewController *webVC = [[OSDWebViewController alloc] init];
//    webVC.title = @"意见反馈";
//    webVC.urlStr = @"http://form.mikecrm.com/atdxdE";
//    webVC.hidesBottomBarWhenPushed = YES;
//    [self.navigationController pushViewController:webVC animated:YES];
    
    [self mailClick];
}

- (void)mailClick
{

    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    
    if (mailClass != nil)
    {
        if ([mailClass canSendMail])
        {
            [self displayComposerSheet];
        }
        else
        {
            [self launchMailAppOnDevice];
        }
    }
    else
    {
        [self launchMailAppOnDevice];
    }
    
    
}

//可以发送邮件的话
-(void)displayComposerSheet
{
    MFMailComposeViewController *mailPicker = [[MFMailComposeViewController alloc] init];
    
    mailPicker.mailComposeDelegate = self;
    
    //设置主题
    [mailPicker setSubject: @"意见反馈"];
    
    // 添加发送者
    NSArray *toRecipients = [NSArray arrayWithObject: ContactMail];
    //NSArray *ccRecipients = [NSArray arrayWithObjects:@"second@example.com", @"third@example.com", nil];
    //NSArray *bccRecipients = [NSArray arrayWithObject:@"fourth@example.com", nil];
    [mailPicker setToRecipients: toRecipients];
    //[picker setCcRecipients:ccRecipients];
    //[picker setBccRecipients:bccRecipients];
    
    // 添加图片
    
    NSString * sysv = [UIDevice currentDevice].systemVersion;
    NSString * sysVersion = [NSString stringWithFormat:@"iOS %@",sysv];
    
    NSString * deviceModel = [self deviceVersion];
    
    NSString *emailBody = [NSString stringWithFormat:@"\n\n\n系统版本：%@\n手机型号：%@\nAPP版本号：%@\n",sysVersion,deviceModel,CurrentVersion];
    [mailPicker setMessageBody:emailBody isHTML:NO];
    
    [self presentViewController:mailPicker animated:YES completion:^{
        
    }];
}
-(void)launchMailAppOnDevice
{
    NSString *recipients = [NSString stringWithFormat:@"mailto:%@",ContactMail];

    
    NSString *email = [NSString stringWithFormat:@"%@", recipients];
    email = [email stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString:email]];
    
}
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    //    NSString *msg;
    
    switch (result)
    {
        case MFMailComposeResultCancelled:
        {
            [controller dismissViewControllerAnimated:YES completion:^{
                //                [hud hide:YES];
                //                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
            break;
        case MFMailComposeResultSaved:
        {
            [controller dismissViewControllerAnimated:YES completion:^{
                //                [hud hide:YES];
                //                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
            break;
        case MFMailComposeResultSent:
        {
            [controller dismissViewControllerAnimated:YES completion:^{
                //                [hud hide:YES];
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
            break;
        case MFMailComposeResultFailed:
        {
            [controller dismissViewControllerAnimated:YES completion:^{
                //                [hud hide:YES];
                //                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
            break;
        default:
            break;
    }
    
    //    [controller dismissViewControllerAnimated:YES completion:^{
    //        [hud hide:YES];
    //        [self.navigationController popViewControllerAnimated:YES];
    //    }];
}

-(void)toKaiyuanPage
{
//    OSDWebViewController *webVC = [[OSDWebViewController alloc] init];
//    webVC.urlStr = @"http://uzero.cn/ipoem/ios_opensource.html";
//    [self.navigationController pushViewController:webVC animated:YES];
    
    NSString * searchStr = @"http://xinle.co/2017/07/12/baimiaoopensource/";
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9) {
        SFSafariViewController * sv = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:searchStr]];
        //        sv.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        [self presentViewController:sv animated:YES completion:^{
            
        }];
    }

}


- (NSString*)deviceVersion
{
    // 需要#import "sys/utsname.h"
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    //iPhone
    
    if ([deviceString isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([deviceString isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([deviceString isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([deviceString isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([deviceString isEqualToString:@"iPhone3,2"])    return @"Verizon iPhone 4";
    if ([deviceString isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([deviceString isEqualToString:@"iPhone5,1"])    return @"iPhone 5";
    if ([deviceString isEqualToString:@"iPhone5,2"])    return @"iPhone 5";
    if ([deviceString isEqualToString:@"iPhone5,3"])    return @"iPhone 5C";
    if ([deviceString isEqualToString:@"iPhone5,4"])    return @"iPhone 5C";
    if ([deviceString isEqualToString:@"iPhone6,1"])    return @"iPhone 5S";
    if ([deviceString isEqualToString:@"iPhone6,2"])    return @"iPhone 5S";
    if ([deviceString isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([deviceString isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([deviceString isEqualToString:@"iPhone8,1"])    return @"iPhone 6s";
    if ([deviceString isEqualToString:@"iPhone8,2"])    return @"iPhone 6s Plus";
    if ([deviceString isEqualToString:@"iPhone8,4"])    return @"iPhone SE";
    if ([deviceString isEqualToString:@"iPhone9,1"])    return @"iPhone 7";
    if ([deviceString isEqualToString:@"iPhone9,3"])    return @"iPhone 7";
    if ([deviceString isEqualToString:@"iPhone9,2"])    return @"iPhone 7 Plus";
    if ([deviceString isEqualToString:@"iPhone9,4"])    return @"iPhone 7 Plus";
    
    //iPod
    
    if ([deviceString isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([deviceString isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([deviceString isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([deviceString isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([deviceString isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([deviceString isEqualToString:@"iPod7,1"])      return @"iPod Touch 6G";
    
    //iPad
    
    if ([deviceString isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([deviceString isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([deviceString isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([deviceString isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([deviceString isEqualToString:@"iPad2,4"])      return @"iPad 2 (32nm)";
    if ([deviceString isEqualToString:@"iPad2,5"])      return @"iPad mini (WiFi)";
    if ([deviceString isEqualToString:@"iPad2,6"])      return @"iPad mini (GSM)";
    if ([deviceString isEqualToString:@"iPad2,7"])      return @"iPad mini (CDMA)";
    if ([deviceString isEqualToString:@"iPad4,4"])      return @"iPad mini 2";
    if ([deviceString isEqualToString:@"iPad4,5"])      return @"iPad mini 2";
    if ([deviceString isEqualToString:@"iPad4,6"])      return @"iPad mini 2";
    if ([deviceString isEqualToString:@"iPad4,7"])      return @"iPad mini 3";
    if ([deviceString isEqualToString:@"iPad4,8"])      return @"iPad mini 3";
    if ([deviceString isEqualToString:@"iPad4,9"])      return @"iPad mini 3";
    if ([deviceString isEqualToString:@"iPad5,1"])      return @"iPad mini 4";
    if ([deviceString isEqualToString:@"iPad5,2"])      return @"iPad mini 4";
    if ([deviceString isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([deviceString isEqualToString:@"iPad3,2"])      return @"iPad 3 (CDMA)";
    if ([deviceString isEqualToString:@"iPad3,3"])      return @"iPad 3 (4G)";
    if ([deviceString isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([deviceString isEqualToString:@"iPad3,5"])      return @"iPad 4 (4G)";
    if ([deviceString isEqualToString:@"iPad3,6"])      return @"iPad 4 (CDMA)";
    if ([deviceString isEqualToString:@"iPad4,1"])      return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad4,2"])      return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad4,3"])      return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad5,3"])      return @"iPad Air 2";
    if ([deviceString isEqualToString:@"iPad5,4"])      return @"iPad Air 2";
    if ([deviceString isEqualToString:@"iPad6,7"])      return @"iPad Pro (12.9 inch)";
    if ([deviceString isEqualToString:@"iPad6,8"])      return @"iPad Pro (12.9 inch)";
    if ([deviceString isEqualToString:@"iPad6,3"])      return @"iPad Pro (9.7 inch)";
    if ([deviceString isEqualToString:@"iPad6,4"])      return @"iPad Pro (9.7 inch)";
    
    //Simulator
    
    if ([deviceString isEqualToString:@"i386"])         return @"Simulator";
    if ([deviceString isEqualToString:@"x86_64"])       return @"Simulator";
    
    return deviceString;
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

@end
