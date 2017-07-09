//
//  AipGeneralVC.m
//  OCRLib
//  通用文字识别ViewController
//  Created by Yan,Xiangda on 2017/2/16.
//  Copyright © 2017年 Baidu. All rights reserved.
//

#import "AipGeneralVC.h"
#import "AipCameraController.h"
#import "AipCameraPreviewView.h"
#import "AipCutImageView.h"
#import "AipNavigationController.h"
#import "AipOcrService.h"
#import "AipImageView.h"
#import "ResultViewController.h"
#import "SVProgressHUD.h"

#include <vector>
#import "MMOpenCVHelper.h"
#define backgroundHex @"2196f3"
#define kCameraToolBarHeight 68
#import "UIColor+HexRepresentation.h"
#import "MMCropView.h"
#import <CoreMotion/CoreMotion.h>
#import "IPDFCameraViewController.h"



#define MyLocal(x, ...) NSLocalizedString(x, nil)

#define V_X(v)      v.frame.origin.x
#define V_Y(v)      v.frame.origin.y
#define V_H(v)      v.frame.size.height
#define V_W(v)      v.frame.size.width

@interface MagnifierView : UIView {
    //    CGPoint touchPoint;
}
@property (nonatomic, strong) UIView *viewToMagnify;
@property (nonatomic, assign) CGPoint touchPoint;
- (void)drawRect:(CGRect)rect;
@end



@implementation MagnifierView

- (void)setTouchPoint:(CGPoint)pt {
    _touchPoint = pt;
    
    self.center = CGPointMake(pt.x, pt.y-50);//跟随touchmove 不断得到中心点
}

- (void)drawRect:(CGRect)rect {
    
    //绘制放大镜效果部分
    
    CGContextRef context = UIGraphicsGetCurrentContext();//获取的是当前view的图形上下文
    CGContextTranslateCTM(context,1*(self.frame.size.width*0.5),1*(self.frame.size.height*0.5 ));//重新设置坐标系原点
    CGContextScaleCTM(context, 1.5, 1.5);//通过调用CGContextScaleCTM函数来指定x, y缩放因子 这里我们是扩大1.5倍
    CGContextTranslateCTM(context,-1*(_touchPoint.x),-1*(_touchPoint.y));
    [self.viewToMagnify.layer renderInContext:context];//直接在一个 Core Graphics 上下文中绘制放大后的图像，实现放大镜效果
}

@end

@interface AipGeneralVC () <UIAlertViewDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate,AipCutImageDelegate>
{
    MagnifierView *loop;
}
@property (weak, nonatomic) IBOutlet UIButton *captureButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *albumButton;
@property (weak, nonatomic) IBOutlet UIButton *lightButton;
@property (weak, nonatomic) IBOutlet UIButton *checkCloseBtn;
@property (weak, nonatomic) IBOutlet UIButton *checkChooseBtn;
@property (weak, nonatomic) IBOutlet UIButton *transformButton;
@property (weak, nonatomic) IBOutlet UIView *checkView;
@property (weak, nonatomic) IBOutlet UIView *toolsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolViewBoom;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *checkViewBoom;
//@property (weak, nonatomic) IBOutlet AipCameraPreviewView *previewView;
@property (weak, nonatomic) IBOutlet AipCutImageView *cutImageView;
@property (weak, nonatomic) IBOutlet AipImageView *maskImageView;
//@property (strong, nonatomic) AipCameraController *cameraController;
@property (assign, nonatomic) UIDeviceOrientation curDeviceOrientation;
@property (assign, nonatomic) UIDeviceOrientation imageDeviceOrientation;
@property (assign, nonatomic) UIImageOrientation imageOrientation;
@property (assign, nonatomic) CGSize size;

@property (weak, nonatomic) IBOutlet IPDFCameraViewController *cameraViewController;

@property(nonatomic,strong) CMMotionManager *cmmotionManager;
@property (weak, nonatomic) IBOutlet UIImageView *focusIndicator;
@property (weak, nonatomic) IBOutlet UILabel *titleL;

@property (assign,nonatomic)float finalImgWidth;


@property (strong, nonatomic) MMCropView *cropRect;
@property (nonatomic, strong) NSTimer *touchTimer;

@end

@implementation AipGeneralVC

#pragma mark - Lifecycle

- (void)dealloc{
    
    NSLog(@"♻️ Dealloc %@", NSStringFromClass([self class]));
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    firstIn = YES;
    
    [self.cameraViewController setupCameraView];
    [self.cameraViewController setEnableBorderDetection:YES];
    [self.cameraViewController setCameraViewType:  IPDFCameraViewTypeNormal];
    
    
//    UITapGestureRecognizer * tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusGesture:)];
//    [self.cameraViewController addGestureRecognizer:tapGes];
    
    

//    [self updateTitleLabel];
    
//    self.cameraController = [[AipCameraController alloc] initWithCameraPosition:AVCaptureDevicePositionBack];
    
    [self setupViews];
    
    
    [self setUpMaskImageView];
//    //delegate 用做传递手势事件
//    self.maskImageView.delegate = self.cutImageView;
//    self.cutImageView.imgDelegate = self;
    
    
    self.maskImageView.hidden = YES;
    self.cutImageView.hidden = YES;
    
    
    

    
   
    
    
    
    
    
    self.imageDeviceOrientation = UIDeviceOrientationPortrait;
    
    
//    [self getDeviceOrientation];

   
   
}
- (IBAction)gestureRec:(UITapGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateRecognized)
    {
        CGPoint location = [sender locationInView:self.cameraViewController];
        location.y+=70;
        
        [self focusIndicatorAnimateToPoint:location];
        
        [self.cameraViewController focusAtPoint:location completionHandler:^
         {
             [self focusIndicatorAnimateToPoint:location];
         }];
    }
        
    
}




- (void)focusIndicatorAnimateToPoint:(CGPoint)targetPoint
{
    [self.focusIndicator setCenter:targetPoint];
    self.focusIndicator.alpha = 0.0;
    self.focusIndicator.hidden = NO;
    
    [UIView animateWithDuration:0.4 animations:^
     {
         self.focusIndicator.alpha = 1.0;
     }
                     completion:^(BOOL finished)
     {
         [UIView animateWithDuration:0.4 animations:^
          {
              self.focusIndicator.alpha = 0.0;
          }];
     }];
}


//- (UIStatusBarStyle)preferredStatusBarStyle
//{
//    return UIStatusBarStyleLightContent;
//}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
    if (!firstIn) {
        return;
    }
    
    [self initCropFrame];
    //    [self adjustPossition];
    
    
    _cropRect= [[MMCropView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_cropRect];
    
    UIPanGestureRecognizer *singlePan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(singlePan:)];
    singlePan.maximumNumberOfTouches = 1;
    [_cropRect addGestureRecognizer:singlePan];
    
    //    [self setCropUI];
    [self.view bringSubviewToFront:_cropRect];
    
    _cropRect.hidden = YES;

    firstIn = NO;
   
}

- (void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
//    [self.cameraController startRunningCamera];
    

    
    [self.cameraViewController start];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
//    [self.cameraController stopRunningCamera];
    [self.cameraViewController stop];
}

-(void)getDeviceOrientation
{
    if([self.cmmotionManager isDeviceMotionAvailable]) {
        [self.cmmotionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
            AVCaptureVideoOrientation orientationNew;
            if (accelerometerData.acceleration.x >= 0.75) {//home button left
//                orientationNew = UIDeviceOrientationLandscapeRight;
                NSLog(@"home button left");
            }
            else if (accelerometerData.acceleration.x <= -0.75) {//home button right
//                orientationNew = UIDeviceOrientationLandscapeLeft;
                NSLog(@"home button right");
            }
            else if (accelerometerData.acceleration.y <= -0.75) {
//                orientationNew = UIDeviceOrientationPortrait;
                NSLog(@"UIDeviceOrientationPortrait");
            }
            else if (accelerometerData.acceleration.y >= 0.75) {
//                orientationNew = UIDeviceOrientationPortraitUpsideDown;
                NSLog(@"UIDeviceOrientationPortraitUpsideDown");
            }
            else {
                // Consider same as last time
                return;
            }
            
        }];
    }
}


#pragma mark - SetUp


-(void)initCropFrame{
    _sourceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 40, self.view.bounds.size.width-30, self.view.bounds.size.height-kCameraToolBarHeight-40)];
//    _sourceImageView.backgroundColor = [UIColor redColor];
    [_sourceImageView setContentMode:UIViewContentModeScaleAspectFit];
//    [_sourceImageView setImage:_adjustedImage];
    //     [_sourceImageView setImage:[UIImage imageNamed:@"testtwo.jpg"]];
    _sourceImageView.clipsToBounds=YES;
    
    
    [self.view addSubview:_sourceImageView];
    
    _sourceImageView.hidden = YES;
    
    //    NSLog(@"%f %f",_sourceImageView.contentFrame.size.height,_sourceImageView.contentFrame.size.height);
    
    
//    [self buttonsScroll];
//    
//    [UIView animateWithDuration:0.5 animations:^{
//        scrollView.frame=CGRectMake(0, -64, self.view.bounds.size.width, 64);
//    }];
    
}


//还原初始值
- (void)reset{
    
    _cropImage = nil;
    
    self.sourceImageView.hidden = YES;
    self.cropRect.hidden = YES;
    
    _adjustedImage = nil;
    
    [self.sourceImageView setImage:nil];
    
    self.imageOrientation = UIImageOrientationUp;
    self.closeButton.hidden = YES;
//    self.previewView.hidden = NO;
    
    self.cameraViewController.hidden = NO;
    [self.cameraViewController start];
    self.titleL.text = @"拍摄要识别的区域";
    
    
    self.cutImageView.hidden = YES;
    self.maskImageView.hidden = YES;
    self.checkViewBoom.constant = -V_H(self.checkView);
    self.toolViewBoom.constant = 0;
    //关灯
    [self OffLight];
}

- (void)setupViews {
    
    self.navigationController.navigationBarHidden = YES;
    
//    self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
//    self.previewView.session = self.cameraController.session;
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
    
    fromLib = isFromLib;
    if (isFromLib) {
        
        self.cutImageView.userInteractionEnabled = YES;
        self.transformButton.hidden = NO;
    }else{
        
        self.cutImageView.userInteractionEnabled = NO;
        self.transformButton.hidden = YES;
    }
    self.cameraViewController.hidden = YES;
    [self.cameraViewController stop];
    self.titleL.text = @"";
   
//    self.cutImageView.hidden = NO;
//    self.maskImageView.hidden = NO;
    
    
    self.sourceImageView.hidden = NO;
    self.cropRect.hidden = NO;
    
    _adjustedImage = image;
    
    [self.sourceImageView setImage:_adjustedImage];
    CGRect cropFrame=CGRectMake(_sourceImageView.contentFrame.origin.x,_sourceImageView.contentFrame.origin.y+40-15,_sourceImageView.contentFrame.size.width+30,_sourceImageView.contentFrame.size.height+30);
    [_cropRect setFrame:cropFrame];
    [_cropRect resetFrame];
    
    [self detectEdges];
    _initialRect = self.sourceImageView.frame;
    final_Rect =self.sourceImageView.frame;
    
    
    
    self.closeButton.hidden = YES;
    self.checkViewBoom.constant = 0;
    self.toolViewBoom.constant = -V_H(self.toolsView);
}

#pragma mark - Action handling

- (IBAction)turnLight:(id)sender {
    
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if(![device isTorchModeSupported:AVCaptureTorchModeOn] || ![device isTorchModeSupported:AVCaptureTorchModeOff]) {
        
        //ytodo [self passport_showTextHUDWithTitle:@"暂不支持照明功能" hiddenAfterDelay:0.2];
        return;
    }
//    [self.previewView.session beginConfiguration];
    [device lockForConfiguration:nil];
    if (!self.lightButton.selected) { // 照明状态
        if (device.torchMode == AVCaptureTorchModeOff) {
            // Set torch to on
            [device setTorchMode:AVCaptureTorchModeOn];
        }
        
    }else
    {
        // Set torch to on
        [device setTorchMode:AVCaptureTorchModeOff];
    }
    self.lightButton.selected = !self.lightButton.selected;
    [device unlockForConfiguration];
//    [self.previewView.session commitConfiguration];
}

- (IBAction)pressTransform:(id)sender {
    
    //向右转90'
    _sourceImageView.transform = CGAffineTransformRotate (_sourceImageView.transform, M_PI_2);
    _cropRect.transform = CGAffineTransformRotate (_cropRect.transform, M_PI_2);
    if (self.imageOrientation == UIImageOrientationUp) {
        
        self.imageOrientation = UIImageOrientationRight;
    }else if (self.imageOrientation == UIImageOrientationRight){
        
        self.imageOrientation = UIImageOrientationDown;
    }else if (self.imageOrientation == UIImageOrientationDown){
        
        self.imageOrientation = UIImageOrientationLeft;
    }else{
        
        self.imageOrientation = UIImageOrientationUp;
    }
    
//    [self rotateStateDidChange];
}

#pragma mark Animate
- (CATransform3D)rotateTransform:(CATransform3D)initialTransform clockwise:(BOOL)clockwise
{
    CGFloat arg = M_PI_2;
    if(!clockwise){
        arg *= -1;
    }
    
    CATransform3D transform = initialTransform;
    transform = CATransform3DRotate(transform, arg, 0, 0, 1);
    transform = CATransform3DRotate(transform, 0*M_PI, 0, 1, 0);
    transform = CATransform3DRotate(transform, 0*M_PI, 1, 0, 0);
    
    return transform;
}

- (void)rotateStateDidChange
{
    CATransform3D transform = [self rotateTransform:CATransform3DIdentity clockwise:YES];
    
    CGFloat arg = M_PI_2;
    CGFloat Wnew = fabs(_initialRect.size.width * cos(arg)) + fabs(_initialRect.size.height * sin(arg));
    CGFloat Hnew = fabs(_initialRect.size.width * sin(arg)) + fabs(_initialRect.size.height * cos(arg));
    
    CGFloat Rw = final_Rect.size.width / Wnew;
    CGFloat Rh = final_Rect.size.height / Hnew;
    CGFloat scale = MIN(Rw, Rh) * 1;
    transform = CATransform3DScale(transform, scale, scale, 1);
    _sourceImageView.layer.transform = transform;
    _cropRect.layer.transform = transform;
    
    //    NSLog(@"%@",_sourceImageView);
}


//上传图片识别结果
- (IBAction)pressCheckChoose:(id)sender {
    
    //ytodo tips: MyLocal(@"识别中...")
    
    if (!_cropImage) {
        [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
        [SVProgressHUD showWithStatus:@"裁剪图片..."];
        
        
        
        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_queue_create(NULL, NULL), ^{
            [self cropAction];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf uploadAndRecText];
            });
        });
        
    }
    
   
//    return;
    
    


    
}

-(void)uploadAndRecText
{
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD showWithStatus:@"识别中..."];
    
    //    self.cutImageView.bgImageView.image = _cropImage;
    
    //    CGRect rect  = [self TransformTheRect];
    ////    CGRect rect = CGRectMake(0, 0, <#CGFloat width#>, <#CGFloat height#>)
    //
    //    UIImage *cutImage = [self.cutImageView cutImageFromView:self.cutImageView.bgImageView withSize:self.size atFrame:rect];
    //
    //    UIImage *image = [self rotateImageEx:cutImage.CGImage byDeviceOrientation:self.imageDeviceOrientation];
    //
    //    UIImage *finalImage = [self rotateImageEx:image.CGImage orientation:self.imageOrientation];
    
    //    UIImage * finalImage = self.cutImageView.bgImageView.image;
    
    
    UIImage * finalImage = _cropImage;
    NSLog(@"finalImageWidth:%f",finalImage.size.width);
    
    self.finalImgWidth = finalImage.size.width;
    
    
    //    return;
    
    NSDictionary *options = @{@"language_type": @"CHN_ENG", @"detect_direction": @"true"};
    
    __weak __typeof__(self) weakSelf = self;
    [[AipOcrService shardService] detectTextFromImage:finalImage withOptions:options successHandler:^(id result) {
        NSLog(@"%@", result);
        //        if ([self.delegate respondsToSelector:@selector(ocrOnGeneralSuccessful:)]) {
        //            [self.delegate ocrOnGeneralSuccessful:result];
        //        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [weakSelf toResultVC:result];
        });
    } failHandler:^(NSError *err) {
        //        if ([self.delegate respondsToSelector:@selector(ocrOnFail:)]) {
        //            [self.delegate ocrOnFail:err];
        //        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"识别失败 %li %@",[err code],[err localizedDescription]]];
        });
    }];
}

-(void)toResultVC:(id)result
{
//    float lastEndY = -1;
//    float lastLeft = -1;
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
        
        float maxHeight = 0.f;
        float maxWidth = 0.f;
        
        for(NSDictionary *obj in result[@"words_result"]){
            
            
            if ([obj[@"location"][@"width"] floatValue]>maxWidth) {
                maxWidth = [obj[@"location"][@"width"] floatValue];
            }
            if ([obj[@"location"][@"height"] floatValue]>maxHeight) {
                maxHeight = [obj[@"location"][@"height"] floatValue];
            }
 
        }
        
        if ([result[@"direction"] intValue]==0 || [result[@"direction"] intValue]==2) {
            for(NSDictionary *obj in result[@"words_result"]){
                
                
                if ([obj[@"location"][@"width"] floatValue]/maxWidth<(9.f/10.f)) {
                    [message appendFormat:@"%@\n", obj[@"words"]];
                }
                else
                    [message appendFormat:@"%@", obj[@"words"]];
                
            }
        }
        else
        {
            for(NSDictionary *obj in result[@"words_result"]){
                
                
                if ([obj[@"location"][@"height"] floatValue]/maxHeight<(9.f/10.f)) {
                    [message appendFormat:@"%@\n", obj[@"words"]];
                }
                else
                    [message appendFormat:@"%@", obj[@"words"]];
                
            }
        }
        
        
    }else{
        [message appendFormat:@"%@", result];
    }

    
    ResultViewController * resultVC = [[ResultViewController alloc] init];
    resultVC.resultStr = message;
    [self.navigationController pushViewController:resultVC animated:YES];
}

-(BOOL)isEndBiaodian:(NSString *)str
{
    if ([str isEqualToString:@"."]||[str isEqualToString:@"。"]||[str isEqualToString:@":"]||[str isEqualToString:@"："]||[str isEqualToString:@"……"]||[str isEqualToString:@"..."]||[str isEqualToString:@"…"]||[str isEqualToString:@"！"]||[str isEqualToString:@"!"]||[str isEqualToString:@"？"]||[str isEqualToString:@"?"]) {
        return YES;
    }
    return NO;
}


- (IBAction)pressCheckBack:(id)sender {
    
    [self reset];
}


- (IBAction)captureIDCard:(id)sender {
    
//    __weak __typeof (self) weakSelf = self;
//    [self.cameraController captureStillImageWithHandler:^(NSData *imageData) {
//        
//        
//        [weakSelf setupCutImageView:[UIImage imageWithData:imageData]fromPhotoLib:NO];
//    }];
    
    __weak typeof(self) weakSelf = self;
    
    [self.cameraViewController captureImageWithCompletionHander:^(NSString *imageFilePath)
     {
         UIImage * image = [UIImage imageWithContentsOfFile:imageFilePath];
         [weakSelf setupCutImageView:image fromPhotoLib:NO];
        
     }];
}


- (IBAction)pressBackButton:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)openPhotoAlbum:(id)sender {
    
    if ([UIImagePickerController isSourceTypeAvailable:(UIImagePickerControllerSourceTypePhotoLibrary)]) {
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        //model 一个 View
        [self presentViewController:picker animated:YES completion:^{
            
            
        }];
    }
    else {
        NSAssert(NO, @" ");
    }
}

#pragma mark - segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
}
#pragma mark - notification

//监测设备方向
- (void)orientationChanged:(NSNotification *)notification{
    
    if (![self deviceOrientationCanChange]) {
        
        return;
    }
    
    CGAffineTransform transform;
    
    if (self.curDeviceOrientation == UIDeviceOrientationPortrait) {
        
        transform = CGAffineTransformMakeRotation(0);

        self.imageDeviceOrientation = UIDeviceOrientationPortrait;
    }else if (self.curDeviceOrientation == UIDeviceOrientationLandscapeLeft){
        
        transform = CGAffineTransformMakeRotation(M_PI_2);
        
        self.imageDeviceOrientation = UIDeviceOrientationLandscapeLeft;
    }else if (self.curDeviceOrientation == UIDeviceOrientationLandscapeRight){
        
        transform = CGAffineTransformMakeRotation(-M_PI_2);
        
        self.imageDeviceOrientation = UIDeviceOrientationLandscapeRight;
    }else {
        
        transform = CGAffineTransformMakeRotation(0);
        
        self.imageDeviceOrientation = UIDeviceOrientationPortrait;
    }
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        
        self.albumButton.transform = transform;
        self.closeButton.transform = transform;
        self.lightButton.transform = transform;
        self.closeButton.transform = transform;
        self.captureButton.transform = transform;
        self.checkCloseBtn.transform = transform;
        self.checkChooseBtn.transform = transform;
        self.transformButton.transform = transform;
    } completion:^(BOOL finished) {
        
        
    }];
    
    
}

#pragma mark - loadData

#pragma mark - public

+(CGFloat)speScale{
    
    return (CGFloat) (([UIScreen mainScreen].bounds.size.width == 414) ? 1.1: ([UIScreen mainScreen].bounds.size.width == 320) ? 0.85 : 1);
}

+(UIViewController *)ViewControllerWithDelegate:(id<AipOcrDelegate>)delegate {
    
    UIStoryboard *mainSB = [UIStoryboard storyboardWithName:@"AipOcrSdk" bundle:[NSBundle bundleForClass:[self class]]];
    
    AipGeneralVC *vc = [mainSB instantiateViewControllerWithIdentifier:@"AipGeneralVC"];
    vc.delegate = delegate;
    
    AipNavigationController *navController = [[AipNavigationController alloc] initWithRootViewController:vc];
    return navController;
}

#pragma mark - private

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

- (void)OffLight {
    if (self.lightButton.selected) {
        AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//        [self.previewView.session beginConfiguration];
        [device lockForConfiguration:nil];
        if([device isTorchModeSupported:AVCaptureTorchModeOff]) {
            [device setTorchMode:AVCaptureTorchModeOff];
        }
        [device unlockForConfiguration];
//        [self.previewView.session commitConfiguration];
    }
    
    self.lightButton.selected = NO;
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
        self.curDeviceOrientation = UIDeviceOrientationPortrait;
        return YES;
    }
    else if([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft)
    {
        self.curDeviceOrientation = UIDeviceOrientationLandscapeLeft;
        return YES;
    }
    else if([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight)
    {
        self.curDeviceOrientation = UIDeviceOrientationLandscapeRight;
        return YES;
    }
    return NO;
}



#pragma mark - dataSource && delegate

//AipCutImageDelegate

- (void)AipCutImageBeginPaint{
    
}
- (void)AipCutImageScale{
    
}
- (void)AipCutImageMove{
    
}
- (void)AipCutImageEndPaint{
    
}

//UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    NSAssert(image, @" ");
    if (image) {
        
        [self setupCutImageView:image fromPhotoLib:YES];
        
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

//UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    [self.navigationController popViewControllerAnimated:YES];
    
}

-(void)singlePan:(UIPanGestureRecognizer *)gesture{
    CGPoint posInStretch = [gesture locationInView:_cropRect];
    CGPoint pointInSelfView = [self.view convertPoint:posInStretch fromView:_cropRect];
    if(gesture.state==UIGestureRecognizerStateBegan){
        [_cropRect findPointAtLocation:posInStretch];
        
        self.touchTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                           target:self
                                                         selector:@selector(addLoop)
                                                         userInfo:nil
                                                          repeats:NO];
        
        if(loop == nil){
            loop = [[MagnifierView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
            loop.viewToMagnify = self.view;
            loop.layer.borderColor = [UIColor grayColor].CGColor;
            loop.layer.borderWidth = 2;
            loop.layer.cornerRadius = 50;
            loop.layer.masksToBounds = YES;
        }
        
//        UITouch *touch = [touches anyObject];
        loop.touchPoint = pointInSelfView;
        [loop setNeedsDisplay];
        [[UIApplication sharedApplication].keyWindow addSubview:loop];
    }
    if(gesture.state==UIGestureRecognizerStateEnded){
        _cropRect.activePoint.backgroundColor = [UIColor grayColor];
        _cropRect.activePoint = nil;
        [_cropRect checkangle:0];
        
        
        [self.touchTimer invalidate];
        self.touchTimer = nil;
        
        [loop removeFromSuperview];
        loop = nil;
     
    }
    [_cropRect moveActivePointToLocation:posInStretch];
    
     [self handleAction:pointInSelfView];
    
}

- (void)addLoop {
//    [loop bringSubviewToFront:self.view];//让放大镜显示在最上层
}

- (void)handleAction:(CGPoint)timerObj {
//    NSSet *touches = timerObj;
//    UITouch *touch = [touches anyObject];
    loop.touchPoint = timerObj;//将本身的touch信息传递给放大镜，设置放大镜的中心点
    [loop setNeedsDisplay];
    //    loop drawRect:<#(CGRect)#>
}



#pragma mark OpenCV
- (void)detectEdges
{
    cv::Mat original = [MMOpenCVHelper cvMatFromUIImage:_sourceImageView.image];
    CGSize targetSize = _sourceImageView.contentSize;
    cv::resize(original, original, cvSize(targetSize.width, targetSize.height));
    
    
    
    std::vector<std::vector<cv::Point>>squares;
    std::vector<cv::Point> largest_square;
    
    find_squares(original, squares);
    find_largest_square(squares, largest_square);
    
    if (largest_square.size() == 4)
    {
        
        // Manually sorting points, needs major improvement. Sorry.
        
        NSMutableArray *points = [NSMutableArray array];
        NSMutableDictionary *sortedPoints = [NSMutableDictionary dictionary];
        
        for (int i = 0; i < 4; i++)
        {
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGPoint:CGPointMake(largest_square[i].x, largest_square[i].y)], @"point" , [NSNumber numberWithInt:(largest_square[i].x + largest_square[i].y)], @"value", nil];
            [points addObject:dict];
        }
        
        int min = [[points valueForKeyPath:@"@min.value"] intValue];
        int max = [[points valueForKeyPath:@"@max.value"] intValue];
        
        int minIndex = 0;
        int maxIndex = 0;
        
        int missingIndexOne = 0;
        int missingIndexTwo = 0;
        
        for (int i = 0; i < 4; i++)
        {
            NSDictionary *dict = [points objectAtIndex:i];
            
            if ([[dict objectForKey:@"value"] intValue] == min)
            {
                [sortedPoints setObject:[dict objectForKey:@"point"] forKey:@"0"];
                minIndex = i;
                continue;
            }
            
            if ([[dict objectForKey:@"value"] intValue] == max)
            {
                [sortedPoints setObject:[dict objectForKey:@"point"] forKey:@"2"];
                maxIndex = i;
                continue;
            }
            
            NSLog(@"MSSSING %i", i);
            
            missingIndexOne = i;
        }
        
        for (int i = 0; i < 4; i++)
        {
            if (missingIndexOne != i && minIndex != i && maxIndex != i)
            {
                missingIndexTwo = i;
            }
        }
        
        
        if (largest_square[missingIndexOne].x < largest_square[missingIndexTwo].x)
        {
            //2nd Point Found
            [sortedPoints setObject:[[points objectAtIndex:missingIndexOne] objectForKey:@"point"] forKey:@"3"];
            [sortedPoints setObject:[[points objectAtIndex:missingIndexTwo] objectForKey:@"point"] forKey:@"1"];
        }
        else
        {
            //4rd Point Found
            [sortedPoints setObject:[[points objectAtIndex:missingIndexOne] objectForKey:@"point"] forKey:@"1"];
            [sortedPoints setObject:[[points objectAtIndex:missingIndexTwo] objectForKey:@"point"] forKey:@"3"];
        }
        
        CGPoint point0 = CGPointMake([(NSValue *)[sortedPoints objectForKey:@"0"] CGPointValue].x+15, [(NSValue *)[sortedPoints objectForKey:@"0"] CGPointValue].y+15);
        CGPoint point1 = CGPointMake([(NSValue *)[sortedPoints objectForKey:@"1"] CGPointValue].x+15, [(NSValue *)[sortedPoints objectForKey:@"1"] CGPointValue].y+15);
        CGPoint point2 = CGPointMake([(NSValue *)[sortedPoints objectForKey:@"2"] CGPointValue].x+15, [(NSValue *)[sortedPoints objectForKey:@"2"] CGPointValue].y+15);
        CGPoint point3 = CGPointMake([(NSValue *)[sortedPoints objectForKey:@"3"] CGPointValue].x+15, [(NSValue *)[sortedPoints objectForKey:@"3"] CGPointValue].y+15);
        
        [_cropRect topLeftCornerToCGPoint:point0];
        [_cropRect topRightCornerToCGPoint:point1];
        [_cropRect bottomRightCornerToCGPoint:point2];
        [_cropRect bottomLeftCornerToCGPoint:point3];
        
        NSLog(@"%@ Sorted Points",sortedPoints);
        
        
        
    }
    else{
        
    }
    
    original.release();
    
    
    
}


// http://stackoverflow.com/questions/8667818/opencv-c-obj-c-detecting-a-sheet-of-paper-square-detection
void find_squares(cv::Mat& image, std::vector<std::vector<cv::Point>>&squares) {
    
    // blur will enhance edge detection
    
    cv::Mat blurred(image);
    //    medianBlur(image, blurred, 9);
    GaussianBlur(image, blurred, cvSize(11,11), 0);//change from median blur to gaussian for more accuracy of square detection
    
    cv::Mat gray0(blurred.size(), CV_8U), gray;
    std::vector<std::vector<cv::Point> > contours;
    
    // find squares in every color plane of the image
    for (int c = 0; c < 3; c++)
    {
        int ch[] = {c, 0};
        mixChannels(&blurred, 1, &gray0, 1, ch, 1);
        
        // try several threshold levels
        const int threshold_level = 2;
        for (int l = 0; l < threshold_level; l++)
        {
            // Use Canny instead of zero threshold level!
            // Canny helps to catch squares with gradient shading
            if (l == 0)
            {
                Canny(gray0, gray, 10, 20, 3); //
                //                Canny(gray0, gray, 0, 50, 5);
                
                // Dilate helps to remove potential holes between edge segments
                dilate(gray, gray, cv::Mat(), cv::Point(-1,-1));
            }
            else
            {
                gray = gray0 >= (l+1) * 255 / threshold_level;
            }
            
            // Find contours and store them in a list
            findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
            
            // Test contours
            std::vector<cv::Point> approx;
            for (size_t i = 0; i < contours.size(); i++)
            {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                approxPolyDP(cv::Mat(contours[i]), approx, arcLength(cv::Mat(contours[i]), true)*0.02, true);
                
                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if (approx.size() == 4 &&
                    fabs(contourArea(cv::Mat(approx))) > 1000 &&
                    isContourConvex(cv::Mat(approx)))
                {
                    double maxCosine = 0;
                    
                    for (int j = 2; j < 5; j++)
                    {
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    if (maxCosine < 0.3)
                        squares.push_back(approx);
                }
            }
        }
    }
}

void find_largest_square(const std::vector<std::vector<cv::Point> >& squares, std::vector<cv::Point>& biggest_square)
{
    if (!squares.size())
    {
        // no squares detected
        return;
    }
    
    int max_width = 0;
    int max_height = 0;
    int max_square_idx = 0;
    
    for (size_t i = 0; i < squares.size(); i++)
    {
        // Convert a set of 4 unordered Points into a meaningful cv::Rect structure.
        cv::Rect rectangle = boundingRect(cv::Mat(squares[i]));
        
        //        cout << "find_largest_square: #" << i << " rectangle x:" << rectangle.x << " y:" << rectangle.y << " " << rectangle.width << "x" << rectangle.height << endl;
        
        // Store the index position of the biggest square found
        if ((rectangle.width >= max_width) && (rectangle.height >= max_height))
        {
            max_width = rectangle.width;
            max_height = rectangle.height;
            max_square_idx = i;
        }
    }
    
    biggest_square = squares[max_square_idx];
}


double angle( cv::Point pt1, cv::Point pt2, cv::Point pt0 ) {
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

cv::Mat debugSquares( std::vector<std::vector<cv::Point> > squares, cv::Mat image ){
    
    NSLog(@"DEBUG!/?!");
    for ( unsigned int i = 0; i< squares.size(); i++ ) {
        // draw contour
        
        NSLog(@"LOOP!");
        
        cv::drawContours(image, squares, i, cv::Scalar(255,0,0), 1, 8, std::vector<cv::Vec4i>(), 0, cv::Point());
        
        // draw bounding rect
        cv::Rect rect = boundingRect(cv::Mat(squares[i]));
        cv::rectangle(image, rect.tl(), rect.br(), cv::Scalar(0,255,0), 2, 8, 0);
        
        // draw rotated rect
        cv::RotatedRect minRect = minAreaRect(cv::Mat(squares[i]));
        cv::Point2f rect_points[4];
        minRect.points( rect_points );
        for ( int j = 0; j < 4; j++ ) {
            cv::line( image, rect_points[j], rect_points[(j+1)%4], cv::Scalar(0,0,255), 1, 8 ); // blue
        }
    }
    
    return image;
}


- (void)cropAction {
    
    if([_cropRect frameEdited]){
        
        //Thanks To stackOverflow
        CGFloat scaleFactor =  [_sourceImageView contentScale];
        CGPoint ptBottomLeft = [_cropRect coordinatesForPoint:1 withScaleFactor:scaleFactor];
        CGPoint ptBottomRight = [_cropRect coordinatesForPoint:2 withScaleFactor:scaleFactor];
        CGPoint ptTopRight = [_cropRect coordinatesForPoint:3 withScaleFactor:scaleFactor];
        CGPoint ptTopLeft = [_cropRect coordinatesForPoint:4 withScaleFactor:scaleFactor];
        
        
        
        CGFloat w1 = sqrt( pow(ptBottomRight.x - ptBottomLeft.x , 2) + pow(ptBottomRight.x - ptBottomLeft.x, 2));
        CGFloat w2 = sqrt( pow(ptTopRight.x - ptTopLeft.x , 2) + pow(ptTopRight.x - ptTopLeft.x, 2));
        
        CGFloat h1 = sqrt( pow(ptTopRight.y - ptBottomRight.y , 2) + pow(ptTopRight.y - ptBottomRight.y, 2));
        CGFloat h2 = sqrt( pow(ptTopLeft.y - ptBottomLeft.y , 2) + pow(ptTopLeft.y - ptBottomLeft.y, 2));
        
        CGFloat maxWidth = (w1 < w2) ? w1 : w2;
        CGFloat maxHeight = (h1 < h2) ? h1 : h2;
        
        
        
        cv::Point2f src[4], dst[4];
        src[0].x = ptTopLeft.x;
        src[0].y = ptTopLeft.y;
        src[1].x = ptTopRight.x;
        src[1].y = ptTopRight.y;
        src[2].x = ptBottomRight.x;
        src[2].y = ptBottomRight.y;
        src[3].x = ptBottomLeft.x;
        src[3].y = ptBottomLeft.y;
        
        dst[0].x = 0;
        dst[0].y = 0;
        dst[1].x = maxWidth - 1;
        dst[1].y = 0;
        dst[2].x = maxWidth - 1;
        dst[2].y = maxHeight - 1;
        dst[3].x = 0;
        dst[3].y = maxHeight - 1;
        
        cv::Mat undistorted = cv::Mat( cvSize(maxWidth,maxHeight), CV_8UC4);
        cv::Mat original = [MMOpenCVHelper cvMatFromUIImage:_adjustedImage];
        
        NSLog(@"%f %f %f %f",ptBottomLeft.x,ptBottomRight.x,ptTopRight.x,ptTopLeft.x);
        cv::warpPerspective(original, undistorted, cv::getPerspectiveTransform(src, dst), cvSize(maxWidth, maxHeight));
        
        
        UIImage * cropedImage = [MMOpenCVHelper UIImageFromCVMat:undistorted];
            
            
//            _sourceImageView.image=cropedImage;
//            _cropImage=_sourceImageView.image;
        
        
        
//         [self.cutImageView setBGImage:_sourceImageView.image fromPhotoLib:fromLib useGestureRecognizer:NO];
        
//        _sourceImageView.hidden = YES;
//        _cropRect.hidden = YES;
//        self.cutImageView.hidden = NO;
//        self.maskImageView.hidden = NO;
//
//        self.maskImageView.cropAreaView.frame = self.cutImageView.bgImageView.contentFrame;
//
//        UIImage * resultImage;
//        CGSize size = self.cutImageView.bgImageView.contentFrame.size;
//
//        UIGraphicsBeginImageContext(size);
//        [_sourceImageView.image drawInRect:CGRectMake(0, 0, size.width, size.height)];
//        _cropImage = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
        
        
        CGSize size = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.width*cropedImage.size.height/cropedImage.size.width);
        
//        NSLog(@"thisSize:%@",NSStringFromCGSize(size));
        
        
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        
        [cropedImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
        
        _cropImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        
        
        
        
//        NSData * data = UIImageJPEGRepresentation(_sourceImageView.image,1);
//
//        NSData * data2 = UIImageJPEGRepresentation(_cropImage,1);;
//        if ([data length]<1000000) {
//            data2 = UIImageJPEGRepresentation(_sourceImageView.image,0.9);
//        }
//        else if ([data length]>=1000000 && [data length]<2000000)
//        {
//            data2 = UIImageJPEGRepresentation(_sourceImageView.image,0.8);
//        }
//        else if ([data length]>=2000000 && [data length]<4000000){
//            data2 = UIImageJPEGRepresentation(_sourceImageView.image,0.7);
//        }
//        else
//        {
//            data2 = UIImageJPEGRepresentation(_sourceImageView.image,0.4);
//        }
        
//        NSLog(@"_adjustedImage:%lu,sourceImage:%lu",[UIImageJPEGRepresentation(_adjustedImage,1) length],[data length]);
//        NSLog(@"resultImage:%lu",[data2 length]);
        
//        _cropImage = [UIImage imageWithData:data2];
        
//        [self.cutImageView setBGImage:_cropImage fromPhotoLib:fromLib useGestureRecognizer:NO];
        
             
            
            //         _sourceImageView.image = [MMOpenCVHelper UIImageFromCVMat:grayImage];//For gray image
            
       
        
        original.release();
        undistorted.release();
        
        
        
    }
    else{
        UIAlertView  *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"无效的区域" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        
    }
    
}

//Image Processing
-(UIImage *)grayImage:(UIImage *)processedImage{
    cv::Mat grayImage = [MMOpenCVHelper cvMatGrayFromAdjustedUIImage:processedImage];
    
    cv::medianBlur(grayImage, grayImage, 7);
    cv::adaptiveThreshold(grayImage, grayImage, 245, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, 11, 2);
    
    
//    cv::GaussianBlur(grayImage, grayImage, cvSize(11,11), 0);
//    cv::adaptiveThreshold(grayImage, grayImage, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, 15, 4);
    
    UIImage *grayeditImage=[MMOpenCVHelper UIImageFromCVMat:grayImage];
    grayImage.release();
    
    return grayeditImage;
    
}

-(UIImage *)magicColor:(UIImage *)processedImage{
    cv::Mat  original = [MMOpenCVHelper cvMatFromAdjustedUIImage:processedImage];
    
    cv::Mat new_image = cv::Mat::zeros( original.size(), original.type() );
    
    original.convertTo(new_image, -1, 1.9, -80);
    
    original.release();
    UIImage *magicColorImage=[MMOpenCVHelper UIImageFromCVMat:new_image];
    new_image.release();
    return magicColorImage;
    
    
}

-(UIImage *)blackandWhite:(UIImage *)processedImage{
    cv::Mat original = [MMOpenCVHelper cvMatGrayFromAdjustedUIImage:processedImage];
    
    cv::Mat new_image = cv::Mat::zeros( original.size(), original.type() );
    
    original.convertTo(new_image, -1, 1.4, -50);
    original.release();
    
    UIImage *blackWhiteImage=[MMOpenCVHelper UIImageFromCVMat:new_image];
    new_image.release();
    
    
    
    return blackWhiteImage;
    
}





#pragma mark - function

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

@end
