//
//  RCSightCapturer.m
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/4/24.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightCapturer.h"
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCallCenter.h>
#import "RongSightAdaptiveHeader.h"

@interface RCSightCapturer () <AVCaptureVideoDataOutputSampleBufferDelegate,
                               AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureDeviceInput *activeVideoInput;
@property (nonatomic, strong) AVCaptureDeviceInput *activeAudioInput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *activeAudioDeviceOutput;

@property (nonatomic, strong) AVCaptureDevice *audioDevice;

@property (nonatomic, strong) AVCaptureDevice *videoDevice;

@property (nonatomic, strong) dispatch_queue_t sessionQueue;

@property (nonatomic, strong) AVCaptureConnection *audioConnection;

@property (nonatomic, strong) AVCaptureConnection *videoConnection;

@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput;

@property (nonatomic, assign) AVCaptureVideoOrientation videoBufferOrientation;

@property (nonatomic, copy) NSDictionary *videoCompressionSettings;

@property (nonatomic, copy) NSDictionary *audioCompressionSettings;

@property (nonatomic, strong) NSURL *recordUrl;

@property (nonatomic, assign) BOOL addAdjustingFocusKVOFlag;

@property (nonatomic, strong) NSTimer *adjustingFocusTimeoutTimer;

@end

@implementation RCSightCapturer

- (instancetype)initWithVideoPreviewPlayer:(AVCaptureVideoPreviewLayer *)layer {
    if (self = [super init]) {
        layer.videoGravity = AVLayerVideoGravityResizeAspect;
        layer.session = self.captureSession;
        [self setupCaptureSession];
    }
    return self;
}

- (void)dealloc {
    if (self.addAdjustingFocusKVOFlag) {
        [[self activeCamera] removeObserver:self forKeyPath:@"adjustingFocus"];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Properties
- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return _captureSession;
}

- (AVCaptureDevice *)audioDevice {
    if (!_audioDevice) {
        _audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    }
    return _audioDevice;
}

- (AVCaptureDevice *)videoDevice {
    if (!_videoDevice) {
        _videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return _videoDevice;
}

- (dispatch_queue_t)sessionQueue {
    if (!_sessionQueue) {
        _sessionQueue = dispatch_queue_create("com.rongcloud.sightcapturer.session", DISPATCH_QUEUE_SERIAL);
    }
    return _sessionQueue;
}

- (AVCaptureStillImageOutput *)imageOutput {
    if (!_imageOutput) {
        _imageOutput = [[AVCaptureStillImageOutput alloc] init];
        _imageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
    }
    return _imageOutput;
}

- (NSURL *)recordUrl {
    if (!_recordUrl) {
        _recordUrl =
            [[NSURL alloc] initFileURLWithPath:[NSString pathWithComponents:@[ NSTemporaryDirectory(), @"Movie.mp4" ]]];
    }
    return _recordUrl;
}

#pragma mark - Helper
- (void)setupCaptureSession {

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(sessionWasInterrupted:)
                          name:AVCaptureSessionWasInterruptedNotification
                        object:nil];
    
    /*audio*/
    CTCallCenter *center = [[CTCallCenter alloc] init];
    if (center.currentCalls.count == 0) {   // 打电话时，麦克风被占用，不能录音，否则 15+ 系统报错
        AVCaptureDeviceInput *audioDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.audioDevice error:nil];
        BOOL isEnable = audioDeviceInput.ports.firstObject.enabled;
        if ([self.captureSession canAddInput:audioDeviceInput]) {
            [self.captureSession addInput:audioDeviceInput];
            self.activeAudioInput = audioDeviceInput;
        }

        AVCaptureAudioDataOutput *audioDeviceOutput = [[AVCaptureAudioDataOutput alloc] init];
        [audioDeviceOutput setSampleBufferDelegate:self queue:self.sessionQueue];

        if ([self.captureSession canAddOutput:audioDeviceOutput]) {
            [self.captureSession addOutput:audioDeviceOutput];
            self.activeAudioDeviceOutput = audioDeviceOutput;
        }
        self.audioConnection = [audioDeviceOutput connectionWithMediaType:AVMediaTypeAudio];
    }

    /*video*/
    AVCaptureDeviceInput *videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.videoDevice error:nil];
    if ([self.captureSession canAddInput:videoDeviceInput]) {
        [self.captureSession addInput:videoDeviceInput];
        self.activeVideoInput = videoDeviceInput;
    }

    AVCaptureVideoDataOutput *videoDeviceOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoDeviceOutput setSampleBufferDelegate:self queue:self.sessionQueue];
    videoDeviceOutput.alwaysDiscardsLateVideoFrames = NO;

    if ([self.captureSession canAddOutput:videoDeviceOutput]) {
        [self.captureSession addOutput:videoDeviceOutput];
    }

    self.videoConnection = [videoDeviceOutput connectionWithMediaType:AVMediaTypeVideo];
    
    // 视频防抖
    AVCaptureDevice *device = [self activeCamera];
    AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
    if ([device.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
        [self.videoConnection setPreferredVideoStabilizationMode:stabilizationMode];
    }

    if ([self.captureSession canAddOutput:self.imageOutput]) {
        [self.captureSession addOutput:self.imageOutput];
    }

    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;

    CMTime frameDuration = CMTimeMake(1, 30);

    NSError *error = nil;
    if ([self.videoDevice lockForConfiguration:&error]) {
        self.videoDevice.activeVideoMaxFrameDuration = frameDuration;
        self.videoDevice.activeVideoMinFrameDuration = frameDuration;
        [self.videoDevice unlockForConfiguration];
    }
    
    NSDictionary *audioSettingDic = @{
         AVFormatIDKey : @(kAudioFormatMPEG4AAC),
         AVNumberOfChannelsKey : @1,
         AVSampleRateKey : @44100,
         AVEncoderBitRateKey : @96000,
     };
    
    self.audioCompressionSettings = audioSettingDic;
    self.videoCompressionSettings =
        [[videoDeviceOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeMPEG4] copy];

    self.videoBufferOrientation = self.videoConnection.videoOrientation;

    [self focusAtPoint:CGPointMake(0.5, 0.5)];
}

- (void)teardownCaptureSession {
    if (self.captureSession) {
        self.captureSession = nil;
    }
}

- (BOOL)canSwitchCameras {
    return self.cameraCount > 1;
}

- (NSUInteger)cameraCount {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)activeCamera {
    return self.activeVideoInput.device;
}

- (AVCaptureDevice *)inactiveCamera {
    AVCaptureDevice *device = nil;
    if (self.cameraCount > 1) {
        if (AVCaptureDevicePositionBack == [self activeCamera].position) {
            device = [self cameraWithPosition:AVCaptureDevicePositionFront];
        } else {
            device = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }
    }
    return device;
}

- (void)adjustingFocusTimeout {
    [self removeAdjustingFocusObserverIfNeeded];
}

- (UIImage *)fixOrientationOfImage:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp)
        return image;

    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

#pragma mark - Api

- (NSDictionary *)recommendedVideoCompressionSettings {
    NSDictionary *systemSettings = [self.videoCompressionSettings copy];
    NSInteger height = [systemSettings[@"AVVideoHeightKey"] integerValue] / 2;
    NSInteger width = [systemSettings[@"AVVideoWidthKey"] integerValue] / 2;
    NSDictionary *settings = @{
        AVVideoCodecKey : @"avc1",
        AVVideoHeightKey : @(height),
        AVVideoWidthKey : @(width),
        AVVideoCompressionPropertiesKey : @{
            AVVideoAverageBitRateKey : @(width * height * 6),
            AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel,
            AVVideoExpectedSourceFrameRateKey : @(30), // 帧率
            AVVideoMaxKeyFrameIntervalKey : @(5) // 关键帧最大间隔，1为每个都是关键帧，数值越大压缩率越高
        }
    };
    /*
     NSMutableDictionary *settings = [[NSMutableDictionary alloc]
     initWithDictionary:self.videoCompressionSettings];
     settings[@"AVVideoCodecKey"] = @"avc1";
     settings[@"AVVideoHeightKey"] = @([settings[@"AVVideoHeightKey"] integerValue] / 2);
     settings[@"AVVideoWidthKey"] = @([settings[@"AVVideoWidthKey"] integerValue] / 2);
     settings[@"AVVideoCompressionPropertiesKey"][@"MaxKeyFrameIntervalDuration"] = @(5);
     settings[@"AVVideoCompressionPropertiesKey"][@"AverageBitRate"] = @(1024 * 1024);
     settings[@"AVVideoCompressionPropertiesKey"][@"ProfileLevel"] = @"H264_High_AutoLevel";
     [settings[@"AVVideoCompressionPropertiesKey"] removeObjectForKey:@"SoftMaxQuantizationParameter"];
     [settings[@"AVVideoCompressionPropertiesKey"] removeObjectForKey:@"SoftMinQuantizationParameter"];
     [settings[@"AVVideoCompressionPropertiesKey"] removeObjectForKey:@"RelaxAverageBitRateTarget"];
     [settings[@"AVVideoCompressionPropertiesKey"] removeObjectForKey:@"AllowOpenGOP"];
     [settings[@"AVVideoCompressionPropertiesKey"] removeObjectForKey:@"MaxQuantizationParameter"];
     [settings[@"AVVideoCompressionPropertiesKey"] removeObjectForKey:@"MinimizeMemoryUsage"];
     */
    return [settings copy]; //[self.videoCompressionSettings copy];
}

- (NSDictionary *)recommendedAudioCompressionSettings {
    return [self.audioCompressionSettings copy];
}

- (void)startRunning {
    if (![self.captureSession isRunning]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.sessionQueue, ^{
            [[AVAudioSession sharedInstance] setActive:NO error:nil];
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
            [[AVAudioSession sharedInstance] setActive:YES error:nil];
            weakSelf.captureSession.automaticallyConfiguresApplicationAudioSession = NO;
            [weakSelf.captureSession startRunning];
        });
    }
}

- (void)stopRunning {
    if ([self.captureSession isRunning]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.sessionQueue, ^{
            [weakSelf.captureSession stopRunning];
            if (RCKitConfigCenter.message.isExclusiveSoundPlayer) {
                [[AVAudioSession sharedInstance] setActive:NO error:nil];
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
                [[AVAudioSession sharedInstance] setActive:YES error:nil];
            } else {
                [[AVAudioSession sharedInstance] setActive:NO
                                               withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                                     error:nil];
            }
            [weakSelf teardownCaptureSession];
        });
    }
}

- (void)removeAdjustingFocusObserverIfNeeded {
    if (self.addAdjustingFocusKVOFlag && [self cameraSupportsTapToFocus]) {
        [[self activeCamera] removeObserver:self forKeyPath:@"adjustingFocus"];
        self.addAdjustingFocusKVOFlag = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(focusDidfinish:)]) {
                [self.delegate focusDidfinish:[self activeCamera].focusPointOfInterest];
            }
        });
    }
}

- (BOOL)resetSessionInput {
    if (![self canSwitchCameras]) {
        return NO;
    }
    if (self.adjustingFocusTimeoutTimer) {
        [self.adjustingFocusTimeoutTimer invalidate];
    }
    [self removeAdjustingFocusObserverIfNeeded];
    NSError *error;
    AVCaptureDevice *videoDevice = [self activeCamera];

    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];

    if (videoInput) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.captureSession beginConfiguration];
            [self.captureSession removeInput:self.activeVideoInput];
            if ([self.captureSession canAddInput:videoInput]) {
                [self.captureSession addInput:videoInput];
                self.activeVideoInput = videoInput;
            } else if ([self.captureSession canAddInput:self.activeVideoInput]) {
                [self.captureSession addInput:self.activeVideoInput];
            }
            [self.captureSession commitConfiguration];
        });
    } else {
        ////error
        return NO;
    }
    return YES;
}

- (void)resetAudioSession {
    CTCallCenter *center = [[CTCallCenter alloc] init];
    if (center.currentCalls.count != 0) return; // 打电话期间不需要设置 audio session
    AVCaptureDevice *newAudioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        /*audio*/
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.activeAudioInput];
        AVCaptureDeviceInput *audioDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:newAudioDevice error:nil];
        if ([self.captureSession canAddInput:audioDeviceInput]) {
            [self.captureSession addInput:audioDeviceInput];
            self.activeAudioInput = audioDeviceInput;
            _audioDevice = newAudioDevice;
        }else if ([self.captureSession canAddInput:self.activeAudioInput]) {
            [self.captureSession addInput:self.activeAudioInput];
        }
        
        AVCaptureAudioDataOutput *audioDeviceOutput = [[AVCaptureAudioDataOutput alloc] init];
        [audioDeviceOutput setSampleBufferDelegate:self queue:self.sessionQueue];
        [self.captureSession removeOutput:self.activeAudioDeviceOutput];
        if ([self.captureSession canAddOutput:audioDeviceOutput]) {
            [self.captureSession addOutput:audioDeviceOutput];
            self.activeAudioDeviceOutput = audioDeviceOutput;
        }else if ([self.captureSession canAddOutput:self.activeAudioDeviceOutput]) {
            [self.captureSession addOutput:self.activeAudioDeviceOutput];
        }
        self.audioConnection = [self.activeAudioDeviceOutput connectionWithMediaType:AVMediaTypeAudio];

        [self.captureSession commitConfiguration];
    });

}

- (BOOL)switchCamera {
    if (![self canSwitchCameras]) {
        return NO;
    }
    if (self.adjustingFocusTimeoutTimer) {
        [self.adjustingFocusTimeoutTimer invalidate];
    }
    [self removeAdjustingFocusObserverIfNeeded];
    NSError *error;
    AVCaptureDevice *videoDevice = [self inactiveCamera];

    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];

    if (videoInput) {
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.activeVideoInput];
        if ([self.captureSession canAddInput:videoInput]) {
            [self.captureSession addInput:videoInput];
            self.activeVideoInput = videoInput;
        } else if ([self.captureSession canAddInput:self.activeVideoInput]) {
            [self.captureSession addInput:self.activeVideoInput];
        }
        [self.captureSession commitConfiguration];
    } else {
        ////error
        return NO;
    }
    return YES;
}

- (BOOL)cameraSupportsTapToFocus {
    return [[self activeCamera] isFocusPointOfInterestSupported] &&
           [[self activeCamera] isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus];
}

- (void)focusAtPoint:(CGPoint)point {
    if (self.addAdjustingFocusKVOFlag) {
        return;
    }
    AVCaptureDevice *device = [self activeCamera];
    if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {

        [device addObserver:self
                 forKeyPath:@"adjustingFocus"
                    options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                    context:nil];
        self.addAdjustingFocusKVOFlag = YES;
        self.adjustingFocusTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                           target:self
                                                                         selector:@selector(adjustingFocusTimeout)
                                                                         userInfo:nil
                                                                          repeats:NO];
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.focusPointOfInterest = point;
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [device unlockForConfiguration];
        } else {
            NSLog(@"error %@", error);
        }
    }
}

- (void)captureStillImage:(AVCaptureVideoOrientation)orientation completion:(void (^)(UIImage *image))completion {

    AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];

    static NSUInteger tryCount = 0;
    if (connection.isVideoOrientationSupported) {
        connection.videoOrientation = orientation;
    }

    __weak typeof(self) weakSelf = self;
    id handler = ^(CMSampleBufferRef sampleBuffer, NSError *error) {
        if (sampleBuffer != NULL) {

            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
            /// 以 Camera 坐标系存储的图片
            UIImage *image = [[UIImage alloc] initWithData:imageData];
            /// 转化以屏幕坐标系存储
            image = [weakSelf fixOrientationOfImage:image];
            tryCount = 0;
            if (completion) {
                completion(image);
            }

        } else {
            tryCount++;
            if (tryCount > 3) {
                tryCount = 0;
                completion(nil);
                return;
            }
            NSLog(@"NULL sampleBuffer: %@", [error localizedDescription]);
            [weakSelf captureStillImage:orientation completion:completion];
        }
    };
    // Capture still image
    if (connection && connection.enabled && connection.active) {
        [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:handler];
    }
}

#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    [self.delegate didOutputSampleBuffer:sampleBuffer];
}

#pragma mark - Notification Selector
- (void)sessionWasInterrupted:(NSNotification *)notification {
    NSLog(@"Capture session was interrupted with reason: %@", notification);

    [self.captureSession removeOutput:self.audioConnection.output];
    self.audioConnection = nil;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"adjustingFocus"] && object == [self activeCamera]) {
        long oldValue = [[change objectForKey:NSKeyValueChangeOldKey] longValue];
        long newValue = [[change objectForKey:NSKeyValueChangeNewKey] longValue];
        if (oldValue == newValue) {
            return;
        }
        AVCaptureDevice *device = object;
        BOOL adjustingFocus = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (!adjustingFocus) {
            if (self.addAdjustingFocusKVOFlag) {
                [device removeObserver:self forKeyPath:@"adjustingFocus"];
                self.addAdjustingFocusKVOFlag = NO;
                [self.adjustingFocusTimeoutTimer invalidate];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(focusDidfinish:)]) {
                    [self.delegate focusDidfinish:device.focusPointOfInterest];
                }
            });
            
        }
    }
}
@end
