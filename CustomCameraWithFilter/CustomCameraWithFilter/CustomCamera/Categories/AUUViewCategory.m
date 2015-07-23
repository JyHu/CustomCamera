//
//  AUUViewCategory.m
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/19.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import "AUUViewCategory.h"

@implementation UIView(AUUViewCategory)

- (void)setX:(CGFloat)X
{
    CGRect rect = self.frame;
    rect.origin.x = X;
    self.frame = rect;
}

- (CGFloat)X
{
    return self.frame.origin.x;
}

- (void)setY:(CGFloat)Y
{
    CGRect rect = self.frame;
    rect.origin.y = Y;
    self.frame = rect;
}

- (CGFloat)Y
{
    return self.frame.origin.y;
}

- (void)setW:(CGFloat)W
{
    CGRect rect = self.frame;
    rect.size.width = W;
    self.frame = rect;
}

- (CGFloat)W
{
    return self.frame.size.width;
}

- (void)setH:(CGFloat)H
{
    CGRect rect = self.frame;
    rect.size.height = H;
    self.frame = rect;
}

- (CGFloat)H
{
    return self.frame.size.height;
}

- (CGFloat)MX
{
    return self.frame.size.width + self.frame.origin.x;
}

- (CGFloat)MY
{
    return self.frame.size.height + self.frame.origin.y;
}

@end
