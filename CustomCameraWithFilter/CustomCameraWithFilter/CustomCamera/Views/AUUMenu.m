//
//  AUUMenu.m
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/21.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import "AUUMenu.h"

@interface AUUMenu()

@property (retain, nonatomic) UICollectionView *p_menuCollection;

@end

@implementation AUUMenu

@synthesize p_menuCollection = _p_menuCollection;

- (id)initWithData:(NSArray *)data
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    
    if (self)
    {
        
    }
    
    return self;
}

- (void)show
{
    
}

- (void)dismiss
{
    
}

- (void)selectedItemAtIndex:(AUUSliderMenuSelectedResultBlock)completion
{
    
}

@end
