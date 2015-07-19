//
//  AUUCameraViewController.h
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/19.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AUUCameraViewController : UIViewController

@property (retain, nonatomic) UIButton *backButton;             /* 返回按钮 */
@property (retain, nonatomic) UIButton *takePictureButton;      /* 拍照按钮 */
@property (retain, nonatomic) UIButton *changeCameraButton;     /* 切换摄像头 */
@property (retain, nonatomic) UIButton *flashControlButton;     /* 闪光灯控制 */
@property (retain, nonatomic) UIButton *imageAlbumButton;       /* 相册 */
@property (retain, nonatomic) UIButton *filterMenuButton;       /* 滤镜菜单 */
@property (retain, nonatomic) UIButton *saveToAlbumButton;      /* 保存至相册 */
@property (retain, nonatomic) UIButton *cancelPreviewButton;    /* 取消编辑 */
@property (retain, nonatomic) UIButton *turnToEditViewControllerButton; /* 跳转编辑界面 */
@property (retain, nonatomic) UIButton *shareButton;            /* 分享按钮 */

@property (retain, nonatomic) UIButton *flashModeAutoButton;    /* 闪光灯自动 */
@property (retain, nonatomic) UIButton *flashModeONButton;      /* 闪光灯开启 */
@property (retain, nonatomic) UIButton *flashModeOFFButton;     /* 闪光灯关闭 */

@property (retain, nonatomic) UIButton *cameraPositionAutoButton;
@property (retain, nonatomic) UIButton *cameraPositionBackButton;
@property (retain, nonatomic) UIButton *cameraPositionFrontButton;

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

- (void)turnToEditViewController:(UIViewController *)viewController waitingEditImage:(CIImage *)editingImage;

@end
