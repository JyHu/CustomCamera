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
    AUUCaptureDevicePositionAuto,
    AUUCaptureDevicePositionBack,
    AUUCaptureDevicePositionFront,
};

typedef NS_ENUM(NSUInteger, AUUDeviceFlashMode) {
    AUUDeviceFlashModeAuto,
    AUUDeviceFlashModeOFF,
    AUUDeviceFlashModeON,
};

@class AUUCameraManager;

@protocol AUUCameraManagerDelegate <NSObject>

@required


- (void)didCustomCameraManager:(AUUCameraManager *)cameraManager finishedCaptureWithImage:(UIImage *)image assetURL:(NSURL *)url;
- (void)didCustomCameraManager:(AUUCameraManager *)cameraManager finishedAdjustingFocus:(BOOL)finish;

@end

@interface AUUCameraManager : NSObject

@property (assign, nonatomic) id<AUUCameraManagerDelegate> delgate;
@property (copy, nonatomic) CIFilter *filter;
@property (assign, nonatomic, readonly) BOOL adjustingFocus;
@property (assign, nonatomic) BOOL autoWriteToAlbum;
@property (assign, nonatomic, readonly) AUUDeviceFlashMode deviceFlashMode;
@property (assign, nonatomic, readonly) AUUCaptureDevicePosition captureDevicePosition;

- (void) startRunning;
- (void) stopRunning;

- (void) captureImageNow;
- (void) captureImageWhenFocusOK;
- (void) embedPreviewInView:(UIView *)view;
- (void) changePreviewOrientation:(UIDeviceOrientation)interfaceOrientation;
- (void) changeCapturePosition:(AUUCaptureDevicePosition)position;
- (void) changeDeviceFlashMode:(AUUDeviceFlashMode)flashMode;
- (void) writeCurrentPictureToAlbumWithCompletion:(void (^)(NSURL *assetURL, NSError *error))completion;

- (void) captureExit;

@end
