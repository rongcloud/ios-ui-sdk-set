//
//  RCUserInfoCache.h
//  RongIMKit
//
//  Created by 岑裕 on 16/1/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

@protocol RCUserInfoUpdateDelegate <NSObject>

- (void)onUserInfoUpdate:(RCUserInfo *)userInfo;

@end

@interface RCUserInfoCache : NSObject

@property (nonatomic, weak) id<RCUserInfoUpdateDelegate> updateDelegate;

+ (instancetype)sharedCache;

- (RCUserInfo *)getUserInfo:(NSString *)userId;

- (void)updateUserInfo:(RCUserInfo *)userInfo forUserId:(NSString *)userId;

- (void)clearUserInfoNetworkCacheOnly:(NSString *)userId;

- (void)clearUserInfo:(NSString *)userId;

- (void)clearAllUserInfo;

@end
