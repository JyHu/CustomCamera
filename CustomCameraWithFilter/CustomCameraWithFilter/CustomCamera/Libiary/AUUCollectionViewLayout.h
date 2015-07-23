//
//  AUUCollectionViewLayout.h
//  WaterTesting
//
//  Created by 胡金友 on 15/7/2.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, AUUCollectionViewDirection) {
    AUUCollectionViewDirectionHorizontal,
    AUUCollectionViewDirectionVertical,
};

@class AUUCollectionViewLayout;

@protocol AUUCollectionViewLayoutDelegate <NSObject>

@required

/**
 *  @author JyHu, 15-07-03 10:07:53
 *
 *  必须实现的代理方法，获取瀑布流中每个cell的尺寸
 *
 *  @param collectionView       UICollectionView
 *  @param collectionViewLayout AUUCollectionViewLayout
 *  @param indexPath            当前cell的位置
 *
 *  @return CGSize
 *
 *  @since  v 1.0
 */
- (CGSize)collectionView:(UICollectionView *)collectionView
    collectionViewLayout:(AUUCollectionViewLayout *)collectionViewLayout
   sizeOfItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  @author JyHu, 15-07-05 19:07:54
 *
 *  当设备的方向发生旋转的时候，判断是否需要进行collectionView的重新布局
 *
 *  @param collectionView       当前布局所在的collectionView
 *  @param collectionViewLayout 当前的布局
 *  @param device               当前的设备，可以获取设备的方向等信息
 *
 *  @return BOOL值，如果真则重新布局
 *
 *  @since  v 1.0
 */
- (BOOL)shouldCollectionViewRotationWhenDeviceOrientationWillChange:(UICollectionView *)collectionView
                                               collectionViewLayout:(AUUCollectionViewLayout *)collectionViewLayout
                                                             device:(UIDevice *)device;

@end

@interface AUUCollectionViewLayout : UICollectionViewLayout

/**
 *  @author JyHu, 15-07-02 18:07:07
 *
 *  代理
 *
 *  @since  v 1.0
 */
@property (assign, nonatomic) id<AUUCollectionViewLayoutDelegate> layoutDelegate;

/**
 *  @author JyHu, 15-07-02 18:07:54
 *
 *  要显示多少列
 *
 *  @since  v 1.0
 */
@property (assign, nonatomic) NSInteger numberOfRows;

/**
 *  @author JyHu, 15-07-02 18:07:44
 *
 *  间距
 *
 *  @since  v 1.0
 */
@property (assign, nonatomic) CGFloat interval;

/**
 *  @author JyHu, 15-07-02 18:07:17
 *
 *  要做瀑布流的section
 *
 *  @since  v 1.0
 */
@property (assign, nonatomic) NSInteger fallInSection;

/**
 *  @author JyHu, 15-07-10 00:40:17
 *
 *  瀑布流布局的方向
 *
 *  @since  v 1.0
 */
@property (assign, nonatomic) AUUCollectionViewDirection collectionViewDirection;

/**
 *  @author JyHu, 15-07-03 10:07:49
 *
 *  重新计算布局文件的属性
 *
 *      - 适合瀑布流中所有的数据重新刷新的情况，会重头开始计算瀑布流中所有的位置和属性设置
 *
 *      - 如果不使用这个重置方法的话，默认的是以追加的方式计算属性，即已经显示过的不再计算属性，
 *           只计算追加上来的数据的属性，这样可以减少计算的过程
 *
 *  @since  v 1.0
 */
- (void)resetLayout;

@end
