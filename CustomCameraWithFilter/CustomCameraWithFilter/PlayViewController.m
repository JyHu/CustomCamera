//
//  PlayViewController.m
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/21.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import "PlayViewController.h"
#import "AUUCameraManager.h"

@interface PlayViewController ()<AUUCameraManagerDelegate>

@end

@implementation PlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor greenColor];
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        CGSize size = [UIScreen mainScreen].bounds.size;
        
        for (NSInteger i = 0; i < 1; i ++)
        {
            for (NSInteger j = 0; j < 2; j ++)
            {
                CGRect r = CGRectMake(size.width / 3.0 *i, size.height / 4.0 * j, size.width / 3.0, size.height / 4.0);
                
                AUUCameraManager *manager = [[AUUCameraManager alloc] init];
                manager.delgate = self;
                [manager startRunning];
                
                UIView *tView = [[UIView alloc] initWithFrame:r];
                tView.backgroundColor = [UIColor brownColor];
                [self.view addSubview:tView];
                
                [manager embedPreviewInView:tView];
            }
        }
    });
}

- (void)didCustomCameraManager:(AUUCameraManager *)cameraManager finishedAdjustingFocus:(BOOL)finish
{
    
}

- (void)didCustomCameraManager:(AUUCameraManager *)cameraManager finishedCaptureWithImage:(UIImage *)image assetURL:(NSURL *)url
{
    
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
