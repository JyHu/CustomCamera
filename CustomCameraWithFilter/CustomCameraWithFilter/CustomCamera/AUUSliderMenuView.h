//
//  AUUSliderMenuView.h
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/19.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import <UIKit/UIKit.h>



typedef void (^AUUSliderMenuSelectedResultBlock) (NSInteger index);

@interface AUUSliderMenuView : UIView

@property (retain, nonatomic) UITableView *menuTable;

- (id)initWithData:(NSArray *)data;

- (void)show;

- (void)dismiss;

- (void)selectedItemAtIndex:(AUUSliderMenuSelectedResultBlock)completion;

@end
