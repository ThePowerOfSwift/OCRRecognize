//
//  IPDFRectangleFeature.h
//  AipOcrDemo
//
//  Created by Tolecen on 2017/7/10.
//  Copyright © 2017年 Baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface IPDFRectangleFeature : NSObject
@property (nonatomic) CGPoint topLeft;
@property (nonatomic) CGPoint topRight;
@property (nonatomic) CGPoint bottomRight;
@property (nonatomic) CGPoint bottomLeft;
@end
