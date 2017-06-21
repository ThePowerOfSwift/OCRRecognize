//
//  AipCutImageView.h
//  BaiduOCR
//
//  Created by Yan,Xiangda on 2017/2/9.
//  Copyright © 2017年 Baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "AipImageEXView.h"

@protocol AipCutImageEXDelegate <NSObject>
@optional

- (void)AipCutImageBeginPaint;
- (void)AipCutImageScale;
- (void)AipCutImageMove;
- (void)AipCutImageEndPaint;

@end

@interface AipCutImageEXView : UIView <UITextViewDelegate,AipImageViewEXDelegate>

@property (nonatomic, assign)   id<AipCutImageEXDelegate>   imgDelegate;
@property (nonatomic, retain)   NSString                  *strSelectContent;
@property (nonatomic, strong)   UIImageView               *bgImageView;
@property (nonatomic, assign)   BOOL                      isImageFromLib;
//截图的分辨率系数 开发者可自行配置
@property (nonatomic, assign)   CGFloat                   scale;

//设置页面图片
- (void)setBGImage:(UIImage *)aImage fromPhotoLib:(BOOL)isFromLib useGestureRecognizer:(BOOL)isUse;

- (UIImage *)cutImageFromView:(UIImageView *)theView withSize:(CGSize)ori atFrame:(CGRect)rect;

@end
