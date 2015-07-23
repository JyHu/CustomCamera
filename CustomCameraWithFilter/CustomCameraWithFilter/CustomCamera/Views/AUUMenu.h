//
//  AUUMenu.h
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/21.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^AUUSliderMenuSelectedResultBlock) (NSInteger index);

@interface AUUMenu : UIView

- (id)initWithData:(NSArray *)data;

- (void)show;

- (void)dismiss;

- (void)selectedItemAtIndex:(AUUSliderMenuSelectedResultBlock)completion;

@end
