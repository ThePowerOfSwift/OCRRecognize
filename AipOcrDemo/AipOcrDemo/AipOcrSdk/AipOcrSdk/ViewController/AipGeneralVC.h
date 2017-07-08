//
//  AipGeneralVC.h
//  OCRLib
//
//  Created by Yan,Xiangda on 2017/2/16.
//  Copyright © 2017年 Baidu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "AipOcrDelegate.h"

#import "UIImage+fixOrientation.h"
#import "UIImageView+ContentFrame.h"
//@class AipGeneralVC;
//@protocol MMCropDelegate <NSObject>
//
//-(void)didFinishCropping:(UIImage *)finalCropImage from:(AipGeneralVC *)cropObj;
//
//@end
@interface AipGeneralVC : UIViewController
{
    CGFloat _rotateSlider;
    CGRect _initialRect,final_Rect;
    
    CGFloat firstIn;
    
    BOOL fromLib;
}
@property (nonatomic, weak) id<AipOcrDelegate> delegate;

@property (strong, nonatomic) UIImageView *sourceImageView;
//@property (weak,nonatomic) id<MMCropDelegate> cropdelegate;
@property (strong, nonatomic) UIImage *adjustedImage,*cropgrayImage,*cropImage;

//Detect Edges
-(void)detectEdges;
//- (void) closeWithCompletion:(void (^)(void))completion;

+(UIViewController *)ViewControllerWithDelegate:(id<AipOcrDelegate>)delegate;

@end
