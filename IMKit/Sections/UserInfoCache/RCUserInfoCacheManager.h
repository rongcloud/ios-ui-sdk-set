//
//  RCUserInfoCacheManager.h
//  RongIMKit
//
//  Created by 岑裕 on 16/1/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCInfoNotificationCenter.h"
NS_ASSUME_NONNULL_BEGIN

@interface RCUserInfoCacheManager : NSObject

+ (instancetype)sharedManager;

#pragma mark - UserInfo

//从cache现取，没有值直接返回nil，并调用用户信息提供者
- (RCUserInfo *)getUserInfo:(NSString *)userId;

//从cache和用户信息提供者取
- (void)getUserInfo:(NSString *)userId complete:(void (^)(RCUserInfo *userInfo))completeBlock;

//只获取当前cache中的用户信息，不进行任何回调
- (RCUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId;

- (void)updateUserInfo:(RCUserInfo *)userInfo forUserId:(NSString *)userId;

- (void)clearUserInfo:(NSString *)userId;

- (void)clearAllUserInfo;

#pragma mark - GroupUserInfo (sugar for ConversationUserInfo)

- (RCUserInfo *)getUserInfo:(NSString *)userId inGroupId:(NSString *)groupId;

- (void)getUserInfo:(NSString *)userId
          inGroupId:(NSString *)groupId
           complete:(void (^)(RCUserInfo *userInfo))completeBlock;

- (RCUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId inGroupId:(NSString *)groupId;

- (void)updateUserInfo:(RCUserInfo *)userInfo forUserId:(NSString *)userId inGroup:(NSString *)groupId;

- (void)clearGroupUserInfo:(NSString *)userId inGroup:(NSString *)groupId;

- (void)clearAllGroupUserInfo;

#pragma mark - GroupInfo (sugar for ConversationInfo)

- (RCGroup *)getGroupInfo:(NSString *)groupId;

- (void)getGroupInfo:(NSString *)groupId complete:(void (^)(RCGroup *groupInfo))completeBlock;

- (RCGroup *)getGroupInfoFromCacheOnly:(NSString *)groupId;

- (void)updateGroupInfo:(RCGroup *)groupInfo forGroupId:(NSString *)groupId;

- (void)clearGroupInfo:(NSString *)groupId;

- (void)clearAllGroupInfo;

#pragma mark - PublicServiceProfile
- (RCPublicServiceProfile *)getPublicServiceProfile:(NSString *)serviceId;

- (void)updatePublicServiceProfileInfo:(RCPublicServiceProfile *)profileInfo forServiceId:(NSString *)serviceId;

@end

NS_ASSUME_NONNULL_END
