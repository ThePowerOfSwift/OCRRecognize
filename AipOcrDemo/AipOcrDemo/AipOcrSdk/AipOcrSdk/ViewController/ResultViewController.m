//
//  ResultViewController.m
//  AipOcrSdk
//
//  Created by Tolecen on 2017/6/17.
//  Copyright © 2017年 baidu. All rights reserved.
//

#import "ResultViewController.h"
#import "SVProgressHUD.h"
@interface ResultViewController ()<UIActionSheetDelegate>
@property (nonatomic,strong)UITextView * textV;
@end

@implementation ResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"识别结果";
    
    UIButton *syncBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    [syncBtn setImage:[UIImage imageNamed:@"copyText.png"] forState:UIControlStateNormal];
    [syncBtn setTitle:@"复制" forState:UIControlStateNormal];
    [syncBtn setTitleColor:[UIColor colorWithRed:0 green:122/255.f blue:1 alpha:1] forState:UIControlStateNormal];
    [syncBtn sizeToFit];
    syncBtn.frame = CGRectMake(0, 0, CGRectGetWidth(syncBtn.frame), CGRectGetHeight(syncBtn.frame));
//    [syncBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [syncBtn addTarget:self action:@selector(copyText) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:syncBtn];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;

    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITextView * textV = [[UITextView alloc] initWithFrame:CGRectMake(15, 15, self.view.frame.size.width-30, self.view.frame.size.height-30)];
    textV.backgroundColor = [UIColor clearColor];
    textV.font = [UIFont systemFontOfSize:18];
//    textV.editable = NO;
    textV.textColor = [UIColor colorWithRed:50/255.f green:50/255.f blue:50/255.f alpha:1];
    [self.view addSubview:textV];
    self.textV = textV;
    
//    textV.text = _resultStr;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 8;// 字体的行间距
    NSDictionary *attributes = @{
                                 NSFontAttributeName:[UIFont systemFontOfSize:18],
                                 NSParagraphStyleAttributeName:paragraphStyle
                                 };
    
    textV.attributedText = [[NSAttributedString alloc] initWithString:_resultStr attributes:attributes];
    // Do any additional setup after loading the view.
}

-(void)copyText
{
    UIPasteboard*pasteboard = [UIPasteboard generalPasteboard];
    
    pasteboard.string=self.textV.text;
    
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD showSuccessWithStatus:@"复制成功"];
    
    [self showMoreAction];
}

-(void)showMoreAction
{

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"分享到" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"有道云笔记",nil];
    [actionSheet showInView:self.view];
    
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==0) {
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"youdaonote://"]]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"youdaonote://"]];
        }
        else
        {
            [SVProgressHUD showErrorWithStatus:@"未安装有道云笔记"];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = YES;
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