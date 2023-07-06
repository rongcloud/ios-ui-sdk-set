//
//  RCSightRecorder.m
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/4/24.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightRecorder.h"

CGAffineTransform transformBaseOnCaptureOrientation(AVCaptureVideoOrientation orientation) {
    CGAffineTransform result;

    switch (orientation) {

    case AVCaptureVideoOrientationLandscapeLeft:
        result = CGAffineTransformMakeRotation(M_PI);
        break;
    case AVCaptureVideoOrientationPortraitUpsideDown:
        result = CGAffineTransformMakeRotation((M_PI_2 * 3));
        break;

    case AVCaptureVideoOrientationPortrait:
        result = CGAffineTransformMakeRotation(M_PI_2);
        break;

    default: /// landscape left
        result = CGAffineTransformIdentity;
        break;
    }

    return result;
}

@interface RCSightRecorder ()

@property (strong, nonatomic) AVAssetWriter *assetWriter;
@property (strong, nonatomic) AVAssetWriterInput *assetWriterVideoInput;
@property (strong, nonatomic) AVAssetWriterInput *assetWriterAudioInput;
@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor *assetWriterInputPixelBufferAdaptor;
@property (strong, nonatomic) dispatch_queue_t dispatchQueue;
@property (strong, nonatomic) NSDictionary *videoSettings;
@property (strong, nonatomic) NSDictionary *audioSettings;
@property (nonatomic) BOOL isWriting;
@property (nonatomic) BOOL firstSample;

@end

@implementation RCSightRecorder

- (instancetype)initWithVideoSettings:(NSDictionary *)videoSettings
                        audioSettings:(NSDictionary *)audioSettings
                        dispatchQueue:(dispatch_queue_t)dispatchQueue {
    if (self = [super init]) {
        self.videoSettings = [videoSettings copy];
        self.audioSettings = [audioSettings copy];
        self.dispatchQueue = dispatchQueue;
        self.firstSample = YES;
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self
                          selector:@selector(sessionWasInterrupted:)
                              name:AVCaptureSessionWasInterruptedNotification
                            object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Api

- (void)prepareToRecord:(AVCaptureVideoOrientation)orientation {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.dispatchQueue, ^{

        NSError *error = nil;

        NSString *fileType = AVFileTypeMPEG4;
        weakSelf.assetWriter = [AVAssetWriter assetWriterWithURL:[weakSelf outputURL] fileType:fileType error:&error];
        if (!weakSelf.assetWriter || error) {
            NSString *formatString = @"Could not create AVAssetWriter: %@";
            NSLog(@"%@", [NSString stringWithFormat:formatString, error]);
            return;
        }

        weakSelf.assetWriterVideoInput =
            [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:weakSelf.videoSettings];
        weakSelf.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        weakSelf.assetWriterVideoInput.transform = transformBaseOnCaptureOrientation(orientation);

        NSDictionary *attributes = @{
            (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
            (id)kCVPixelBufferWidthKey : weakSelf.videoSettings[AVVideoWidthKey],
            (id)kCVPixelBufferHeightKey : weakSelf.videoSettings[AVVideoHeightKey],
            (id)kCVPixelFormatOpenGLESCompatibility : (id)kCFBooleanTrue
        };

        weakSelf.assetWriterInputPixelBufferAdaptor =
            [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:weakSelf.assetWriterVideoInput
                                                       sourcePixelBufferAttributes:attributes];

        if ([weakSelf.assetWriter canAddInput:weakSelf.assetWriterVideoInput]) {
            [weakSelf.assetWriter addInput:weakSelf.assetWriterVideoInput];
        } else {
            NSLog(@"Unable to add video input.");
            return;
        }
        if (weakSelf.audioSettings) {
            weakSelf.assetWriterAudioInput =
                [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:weakSelf.audioSettings];
            weakSelf.assetWriterAudioInput.expectsMediaDataInRealTime = YES;
            if ([weakSelf.assetWriter canAddInput:weakSelf.assetWriterAudioInput]) {
                [weakSelf.assetWriter addInput:weakSelf.assetWriterAudioInput];
            } else {
                NSLog(@"Unable to add audio input.");
            }
        }

        weakSelf.firstSample = YES;
        weakSelf.isWriting = YES;
    });
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!self.isWriting) {
        return;
    }

    CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);

    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDesc);

    if (mediaType == kCMMediaType_Video) {

        CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);

        if (self.firstSample) {
            if ([self.assetWriter startWriting]) {
                [self.assetWriter startSessionAtSourceTime:timestamp];
            } else {
                NSLog(@"Failed to start writing.");
            }
            self.firstSample = NO;
        }

        CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

        if (self.assetWriterVideoInput.readyForMoreMediaData) {
            if (![self.assetWriterInputPixelBufferAdaptor appendPixelBuffer:imageBuffer
                                                       withPresentationTime:timestamp]) {
                NSLog(@"Error appending pixel buffer.");
            }
        }

    } else if (!self.firstSample && mediaType == kCMMediaType_Audio) {
        if (self.assetWriterAudioInput.isReadyForMoreMediaData) {
            if (![self.assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
                NSLog(@"Error appending audio sample buffer.");
            }
        }
    }
}

- (void)finishRecording {
    dispatch_async(self.dispatchQueue, ^{
        self.isWriting = NO;
        if (self.assetWriter.status == AVAssetWriterStatusWriting) {
            [self.assetWriter finishWritingWithCompletionHandler:^{
                if (self.assetWriter.status == AVAssetWriterStatusCompleted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSURL *fileURL = [self.assetWriter outputURL];
                        [self.delegate sightRecorder:self didWriteMovieAtURL:fileURL];
                    });
                } else {
                    [self reportFailedWith:self.assetWriter.error status:self.assetWriter.status];
                }
            }];
        } else {
            [self reportFailedWith:self.assetWriter.error status:self.assetWriter.status];
        }
    });
}

- (void)reportFailedWith:(NSError *)error status:(NSInteger)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(sightRecorder:didFailWithError:status:)]) {
            [self.delegate sightRecorder:self didFailWithError:error status:status];
        }
    });
}
#pragma mark - helpers
- (NSURL *)outputURL {
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    long long totalMilliseconds = interval * 1000;
    NSString *sightFileName = [NSString stringWithFormat:@"sight_%lld.mp4", totalMilliseconds];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:sightFileName];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    return url;
}

#pragma mark - Notification Selector
- (void)sessionWasInterrupted:(NSNotification *)notification {
}

@end
