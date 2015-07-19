//
//  AUUColorCategory.m
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/19.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import "AUUColorCategory.h"

@implementation UIColor(AUUColorCategory)

+ (UIColor *)randomColorWithAlpha:(CGFloat)alpha
{
    CGFloat r = arc4random_uniform(256) / 255.0;
    CGFloat g = arc4random_uniform(256) / 255.0;
    CGFloat b = arc4random_uniform(256) / 256.0;
    
    return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
}

@end
