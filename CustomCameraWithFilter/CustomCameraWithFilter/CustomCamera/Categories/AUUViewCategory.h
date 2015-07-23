//
//  AUUViewCategory.h
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/19.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView(AUUViewCategory)

@property (assign, nonatomic) CGFloat X;
@property (assign, nonatomic) CGFloat Y;
@property (assign, nonatomic) CGFloat H;
@property (assign, nonatomic) CGFloat W;

@property (assign, nonatomic, readonly) CGFloat MX;
@property (assign, nonatomic, readonly) CGFloat MY;

@end
