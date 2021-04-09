//
//  RCVoiceRecorder.m
//  RongExtensionKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCVoiceRecorder.h"
#import "RCExtensionService.h"
#import <AVFoundation/AVFoundation.h>
#import "RCKitConfig.h"
#import "RCKitCommonDefine.h"

static RCVoiceRecorder *rcVoiceRecorderHandler = nil;
static RCVoiceRecorder *rcHQVoiceRecorderHandler = nil;

@interface RCVoiceRecorder () <AVAudioRecorderDelegate>

@property (nonatomic, strong) NSDictionary *recordSettings;
@property (nonatomic, strong) NSURL *recordTempFileURL;
@property (nonatomic) BOOL isRecording;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, weak) id<RCVoiceRecorderDelegate> voiceRecorderDelegate;
@end

@implementation RCVoiceRecorder
#pragma mark - Public Methods
+ (RCVoiceRecorder *)defaultVoiceRecorder {
    @synchronized(self) {
        if (nil == rcVoiceRecorderHandler) {
            rcVoiceRecorderHandler = [[[self class] alloc] init];
            NSInteger sample = 8000.00f;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            switch ([RCIMClient sharedRCIMClient].sampleRate) {
#pragma clang diagnostic pop
            case RCSample_Rate_8000:
                sample = 8000.00f;
                break;
            case RCSample_Rate_16000:
                sample = 16000.00f;
                break;
            default:
                break;
            }
            rcVoiceRecorderHandler.recordSettings = @{
                AVFormatIDKey : @(kAudioFormatLinearPCM),
                AVSampleRateKey : @(sample),
                AVNumberOfChannelsKey : @1,
                AVLinearPCMIsNonInterleaved : @NO,
                AVLinearPCMIsFloatKey : @NO,
                AVLinearPCMIsBigEndianKey : @NO
            };

            rcVoiceRecorderHandler.recordTempFileURL =
                [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"tempAC.wav"]];
            DebugLog(@"[RongExtensionKit]: Using File called: %@", rcVoiceRecorderHandler.recordTempFileURL);
        }
        return rcVoiceRecorderHandler;
    }
}

+ (RCVoiceRecorder *)hqVoiceRecorder {
    @synchronized(self) {
        if (nil == rcHQVoiceRecorderHandler) {
            rcHQVoiceRecorderHandler = [[[self class] alloc] init];
            rcHQVoiceRecorderHandler.recordSettings = @{
                AVFormatIDKey : @(kAudioFormatMPEG4AAC_HE),
                AVNumberOfChannelsKey : @1,
                AVEncoderBitRateKey : @(32000)
            };
            rcHQVoiceRecorderHandler.recordTempFileURL =
                [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"HQTempAC.m4a"]];
            DebugLog(@"[RongExtensionKit]: Using File called: %@", rcHQVoiceRecorderHandler.recordTempFileURL);
        }
        return rcHQVoiceRecorderHandler;
    }
}

- (BOOL)startRecordWithObserver:(id<RCVoiceRecorderDelegate>)observer {
    self.voiceRecorderDelegate = observer;

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioSession setActive:YES error:nil];

    NSError *error = nil;

    if (nil == self.recorder) {
        self.recorder =
            [[AVAudioRecorder alloc] initWithURL:self.recordTempFileURL settings:self.recordSettings error:&error];
        self.recorder.delegate = self;
        self.recorder.meteringEnabled = YES;
    }

    BOOL isRecord = NO;
    isRecord = [self.recorder prepareToRecord];
    DebugLog(@"[RongExtensionKit]: prepareToRecord is %@", isRecord ? @"success" : @"failed");

    isRecord = [self.recorder record];
    DebugLog(@"[RongExtensionKit]: record is %@", isRecord ? @"success" : @"failed");
    self.isRecording = self.recorder.isRecording;
    return isRecord;
}

- (BOOL)cancelRecord {
    self.voiceRecorderDelegate = nil;
    if (nil != self.recorder && [self.recorder isRecording] &&
        [[NSFileManager defaultManager] fileExistsAtPath:self.recorder.url.path]) {
        [self.recorder stop];
        [self.recorder deleteRecording];
        self.recorder = nil;
        self.isRecording = self.recorder.isRecording;
        if (!RCKitConfigCenter.message.isExclusiveSoundPlayer) {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [[AVAudioSession sharedInstance] setActive:NO
                                           withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                                 error:nil];
        } else {
            AVAudioSession *audioSession = [AVAudioSession sharedInstance];
            [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
            [audioSession setActive:YES error:nil];
        }
        return YES;
    }
    if (!RCKitConfigCenter.message.isExclusiveSoundPlayer) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:NO
                                       withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                             error:nil];
    } else {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
        [audioSession setActive:YES error:nil];
    }
    return NO;
}
- (void)stopRecord:(void (^)(NSData *, NSTimeInterval))compeletion {
    if (!self.recorder.url)
        return;
    NSURL *url = [[NSURL alloc] initWithString:self.recorder.url.absoluteString];
    NSTimeInterval audioLength = self.recorder.currentTime;
    [self.recorder stop];
    NSData *currentRecordData = [NSData dataWithContentsOfURL:url];
    self.isRecording = self.recorder.isRecording;
    self.recorder = nil;
    //非独占式播放音频需要释放AVAudioSession
    if (!RCKitConfigCenter.message.isExclusiveSoundPlayer) {
        [[AVAudioSession sharedInstance] setActive:NO
                                       withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                             error:nil];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];

    } else {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
        [audioSession setActive:YES error:nil];
    }

    compeletion(currentRecordData, audioLength);
}
- (CGFloat)updateMeters {
    if (nil != self.recorder) {
        [self.recorder updateMeters];
    }

    float peakPower = [self.recorder averagePowerForChannel:0];
    CGFloat power = (1.0 / 160.0) * (peakPower + 160.0);
    return power;
}
#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if ([self.voiceRecorderDelegate respondsToSelector:@selector(RCVoiceAudioRecorderDidFinishRecording:)]) {
        [self.voiceRecorderDelegate RCVoiceAudioRecorderDidFinishRecording:flag];
    }
    self.voiceRecorderDelegate = nil;
    self.isRecording = self.recorder.isRecording;
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    if ([self.voiceRecorderDelegate respondsToSelector:@selector(RCVoiceAudioRecorderEncodeErrorDidOccur:)]) {
        [self.voiceRecorderDelegate RCVoiceAudioRecorderEncodeErrorDidOccur:error];
    }

    self.voiceRecorderDelegate = nil;
    self.isRecording = self.recorder.isRecording;
}
@end
