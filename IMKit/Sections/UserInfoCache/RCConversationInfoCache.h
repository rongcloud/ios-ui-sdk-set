//
//  RCConversationInfoCache.h
//  RongIMKit
//
//  Created by 岑裕 on 16/1/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCConversationInfo.h"
#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

@protocol RCConversationInfoUpdateDelegate <NSObject>

- (void)onConversationInfoUpdate:(RCConversationInfo *)conversationInfo;

@end

@interface RCConversationInfoCache : NSObject

@property (nonatomic, weak) id<RCConversationInfoUpdateDelegate> updateDelegate;

+ (instancetype)sharedCache;

- (RCConversationInfo *)getConversationInfo:(RCConversationType)conversationType targetId:(NSString *)targetId;

- (void)updateConversationInfo:(RCConversationInfo *)conversationInfo
              conversationType:(RCConversationType)conversationType
                      targetId:(NSString *)targetId;

- (void)clearConversationInfoNetworkCacheOnly:(RCConversationType)conversationType targetId:(NSString *)targetId;

- (void)clearConversationInfo:(RCConversationType)conversationType targetId:(NSString *)targetId;

- (void)clearAllConversationInfo;

@end
