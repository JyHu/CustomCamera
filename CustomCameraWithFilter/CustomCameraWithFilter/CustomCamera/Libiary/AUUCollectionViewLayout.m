//
//  AUUCollectionViewLayout.m
//  WaterTesting
//
//  Created by 胡金友 on 15/7/2.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import "AUUCollectionViewLayout.h"

@interface AUUCollectionViewLayout()

/**
 *  @author JyHu, 15-07-02 18:07:36
 *
 *  缓存每列的高度
 *
 *  @since  v 1.0
 */
@property (retain, nonatomic) NSMutableArray    *p_distanceOfRowsArr;

/**
 *  @author JyHu, 15-07-02 18:07:24
 *
 *  每个cell的平均宽度
 *
 *  @since  v 1.0
 */
@property (assign, nonatomic) CGFloat           p_itemWidth;

/**
 *  @author JyHu, 15-07-02 18:07:07
 *
 *  需要瀑布流的section有多少的cell
 *
 *  @since  v 1.0
 */
@property (assign, nonatomic) NSInteger         p_cellCount;

/**
 *  @author JyHu, 15-07-02 18:07:37
 *
 *  所要计算的瀑布流的CollectionView的大小
 *
 *  @since  v 1.0
 */
@property (assign, nonatomic) CGSize            p_contentSize;

/**
 *  @author JyHu, 15-07-03 10:07:02
 *
 *  缓存所有cell的布局方式，减少计算过程
 *
 *  @since  v 1.0
 */
@property (retain, nonatomic) NSMutableArray    *p_layoutAttributes;

/**
 *  @author JyHu, 15-07-03 10:07:32
 *
 *  重新计算的时候开始计算的位置
 *
 *  @since  v 1.0
 */
@property (assign, nonatomic) NSInteger         p_reloadBeginIndex;

@end

@implementation AUUCollectionViewLayout

@synthesize layoutDelegate      = _layoutDelegate;
@synthesize numberOfRows        = _numberOfRows;
@synthesize interval            = _interval;
@synthesize fallInSection       = _fallInSection;

@synthesize p_contentSize       = _p_contentSize;
@synthesize p_itemWidth         = _p_itemWidth;
@synthesize p_distanceOfRowsArr = _p_distanceOfRowsArr;
@synthesize p_cellCount         = _p_cellCount;
@synthesize p_layoutAttributes  = _p_layoutAttributes;
@synthesize p_reloadBeginIndex  = _p_reloadBeginIndex;


- (id)init
{
    self = [super init];
    
    if (self)
    {
        _numberOfRows = 2;
        _interval = 10;
        _fallInSection = 0;
        _p_reloadBeginIndex = 0;
        
        _p_distanceOfRowsArr = [[NSMutableArray alloc] init];
        _p_layoutAttributes = [[NSMutableArray alloc] init];
        
        self.collectionViewDirection = AUUCollectionViewDirectionVertical;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceOrientationDidChanged:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - UICollectionViewLayout methods

- (void)prepareLayout
{
    [super prepareLayout];
        
    _p_contentSize = self.collectionView.frame.size;
    
    _p_cellCount = [self.collectionView numberOfItemsInSection:_fallInSection];
    
    /**
     *  @author JyHu, 15-07-03 10:07:01
     *
     *  平均计算每个cell的宽度
     *
     *  @since  v 1.0
     */
    _p_itemWidth = ((self.collectionViewDirection == AUUCollectionViewDirectionVertical ? _p_contentSize.width : _p_contentSize.height) - (_numberOfRows + 1) * _interval) / (_numberOfRows * 1.0);
}

- (CGSize)collectionViewContentSize
{
    CGFloat maxDistance;
    
    if (_p_distanceOfRowsArr && [_p_distanceOfRowsArr count] != 0)
    {
        /**
         *  @author JyHu, 15-07-03 10:07:41
         *
         *  找到当前各列中最高的一列，然后设置collectionView的contentSize
         *
         *  @since  v 1.0
         */
        maxDistance = [[_p_distanceOfRowsArr objectAtIndex:[self higherRowIndex]] floatValue];
    }
    
    if (maxDistance < (self.collectionViewDirection == AUUCollectionViewDirectionVertical ? _p_contentSize.height : _p_contentSize.width))
    {
        /**
         *  @author JyHu, 15-07-03 10:07:22
         *
         *  防止collectionView的contentSize过小的时候无法滚动
         *
         *  @since  v 1.0
         */
        maxDistance = (self.collectionViewDirection == AUUCollectionViewDirectionVertical ? _p_contentSize.height : _p_contentSize.width) + 1;
    }
    
    return (self.collectionViewDirection == AUUCollectionViewDirectionVertical ?
                            CGSizeMake(_p_contentSize.width, maxDistance) :
                            CGSizeMake(maxDistance, _p_contentSize.height));
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    /**
     *  @author JyHu, 15-07-03 10:07:24
     *
     *  如果需要重新计算，需要清空所有的缓存数据
     *
     *  @since  v 1.0
     */
    if (_p_distanceOfRowsArr && _p_reloadBeginIndex == 0 && _p_layoutAttributes)
    {
        [_p_distanceOfRowsArr removeAllObjects];
        [_p_layoutAttributes removeAllObjects];
        
        /**
         *  @author JyHu, 15-07-03 10:07:23
         *
         *  重置所有列的起始位置
         *
         *  @since  v 1.0
         */
        for (NSInteger i = 0; i < self.numberOfRows; i ++)
        {
            [_p_distanceOfRowsArr addObject:@(_interval)];
        }
    }
    
    /**
     *  @author JyHu, 15-07-03 10:07:36
     *
     *  从 _p_reloadBeginIndex 开始计算每个cell的属性
     *
     *  @since  v 1.0
     */
    for (NSInteger i = _p_reloadBeginIndex ; i< self.p_cellCount; i++)
    {
        NSIndexPath *indexpath = [NSIndexPath indexPathForRow:i inSection:self.fallInSection];
        
        [_p_layoutAttributes addObject:[self layoutAttributesForItemAtIndexPath:indexpath]];
    }
    
    /**
     *  @author JyHu, 15-07-03 10:07:40
     *
     *  缓存当前cell的数量，如果不重置，下次再计算的时候只需要计算追加上来的数据即可，减少计算的过程
     *
     *  @since  v 1.0
     */
    _p_reloadBeginIndex = _p_cellCount;
    
    return _p_layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{    
    CGSize itemSize = [self.layoutDelegate collectionView:self.collectionView
                                     collectionViewLayout:self
                                    sizeOfItemAtIndexPath:indexPath];
    
    /**
     *  @author JyHu, 15-07-03 10:07:34
     *
     *  等比例重新计算代理给的size，防止传递过来的size过大或过小
     *
     *  @since  v 1.0
     */
    CGFloat itemLength;
    
    if (self.collectionViewDirection == AUUCollectionViewDirectionVertical)
    {
        itemLength = floorf(itemSize.height * self.p_itemWidth / itemSize.width);
    }
    else
    {
        itemLength = floor(itemSize.width * self.p_itemWidth / itemSize.height);
    }
    
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
    /**
     *  @author JyHu, 15-07-03 10:07:35
     *
     *  把当前的cell追加到当前collectionView中最短的一列上
     *
     *  @since  v 1.0
     */
    NSInteger row = [self shorterRowIndex];
    
    CGFloat x ;     //  x坐标
    CGFloat y;      //  y坐标
    CGFloat ud;     //  设置后更新的距离
    
    if (self.collectionViewDirection == AUUCollectionViewDirectionVertical)
    {
        x = _interval * (row + 1) + _p_itemWidth * row;
        y = [[_p_distanceOfRowsArr objectAtIndex:row] floatValue];
        ud = y + _interval + itemLength;
    }
    else
    {
        x = [[_p_distanceOfRowsArr objectAtIndex:row] floatValue];
        y = _interval * (row + 1) + _p_itemWidth * row;
        ud = x + _interval + itemLength;
    }
    
    /**
     *  @author JyHu, 15-07-03 10:07:59
     *
     *  追加玩后更新一下当前列的位置
     *
     *  @param itemHeight 更新后的列高加上间距
     *
     *  @since  v 1.0
     */
    [self updateRowDistance:ud inRow:row];
    
    CGRect finalFrame = CGRectMake(x, y, 0, 0);
    
    if (self.collectionViewDirection == AUUCollectionViewDirectionVertical)
    {
        finalFrame.size = CGSizeMake(_p_itemWidth, itemLength);
    }
    else
    {
        finalFrame.size = CGSizeMake(itemLength, _p_itemWidth);
    }
    
    attributes.frame = finalFrame;
    
    return attributes;
}

#pragma mark - handler methods 

- (void)resetLayout
{
    _p_reloadBeginIndex = 0;
}

#pragma mark - help methods

/**
 *  @author JyHu, 15-07-03 10:07:56
 *
 *  计算出所有列中最长的一列
 *
 *  @return 列号
 *
 *  @since  v 1.0
 */
- (NSInteger)higherRowIndex
{
    NSInteger row = 0;
    
    for (NSInteger index = 1; index < _p_distanceOfRowsArr.count; index ++)
    {
        CGFloat y1 = [[_p_distanceOfRowsArr objectAtIndex:row] floatValue];
        CGFloat y2 = [[_p_distanceOfRowsArr objectAtIndex:index] floatValue];
        
        if (y1 < y2)
        {
            row = index;
        }
    }
    
    return row;
}

/**
 *  @author JyHu, 15-07-03 10:07:32
 *
 *  计算出所有列中最短的一列
 *
 *  @return 列号
 *
 *  @since  v 1.0
 */
- (NSInteger)shorterRowIndex
{
    NSInteger row = 0;
    
    for (NSInteger index = 1; index < _p_distanceOfRowsArr.count; index ++)
    {
        CGFloat y1 = [[_p_distanceOfRowsArr objectAtIndex:row] floatValue];
        CGFloat y2 = [[_p_distanceOfRowsArr objectAtIndex:index] floatValue];
        
        if (y1 > y2)
        {
            row = index;
        }
    }
    
    return row;
}

/**
 *  @author JyHu, 15-07-03 10:07:08
 *
 *  重设缓存的列高位置
 *
 *  @param y   列高
 *  @param row 列
 *
 *  @since  v 1.0
 */
- (void)updateRowDistance:(CGFloat)y inRow:(NSInteger)row
{
    if (_p_distanceOfRowsArr && row < _p_distanceOfRowsArr.count)
    {
        [_p_distanceOfRowsArr replaceObjectAtIndex:row withObject:@(y)];
    }
}

#pragma mark - setter methods

- (void)setNumberOfRows:(NSInteger)numberOfRows
{
    /**
     *  @author JyHu, 15-07-03 10:07:23
     *
     *  少于两列的话做瀑布流就不算是瀑布流了，没意义
     *
     *  @param numberOfRows 瀑布流的列数
     *
     *  @since  v 1.0
     */
    _numberOfRows = (numberOfRows < 2 ? 2 : numberOfRows);
}

- (void)setInterval:(CGFloat)interval
{
    /**
     *  @author JyHu, 15-07-03 10:07:03
     *
     *  设置cell的布局间距，必须是整数
     *
     *  @param interval 间距
     *
     *  @since  v 1.0
     */
    _interval = (interval < 0 ? 10 : interval);
}

- (void)setFallInSection:(NSInteger)fallInSection
{
    NSInteger secs = [self.collectionView numberOfSections];
 
    /**
     *  @author JyHu, 15-07-07 17:07:04
     *
     *  必须在有效的范围内
     *
     *  @since  v 1.0
     */
    _fallInSection = ((fallInSection > 0 && fallInSection < secs) ? fallInSection : 0);
}

#pragma mark - Device orientation did changed notification

- (void)deviceOrientationDidChanged:(NSNotification *)notify
{
    if (self.layoutDelegate && [self.layoutDelegate respondsToSelector:@selector(shouldCollectionViewRotationWhenDeviceOrientationWillChange:collectionViewLayout:device:)])
    {
        /**
         *  @author JyHu, 15-07-07 17:07:47
         *
         *  当屏幕发生旋转的时候，通知CollectionView所在的Viewcontroller，并返回是否需要重新布局瀑布流
         *
         *  @since  v 1.0
         */
        BOOL rotation = [self.layoutDelegate shouldCollectionViewRotationWhenDeviceOrientationWillChange:self.collectionView collectionViewLayout:self device:(UIDevice *)notify.object];
        
        if (rotation)
        {
            /**
             *  @author JyHu, 15-07-07 17:07:35
             *
             *  重置记录的布局开始位置
             *
             *  @since  v 1.0
             */
            _p_reloadBeginIndex = 0;
            
            [self.collectionView reloadData];
        }
    }
}

- (void)dealloc
{
//    [[NSNotificationCenter defaultCenter] removeObserver:UIDeviceOrientationDidChangeNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

@end
