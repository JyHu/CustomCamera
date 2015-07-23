//
//  AUUFilterFactory.m
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/19.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import "AUUFilterFactory.h"

NSString *filterNameWithType(AUUFilterType type);

NSString *filterNameWithType(AUUFilterType type)
{
    switch (type) {
        case AUUFilterTypeInverse:
            return @"CIColorInvert";
            
        case AUUFilterTypeMonochrome:
            return @"CIPhotoEffectMono";
            
        case AUUFilterTypeReminiscence:
            return @"CIPhotoEffectInstant";
            
        case AUUFilterTypeTimeAndTide:
            return @"CIPhotoEffectTransfer";
            
        case AUUFilterTypeNoir:
            return @"CIPhotoEffectNoir";
            
        case AUUFilterTypeTonal:
            return @"CIPhotoEffectTonal";
            
        case AUUFilterTypeFade:
            return @"CIPhotoEffectFade";
            
        case AUUFilterTypeProcess:
            return @"CIPhotoEffectProcess";
            
        case AUUFilterTypeChrome:
            return @"CIPhotoEffectChrome";
            
        default:
            break;
    }
    
    return @"";
}

@implementation AUUFilterFactory

+ (CIFilter *)filterWithType:(AUUFilterType)filterType
{
    NSString *f = filterNameWithType(filterType);
    NSLog(@"%@ - %@", f, @(filterType));
    return [CIFilter filterWithName:f];
}

+ (NSArray *)filtersArr
{
    NSMutableArray *filterNamesArr = [[NSMutableArray alloc] init];
    
    [filterNamesArr addObject:@{AUUFilterLocalizedNameKey : @"反色",
                                AUUFilterOfficalNameKey : @(AUUFilterTypeInverse)}];
    [filterNamesArr addObject:@{AUUFilterLocalizedNameKey : @"单色",
                                AUUFilterOfficalNameKey : @(AUUFilterTypeMonochrome)}];
    [filterNamesArr addObject:@{AUUFilterLocalizedNameKey : @"怀旧",
                                AUUFilterOfficalNameKey : @(AUUFilterTypeReminiscence)}];
    [filterNamesArr addObject:@{AUUFilterLocalizedNameKey : @"岁月",
                                AUUFilterOfficalNameKey : @(AUUFilterTypeTimeAndTide)}];
    [filterNamesArr addObject:@{AUUFilterLocalizedNameKey : @"黑白",
                                AUUFilterOfficalNameKey : @(AUUFilterTypeNoir)}];
    [filterNamesArr addObject:@{AUUFilterLocalizedNameKey : @"色调",
                                AUUFilterOfficalNameKey : @(AUUFilterTypeTonal)}];
    [filterNamesArr addObject:@{AUUFilterLocalizedNameKey : @"褪色",
                                AUUFilterOfficalNameKey : @(AUUFilterTypeFade)}];
    [filterNamesArr addObject:@{AUUFilterLocalizedNameKey : @"冲印",
                                AUUFilterOfficalNameKey : @(AUUFilterTypeProcess)}];
    [filterNamesArr addObject:@{AUUFilterLocalizedNameKey : @"珞璜",
                                AUUFilterOfficalNameKey : @(AUUFilterTypeChrome)}];
    
    return filterNamesArr;
}

@end


NSString *const AUUFilterLocalizedNameKey = @"AUUFilterLocalizedNameKey";
NSString *const AUUFilterOfficalNameKey = @"AUUFilterOfficalNameKey";
