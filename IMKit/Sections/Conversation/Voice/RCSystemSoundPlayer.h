//
//  RCSystemSoundPlayer.h
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

typedef void (^RCSystemSoundPlayerCompletion)(BOOL complete);

@interface RCSystemSoundPlayer : NSObject

+ (RCSystemSoundPlayer *)defaultPlayer;

- (void)setSystemSoundPath:(NSString *)path;

- (void)playSoundByMessage:(RCMessage *)rcMessage completeBlock:(RCSystemSoundPlayerCompletion)completion;

/**
 * 设置忽略响铃的会话
 */
- (void)setIgnoreConversationType:(RCConversationType)conversationType targetId:(NSString *)targetId;

/**
 * 清除忽略响铃的会话
 */
- (void)resetIgnoreConversation;

@end
