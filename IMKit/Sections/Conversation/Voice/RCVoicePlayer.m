//
//  RCVoicePlayer.m
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCVoicePlayer.h"
#import "RCIM.h"
#import <AVFoundation/AVFoundation.h>
#import "RCKitConfig.h"
#import "RCKitCommonDefine.h"
#import "RCHQVoiceMsgDownloadManager.h"

NSString *const kRCContinuousPlayNotification = @"RCContinuousPlayNotification";
NSString *const kNotificationStopVoicePlayer = @"kNotificationStopVoicePlayer";
NSString *const kNotificationVoiceWillPlayNotification = @"kNotificationVoiceWillPlayNotification";
NSString *const kNotificationPlayVoice = @"kNotificationPlayVoice";
static BOOL bSensorStateStart = YES;
static RCVoicePlayer *rcVoicePlayerHandler = nil;

@interface RCVoicePlayer () <AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic, weak) id<RCVoicePlayerObserver> voicePlayerObserver;
@property (nonatomic) NSString *playerCategory;
- (void)enableSystemProperties;
- (void)setDefaultAudioSession:(NSString *)category;
- (void)disableSystemProperties;
- (BOOL)startPlayVoice:(NSData *)data;
@end

@implementation RCVoicePlayer

+ (RCVoicePlayer *)defaultPlayer {
    @synchronized(self) {
        if (nil == rcVoicePlayerHandler) {
            rcVoicePlayerHandler = [[[self class] alloc] init];
            rcVoicePlayerHandler.playerCategory = AVAudioSessionCategoryPlayback;
        }
    }
    return rcVoicePlayerHandler;
}

- (void)setDefaultAudioSession:(NSString *)category {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    DebugLog(@"[RongIMKit]: [audioSession category ] %@", [audioSession category]);
    //    //默认情况下扬声器播放，如果当前audioSession状态是AVAudioSessionCategoryRecord，证明正在录音，不要设置category
    //    if(![[audioSession category ] isEqualToString:AVAudioSessionCategoryRecord])
    [audioSession setCategory:category
                        error:nil]; // 2016-12-05,edit by dulizhao ,设置category，在手机静音的情况下也可播放声音。
    [audioSession setActive:YES error:nil];
}

//处理监听触发事件
- (void)sensorStateChange:(NSNotification *)notification {
    if (bSensorStateStart) {
        bSensorStateStart = NO;

        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[UIDevice currentDevice] proximityState] == YES) {
                self.playerCategory = AVAudioSessionCategoryPlayAndRecord;
                DebugLog(@"[RongIMKit]: Device is close to user");
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
            } else {
                DebugLog(@"[RongIMKit]: Device is not close to user");
                self.playerCategory = AVAudioSessionCategoryPlayback;
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            }
            bSensorStateStart = YES;
        });
    }
}

- (void)playAudio:(RCMessageModel *)model {
    [self sendVoiceWillPlayNotification:model];
    if ([model.content isKindOfClass:RCVoiceMessage.class]) {
        [self playNormalVoiceMessage:model];
    } else if ([model.content isKindOfClass:RCHQVoiceMessage.class]) {
        [self playHQVoiceMessage:model];
    } else {
        DebugLog(@"[RongIMKit]:  messages are not supported play");
    }
}

- (void)playNormalVoiceMessage:(RCMessageModel *)model {
    RCVoiceMessage *voiceContent = (RCVoiceMessage *)model.content;
    if (voiceContent.wavAudioData) {
        [self playVoice:model.conversationType targetId:model.targetId messageId:model.messageId voiceData:voiceContent.wavAudioData observer:nil];
    } else {
        DebugLog(@"[RongIMKit]: RCVoiceMessage.voiceData is NULL");
    }
}

- (void)playHQVoiceMessage:(RCMessageModel *)model {
    RCHQVoiceMessage *voiceContent = (RCHQVoiceMessage *)model.content;
    if (voiceContent.localPath > 0 && [[NSFileManager defaultManager] fileExistsAtPath:voiceContent.localPath]) {
        NSError *error;
        NSData *wavAudioData =
            [[NSData alloc] initWithContentsOfFile:voiceContent.localPath options:NSDataReadingMappedAlways error:&error];
        [self playVoice:model.conversationType targetId:model.targetId messageId:model.messageId voiceData:wavAudioData observer:nil];
    } else {
        self.messageId = model.messageId;
        self.conversationType = model.conversationType;
        self.targetId = model.targetId;
        [[RCCoreClient sharedCoreClient] getMessage:model.messageId completion:^(RCMessage * _Nullable message) {
            if (message) {
                [[RCHQVoiceMsgDownloadManager defaultManager] pushVoiceMsgs:@[message] priority:YES];
            }
        }];
    }
}

- (BOOL)playVoice:(RCConversationType)conversationType
         targetId:(NSString *)targetId
        messageId:(long)messageId
        voiceData:(NSData *)data
         observer:(id<RCVoicePlayerObserver>)observer {
    if (self.isPlaying) {
        [self resetPlayer];
    }

    self.voicePlayerObserver = observer;
    self.messageId = messageId;
    self.conversationType = conversationType;
    self.targetId = targetId;
    [self enableSystemProperties];
    [self setDefaultAudioSession:_playerCategory];
    return [self startPlayVoice:data];
}

//停止播放
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    DebugLog(@"%s", __FUNCTION__);

    self.isPlaying = self.audioPlayer.playing;
    [self disableSystemProperties];

    // notify at the end
    if ([self.voicePlayerObserver respondsToSelector:@selector(PlayerDidFinishPlaying:)]) {
        [self.voicePlayerObserver PlayerDidFinishPlaying:flag];
    }

    // set the observer to nil
    self.voicePlayerObserver = nil;
    self.audioPlayer = nil;
    if (!RCKitConfigCenter.message.isExclusiveSoundPlayer) {
        [[AVAudioSession sharedInstance] setActive:NO
                                       withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                             error:nil];
    } else {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
        [audioSession setActive:YES error:nil];
    }
    [self sendPlayFinishNotification];
    [self sendContinuousPlayNotification];
}

- (void)sendContinuousPlayNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kRCContinuousPlayNotification
                                                        object:@(self.messageId)
                                                      userInfo:@{
        @"conversationType" : @(self.conversationType),
        @"targetId" : self.targetId
    }];
}

- (void)sendVoiceWillPlayNotification:(RCMessageModel *)model {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationVoiceWillPlayNotification
                                                        object:@(model.messageId)
                                                      userInfo:@{
                                                          @"conversationType" : @(model.conversationType),
                                                          @"targetId" : model.targetId
                                                      }];
}

- (void)sendPlayStartNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationPlayVoice
                                                        object:@(self.messageId)
                                                      userInfo:@{
                                                          @"conversationType" : @(self.conversationType),
                                                          @"targetId" : self.targetId
                                                      }];
}

- (void)sendPlayFinishNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationStopVoicePlayer
                                                        object:@(self.messageId)
                                                      userInfo:@{
                                                          @"conversationType" : @(self.conversationType),
                                                          @"targetId" : self.targetId
                                                      }];
}
//播放错误
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    DebugLog(@"%s", __FUNCTION__);
    // do something
    self.isPlaying = self.audioPlayer.playing;
    [self disableSystemProperties];

    // notify at the end
    if ([self.voicePlayerObserver respondsToSelector:@selector(audioPlayerDecodeErrorDidOccur:)]) {
        [self.voicePlayerObserver audioPlayerDecodeErrorDidOccur:error];
    }
    self.voicePlayerObserver = nil;
    self.audioPlayer = nil;
    if (!RCKitConfigCenter.message.isExclusiveSoundPlayer) {
        [[AVAudioSession sharedInstance] setActive:NO
                                       withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                             error:nil];
    } else {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
        [audioSession setActive:YES error:nil];
    }
    [self sendPlayFinishNotification];
}

- (BOOL)startPlayVoice:(NSData *)data {
    NSError *error = nil;

    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
    self.audioPlayer.delegate = self;
    self.audioPlayer.volume = 1.0;

    BOOL ready = NO;
    if (!error) {

        DebugLog(@"[RongIMKit]: init AudioPlayer %@", error);

        ready = [self.audioPlayer prepareToPlay];
        DebugLog(@"[RongIMKit]: prepare audio player %@", ready ? @"success" : @"failed");
        ready = [self.audioPlayer play];
        DebugLog(@"[RongIMKit]: async play is %@", ready ? @"success" : @"failed");
        if (ready) {
            [self sendPlayStartNotification];
        }
    }
    self.isPlaying = self.audioPlayer.playing;
    DebugLog(@"self.isPlaying > %d", self.isPlaying);
    DebugLog(@"[RongIMKit]: [audioSession category ] %@", [[AVAudioSession sharedInstance] category]);
    return ready;
}

- (void)stopPlayVoice {
    [self resetPlayer];
    if (!RCKitConfigCenter.message.isExclusiveSoundPlayer) {
        [[AVAudioSession sharedInstance] setActive:NO
                                       withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                             error:nil];
    } else {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
        [audioSession setActive:YES error:nil];
    }
}

- (void)resetPlayer {
    if (nil != self.audioPlayer && self.audioPlayer.playing) {
        [self.audioPlayer stop];
        self.audioPlayer = nil;

        [self sendPlayFinishNotification];
        [self disableSystemProperties];
    }
    self.isPlaying = self.audioPlayer.playing;
    self.voicePlayerObserver = nil;
}

- (void)enableSystemProperties {
    [[UIDevice currentDevice]
        setProximityMonitoringEnabled:YES]; //建议在播放之前设置yes，播放结束设置NO，这个功能是开启红外感应
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceProximityStateDidChangeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sensorStateChange:)
                                                 name:UIDeviceProximityStateDidChangeNotification
                                               object:nil];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}
- (void)disableSystemProperties {
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC));
    dispatch_after(time, dispatch_get_main_queue(), ^(void) {
        if (!self.isPlaying) {
            self.playerCategory = AVAudioSessionCategoryPlayback;
            [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:UIDeviceProximityStateDidChangeNotification
                                                          object:nil];
        }
    });
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

@end
