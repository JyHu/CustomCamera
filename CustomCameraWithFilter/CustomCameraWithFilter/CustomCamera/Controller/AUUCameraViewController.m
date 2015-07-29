//
//  AUUCameraViewController.m
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/19.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import "AUUCameraViewController.h"
#import "AUUCameraManager.h"
#import "AUUImageCategory.h"
#import "AUUMacro.h"
#import "AUUViewCategory.h"
#import "AUUSliderMenuView.h"
#import "AUUFilterFactory.h"
#import "AUUAlbumViewController.h"
#import "AUUPictureEditViewController.h"

#define kUseSingletonCameraManager 1

#define kNavigationContainerViewHeight 44.0
#define kMaxToolsContainerViewHeight 144.0
#define kMinToolsContainerViewHeight 44.0

static CGFloat commonButtonHeight = 30.0f;
static CGFloat commonButtonWidth = 72.0f;
static CGFloat commonButtonMargin = 20.0f;
static CGFloat commonTipsLabelHeight = 20.0f;

@interface AUUCameraViewController ()<AUUCameraManagerDelegate>

@property (retain, nonatomic) AUUCameraManager *p_cameraManager;
@property (retain, nonatomic) UIImageView *p_navigationContainerView;
@property (retain, nonatomic) UIImageView *p_toolsContainerView;
@property (retain, nonatomic) UILabel *p_tipsLabel;
@property (assign, nonatomic) BOOL p_tipsLabelHidden;
@property (retain, nonatomic) UIView *p_preView;

@property (assign, nonatomic) BOOL p_flashModeMenuViewable;
@property (assign, nonatomic) BOOL p_cameraPositionMenuViewable;
@property (assign, nonatomic) BOOL p_currentInPreview;

@property (retain, nonatomic) AUUSliderMenuView *p_sliderMenu;

@end

@implementation AUUCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.p_currentInPreview = NO;
    self.p_tipsLabelHidden = YES;
    self.p_flashModeMenuViewable = NO;
    self.p_cameraPositionMenuViewable = NO;
    
    self.view.backgroundColor = [UIColor redColor];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
    {
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    
//    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)])
//    {
//        SEL selector = NSSelectorFromString(@"setOrientation:");
//        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
//        [invocation setSelector:selector];
//        [invocation setTarget:[UIDevice currentDevice]];
//        int val = UIInterfaceOrientationPortrait;
//        [invocation setArgument:&val atIndex:2];
//        [invocation invoke];
//    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationPortrait;
}

- (void)viewWillAppear:(BOOL)animated
{
    
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.p_cameraManager)
    {
        [self.p_cameraManager startRunning];
    }
    else
    {
#ifdef kUseSingletonCameraManager
        self.p_cameraManager = [AUUCameraManager defaultManager];
#else
        self.p_cameraManager = [[AUUCameraManager alloc] init];
#endif
        
        self.p_cameraManager = [[AUUCameraManager alloc] init];
        self.p_cameraManager.delgate = self;
        [self.p_cameraManager startRunning];
        
        self.p_preView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.p_preView.backgroundColor = [UIColor blueColor];
        self.p_preView.alpha = 0;
        [self.p_cameraManager embedPreviewInView:self.p_preView];
        [self.view addSubview:self.p_preView];
        
        [UIView animateWithDuration:defaultAnimationDuration animations:^{
            self.p_preView.alpha = 1;
        }completion:^(BOOL finished) {
            [self setupUI];
        }];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    
    CGPoint pt = [touch locationInView:self.p_preView];
    
    if (CGRectContainsPoint(self.p_preView.frame, pt))
    {
        if (self.p_cameraPositionMenuViewable || self.p_flashModeMenuViewable)
        {
            if (self.p_cameraPositionMenuViewable)
            {
                if (self.p_currentInPreview)
                {
                    [self cancelChangeCameraPositionMenuWithNOAnimation];
                    
                    if (!self.p_tipsLabelHidden)
                    {
                        [self clearTips];
                    }
                }
                else
                {
                    [self cancelChangeCameraPositionMenuWithAnimation];
                }
            }
            
            if (self.p_flashModeMenuViewable)
            {
                if (self.p_currentInPreview)
                {
                    [self cancelchangeFlashModeMenuWithNOAnimation];
                    
                    if (!self.p_tipsLabelHidden)
                    {
                        [self clearTips];
                    }
                }
                else
                {
                    [self cancelchangeFlashModeMenuWithAnimation];
                }
            }
        }
        else if (!self.p_tipsLabelHidden)
        {
            [self clearTips];
        }
        
        if (self.p_cameraManager)
        {
            UITouch *touch = touches.anyObject;
            
            CGPoint touchPoint = [touch locationInView:self.p_preView];
            
            CGPoint pt = CGPointMake(touchPoint.x / self.p_preView.W, touchPoint.y / self.p_preView.H);
            
            [self.p_cameraManager focusAtPoint:pt];
        }
    }
    else
    {
        
    }
}

#pragma mark - UI methods

- (void)setupUI
{
    [self.p_navigationContainerView addSubview:self.backButton];
    [self.p_navigationContainerView addSubview:self.flashControlButton];
    [self.p_navigationContainerView addSubview:self.changeCameraButton];
    [self.p_navigationContainerView addSubview:self.cancelPreviewButton];
    [self.p_navigationContainerView addSubview:self.saveToAlbumButton];
    
    [self.p_navigationContainerView addSubview:self.flashModeAutoButton];
    [self.p_navigationContainerView addSubview:self.flashModeONButton];
    [self.p_navigationContainerView addSubview:self.flashModeOFFButton];
    
    [self.p_navigationContainerView addSubview:self.cameraPositionAutoButton];
    [self.p_navigationContainerView addSubview:self.cameraPositionBackButton];
    [self.p_navigationContainerView addSubview:self.cameraPositionFrontButton];
    
    [self.p_toolsContainerView addSubview:self.imageAlbumButton];
    [self.p_toolsContainerView addSubview:self.takePictureButton];
    [self.p_toolsContainerView addSubview:self.filterMenuButton];
    [self.p_toolsContainerView addSubview:self.shareButton];
    [self.p_toolsContainerView addSubview:self.turnToEditViewControllerButton];
    
    [self.view addSubview:self.p_tipsLabel];
    
    _p_sliderMenu = [[AUUSliderMenuView alloc] initWithData:[AUUFilterFactory filtersArr]];
    [self sliderMenuFrameAdjust];
    [_p_sliderMenu selectedItemAtIndex:^(NSInteger index) {
        [_p_sliderMenu dismiss];
        
        if (index != AUUSelectionCancel)
        {
            if (!index)
            {
                index = 0;
            }
            NSDictionary *dict = [[AUUFilterFactory filtersArr] objectAtIndex:index];
            AUUFilterType filterType = (AUUFilterType)[[dict objectForKey:AUUFilterOfficalNameKey] integerValue];
            [self showTips:[NSString stringWithFormat:@"您选择了滤镜:%@", dict[AUUFilterLocalizedNameKey]]];
            if (self.p_cameraManager)
            {
                [self.p_cameraManager setFilter:[AUUFilterFactory filterWithType:filterType]];
            }
        }
        else
        {
            self.p_cameraManager.filter = nil;
            [self showTips:@"您选择了取消滤镜。"];
        }
    }];
}

- (void)turnToEditViewController:(UIViewController *)viewController waitingEditImage:(CIImage *)editingImage
{
    
}

#pragma mark - Button click methods

- (void)dismissSelf
{
    [self.p_cameraManager stopRunning];
    
    [self.p_preView removeFromSuperview];
    
    [self.p_cameraManager captureExit];
    
    self.p_preView = nil;
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)flashControl
{
    [self changeFlashModeMenuWithAnimation];
    [self showTips:@"请选择闪光灯状态..."];
}

- (void)changeFlashMode:(UIButton *)button
{
    [self.p_cameraManager changeDeviceFlashMode:(AUUDeviceFlashMode)button.tag];
    [self cancelchangeFlashModeMenuWithAnimation];
    
    NSArray *tips = @[@"根据设备默认选择闪光灯", @"关闭闪光灯", @"打开闪光灯"];
    [self showTips:[NSString stringWithFormat:@"您选择了:%@", tips[button.tag]]];
}

- (void)changeCaptureDevice
{
    [self changeCameraPositionMenuWithAnimation];
    [self showTips:@"请选择摄像头位置"];
}

- (void)changeCameraPosition:(UIButton *)button
{
    [self.p_cameraManager changeCapturePosition:(AUUCaptureDevicePosition)button.tag];
    [self cancelChangeCameraPositionMenuWithAnimation];
    
    NSArray *tips = @[@"根据需求自动打开", @"后置摄像头", @"前置摄像头"];
    [self showTips:[NSString stringWithFormat:@"您选择了:%@", tips[button.tag]]];
}

- (void)cancelPreview
{
    [self cancelpreviewImageWithAnimation];
}

- (void)saveToAlbum
{
    [self.p_cameraManager writeCurrentPictureToAlbumWithCompletion:^(NSURL *assetURL, NSError *error) {
        if (error)
        {
            
        }
        else
        {
            [self cancelPreview];
            [self showTips:@"成功保存照片到相册！"];
        }
    }];
}

- (void)turnToAlbum
{
    [self.p_cameraManager stopRunning];
    
    AUUAlbumViewController *albumVC = [[AUUAlbumViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:albumVC];
    
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)takePicture
{
    [self.p_cameraManager captureImageWhenFocusOK];
}

- (void)filterMenu
{
    [self.p_sliderMenu show];
    [self sliderMenuFrameAdjust];
}

- (void)shareCurrentPicture
{
    
}

- (void)turnToEditViewController
{
    [self presentViewController:[[AUUPictureEditViewController alloc] init] animated:YES completion:^{
        
    }];
}

#pragma mark - AUUCameraManagerDelegate

- (void)didCustomCameraManager:(AUUCameraManager *)cameraManager finishedCaptureWithImage:(UIImage *)image assetURL:(NSURL *)url
{
    if (!cameraManager.autoWriteToAlbum)
    {
        [self previewImageWithAnimation];
    }
}

- (void)didCustomCameraManager:(AUUCameraManager *)cameraManager finishedAdjustingFocus:(BOOL)adjusting
{
    
}

#pragma mark - Help methods

- (UIImageView *)blurImageviewWithFrame:(CGRect)rect
{
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:rect];
    imageView.image = [UIImage imageWithColor:kRGBA(1, 1, 1, 0.3)];
    imageView.userInteractionEnabled = YES;
    
    return imageView;
}

- (UIButton *)buttonWithTitle:(NSString *)title selector:(SEL)sel frame:(CGRect)rect
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = rect;
    [button.titleLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [button setBackgroundColor:kRGBA(0.5, 0.5, 0.5, 0.3)];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    
    return button;
}

- (UILabel *)tipsLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake( 0, -20, kScreenSize.width, commonTipsLabelHeight)];
    label.textAlignment = NSTextAlignmentRight;
    label.textColor = [UIColor blueColor];
    label.font = [UIFont systemFontOfSize:12];
    label.backgroundColor = kRGBA(1, 1, 1, 0.3);
    
    return label;
}

- (CGFloat)navigationItemYOrigin
{
    return (kNavigationContainerViewHeight - commonButtonHeight) / 2.0;
}

- (CGFloat)commonTipsLabelHeight
{
    return (self.p_tipsLabelHidden ? commonTipsLabelHeight : 0);
}

- (void)previewImageWithAnimation
{
    self.p_currentInPreview = YES;
    
    [UIView animateWithDuration:defaultAnimationDuration animations:^{
        self.p_navigationContainerView.X = -kScreenSize.width;
        self.p_toolsContainerView.X = -kScreenSize.width;
        self.p_toolsContainerView.H = kMinToolsContainerViewHeight;
        self.p_toolsContainerView.Y = kScreenSize.height - kMinToolsContainerViewHeight;
        
        self.view.userInteractionEnabled = NO;
    }completion:^(BOOL finished) {
        self.view.userInteractionEnabled = YES;
    }];
}

- (void)cancelpreviewImageWithAnimation
{
    self.p_currentInPreview = NO;
    
    [UIView animateWithDuration:defaultAnimationDuration animations:^{
        self.p_navigationContainerView.X = 0;
        self.p_toolsContainerView.X = 0;
        self.p_toolsContainerView.H = kMaxToolsContainerViewHeight;
        self.p_toolsContainerView.Y = kScreenSize.height - kMaxToolsContainerViewHeight;
        
        self.view.userInteractionEnabled = NO;
    }completion:^(BOOL finished) {
        self.view.userInteractionEnabled = YES;
        [self.p_cameraManager startRunning];
    }];
}

- (void)changeFlashModeMenuWithAnimation
{
    [UIView animateWithDuration:defaultAnimationDuration animations:^{
        for (UIButton *button in @[self.backButton, self.flashControlButton, self.changeCameraButton]) {
            button.X = -button.W;
            button.alpha = 0;
        }
        
        for (UIButton *button in @[self.flashModeONButton, self.flashModeOFFButton, self.flashModeAutoButton]) {
            button.alpha = 1;
        }
        
        self.flashModeAutoButton.X = commonButtonMargin;
        self.flashModeONButton.X = (kScreenSize.width - commonButtonWidth) / 2.0;
        self.flashModeOFFButton.X = kScreenSize.width - commonButtonWidth - commonButtonMargin;
        
        self.view.userInteractionEnabled = NO;
    }completion:^(BOOL finished) {
        self.view.userInteractionEnabled = YES;
        self.p_flashModeMenuViewable = YES;
    }];
    
    [self sliderMenuFrameAdjust];
}

- (void)cancelchangeFlashModeMenuWithAnimation
{
    [self cancelchangeFlashModeMenuWithAnimationWithDuration:defaultAnimationDuration];
}

- (void)cancelchangeFlashModeMenuWithNOAnimation
{
    [self cancelchangeFlashModeMenuWithAnimationWithDuration:0];
}

- (void)cancelchangeFlashModeMenuWithAnimationWithDuration:(NSTimeInterval)interval
{
    [UIView animateWithDuration:interval animations:^{
        for (UIButton *button in @[self.flashModeONButton, self.flashModeOFFButton, self.flashModeAutoButton]) {
            button.alpha = 0;
            button.X = kScreenSize.width;
        }
        for (UIButton *button in @[self.backButton, self.flashControlButton, self.changeCameraButton]) {
            button.alpha = 1;
        }
        self.backButton.X = commonButtonMargin;
        self.flashControlButton.X = (kScreenSize.width - commonButtonWidth) / 2.0;
        self.changeCameraButton.X = kScreenSize.width - commonButtonWidth - commonButtonMargin;
        
        self.view.userInteractionEnabled = NO;
    }completion:^(BOOL finished) {
        self.view.userInteractionEnabled = YES;
        self.p_flashModeMenuViewable = NO;
    }];
    
    [self sliderMenuFrameAdjust];
}

- (void)changeCameraPositionMenuWithAnimation
{
    [UIView animateWithDuration:defaultAnimationDuration animations:^{
        for (UIButton *button in @[self.backButton, self.flashControlButton, self.changeCameraButton]) {
            button.X = -button.W;
            button.alpha = 0;
        }
        
        for (UIButton *button in @[self.cameraPositionFrontButton, self.cameraPositionBackButton, self.cameraPositionAutoButton]) {
            button.alpha = 1;
        }
        self.cameraPositionAutoButton.X = commonButtonMargin;
        self.cameraPositionBackButton.X = (kScreenSize.width - commonButtonWidth) / 2.0;
        self.cameraPositionFrontButton.X = kScreenSize.width - commonButtonWidth - commonButtonMargin;
        
        self.view.userInteractionEnabled = NO;
    }completion:^(BOOL finished) {
        self.view.userInteractionEnabled = YES;
        self.p_cameraPositionMenuViewable = YES;
    }];
    
    [self sliderMenuFrameAdjust];
}

- (void)cancelChangeCameraPositionMenuWithAnimation
{
    [self cancelChangeCameraPositionMenuWithAnimationDuration:defaultAnimationDuration];
}

- (void)cancelChangeCameraPositionMenuWithNOAnimation
{
    [self cancelChangeCameraPositionMenuWithAnimationDuration:0];
}

- (void)cancelChangeCameraPositionMenuWithAnimationDuration:(NSTimeInterval)interval
{
    [UIView animateWithDuration:interval animations:^{
        for (UIButton *button in @[self.cameraPositionFrontButton, self.cameraPositionBackButton, self.cameraPositionAutoButton]) {
            button.alpha = 0;
            button.X = kScreenSize.width;
        }
        
        for (UIButton *button in @[self.backButton, self.flashControlButton, self.changeCameraButton]) {
            button.alpha = 1;
        }
        self.backButton.X = commonButtonMargin;
        self.flashControlButton.X = (kScreenSize.width - commonButtonWidth) / 2.0;
        self.changeCameraButton.X = kScreenSize.width - commonButtonWidth - commonButtonMargin;
        
        self.view.userInteractionEnabled = NO;
    }completion:^(BOOL finished) {
        self.view.userInteractionEnabled = YES;
        self.p_cameraPositionMenuViewable = NO;
    }];
    
    [self sliderMenuFrameAdjust];
}

- (void)sliderMenuFrameAdjust
{
    CGFloat y = kNavigationContainerViewHeight + (self.p_tipsLabelHidden ? 0 : 20);
    _p_sliderMenu.menuTable.Y = y;
    _p_sliderMenu.menuTable.H = kScreenSize.height - y - kMaxToolsContainerViewHeight;
}

- (void)showTips:(NSString *)tips
{
    self.p_tipsLabel.text = tips;
    
    if (self.p_tipsLabelHidden)
    {
        self.p_tipsLabelHidden = NO;
        
        [self showTipsWithAnimationCompletion:^{
            
        }];
    }
}

- (void)clearTips
{
    [self cancelShowTipsWithAnimation];
}

- (void)clearTipsWithDelay:(NSTimeInterval)timeInterval
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self clearTips];
    });
}

- (void)showTipsWithAnimationCompletion:(void (^)(void))completion
{
    [UIView animateWithDuration:defaultAnimationDuration animations:^{
        self.p_navigationContainerView.Y = (self.p_tipsLabelHidden ? 0 : commonTipsLabelHeight);
        self.p_tipsLabel.Y = (self.p_tipsLabelHidden ? -commonTipsLabelHeight : 0);
    }completion:^(BOOL finished) {
        completion();
    }];
}

- (void)cancelShowTipsWithAnimation
{
    self.p_tipsLabelHidden = YES;
    
    [self showTipsWithAnimationCompletion:^{
        self.p_tipsLabel.text = @"";
    }];
}

#pragma mark - Getter & Setter

- (UIImageView *)p_navigationContainerView
{
    if (!_p_navigationContainerView)
    {
        _p_navigationContainerView = [self blurImageviewWithFrame:CGRectMake(0, 0,
                                                                             kScreenSize.width * 2.0,
                                                                             kNavigationContainerViewHeight)];
        
        [self.view addSubview:_p_navigationContainerView];
    }
    
    return _p_navigationContainerView;
}

- (UIImageView *)p_toolsContainerView
{
    if (!_p_toolsContainerView)
    {
        _p_toolsContainerView = [self blurImageviewWithFrame:CGRectMake(0, kScreenSize.height - kMaxToolsContainerViewHeight,
                                                                        kScreenSize.width * 2.0 , kMaxToolsContainerViewHeight)];
        
        [self.view addSubview:_p_toolsContainerView];
    }
    
    return _p_toolsContainerView;
}

- (UILabel *)p_tipsLabel
{
    if (!_p_tipsLabel)
    {
        _p_tipsLabel = [self tipsLabel];
    }
    return _p_tipsLabel;
}

- (UIButton *)backButton
{
    if (!_backButton)
    {
        _backButton = [self buttonWithTitle:@"返回"
                                   selector:@selector(dismissSelf)
                                      frame:CGRectMake(commonButtonMargin,
                                                       [self navigationItemYOrigin],
                                                       commonButtonWidth, commonButtonHeight)];
    }
    
    return _backButton;
}

- (UIButton *)flashControlButton
{
    if (!_flashControlButton)
    {
        _flashControlButton = [self buttonWithTitle:@"闪光灯"
                                           selector:@selector(flashControl)
                                              frame:CGRectMake((kScreenSize.width - commonButtonWidth) / 2.0,
                                                               [self navigationItemYOrigin],
                                                               commonButtonWidth, commonButtonHeight)];
    }
    
    NSArray *tips = @[@"A", @"OFF", @"ON"];
    [_flashControlButton setTitle:[NSString stringWithFormat:@"闪光灯:%@", tips[self.p_cameraManager.deviceFlashMode]] forState:UIControlStateNormal];
    
    return _flashControlButton;
}

- (UIButton *)changeCameraButton
{
    if (!_changeCameraButton)
    {
        _changeCameraButton = [self buttonWithTitle:@"摄像头"
                                           selector:@selector(changeCaptureDevice)
                                              frame:CGRectMake(kScreenSize.width - commonButtonWidth - commonButtonMargin,
                                                               [self navigationItemYOrigin],
                                                               commonButtonWidth, commonButtonHeight)];
    }
    
    NSArray *tips = @[@"A", @"B", @"F"];
    [_changeCameraButton setTitle:[NSString stringWithFormat:@"摄像头:%@",tips[self.p_cameraManager.captureDevicePosition]] forState:UIControlStateNormal];
    
    return _changeCameraButton;
}
- (UIButton *)cancelPreviewButton
{
    if (!_cancelPreviewButton)
    {
        _cancelPreviewButton = [self buttonWithTitle:@"取消预览"
                                            selector:@selector(cancelPreview)
                                               frame:CGRectMake(kScreenSize.width + commonButtonMargin,
                                                                [self navigationItemYOrigin],
                                                                commonButtonWidth, commonButtonHeight)];
    }
    
    return _cancelPreviewButton;
}

- (UIButton *)saveToAlbumButton
{
    if (!_saveToAlbumButton)
    {
        _saveToAlbumButton = [self buttonWithTitle:@"保存"
                                          selector:@selector(saveToAlbum)
                                             frame:CGRectMake(kScreenSize.width * 2 - commonButtonMargin - commonButtonWidth,
                                                              [self navigationItemYOrigin],
                                                              commonButtonWidth, commonButtonHeight)];
    }
    
    return _saveToAlbumButton;
}

- (UIButton *)imageAlbumButton
{
    if (!_imageAlbumButton)
    {
        _imageAlbumButton = [self buttonWithTitle:@"相册"
                                         selector:@selector(turnToAlbum)
                                            frame:CGRectMake(commonButtonMargin,
                                                             (kMaxToolsContainerViewHeight - commonButtonHeight) / 2.0,
                                                             commonButtonWidth, commonButtonHeight)];
    }
    
    return _imageAlbumButton;
}

- (UIButton *)takePictureButton
{
    if (!_takePictureButton)
    {
        _takePictureButton = [self buttonWithTitle:@"拍照"
                                          selector:@selector(takePicture)
                                             frame:CGRectMake((kScreenSize.width - (kMaxToolsContainerViewHeight - commonButtonMargin * 2)) / 2.0,
                                                              commonButtonMargin,
                                                              kMaxToolsContainerViewHeight - commonButtonMargin * 2,
                                                              kMaxToolsContainerViewHeight - commonButtonMargin * 2)];
        _takePictureButton.layer.masksToBounds = YES;
        _takePictureButton.layer.cornerRadius = _takePictureButton.W / 2.0;
        _takePictureButton.layer.borderWidth = 2;
        _takePictureButton.layer.borderColor = [UIColor whiteColor].CGColor;
    }
    
    return _takePictureButton;
}

- (UIButton *)filterMenuButton
{
    if (!_filterMenuButton)
    {
        _filterMenuButton = [self buttonWithTitle:@"滤镜"
                                         selector:@selector(filterMenu)
                                            frame:CGRectMake(kScreenSize.width - commonButtonMargin - commonButtonWidth,
                                                             (kMaxToolsContainerViewHeight - commonButtonHeight) / 2.0,
                                                             commonButtonWidth, commonButtonHeight)];
    }
    
    return _filterMenuButton;
}

- (UIButton *)shareButton
{
    if (!_shareButton)
    {
        _shareButton = [self buttonWithTitle:@"分享"
                                    selector:@selector(shareCurrentPicture)
                                       frame:CGRectMake(kScreenSize.width + commonButtonMargin,
                                                        (kMinToolsContainerViewHeight - commonButtonHeight) / 2.0,
                                                        commonButtonWidth, commonButtonHeight)];
    }
    
    return _shareButton;
}

- (UIButton *)turnToEditViewControllerButton
{
    if (!_turnToEditViewControllerButton)
    {
        _turnToEditViewControllerButton = [self buttonWithTitle:@"编辑"
                                                       selector:@selector(turnToEditViewController)
                                                          frame:CGRectMake(kScreenSize.width * 2 - commonButtonMargin - commonButtonWidth,
                                                                           (kMinToolsContainerViewHeight - commonButtonHeight) / 2.0,
                                                                           commonButtonWidth, commonButtonHeight)];
    }
    
    return _turnToEditViewControllerButton;
}

- (UIButton *)flashModeAutoButton
{
    if (!_flashModeAutoButton)
    {
        _flashModeAutoButton = [self buttonWithTitle:@"自动"
                                            selector:@selector(changeFlashMode:)
                                               frame:CGRectMake(kScreenSize.width,
                                                                [self navigationItemYOrigin],
                                                                commonButtonWidth, commonButtonHeight)];
        _flashModeAutoButton.alpha = 0;
        _flashModeAutoButton.tag = AUUDeviceFlashModeAuto;
    }
    
    _flashModeAutoButton.enabled = (self.p_cameraManager.deviceFlashMode != AUUDeviceFlashModeAuto);
    
    return _flashModeAutoButton;
}

- (UIButton *)flashModeONButton
{
    if (!_flashModeONButton)
    {
        _flashModeONButton = [self buttonWithTitle:@"开启"
                                          selector:@selector(changeFlashMode:)
                                             frame:CGRectMake(kScreenSize.width,
                                                              [self navigationItemYOrigin],
                                                              commonButtonWidth, commonButtonHeight)];
        _flashModeONButton.alpha = 0;
        _flashModeONButton.tag = AUUDeviceFlashModeON;
    }
    
    _flashModeONButton.enabled = (self.p_cameraManager.deviceFlashMode != AUUDeviceFlashModeON);
    
    return _flashModeONButton;
}

- (UIButton *)flashModeOFFButton
{
    if (!_flashModeOFFButton)
    {
        _flashModeOFFButton = [self buttonWithTitle:@"关闭"
                                           selector:@selector(changeFlashMode:)
                                              frame:CGRectMake(kScreenSize.width,
                                                               [self navigationItemYOrigin],
                                                               commonButtonWidth, commonButtonHeight)];
        _flashModeOFFButton.alpha = 0;
        _flashModeOFFButton.tag = AUUDeviceFlashModeOFF;
    }
    
    _flashModeOFFButton.enabled = (self.p_cameraManager.deviceFlashMode != AUUDeviceFlashModeOFF);
    
    return _flashModeOFFButton;
}

- (UIButton *)cameraPositionAutoButton
{
    if (!_cameraPositionAutoButton)
    {
        _cameraPositionAutoButton = [self buttonWithTitle:@"自动"
                                                 selector:@selector(changeCameraPosition:)
                                                    frame:CGRectMake(kScreenSize.width,
                                                                     [self navigationItemYOrigin],
                                                                     commonButtonWidth, commonButtonHeight)];
        _cameraPositionAutoButton.alpha = 0;
        _cameraPositionAutoButton.tag = AUUCaptureDevicePositionAuto;
    }
    
    _cameraPositionAutoButton.enabled = (self.p_cameraManager.captureDevicePosition != AUUCaptureDevicePositionAuto);
    
    return _cameraPositionAutoButton;
}

- (UIButton *)cameraPositionFrontButton
{
    if (!_cameraPositionFrontButton)
    {
        _cameraPositionFrontButton = [self buttonWithTitle:@"前置"
                                                  selector:@selector(changeCameraPosition:)
                                                     frame:CGRectMake(kScreenSize.width,
                                                                      [self navigationItemYOrigin],
                                                                      commonButtonWidth, commonButtonHeight)];
        
        _cameraPositionFrontButton.alpha = 0;
        _cameraPositionFrontButton.tag = AUUCaptureDevicePositionFront;
    }
    _cameraPositionFrontButton.enabled = (self.p_cameraManager.captureDevicePosition != AUUCaptureDevicePositionFront);
    
    return _cameraPositionFrontButton;
}

- (UIButton *)cameraPositionBackButton
{
    if (!_cameraPositionBackButton)
    {
        _cameraPositionBackButton = [self buttonWithTitle:@"后置"
                                                 selector:@selector(changeCameraPosition:)
                                                    frame:CGRectMake(kScreenSize.width,
                                                                     [self navigationItemYOrigin],
                                                                     commonButtonWidth, commonButtonHeight)];
        _cameraPositionBackButton.alpha = 0;
        _cameraPositionAutoButton.tag = AUUCaptureDevicePositionBack;
    }
    _cameraPositionBackButton.enabled = (self.p_cameraManager.captureDevicePosition != AUUCaptureDevicePositionBack);
    
    return _cameraPositionBackButton;
}

/*
 *    返回--闪光--切设  取消-------保存
 *  |               |               |
 *  |               |               |
 *  |               |               |
 *  |               |               |
 *  |               |               |
 *  |               |               |
 *  |               |               |
 *  |               |               |
 *  |               |               |
 *  |               |               |
 *  |               |               |
 *  |               |               |
 *   相册--拍照--滤镜   分享-------编辑
 */

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    
}

@end
