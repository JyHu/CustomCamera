//
//  AUUAlbumViewController.m
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/23.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import "AUUAlbumViewController.h"
#import "AUUColorCategory.h"
#import "AUUMacro.h"
#import "AUUAlbumCollectionViewCell.h"
#import "AUUCollectionViewLayout.h"

@interface AUUAlbumViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, AUUCollectionViewLayoutDelegate>

@property (retain, nonatomic) UICollectionView *p_albumCollectionView;

@end

@implementation AUUAlbumViewController

@synthesize p_albumCollectionView = _p_albumCollectionView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    AUUCollectionViewLayout *mlayout = [[AUUCollectionViewLayout alloc] init];
    mlayout.numberOfRows = 3;
    mlayout.layoutDelegate = self;
    mlayout.collectionViewDirection = AUUCollectionViewDirectionVertical;
    
    self.p_albumCollectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:mlayout];
    self.p_albumCollectionView.delegate = self;
    self.p_albumCollectionView.dataSource = self;
    self.p_albumCollectionView.backgroundColor = [UIColor redColor];
    self.p_albumCollectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.p_albumCollectionView registerClass:[AUUAlbumCollectionViewCell class] forCellWithReuseIdentifier:@"aaa"];
    [self.view addSubview:self.p_albumCollectionView];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(back)];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 100;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AUUAlbumCollectionViewCell *cell = (AUUAlbumCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"aaa" forIndexPath:indexPath];
    cell.backgroundColor = kRGBA(10 * indexPath.row % 255, 20 * indexPath.row % 255, 30 * indexPath.row % 255, 1);

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView collectionViewLayout:(AUUCollectionViewLayout *)collectionViewLayout sizeOfItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(50 + arc4random_uniform(100), 10 + arc4random_uniform(150));
}

- (BOOL)shouldCollectionViewRotationWhenDeviceOrientationWillChange:(UICollectionView *)collectionView collectionViewLayout:(AUUCollectionViewLayout *)collectionViewLayout device:(UIDevice *)device
{
    return YES;
}

- (void)back
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
