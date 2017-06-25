//
//  ActionViewController.m
//  PhotoInAlbumOCR
//
//  Created by Tolecen on 2017/6/21.
//  Copyright © 2017年 Baidu. All rights reserved.
//

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/runtime.h>
#import "AipCutImageEXView.h"
#import "AipImageEXView.h"
#import "SVProgressHUD.h"
#import "AipOcrService.h"
#import <AipBase/AipBase.h>

#define MyLocal(x, ...) NSLocalizedString(x, nil)

#define V_X(v)      v.frame.origin.x
#define V_Y(v)      v.frame.origin.y
#define V_H(v)      v.frame.size.height
#define V_W(v)      v.frame.size.width


@interface ActionViewController ()<AipCutImageEXDelegate>
{
    CGFloat originBottomConstant;
    CGFloat originBottomToolBarContstant;
    AipOcrManager *_aipOcrManager;
}

@property(strong,nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet AipCutImageEXView *cutImageView;
@property (weak, nonatomic) IBOutlet AipImageEXView *maskImageView;
@property (weak, nonatomic) IBOutlet UIView *topWhite;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightItem;
@property (weak, nonatomic) IBOutlet UIView *successView;
@property (weak, nonatomic) IBOutlet UILabel *successLabel;

@property (nonatomic,strong)UIView * loadingView;
@property (nonatomic,strong)UIActivityIndicatorView * indicator;

@property (weak, nonatomic) IBOutlet UITextView *textv;
@property (weak, nonatomic) IBOutlet UIView *bottomView;

@property (assign, nonatomic) UIDeviceOrientation curDeviceOrientation;
@property (assign, nonatomic) UIDeviceOrientation imageDeviceOrientation;
@property (assign, nonatomic) UIImageOrientation imageOrientation;
@property (assign, nonatomic) CGSize size;

@property (assign,nonatomic)float finalImgWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textbottomCons;
@property (weak, nonatomic) IBOutlet UIView *toolBarView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomToolbarConstant;



@end

@implementation ActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _aipOcrManager = [[AipOcrManager alloc] initWithAK:@"SenZ7A8G8LfUfALOScIDtnPP" andSK:@"iOsmqKm7GUVKE0tf56M58wzFCM9W8CrZ"];
    

    
//    [self prefersStatusBarHidden];
    
    self.title = @"框选要识别的部分";
    
    
    
    self.view.backgroundColor = [UIColor blackColor];
    
    self.view.frame = [[UIScreen mainScreen] bounds];
    
    self.textv.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
    self.textv.hidden = YES;
//    self.topWhite.hidden = YES;
    
    [self setUpMaskImageView];
    //delegate 用做传递手势事件
    self.maskImageView.delegate = self.cutImageView;
    self.cutImageView.imgDelegate = self;
    
    self.imageDeviceOrientation = UIDeviceOrientationPortrait;

    
    // Get the item[s] we're handling from the extension context.
    
    // For example, look for an image and place it into an image view.
    // Replace this with something appropriate for the type[s] your extension supports.
    BOOL imageFound = NO;
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                // This is an image. We'll load it, then place it in our image view.
//                __weak UIImageView *imageView = self.imageView;
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(UIImage *image, NSError *error) {
                    if(image) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                            [imageView setImage:image];
                            [self setupCutImageView:image fromPhotoLib:YES];
                        }];
                    }
                }];
                
                imageFound = YES;
                break;
            }
        }
        
        if (imageFound) {
            // We only handle one image, so stop looking for more.
            break;
        }
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(keyboardWasShow:)
                                                name:UIKeyboardDidShowNotification
                                              object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(keyboardWillBeHidden:)
                                                name:UIKeyboardWillHideNotification
                                              object:nil];
    
    originBottomConstant = _textbottomCons.constant;
    originBottomToolBarContstant = _bottomToolbarConstant.constant;
}



- (IBAction)doneBtnClicked:(UIButton *)sender {
    [self.textv resignFirstResponder];
}


- (void)keyboardWasShow:(NSNotification *)notification {
    // 取得键盘的frame，注意，因为键盘在window的层面弹出来的，所以它的frame坐标也是对应window窗口的。

    
    NSValue* aValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    NSNumber *durationValue = [notification userInfo][UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration = durationValue.doubleValue;
    
    _toolBarView.hidden = NO;
    
    [UIView animateWithDuration:animationDuration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _textbottomCons.constant = (keyboardRect.size.height+40);//修改距离底部的约束
        _bottomToolbarConstant.constant = keyboardRect.size.height;
    } completion:^(BOOL finished) {
    }];
    [self.view setNeedsLayout]; //更新视图
    [self.view layoutIfNeeded];
}

- (void)keyboardWillBeHidden:(NSNotification *)notification{
    // 恢复原理的大小
    _toolBarView.hidden = YES;
    _bottomToolbarConstant.constant = originBottomToolBarContstant;
    _textbottomCons.constant = originBottomConstant;
    [self.view setNeedsLayout]; //更新视图
    [self.view layoutIfNeeded];
}



- (void)setUpMaskImageView {
    
    self.maskImageView.showMidLines = YES;
    self.maskImageView.needScaleCrop = YES;
    self.maskImageView.showCrossLines = YES;
    self.maskImageView.cropAreaCornerWidth = 30;
    self.maskImageView.cropAreaCornerHeight = 30;
    self.maskImageView.minSpace = 30;
    self.maskImageView.cropAreaCornerLineColor = [UIColor colorWithWhite:1 alpha:1];
    self.maskImageView.cropAreaBorderLineColor = [UIColor colorWithWhite:1 alpha:0.7];
    self.maskImageView.cropAreaCornerLineWidth = 3;
    self.maskImageView.cropAreaBorderLineWidth = 1;
    self.maskImageView.cropAreaMidLineWidth = 30;
    self.maskImageView.cropAreaMidLineHeight = 1;
    self.maskImageView.cropAreaCrossLineColor = [UIColor colorWithWhite:1 alpha:0.5];
    self.maskImageView.cropAreaCrossLineWidth = 1;
    self.maskImageView.cropAspectRatio = 662/1010.0;
    
}

//设置背景图
- (void)setupCutImageView:(UIImage *)image fromPhotoLib:(BOOL)isFromLib {
    
    if (isFromLib) {
        
        self.cutImageView.userInteractionEnabled = YES;
        
    }else{
        
        self.cutImageView.userInteractionEnabled = NO;
        
    }
    
    [self.cutImageView setBGImage:image fromPhotoLib:isFromLib useGestureRecognizer:NO];
    self.cutImageView.hidden = NO;
    self.maskImageView.hidden = NO;
    
}
- (IBAction)transferClicked:(UIButton *)sender {
    //向右转90'
    self.cutImageView.bgImageView.transform = CGAffineTransformRotate (self.cutImageView.bgImageView.transform, M_PI_2);
    if (self.imageOrientation == UIImageOrientationUp) {
        
        self.imageOrientation = UIImageOrientationRight;
    }else if (self.imageOrientation == UIImageOrientationRight){
        
        self.imageOrientation = UIImageOrientationDown;
    }else if (self.imageOrientation == UIImageOrientationDown){
        
        self.imageOrientation = UIImageOrientationLeft;
    }else{
        
        self.imageOrientation = UIImageOrientationUp;
    }
}
-(void)addLoadingView
{
    self.loadingView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width-80)/2, (self.view.frame.size.height-80)/2, 80, 80)];
    self.loadingView.backgroundColor = [UIColor blackColor];
    self.loadingView.alpha = 0.7;
    self.loadingView.layer.cornerRadius = 5;
    self.loadingView.layer.masksToBounds = YES;
    [self.view addSubview:self.loadingView];
    
    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.indicator.center = self.loadingView.center;
    [self.view addSubview:self.indicator];
    [self.indicator startAnimating];
    
}
- (IBAction)copyText:(UIBarButtonItem *)sender {
    UIPasteboard*pasteboard = [UIPasteboard generalPasteboard];
    
    pasteboard.string=self.textv.text;
    
    self.successView.hidden = NO;
    self.successLabel.hidden = NO;
    [self performSelector:@selector(hideSuccessView) withObject:nil afterDelay:2];
    
}

-(void)hideSuccessView
{
    self.successView.hidden = YES;
    self.successLabel.hidden = YES;
}
- (IBAction)pressOkBtn:(UIButton *)sender {
    
    [self addLoadingView];
    
    CGRect rect  = [self TransformTheRect];
    
    UIImage *cutImage = [self.cutImageView cutImageFromView:self.cutImageView.bgImageView withSize:self.size atFrame:rect];
    
    UIImage *image = [self rotateImageEx:cutImage.CGImage byDeviceOrientation:self.imageDeviceOrientation];
    
    UIImage *finalImage = [self rotateImageEx:image.CGImage orientation:self.imageOrientation];
    
    
    NSLog(@"finalImageWidth:%f",finalImage.size.width);
    
    self.finalImgWidth = finalImage.size.width;
    
    NSDictionary *options = @{@"language_type": @"CHN_ENG", @"detect_direction": @"true"};
    __weak __typeof__(self) weakSelf = self;
    
    [_aipOcrManager detectTextFromImage:finalImage withOptions:options successHandler:^(id result) {
        NSLog(@"%@", result);
        dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf addSuccessResult:result];
        });
    } failHandler:^(NSError *err) {
        NSLog(@"%@",err);
        [self.loadingView removeFromSuperview];
        [self.indicator removeFromSuperview];
    }];
    
}

-(void)addSuccessResult:(id)result
{
    [self.loadingView removeFromSuperview];
    [self.indicator removeFromSuperview];
    NSMutableString *message = [NSMutableString string];
    if(result[@"words_result"]){
        if ([result[@"words_result"] count]==0) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"
                                                                                     message:@"没有识别出文字哦"
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *doneAlertAction = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction *  action) {
                [alertController dismissViewControllerAnimated:YES completion:nil];
            }];
            [alertController addAction:doneAlertAction];
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }

        for(NSDictionary *obj in result[@"words_result"]){
            
            
            if (([obj[@"location"][@"left"] floatValue]+[obj[@"location"][@"width"] floatValue])/self.finalImgWidth<(9.f/10.f)) {
                [message appendFormat:@"%@\n", obj[@"words"]];
            }
            else
                [message appendFormat:@"%@", obj[@"words"]];
            
        }
    }else{
        [message appendFormat:@"%@", result];
    }
    
    self.textv.hidden = NO;
    self.bottomView.hidden = YES;
    self.rightItem.enabled = YES;

    

    
    
    
    
    //    textV.text = _resultStr;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 8;// 字体的行间距
    NSDictionary *attributes = @{
                                 NSFontAttributeName:[UIFont systemFontOfSize:18],
                                 NSParagraphStyleAttributeName:paragraphStyle
                                 };
    
    _textv.attributedText = [[NSAttributedString alloc] initWithString:message attributes:attributes];

}

- (CGRect)TransformTheRect{
    
    CGFloat x;
    CGFloat y;
    CGFloat width;
    CGFloat height;
    
    CGFloat cropAreaViewX = V_X(self.maskImageView.cropAreaView);
    CGFloat cropAreaViewY = V_Y(self.maskImageView.cropAreaView);
    CGFloat cropAreaViewW = V_W(self.maskImageView.cropAreaView);
    CGFloat cropAreaViewH = V_H(self.maskImageView.cropAreaView);
    
    CGFloat bgImageViewX  = V_X(self.cutImageView.bgImageView);
    CGFloat bgImageViewY  = V_Y(self.cutImageView.bgImageView);
    CGFloat bgImageViewW  = V_W(self.cutImageView.bgImageView);
    CGFloat bgImageViewH  = V_H(self.cutImageView.bgImageView);
    
    if (self.imageOrientation == UIImageOrientationUp) {
        
        
        if (cropAreaViewX< bgImageViewX) {
            
            x = 0;
            width = cropAreaViewW - (bgImageViewX - cropAreaViewX);
        }else{
            
            x = cropAreaViewX-bgImageViewX;
            width = cropAreaViewW;
        }
        
        if (cropAreaViewY< bgImageViewY) {
            
            y = 0;
            height = cropAreaViewH - (bgImageViewY - cropAreaViewY);
        }else{
            
            y = cropAreaViewY-bgImageViewY;
            height = cropAreaViewH;
        }
        
        self.size = CGSizeMake(bgImageViewW, bgImageViewH);
    }else if (self.imageOrientation == UIImageOrientationRight){
        
        if (cropAreaViewY<bgImageViewY) {
            
            x = 0;
            width = cropAreaViewH - (bgImageViewY - cropAreaViewY);
        }else{
            
            x = cropAreaViewY - bgImageViewY;
            width = cropAreaViewH;
        }
        
        CGFloat newCardViewX = cropAreaViewX + cropAreaViewW;
        CGFloat newBgImageViewX = bgImageViewX + bgImageViewW;
        
        if (newCardViewX>newBgImageViewX) {
            y = 0;
            height = cropAreaViewW - (newCardViewX - newBgImageViewX);
        }else{
            
            y = newBgImageViewX - newCardViewX;
            height = cropAreaViewW;
        }
        
        self.size = CGSizeMake(bgImageViewH, bgImageViewW);
    }else if (self.imageOrientation == UIImageOrientationLeft){
        
        if (cropAreaViewX < bgImageViewX) {
            
            y = 0;
            height = cropAreaViewW - (bgImageViewX - cropAreaViewX);
        }else{
            
            y = cropAreaViewX-bgImageViewX;
            height = cropAreaViewW;
        }
        
        CGFloat newCardViewY = cropAreaViewY + cropAreaViewH;
        CGFloat newBgImageViewY = bgImageViewY + bgImageViewH;
        
        if (newCardViewY< newBgImageViewY) {
            
            x = newBgImageViewY - newCardViewY;
            width = cropAreaViewH;
        }else{
            
            x = 0;
            width = cropAreaViewH - (newCardViewY - newBgImageViewY);
        }
        
        self.size = CGSizeMake(bgImageViewH, bgImageViewW);
    }else{
        
        CGFloat newCardViewX = cropAreaViewX + cropAreaViewW;
        CGFloat newBgImageViewX = bgImageViewX + bgImageViewW;
        
        CGFloat newCardViewY = cropAreaViewY + cropAreaViewH;
        CGFloat newBgImageViewY = bgImageViewY + bgImageViewH;
        
        if (newCardViewX < newBgImageViewX) {
            
            x = newBgImageViewX - newCardViewX;
            width = cropAreaViewW;
        }else{
            
            x = 0;
            width = cropAreaViewW - (newCardViewX - newBgImageViewX);
        }
        
        if (newCardViewY < newBgImageViewY) {
            
            y = newBgImageViewY - newCardViewY;
            height = cropAreaViewH;
            
        }else{
            
            y = 0;
            height = cropAreaViewH - (newCardViewY - newBgImageViewY);
        }
        
        self.size = CGSizeMake(bgImageViewW, bgImageViewH);
    }
    
    return CGRectMake(x, y, width, height);
}


//旋转照片
-(UIImage *)rotateImageEx:(CGImageRef)imgRef orientation:(UIImageOrientation) orient
{
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    CGFloat scaleRatio = 1.0;
    
    CGSize imageSize = CGSizeMake(width, height);
    CGFloat boundHeight;
    
    switch(orient)
    {
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            break;
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else
    {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return imageCopy;
}



- (UIImage *)rotateImageEx:(CGImageRef)imgRef byDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    CGFloat scaleRatio = 1.0;
    
    CGSize imageSize = CGSizeMake(width, height);
    CGFloat boundHeight;
    UIImageOrientation orient = UIImageOrientationUp;
    switch(deviceOrientation)
    {
        case UIDeviceOrientationUnknown:
            break;
            
        case UIDeviceOrientationPortrait:     // Device oriented vertically, home button on the bottom
            orient = UIImageOrientationUp;
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
            break;
            
        case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
            orient = UIImageOrientationLeft;
            break;
            
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
            orient = UIImageOrientationRight;
            break;
            
        case UIDeviceOrientationFaceUp:              // Device oriented flat, face up
            break;
            
        case UIDeviceOrientationFaceDown:            // Device oriented flat, face down
        default:
            break;
    }
    
    
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform,M_PI / 2.0);
            break;
        default:
            break;
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft)
    {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else
    {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height),imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return imageCopy;
}


//切换手机方向有很多种，只有在有效的方向上切换，才会在横屏响应函数orientationChanged 中响应
- (BOOL)deviceOrientationCanChange
{
    
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait)
    {
        self.topWhite.hidden = NO;
        self.curDeviceOrientation = UIDeviceOrientationPortrait;
        return YES;
    }
    else if([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft)
    {
        self.topWhite.hidden = YES;
        self.curDeviceOrientation = UIDeviceOrientationLandscapeLeft;
        return YES;
    }
    else if([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight)
    {
        self.topWhite.hidden = YES;
        self.curDeviceOrientation = UIDeviceOrientationLandscapeRight;
        return YES;
    }
    return NO;
}

-(BOOL)shouldAutorotate{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden{
    
    return NO;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)done {
    // Return any edited content to the host app.
    // This template doesn't do anything, so we just echo the passed in items.
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

@end
