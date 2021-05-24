//
//  RCConversationUserInfoCache.h
//  RongIMKit
//
//  Created by 岑裕 on 16/1/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

@protocol RCConversationUserInfoUpdateDelegate <NSObject>

- (void)onConversationUserInfoUpdate:(RCUserInfo *)userInfo
                      inConversation:(RCConversationType)conversationType
                            targetId:(NSString *)targetId;

@end

@interface RCConversationUserInfoCache : NSObject

@property (nonatomic, weak) id<RCConversationUserInfoUpdateDelegate> updateDelegate;

+ (instancetype)sharedCache;

- (RCUserInfo *)getUserInfo:(NSString *)userId
           conversationType:(RCConversationType)conversationType
                   targetId:(NSString *)targetId;

- (void)updateUserInfo:(RCUserInfo *)userInfo
             forUserId:(NSString *)userId
      conversationType:(RCConversationType)conversationType
              targetId:(NSString *)targetId;

- (void)clearConversationUserInfoNetworkCacheOnly:(NSString *)userId
                                 conversationType:(RCConversationType)conversationType
                                         targetId:(NSString *)targetId;

- (void)clearConversationUserInfo:(NSString *)userId
                 conversationType:(RCConversationType)conversationType
                         targetId:(NSString *)targetId;

- (void)clearAllConversationUserInfo;

@end
