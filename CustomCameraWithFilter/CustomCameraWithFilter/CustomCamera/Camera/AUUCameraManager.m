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
@property (retain, nonatomic) CIFilter *p_filter;
@property (assign, nonatomic) UIDeviceOrientation p_deviceOrientationWhenAppear;
@property (retain, nonatomic) UIView *p_cachedPreviewView;
#endif

@property (assign, nonatomic) BOOL p_adjustingFocus;
@property (retain, nonatomic) AVCaptureDevice *p_captureDevice;
@property (assign, nonatomic) AUUDeviceFlashMode p_deviceFlashMode;
@property (assign, nonatomic) AUUCaptureDevicePosition p_captureDevicePosition;

@property (retain, nonatomic) CIContext *p_context;
@property (retain, nonatomic) CIImage *p_ciImage;
@property (assign, nonatomic) BOOL p_wantsTakePictureWhtnFocusedOK;





@end

@implementation AUUCameraManager

@synthesize delgate = _delgate;
@synthesize autoWriteToAlbum = _autoWriteToAlbum;

@synthesize p_captureSession = _p_captureSession;

#ifdef kUseCaptureVideoLayer
@synthesize p_captureVideoPreviewLayer = _p_captureVideoPreviewLayer;
#else
@synthesize filter = _filter;
@synthesize p_layer = _p_layer;
@synthesize p_deviceOrientationWhenAppear = _p_deviceOrientationWhenAppear;
@synthesize p_filter = _p_filter;
@synthesize p_cachedPreviewView = _p_cachedPreviewView;
#endif

@synthesize p_adjustingFocus = _p_adjustingFocus;
@synthesize p_captureDevice = _p_captureDevice;
@synthesize p_deviceFlashMode = _p_deviceFlashMode;
@synthesize p_captureDevicePosition = _p_captureDevicePosition;
@synthesize p_context = _p_context;
@synthesize p_ciImage = _p_ciImage;
@synthesize p_wantsTakePictureWhtnFocusedOK = _p_wantsTakePictureWhtnFocusedOK;

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
        self.autoWriteToAlbum = NO;
        self.p_deviceFlashMode = AUUDeviceFlashModeAuto;
        self.p_captureDevicePosition = AUUCaptureDevicePositionBack;
        self.p_deviceFlashMode = AUUDeviceFlashModeAuto;
        self.p_adjustingFocus = YES;
        self.p_wantsTakePictureWhtnFocusedOK = NO;
        
#ifndef kUseCaptureVideoLayer
        self.p_deviceOrientationWhenAppear = UIDeviceOrientationUnknown;
#endif
        
        [self setup];
        
        /**
         *  @author JyHu, 15-07-28 18:07:10
         *
         *  放在这里的操作很有必要，因为从滤镜处理过的CIImage中获取图片数据需要这个对象，而且这个对象是可以被复用的，但是每次的初始化是很费劲的，所以在拍照还没开始之前就初始化一下，会让拍照的时候不至于刚进入相机的时候卡顿。
         *
         *  @since  v 1.0
         */
        [self p_context];
        
        [self changeCapturePosition:self.p_captureDevicePosition];
        [self changeDeviceFlashMode:self.p_deviceFlashMode];
    }
    
    return self;
}

- (void)setup
{
    /**
     *  @author JyHu, 15-07-28 16:07:05
     *
     *  初始化一个输入输出流的桥接session
     *
     *  @since  v 1.0
     */
    self.p_captureSession = [[AVCaptureSession alloc] init];

    /**
     *  @author JyHu, 15-07-28 16:07:20
     *
     *  开始配置
     *
     *  @since  v 1.0
     */
    [self.p_captureSession beginConfiguration];
    
    /**
     *  @author JyHu, 15-07-28 16:07:34
     *
     *  设置输入质量为高级
     *
     *  @since  v 1.0
     */
    self.p_captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    /**
     *  @author JyHu, 15-07-28 17:07:25
     *
     *  获取一个抽象的硬件设备
     *
     *  @since  v 1.0
     */
    self.p_captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    /**
     *  @author JyHu, 15-07-28 17:07:34
     *
     *  监听对焦的状态
     *
     *  @since  v 1.0
     */
    [self.p_captureDevice addObserver:self
                           forKeyPath:adjustingFocusKey
                              options:NSKeyValueObservingOptionNew
                              context:nil];
    
    NSError *error;
    
    /**
     *  @author JyHu, 15-07-28 17:07:56
     *
     *  初始化一个输入设备
     *
     *  @since  v 1.0
     */
    AVCaptureDeviceInput *t_captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.p_captureDevice error:&error];
    
    if ([self.p_captureSession canAddInput:t_captureInput])
    {
        /**
         *  @author JyHu, 15-07-28 17:07:10
         *
         *  判断并为session加入一个输入设备
         *
         *  @since  v 1.0
         */
        [self.p_captureSession addInput:t_captureInput];
    }
    
    /**
     *  @author JyHu, 15-07-28 17:07:36
     *
     *  初始化一个视频流的输出对象
     *
     *  @since  v 1.0
     */
    AVCaptureVideoDataOutput *captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    /**
     *  @author JyHu, 15-07-28 17:07:17
     *
     *  设置视频的编码和解码格式
     *
     *  现在支持的只有：kCVPixelBufferPixelFormatTypeKey
     *
     *      - kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
     *      - kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
     *      - kCVPixelFormatType_32BGRA.
     *
     *  @since  v 1.0
     */
    captureVideoDataOutput.videoSettings = @{(__bridge id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    
    /**
     *  @author JyHu, 15-07-28 17:07:36
     *
     *  当视频的下一帧有图像的时候，是否丢弃当前未被处理的帧图像。
     *
     *  @since  v 1.0
     */
    captureVideoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    
    
    if ([self.p_captureSession canAddOutput:captureVideoDataOutput])
    {
        /**
         *  @author JyHu, 15-07-28 17:07:50
         *
         *  判断并加入输出对象
         *
         *  @since  v 1.0
         */
        [self.p_captureSession addOutput:captureVideoDataOutput];
    }
    
    /**
     *  @author JyHu, 15-07-28 17:07:17
     *
     *  创建一条串行的gcd queue
     *
     *  因为视频的输出流可以放到异步线程中处理
     *
     *  @since  v 1.0
     */
    dispatch_queue_t queue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL);
    
    /**
     *  @author JyHu, 15-07-28 17:07:59
     *
     *  将视频流的代理设置到线程中
     *
     *  @since  v 1.0
     */
    [captureVideoDataOutput setSampleBufferDelegate:self queue:queue];
    
    /**
     *  @author JyHu, 15-07-28 17:07:58
     *
     *  初始化一个元数据的输出流对象
     *
     *  @since  v 1.0
     */
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    /**
     *  @author JyHu, 15-07-28 17:07:58
     *
     *  将元数据的输出代理放到主线程中，因为元数据的获取不是像视频流的输出一直都有的
     *
     *  @since  v 1.0
     */
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    if ([self.p_captureSession canAddOutput:captureMetadataOutput])
    {
        /**
         *  @author JyHu, 15-07-28 17:07:46
         *
         *  为当前的session添加元数据的输出端口
         *
         *  @since  v 1.0
         */
        [self.p_captureSession addOutput:captureMetadataOutput];
        
        /**
         *  @author JyHu, 15-07-28 17:07:06
         *
         *  设置需要扫描到的元数据类型为人脸
         *
         *  @since  v 1.0
         */
        captureMetadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
    }
    
    [self.p_captureSession commitConfiguration];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

/**
 *  @author JyHu, 15-07-28 17:07:12
 *
 *  视频输出流捕捉到每一帧的时候都会调用这个代理方法
 *
 *  @param captureOutput <#captureOutput description#>
 *  @param sampleBuffer  <#sampleBuffer description#>
 *  @param connection    <#connection description#>
 *
 *  @since  v 1.0
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput
                didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
                       fromConnection:(AVCaptureConnection *)connection
{
    
#ifndef kUseCaptureVideoLayer
    
    if (self.p_deviceOrientationWhenAppear == UIDeviceOrientationUnknown)
    {
        /**
         *  @author JyHu, 15-07-28 18:07:16
         *
         *  缓存初始的时候的屏幕的方向
         *
         *  @since  v 1.0
         */
        self.p_deviceOrientationWhenAppear = [UIDevice currentDevice].orientation;
    }
    
#endif
    
    @autoreleasepool {
        
        /**
         *  @author JyHu, 15-07-28 17:07:10
         *
         *  CVImageBufferRef   Base type for all CoreVideo image buffers，所有的CoreVideo的图形数据流的基础类型
         *
         *  sampleBuffer 当前的多媒体流对象所携带的所有数据
         *
         *  CMSampleBufferGetImageBuffer  从当前的流中获取CVImageBufferRef
         *
         *  @since  v 1.0
         */
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        /**
         *  @author JyHu, 15-07-28 17:07:18
         *
         *  获取到CIImage ，这个是进行滤镜处理的图形数据对象
         *
         *  @since  v 1.0
         */
        CIImage *outputImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
        
#ifndef kUseCaptureVideoLayer
        
        if (self.p_filter != nil)
        {
            /**
             *  @author JyHu, 15-07-28 17:07:49
             *
             *  如果外部有添加的滤镜对象，可以直接添加进来在这里进行处理
             *
             *  @since  v 1.0
             */
            [self.p_filter setValue:outputImage forKey:kCIInputImageKey];
            
            outputImage = self.p_filter.outputImage;
        }
        
#endif

        CGFloat angle;
        
        UIDeviceOrientation orientation;
        
        /**
         *  @author JyHu, 15-07-28 17:07:47
         *
         *  根据屏幕的方向来对输入的视频流进行旋转变换
         *
         *  @since  v 1.0
         */
        
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
        
        // 1080w * 1920h
        CGImageRef cgImage = [self.p_context createCGImage:outputImage fromRect:outputImage.extent];
        
        self.p_ciImage = outputImage;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
#ifdef kUseCaptureVideoLayer
            self.p_captureVideoPreviewLayer.contents = (__bridge id)(cgImage);
#else
            self.p_layer.contents = (__bridge id)(cgImage);
#endif
            
            /**
             *  @author JyHu, 15-07-28 17:07:30
             *
             *  一定要release，否则会程序内存爆增导致崩溃。
             *
             *  @since  v 1.0
             */
            CGImageRelease(cgImage);
        });
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

/**
 *  @author JyHu, 15-07-28 17:07:46
 *
 *  每次捕捉到元数据的时候都会调用这个方法
 *
 *  @param captureOutput   <#captureOutput description#>
 *  @param metadataObjects <#metadataObjects description#>
 *  @param connection      <#connection description#>
 *
 *  @since  v 1.0
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count > 0)
    {
        /**
         *  @author JyHu, 15-07-28 17:07:06
         *
         *  对元数据的处理
         *
         *  @since  v 1.0
         */
    }
}

#pragma mark - Help methods

/**
 *  @author JyHu, 15-07-28 17:07:15
 *
 *  获取指定位置的硬件设备
 *
 *  @param position 设备的位置
 *
 *  @since  v 1.0
 */
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
            /**
             将照片存到相册
             */
            [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:cgImage metadata:_p_ciImage.properties completionBlock:^(NSURL *assetURL, NSError *error) {
                
                if (!error)
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
    
    CGImageRelease(cgImage);
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
    else if ([keyPath isEqualToString:@"frame"] && object == self.p_cachedPreviewView)
    {
        CGRect newRect = [[change objectForKey:@"new"] CGRectValue];
        CGRect oldRect = [[change objectForKey:@"old"] CGRectValue];
        
        CGFloat nw = CGRectGetWidth(newRect);
        CGFloat nh = CGRectGetHeight(newRect);
        CGFloat ow = CGRectGetWidth(oldRect);
        CGFloat oh = CGRectGetHeight(oldRect);
        CGFloat sw = CGRectGetWidth([UIScreen mainScreen].bounds);
        CGFloat sh = CGRectGetHeight([UIScreen mainScreen].bounds);
        
        NSTimeInterval timeInterval = fabs(sqrt(pow(nw, 2) + pow(nh, 2)) - sqrt(pow(ow, 2) + pow(oh, 2))) / sqrt(pow(sw, 2) + pow(sh, 2)) * 0.5;
        
        [UIView animateWithDuration:timeInterval animations:^{
            self.p_layer.frame = [[change objectForKey:@"new"] CGRectValue];
        }];
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

#ifndef kUseCaptureVideoLayer

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

#endif

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
    if (!self.p_captureSession && !view)
    {
        return;
    }
    
    /**
     *  @author JyHu, 15-07-28 18:07:01
     *
     *  AVCaptureVideoPreviewLayer  这个是摄像头实时获取数据显示的layer，所以没法做滤镜处理，如果只是做简单的相机的话，用这个也就够了。
     *
     *  如果想要做实时滤镜处理的话，那就用CALayer了。
     *
     *  @since  v 1.0
     */
    
#ifdef kUseCaptureVideoLayer
    self.p_captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.p_captureSession];
    self.p_captureVideoPreviewLayer.frame = view.bounds;
    self.p_captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [view.layer insertSublayer:self.p_captureVideoPreviewLayer atIndex:0];
#else
    self.p_layer = [CALayer layer];
    self.p_layer.anchorPoint = CGPointZero;
    self.p_layer.bounds = view.bounds;
    self.p_cachedPreviewView = view;
    [self.p_cachedPreviewView.layer insertSublayer:self.p_layer atIndex:0];
    [self.p_cachedPreviewView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
#endif
    
}

#ifdef kUseCaptureVideoLayer

- (void) changePreviewOrientation:(UIInterfaceOrientation)interfaceOrientation
{
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
}

#endif

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
    [self removeObserver:self.p_cachedPreviewView forKeyPath:@"frame"];
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
    self.p_filter = nil;
    self.filter = nil;
#endif
    
    self.p_ciImage = nil;
    self.p_context = nil;
    self.p_captureDevice = nil;
}

@end
