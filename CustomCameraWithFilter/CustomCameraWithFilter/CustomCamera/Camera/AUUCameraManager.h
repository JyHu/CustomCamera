//
//  AUUCameraManager.h
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/19.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, AUUCaptureDevicePosition) {
    AUUCaptureDevicePositionAuto,   //  自动选择
    AUUCaptureDevicePositionBack,   //  后置摄像头
    AUUCaptureDevicePositionFront,  //  前置摄像头
};

typedef NS_ENUM(NSUInteger, AUUDeviceFlashMode) {
    AUUDeviceFlashModeAuto,     //  自动选择
    AUUDeviceFlashModeOFF,      //  关闭闪光灯
    AUUDeviceFlashModeON,       //  开启闪光灯
};

@class AUUCameraManager;

@protocol AUUCameraManagerDelegate <NSObject>

@required

/**
 *  @author JyHu, 15-07-23 16:07:47
 *
 *  当拍照完成时的回调
 *
 *  @param cameraManager self
 *  @param image         拍照图片
 *  @param url           图片在相册中得url
 *
 *  @since  v 1.0
 */
- (void)didCustomCameraManager:(AUUCameraManager *)cameraManager finishedCaptureWithImage:(UIImage *)image assetURL:(NSURL *)url;

/**
 *  @author JyHu, 15-07-23 16:07:57
 *
 *  摄像头聚焦状态的回调
 *
 *  @param cameraManager self
 *  @param adjusting     是否还在聚焦
 *
 *  @since  v 1.0
 */
- (void)didCustomCameraManager:(AUUCameraManager *)cameraManager finishedAdjustingFocus:(BOOL)adjusting;

@optional

/**
 *  @author JyHu, 15-07-23 17:07:12
 *
 *  如果开启了人脸识别，并且识别到了人脸的位置，会执行此方法
 *
 *  @param cameraManager self
 *  @param faceObjects   识别到的人脸信息，AVMetadataFaceObject 数组
 *  @param basedCIImage  视屏流的当前帧
 *
 *  @return 处理过的CIImage
 *
 *  @since  v 1.0
 */
- (CIImage *)didCustomCameraManager:(AUUCameraManager *)cameraManager
                capturedFaceObjects:(NSArray *)faceObjects
                        withCIImage:(CIImage *)basedCIImage;

/**
 *  @author JyHu, 15-07-23 17:07:27
 *
 *  视频流的每一帧的回调，每秒钟会有几十张，如果做滤镜处理的话，不能做太过复杂的处理，否则会造成卡顿的状态。
 *
 *  @param capturedFrame 获取到的当前帧的图像
 *  @param cameraManager self
 *
 *  @return 处理好的当前帧的图像
 *
 *  @since  v 1.0
 */
- (CIImage *)reDisposeCapturedFrme:(CIImage *)capturedFrame
                  forCameraManager:(AUUCameraManager *)cameraManager;

@end

@interface AUUCameraManager : NSObject

/**
 *  @author JyHu, 15-07-23 16:07:53
 *
 *  单利方法
 *
 *  @return self
 *
 *  @since  v 1.0
 */
+ (AUUCameraManager *)defaultManager;

@property (assign, nonatomic) id<AUUCameraManagerDelegate> delgate;     //  代理

/**
 *  @author JyHu, 15-07-23 16:07:42
 *
 *  实时滤镜，不能使用复杂的滤镜，因为是走的视频流，每秒的帧数过多，如果使用复杂滤镜的话，内存会受不了
 *
 *  @since  v 1.0
 */
@property (copy, nonatomic) CIFilter *filter;

/**
 *  @author JyHu, 15-07-23 16:07:28
 *
 *  聚焦的状态
 *
 *  @since  v 1.0
 */
@property (assign, nonatomic, readonly) BOOL adjustingFocus;

/**
 *  @author JyHu, 15-07-23 16:07:36
 *
 *  是否需要自动的保存到相册
 *
 *      - YES   拍照完成后自动保存到相册，然后执行回调函数，并自动进入拍照聚焦状态
 *      - NO    拍照完成后，聚焦当前的视频流暂停，然后执行回调函数，这时候需要手动startRunning才能进入拍照聚焦状态
 *      
 *      默认的状态是NO
 *
 *  @since  v 1.0
 */
@property (assign, nonatomic) BOOL autoWriteToAlbum;

/**
 *  @author JyHu, 15-07-23 16:07:36
 *
 *  获取当前的闪光灯状态
 *
 *  @since  v 1.0
 */
@property (assign, nonatomic, readonly) AUUDeviceFlashMode deviceFlashMode;

/**
 *  @author JyHu, 15-07-23 16:07:51
 *
 *  获取当前使用摄像头的位置
 *
 *  @since  v 1.0
 */
@property (assign, nonatomic, readonly) AUUCaptureDevicePosition captureDevicePosition;

/**
 *  @author JyHu, 15-07-23 16:07:12
 *
 *  开始视屏流
 *
 *  @since  v 1.0
 */
- (void) startRunning;

/**
 *  @author JyHu, 15-07-23 16:07:41
 *
 *  暂停视屏流
 *
 *  @since  v 1.0
 */
- (void) stopRunning;

/**
 *  @author JyHu, 15-07-23 16:07:49
 *
 *  马上拍照，不需要等待聚焦完成，适合马上需要抓拍的情况，可能会拍照不清晰，不推荐使用
 *
 *  @since  v 1.0
 */
- (void) captureImageNow;

/**
 *  @author JyHu, 15-07-23 16:07:32
 *
 *  等待聚焦结束后拍照，拍照相对较清晰
 *
 *  @since  v 1.0
 */
- (void) captureImageWhenFocusOK;

/**
 *  @author JyHu, 15-07-23 16:07:12
 *
 *  设置实时视频流的输出对象
 *
 *  @param view 要显示摄像头传过来的实时视屏的view
 *
 *  @since  v 1.0
 */
- (void) embedPreviewInView:(UIView *)view;

/**
 *  @author JyHu, 15-07-23 16:07:23
 *
 *  设置当前初始的设备方向
 *
 *  @param interfaceOrientation 设备的方向
 *
 *  @since  v 1.0
 */
- (void) changePreviewOrientation:(UIInterfaceOrientation)interfaceOrientation;

/**
 *  @author JyHu, 15-07-23 16:07:02
 *
 *  重新设置摄像头的位置
 *
 *  @param position AUUCaptureDevicePosition enum
 *
 *  @since  v 1.0
 */
- (void) changeCapturePosition:(AUUCaptureDevicePosition)position;

/**
 *  @author JyHu, 15-07-23 16:07:44
 *
 *  重新设置闪光灯的状态
 *
 *  @param flashMode AUUDeviceFlashMode enum
 *
 *  @since  v 1.0
 */
- (void) changeDeviceFlashMode:(AUUDeviceFlashMode)flashMode;

/**
 *  @author JyHu, 15-07-23 16:07:02
 *
 *  将当前拍照结果保存至相册，与 autoWriteToAlbum = NO 配合使用
 *
 *  @param completion 保存成功后的回调
 *
 *  @since  v 1.0
 */
- (void) writeCurrentPictureToAlbumWithCompletion:(void (^)(NSURL *assetURL, NSError *error))completion;

/**
 *  @author JyHu, 15-07-23 16:07:02
 *
 *  退出当前的拍照界面
 *
 *  @since  v 1.0
 */
- (void) captureExit;

/**
 *  @author JyHu, 15-07-23 17:07:50
 *
 *  设置是否需要人脸识别，默认的是开启
 *
 *  @since  v 1.0
 */
@property (assign, nonatomic) BOOL needCaptureFaceObjectMetadata;

/**
 *  @author JyHu, 15-07-23 18:07:49
 *
 *  聚焦点设置
 *
 *  @param point 聚焦的中心位置，x、y 都是 0~1
 *
 *  @since  v 1.0
 */
- (void)focusAtPoint:(CGPoint)point;

@end










/**
 *  @author JyHu, 15-07-23 17:07:31
 *
 *  单个人脸的马赛克处理方法示例
 *
 *  @since  v 1.0
 */

/*
- (CIImage *)makeFaceWithCIImage:(CIImage *)inputImage faceObject:(AVMetadataFaceObject *)faceObject
{
    CIFilter *tFilter = [CIFilter filterWithName:@"CIPixellate"];
    [tFilter setValue:inputImage forKey:kCIInputImageKey];

    [tFilter setValue:@(MAX(inputImage.extent.size.width, inputImage.extent.size.height) / 60.0) forKey:kCIInputScaleKey];
    CIImage *fullPixellatedImage = [tFilter outputImage];

    CIImage *maskImage;
    CGRect faceBounds = faceObject.bounds;

    CGFloat centerX = inputImage.extent.size.width * (faceBounds.origin.x + faceBounds.size.width / 2.0);
    CGFloat centerY = inputImage.extent.size.height * (1 - faceBounds.origin.y - faceBounds.size.height /2.0);
    CGFloat radius = faceBounds.size.width * inputImage.extent.size.width / 2.0;

    CIFilter *radialGradient = [CIFilter filterWithName:@"CIRadialGradient"
                                    withInputParameters:@{@"inputRadius0" : @(radius),
                                                          @"inputRadius1" : @(radius + 1),
                                                          @"inputColor0" : [CIColor colorWithRed:0 green:1 blue:0 alpha:1],
                                                          @"inputColor1" : [CIColor colorWithRed:0 green:0 blue:0 alpha:0],
                                                          kCIInputCenterKey : [CIVector vectorWithX:centerX Y:centerY]}];
    CIImage *radiaGradientOutputImage = [radialGradient.outputImage imageByCroppingToRect:inputImage.extent];
    if (maskImage == nil)
    {
        maskImage = radiaGradientOutputImage;
    }
    else
    {
        maskImage = [CIFilter filterWithName:@"CISourceOverCompositing"
                         withInputParameters:@{kCIInputImageKey : radiaGradientOutputImage,
                                               kCIInputBackgroundImageKey : maskImage}].outputImage;
    }
    CIFilter *blendFilter = [CIFilter filterWithName:@"CIBlendWithMask"];
    [blendFilter setValue:fullPixellatedImage forKey:kCIInputImageKey];
    [blendFilter setValue:inputImage forKey:kCIInputBackgroundImageKey];
    [blendFilter setValue:maskImage forKey:kCIInputMaskImageKey];

    return blendFilter.outputImage;
}
*/