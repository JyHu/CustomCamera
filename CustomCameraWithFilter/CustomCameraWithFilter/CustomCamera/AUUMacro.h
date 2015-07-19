//
//  AUUMacro.h
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/19.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#ifndef CustomCameraWithFilter_AUUMacro_h
#define CustomCameraWithFilter_AUUMacro_h

#define kRGBA(R, G, B, A) ([UIColor colorWithRed:(R/255.0) green:(G/255.0) blue:(B/255.0) alpha:A])

#define kScreenSize ([UIScreen mainScreen].bounds.size)

#define AUUZero (10e-10)

typedef NS_ENUM(NSUInteger, AUUSelection) {
    AUUSelectionCancel = -1
};

static NSTimeInterval defaultAnimationDuration = 0.5f;


#endif
