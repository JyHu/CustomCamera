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
 *  @author JyHu, 15-07-23 16:07:35
 *
 *  控制当前使用到得输出对象
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
@property (assign, nonatomic) CMVideoDimensions p_videoDimensions;
@property (assign, nonatomic) BOOL p_wantsTakePictureWhtnFocusedOK;
@property (retain, nonatomic) CIFilter *p_filter;
@property (retain, nonatomic) NSArray *p_capturedFaceObjectsArr;
@property (assign, nonatomic) UIDeviceOrientation p_deviceOrientationWhenAppear;



@end

@implementation AUUCameraManager

@synthesize delgate = _delgate;
@synthesize filter = _filter;
@synthesize autoWriteToAlbum = _autoWriteToAlbum;
@synthesize needCaptureFaceObjectMetadata = _needCaptureFaceObjectMetadata;

@synthesize p_captureSession = _p_captureSession;

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
@synthesize p_videoDimensions = _p_videoDimensions;
@synthesize p_wantsTakePictureWhtnFocusedOK = _p_wantsTakePictureWhtnFocusedOK;
@synthesize p_filter = _p_filter;
@synthesize p_capturedFaceObjectsArr = _p_capturedFaceObjectsArr;
@synthesize p_deviceOrientationWhenAppear = _p_deviceOrientationWhenAppear;

+ (AUUCameraManager *)defaultManager
{
    static AUUCameraManager *manager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[AUUCameraManager alloc] init];
    });
    
    return manager;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.needCaptureFaceObjectMetadata = YES;
        self.autoWriteToAlbum = NO;
        self.p_deviceFlashMode = AUUDeviceFlashModeAuto;
        self.p_captureDevicePosition = AUUCaptureDevicePositionBack;
        self.p_deviceFlashMode = AUUDeviceFlashModeAuto;
        self.p_adjustingFocus = YES;
        self.p_wantsTakePictureWhtnFocusedOK = NO;
        self.p_deviceOrientationWhenAppear = UIDeviceOrientationUnknown;
        
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
    
    AVCaptureDeviceInput *t_captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.p_captureDevice error:&error];
    
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
        captureMetadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
    }
    
    [self.p_captureSession commitConfiguration];
    

    self.needCaptureFaceObjectMetadata = YES;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.p_deviceOrientationWhenAppear == UIDeviceOrientationUnknown)
    {
        self.p_deviceOrientationWhenAppear = [UIDevice currentDevice].orientation;
    }
    
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
        
        if (self.p_capturedFaceObjectsArr != nil)
        {
            if (self.delgate && [self.delgate respondsToSelector:@selector(didCustomCameraManager:capturedFaceObjects:withCIImage:)])
            {
                outputImage = [self.delgate didCustomCameraManager:self capturedFaceObjects:self.p_capturedFaceObjectsArr withCIImage:outputImage];
            }
        }
        
        if (self.delgate && [self.delgate respondsToSelector:@selector(reDisposeCapturedFrme:forCameraManager:)])
        {
            outputImage = [self.delgate reDisposeCapturedFrme:outputImage forCameraManager:self];
        }
        
        CGFloat angle;
        
        UIDeviceOrientation orientation;
        
#ifdef kUseCaptureVideoLayer
        orientation = [UIDevice currentDevice].orientation;
#else
        orientation = self.p_deviceOrientationWhenAppear;
#endif

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
        self.p_capturedFaceObjectsArr = metadataObjects;
    }
}

#pragma mark - Help methods

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
                    [self startRunning];
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
                                               options:@{kCIContextWorkingColorSpace : [NSNull null],
                                                         kCIContextUseSoftwareRenderer : @(YES)}];
    }
    
    return _p_context;
}

- (void)setFilter:(CIFilter *)filter
{
    if (filter)
    {
        self.p_filter = [filter copy];
    }
    else
    {
        self.p_filter = nil;
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

- (void)setNeedCaptureFaceObjectMetadata:(BOOL)needCaptureFaceObjectMetadata
{
    _needCaptureFaceObjectMetadata = needCaptureFaceObjectMetadata;
    if (self.p_captureSession)
    {
        [self.p_captureSession beginConfiguration];
        
        if (needCaptureFaceObjectMetadata)
        {
            AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
            [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
            if ([self.p_captureSession canAddOutput:captureMetadataOutput])
            {
                [self.p_captureSession addOutput:captureMetadataOutput];
                captureMetadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
            }
        }
        else
        {
            for (AVCaptureOutput *output in self.p_captureSession.outputs)
            {
                if ([output isKindOfClass:[AVCaptureMetadataOutput class]])
                {
                    AVCaptureMetadataOutput *metadataOutput = (AVCaptureMetadataOutput *)output;
                    
                    for (NSString *availableMetadataObjectType in metadataOutput.metadataObjectTypes)
                    {
                        if ([availableMetadataObjectType isEqualToString:AVMetadataObjectTypeFace])
                        {
                            [self.p_captureSession removeOutput:metadataOutput];
                            
                            break;
                        }
                    }
                }
            }
        }
        
        [self.p_captureSession commitConfiguration];
    }
}

- (BOOL)needCaptureFaceObjectMetadata
{
    return _needCaptureFaceObjectMetadata;
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

- (void)focusAtPoint:(CGPoint)point
{
    if ([self.p_captureDevice isFocusPointOfInterestSupported] && [self.p_captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
        NSError *error ;
        
        if ([self.p_captureDevice lockForConfiguration:&error])
        {
            [self.p_captureDevice setFocusPointOfInterest:point];
            [self.p_captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            [self.p_captureDevice unlockForConfiguration];
        }
    }
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
    
    self.p_ciImage = nil;
    self.p_context = nil;
    self.p_capturedFaceObjectsArr = nil;
    self.p_captureDevice = nil;
    self.p_filter = nil;
    self.filter = nil;
}

@end
