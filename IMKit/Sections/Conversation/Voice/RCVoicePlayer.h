//
//  RCVoicePlayer.h
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCMessageModel.h"

/// 语音消息播放停止的Notification
UIKIT_EXTERN NSString *const kNotificationVoiceWillPlayNotification;
UIKIT_EXTERN NSString *const kRCContinuousPlayNotification;

@protocol RCVoicePlayerObserver;
@interface RCVoicePlayer : NSObject

@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, assign) long messageId;
@property (nonatomic, assign) RCConversationType conversationType;
@property (nonatomic, copy) NSString *targetId;

+ (RCVoicePlayer *)defaultPlayer;

- (void)playAudio:(RCMessageModel *)model;

//- (BOOL)playVoice:(NSString *)messageId voiceData:(NSData *)data observer:(id<RCVoicePlayerObserver>)observer;
- (BOOL)playVoice:(RCConversationType)conversationType
         targetId:(NSString *)targetId
        messageId:(long)messageId
        voiceData:(NSData *)data
         observer:(id<RCVoicePlayerObserver>)observer;

- (void)stopPlayVoice;

- (void)resetPlayer;

@end

@protocol RCVoicePlayerObserver <NSObject>

- (void)PlayerDidFinishPlaying:(BOOL)isFinish;

- (void)audioPlayerDecodeErrorDidOccur:(NSError *)error;

@end
