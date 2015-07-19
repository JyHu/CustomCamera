//
//  AUUFilterFactory.h
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/19.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, AUUFilterType) {
    AUUFilterTypeInverse,           /* 反色 */
    AUUFilterTypeMonochrome,        /* 单色 */
    AUUFilterTypeReminiscence,      /* 怀旧 */
    AUUFilterTypeTimeAndTide,       /* 岁月 */
    AUUFilterTypeNoir,              /* 黑白 */
    AUUFilterTypeTonal,             /* 色调 */
    AUUFilterTypeFade,              /* 褪色 */
    AUUFilterTypeProcess,           /* 冲印 */
    AUUFilterTypeChrome,            /* 珞璜 */
};

@interface AUUFilterFactory : NSObject

+ (CIFilter *)filterWithType:(AUUFilterType)filterType;

+ (NSArray *)filtersArr;

@end


extern NSString *const AUUFilterLocalizedNameKey;
extern NSString *const AUUFilterOfficalNameKey;