//
//  AUUCameraManager.m
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/19.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import "AUUCameraManager.h"
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

static NSString *adjustingFocusKey = @"adjustingFocus";

/**
 *  @author JyHu, 15-07-21 14:07:32
 *
 *  使用CALayer可以做实时滤镜处理，但是当手机旋转的时候图片内容也会旋转变形
 *  如果用AVCaptureVideoPreviewLayer的话没法做实时滤镜处理
 *
 *  @since  v 1.0
 */
//#define kUseCaptureVideoLayer 1

@interface AUUCameraManager()
<
AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureMetadataOutputObjectsDelegate
>

@property (retain, nonatomic) AVCaptureSession *p_captureSession;
@property (retain, nonatomic) UIImage *p_image;

#ifdef kUseCaptureVideoLayer
@property (assign, nonatomic) AVCaptureVideoPreviewLayer *p_captureVideoPreviewLayer;
#else
@property (retain, nonatomic) CALayer *p_layer;
#endif

@property (assign, nonatomic) BOOL p_adjustingFocus;
@property (retain, nonatomic) AVCaptureDevice *p_captureDevice;
@property (assign, nonatomic) AUUDeviceFlashMode p_deviceFlashMode;
@property (assign, nonatomic) AUUCaptureDevicePosition p_captureDevicePosition;

@property (retain, nonatomic) CIContext *p_context;
@property (retain, nonatomic) CIImage *p_ciImage;
@property (retain, nonatomic) AVMetadataFaceObject *p_faceObject;
@property (assign, nonatomic) CMVideoDimensions p_videoDimensions;
@property (assign, nonatomic) BOOL p_wantsTakePictureWhtnFocusedOK;
@property (retain, nonatomic) CIFilter *p_filter;



@end

@implementation AUUCameraManager

@synthesize delgate = _delgate;
@synthesize filter = _filter;
@synthesize autoWriteToAlbum = _autoWriteToAlbum;

@synthesize p_captureSession = _p_captureSession;
@synthesize p_image = _p_image;

#ifdef kUseCaptureVideoLayer
@synthesize p_captureVideoPreviewLayer = _p_captureVideoPreviewLayer;
#else
@synthesize p_layer = _p_layer;
#endif

@synthesize p_adjustingFocus = _p_adjustingFocus;
@synthesize p_captureDevice = _p_captureDevice;
@synthesize p_deviceFlashMode = _p_deviceFlashMode;
@synthesize p_captureDevicePosition = _p_captureDevicePosition;
@synthesize p_context = _p_context;
@synthesize p_ciImage = _p_ciImage;
@synthesize p_faceObject = _p_faceObject;
@synthesize p_videoDimensions = _p_videoDimensions;
@synthesize p_wantsTakePictureWhtnFocusedOK = _p_wantsTakePictureWhtnFocusedOK;
@synthesize p_filter = _p_filter;


- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.autoWriteToAlbum = NO;
        self.p_deviceFlashMode = AUUDeviceFlashModeAuto;
        self.p_captureDevicePosition = AUUCaptureDevicePositionBack;
        self.p_deviceFlashMode = AUUDeviceFlashModeAuto;
        self.p_adjustingFocus = YES;
        self.p_wantsTakePictureWhtnFocusedOK = NO;
        
        [self setup];
        
        [self changeCapturePosition:self.p_captureDevicePosition];
        [self changeDeviceFlashMode:self.p_deviceFlashMode];
    }
    
    return self;
}

- (void)setup
{
    self.p_captureSession = [[AVCaptureSession alloc] init];
    
    [self.p_captureSession beginConfiguration];
    
    self.p_captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    self.p_captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [self.p_captureDevice addObserver:self
                           forKeyPath:adjustingFocusKey
                              options:NSKeyValueObservingOptionNew
                              context:nil];
    
    NSError *error;
    AVCaptureDeviceInput *t_captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.p_captureDevice
                                                                                 error:&error];
    if (error)
    {
        NSLog(@"%@", [error localizedDescription]);
    }
    if ([self.p_captureSession canAddInput:t_captureInput])
    {
        [self.p_captureSession addInput:t_captureInput];
    }
    
    AVCaptureVideoDataOutput *captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureVideoDataOutput.videoSettings = @{(__bridge id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    captureVideoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    if ([self.p_captureSession canAddOutput:captureVideoDataOutput])
    {
        [self.p_captureSession addOutput:captureVideoDataOutput];
    }
    
    dispatch_queue_t queue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL);
    [captureVideoDataOutput setSampleBufferDelegate:self queue:queue];
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    if ([self.p_captureSession canAddOutput:captureMetadataOutput])
    {
        [self.p_captureSession addOutput:captureMetadataOutput];
    }
    
    [self.p_captureSession commitConfiguration];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool {
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        CMFormatDescriptionRef formateDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        self.p_videoDimensions = CMVideoFormatDescriptionGetDimensions(formateDescription);
        
        CIImage *outputImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
        
        if (self.p_filter != nil)
        {
            [self.p_filter setValue:outputImage forKey:kCIInputImageKey];
            
            outputImage = self.p_filter.outputImage;
        }
        
        if (self.p_faceObject != nil)
        {
            outputImage = [self makeFaceWithCIImage:outputImage faceObject:_p_faceObject];
        }
        
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        
        CGFloat angle;
        
        if (orientation == UIDeviceOrientationPortrait)
        {
            angle = -M_PI_2;
        }
        else if (orientation == UIDeviceOrientationPortraitUpsideDown)
        {
            angle = M_PI_2;
        }
        else if (orientation == UIDeviceOrientationLandscapeRight)
        {
            angle = M_PI;
        }
        else
        {
            angle = 0;
        }
        
        outputImage = [outputImage imageByApplyingTransform:CGAffineTransformMakeRotation(angle)];
        
        CGImageRef cgImage = [self.p_context createCGImage:outputImage fromRect:outputImage.extent];
        
        self.p_ciImage = outputImage;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
#ifdef kUseCaptureVideoLayer
            self.p_captureVideoPreviewLayer.contents = (__bridge id)(cgImage);
#else
            self.p_layer.contents = (__bridge id)(cgImage);
#endif
            
            CGImageRelease(cgImage);
        });
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count > 0)
    {
        self.p_faceObject = [metadataObjects firstObject];
    }
}

#pragma mark - Help methods

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

- (void)showMessage:(NSString *)msg
{
    UIAlertView *avw = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                  message:msg
                                                 delegate:nil
                                        cancelButtonTitle:@"Sure"
                                        otherButtonTitles:nil, nil];
    [avw show];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices)
    {
        if (device.position == position)
        {
            return device;
        }
    }
    
    return nil;
}

- (void)takePicture
{
    if (self.p_ciImage == nil)
    {
        return;
    }
    
    [self stopRunning];
    
    CGImageRef cgImage = [self.p_context createCGImage:_p_ciImage fromRect:_p_ciImage.extent];
    
    self.p_wantsTakePictureWhtnFocusedOK = NO;
    
    if (_delgate)
    {
        if (self.autoWriteToAlbum)
        {
            [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:cgImage metadata:_p_ciImage.properties completionBlock:^(NSURL *assetURL, NSError *error) {
                
                if (error)
                {
                    [self showMessage:[error localizedDescription]];
                }
                else
                {
                    [_delgate didCustomCameraManager:self
                            finishedCaptureWithImage:[UIImage imageWithCGImage:cgImage]
                                            assetURL:assetURL];
                }
            }];
        }
        else
        {
            [_delgate didCustomCameraManager:self
                    finishedCaptureWithImage:[UIImage imageWithCGImage:cgImage]
                                    assetURL:nil];
        }
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:adjustingFocusKey])
    {
        self.p_adjustingFocus = [[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:@(1)];
        
        if (_delgate)
        {
            [_delgate didCustomCameraManager:self finishedAdjustingFocus:self.p_adjustingFocus];
        }
        
        if (self.p_wantsTakePictureWhtnFocusedOK && !self.p_adjustingFocus)
        {
            [self takePicture];
        }
    }
}

#pragma mark - Getter & Setter methods

- (CIContext *)p_context
{
    if (!_p_context)
    {
        EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _p_context = [CIContext contextWithEAGLContext:eaglContext
                                               options:@{kCIContextWorkingColorSpace : [NSNull null]}];
    }
    
    return _p_context;
}

- (void)setFilter:(CIFilter *)filter
{
    if (filter)
    {
        self.p_filter = [filter copy];
    }
}

- (CIFilter *)filter
{
    if (self.p_filter)
    {
        return self.p_filter;
    }
    
    return nil;
}

- (BOOL)adjustingFocus
{
    return self.p_adjustingFocus;
}

- (AUUCaptureDevicePosition)captureDevicePosition
{
    return self.p_captureDevicePosition;
}

- (AUUDeviceFlashMode)deviceFlashMode
{
    return self.p_deviceFlashMode;
}

#pragma mark - Handle methods

- (void) startRunning
{
    [self.p_captureSession startRunning];
}

- (void) stopRunning
{
    [self.p_captureSession stopRunning];
}

- (void) captureImageNow
{
    [self takePicture];
}

- (void) captureImageWhenFocusOK
{
    if (!self.p_adjustingFocus)
    {
        [self takePicture];
    }
    else
    {
        self.p_wantsTakePictureWhtnFocusedOK = YES;
    }
}

- (void) embedPreviewInView:(UIView *)view
{
    if (!self.p_captureSession)
    {
        return;
    }
    
#ifdef kUseCaptureVideoLayer
    self.p_captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.p_captureSession];
    self.p_captureVideoPreviewLayer.frame = view.bounds;
    self.p_captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [view.layer insertSublayer:self.p_captureVideoPreviewLayer atIndex:0];
#else
    self.p_layer = [CALayer layer];
    self.p_layer.anchorPoint = CGPointZero;
    self.p_layer.bounds = view.bounds;
    [view.layer insertSublayer:self.p_layer atIndex:0];
#endif
    
}

- (void) changePreviewOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    NSLog(@" -  %@  - ", @(interfaceOrientation));
    
#ifdef kUseCaptureVideoLayer
    if (!self.p_captureVideoPreviewLayer)
    {
        return;
    }
    
    [CATransaction begin];
    
    if (interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        self.p_captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    }
    else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        self.p_captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }
    else if (interfaceOrientation == UIInterfaceOrientationPortrait)
    {
        self.p_captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    else
    {
        self.p_captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    }
    
    [CATransaction commit];
#endif
    
}

- (void) changeCapturePosition:(AUUCaptureDevicePosition)position
{
    NSArray *inputs = self.p_captureSession.inputs;
    
    for (AVCaptureDeviceInput *deviceInput in inputs)
    {
        AVCaptureDevice *device = deviceInput.device;
        
        if ([device hasMediaType:AVMediaTypeVideo])
        {
            AVCaptureDevicePosition p = device.position;
            AVCaptureDevice *newCamera = nil;
            AVCaptureDeviceInput *newInput = nil;
            AVCaptureDevicePosition destP;
            
            if (position == AUUCaptureDevicePositionAuto)
            {
                if (p == AVCaptureDevicePositionBack)
                {
                    destP = AVCaptureDevicePositionFront;
                    self.p_captureDevicePosition = AUUCaptureDevicePositionFront;
                }
                else
                {
                    destP = AVCaptureDevicePositionBack;
                    self.p_captureDevicePosition = AUUCaptureDevicePositionBack;
                }
            }
            else if (position == AUUCaptureDevicePositionBack)
            {
                destP = AVCaptureDevicePositionBack;
                self.p_captureDevicePosition = AUUCaptureDevicePositionBack;
            }
            else
            {
                destP = AVCaptureDevicePositionFront;
                self.p_captureDevicePosition = AUUCaptureDevicePositionFront;
            }
            
            newCamera = [self cameraWithPosition:destP];
            
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
            [self.p_captureSession beginConfiguration];
            [self.p_captureSession removeInput:deviceInput];
            [self.p_captureSession addInput:newInput];
            [self.p_captureSession commitConfiguration];
        }
    }
}

- (void) changeDeviceFlashMode:(AUUDeviceFlashMode)flashMode
{
    if ([self.p_captureDevice hasTorch] && [self.p_captureDevice hasFlash])
    {
        self.p_deviceFlashMode = flashMode;
        
        [self.p_captureSession beginConfiguration];
        [self.p_captureDevice lockForConfiguration:nil];
        
        if (flashMode == AUUDeviceFlashModeAuto)
        {
            [self.p_captureDevice setTorchMode:AVCaptureTorchModeAuto];
            [self.p_captureDevice setFlashMode:AVCaptureFlashModeAuto];
        }
        else if (flashMode == AUUDeviceFlashModeON)
        {
            [self.p_captureDevice setTorchMode:AVCaptureTorchModeOn];
            [self.p_captureDevice setFlashMode:AVCaptureFlashModeOn];
        }
        else
        {
            [self.p_captureDevice setFlashMode:AVCaptureFlashModeOff];
            [self.p_captureDevice setTorchMode:AVCaptureTorchModeOff];
        }
        
        [self.p_captureDevice unlockForConfiguration];
        [self.p_captureSession commitConfiguration];
    }
}

- (void)writeCurrentPictureToAlbumWithCompletion:(void (^)(NSURL *, NSError *))completion
{
    CGImageRef cgImage = [self.p_context createCGImage:_p_ciImage fromRect:_p_ciImage.extent];
    
    [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:cgImage metadata:_p_ciImage.properties completionBlock:^(NSURL *assetURL, NSError *error) {
        
        completion(assetURL, error);
    }];
}

#pragma mark - Memory

- (void)dealloc
{
    
}

- (void)captureExit
{
    [self changeDeviceFlashMode:AUUDeviceFlashModeOFF];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device removeObserver:self forKeyPath:adjustingFocusKey];
    
    [self.p_captureSession stopRunning];
    
    self.p_captureSession = nil;
    
#ifdef kUseCaptureVideoLayer
    self.p_captureVideoPreviewLayer = nil;
#else
    self.p_layer = nil;
#endif
    
    self.p_image = nil;
    self.p_ciImage = nil;
    self.p_context = nil;
    self.p_faceObject = nil;
    self.p_captureDevice = nil;
    self.p_filter = nil;
    self.filter = nil;
}

@end
