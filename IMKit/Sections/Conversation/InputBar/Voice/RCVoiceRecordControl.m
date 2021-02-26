//
//  RCVoiceRecordControl.m
//  RongIMKit
//
//  Created by 张改红 on 2020/5/25.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCVoiceRecordControl.h"

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "RCExtensionService.h"
#import "RCVoiceCaptureControl.h"
#import "RCAlertView.h"
#import "RCVoicePlayer.h"
#import "RCKitCommonDefine.h"

@interface RCVoiceRecordControl () <RCVoiceCaptureControlDelegate>
@property (nonatomic, assign) RCConversationType conversationType;
@property (nonatomic, strong) RCVoiceCaptureControl *voiceCaptureControl;
@property (nonatomic, assign) BOOL isAudioRecoderTimeOut;
@end

@implementation RCVoiceRecordControl
- (instancetype)initWithConversationType:(RCConversationType)conversationType {
    self = [super init];
    if (self) {
        self.conversationType = conversationType;
        self.isAudioRecoderTimeOut = NO;
        [self registerNotification];
    }
    return self;
}

//语音消息开始录音
- (void)onBeginRecordEvent {
    if (self.voiceCaptureControl) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(recordWillBegin)]) {
        if (![self.delegate recordWillBegin]) {
            return;
        }
    }

    if ([[RCExtensionService sharedService] isAudioHolding]) {
        NSString *alertMessage = RCLocalizedString(@"AudioHoldingWarning");
        [RCAlertView showAlertController:alertMessage message:nil hiddenAfterDelay:1];
        return;
    }

    [self checkRecordPermission:^{
        self.voiceCaptureControl =
            [[RCVoiceCaptureControl alloc] initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width,
                                                                    [UIScreen mainScreen].bounds.size.height)
                                        conversationType:self.conversationType];
        self.voiceCaptureControl.delegate = self;
        if ([RCVoicePlayer defaultPlayer].isPlaying) {
            [[RCVoicePlayer defaultPlayer] resetPlayer];
        }
        [self.voiceCaptureControl startRecord];
        if ([self.delegate respondsToSelector:@selector(voiceRecordControlDidBegin:)]) {
            [self.delegate voiceRecordControlDidBegin:self];
        }
    }];
}

//语音消息录音结束
- (void)onEndRecordEvent {
    if (!self.voiceCaptureControl) {
        return;
    }

    NSData *recordData = [self.voiceCaptureControl stopRecord];
    if (self.voiceCaptureControl.duration > 1.0f && nil != recordData) {
        if ([self.delegate respondsToSelector:@selector(voiceRecordControl:didEnd:duration:error:)]) {
            [self.delegate voiceRecordControl:self
                                       didEnd:recordData
                                     duration:self.voiceCaptureControl.duration
                                        error:nil];
        }
        [self destroyVoiceCaptureControl];
    } else {
        // message too short
        if (!self.isAudioRecoderTimeOut) {
            self.isAudioRecoderTimeOut = NO;
            [self.voiceCaptureControl showMsgShortView];
            [self performSelector:@selector(destroyVoiceCaptureControl) withObject:nil afterDelay:1.0f];
            if ([self.delegate respondsToSelector:@selector(voiceRecordControlDidCancel:)]) {
                [self.delegate voiceRecordControlDidCancel:self];
            }
        }
    }
}

//滑出显示
- (void)dragExitRecordEvent {
    [self.voiceCaptureControl showCancelView];
}

- (void)dragEnterRecordEvent {
    [self.voiceCaptureControl hideCancelView];
}

- (void)onCancelRecordEvent {
    if (self.voiceCaptureControl) {
        if ([self.delegate respondsToSelector:@selector(voiceRecordControlDidCancel:)]) {
            [self.delegate voiceRecordControlDidCancel:self];
        }
        [self.voiceCaptureControl cancelRecord];
        [self destroyVoiceCaptureControl];
    }
}

#pragma mark - RCVoiceCaptureControlDelegate
- (void)RCVoiceCaptureControlTimeout:(double)duration {
    self.isAudioRecoderTimeOut = YES;
    [self onEndRecordEvent];
}

- (void)RCVoiceCaptureControlTimeUpdate:(double)duration {
}

#pragma mark - Notification
- (void)registerNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(audioSessionInterrupted:)
        name:AVAudioSessionInterruptionNotification
      object:nil];
}

- (void)audioSessionInterrupted:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType interruptionType = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    switch (interruptionType) {
    case AVAudioSessionInterruptionTypeBegan: {
        [self onEndRecordEvent];
    } break;
    default:
        break;
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private
- (void)destroyVoiceCaptureControl {
    [self.voiceCaptureControl stopTimer];
    [self.voiceCaptureControl removeFromSuperview];
    self.voiceCaptureControl = nil;
    self.isAudioRecoderTimeOut = NO;
}

- (void)checkRecordPermission:(void (^)(void))successBlock {
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(recordPermission)]) {
            if ([AVAudioSession sharedInstance].recordPermission == AVAudioSessionRecordPermissionGranted) {
                successBlock();
            } else if ([AVAudioSession sharedInstance].recordPermission == AVAudioSessionRecordPermissionDenied) {
                [self alertRecordPermissionDenied];
            } else if ([AVAudioSession sharedInstance].recordPermission == AVAudioSessionRecordPermissionUndetermined) {
                [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                    if (!granted) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self alertRecordPermissionDenied];
                        });
                    };
                }];
            }
        }
    } else {
        successBlock();
    }
}

- (void)alertRecordPermissionDenied {
    [RCAlertView showAlertController:RCLocalizedString(@"AccessRightTitle")
                             message:RCLocalizedString(@"speakerAccessRight")
                         cancelTitle:RCLocalizedString(@"OK")];
}
@end
