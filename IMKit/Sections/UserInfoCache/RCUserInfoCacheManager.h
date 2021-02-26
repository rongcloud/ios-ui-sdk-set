//
//  RCUserInfoCacheManager.h
//  RongIMKit
//
//  Created by 岑裕 on 16/1/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCConversationInfoCache.h"
#import "RCConversationUserInfoCache.h"
#import "RCIM.h"
#import "RCUserInfoCache.h"
#import "RCUserInfoCacheDBHelper.h"
#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

//消息分发
FOUNDATION_EXPORT NSString *const RCKitDispatchUserInfoUpdateNotification;
FOUNDATION_EXPORT NSString *const RCKitDispatchGroupUserInfoUpdateNotification;
FOUNDATION_EXPORT NSString *const RCKitDispatchGroupInfoUpdateNotification;
FOUNDATION_EXPORT NSString *const RCKitDispatchPublicServiceInfoNotification;

#define rcUserInfoWriteDBHelper ([RCUserInfoCacheManager sharedManager].writeDBHelper)
#define rcUserInfoReadDBHelper ([RCUserInfoCacheManager sharedManager].readDBHelper)
#define rcUserInfoDBQueue ([RCUserInfoCacheManager sharedManager].dbQueue)

@interface RCUserInfoCacheManager : NSObject

@property (nonatomic, strong) RCUserInfoCacheDBHelper *writeDBHelper;
@property (nonatomic, strong) RCUserInfoCacheDBHelper *readDBHelper;
@property (nonatomic, strong) dispatch_queue_t dbQueue;

+ (instancetype)sharedManager;

// appkey, token, userId, 确定存储的DB路径
@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, copy) NSString *currentUserId;

#pragma mark - UserInfo

//从cache现取，没有值直接返回nil，并调用用户信息提供者
- (RCUserInfo *)getUserInfo:(NSString *)userId;

//从cache和用户信息提供者取
- (void)getUserInfo:(NSString *)userId complete:(void (^)(RCUserInfo *userInfo))completeBlock;

//只获取当前cache中的用户信息，不进行任何回调
- (RCUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId;

- (void)updateUserInfo:(RCUserInfo *)userInfo forUserId:(NSString *)userId;

- (void)clearUserInfoNetworkCacheOnly:(NSString *)userId;

- (void)clearUserInfo:(NSString *)userId;

- (void)clearAllUserInfo;

#pragma mark - GroupUserInfo (sugar for ConversationUserInfo)

@property (nonatomic, assign) BOOL groupUserInfoEnabled;

- (RCUserInfo *)getUserInfo:(NSString *)userId inGroupId:(NSString *)groupId;

- (void)getUserInfo:(NSString *)userId
          inGroupId:(NSString *)groupId
           complete:(void (^)(RCUserInfo *userInfo))completeBlock;

- (RCUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId inGroupId:(NSString *)groupId;

- (void)updateUserInfo:(RCUserInfo *)userInfo forUserId:(NSString *)userId inGroup:(NSString *)groupId;

- (void)clearGroupUserInfoNetworkCacheOnly:(NSString *)userId inGroup:(NSString *)groupId;

- (void)clearGroupUserInfo:(NSString *)userId inGroup:(NSString *)groupId;

- (void)clearAllGroupUserInfo;

#pragma mark - GroupInfo (sugar for ConversationInfo)

- (RCGroup *)getGroupInfo:(NSString *)groupId;

- (void)getGroupInfo:(NSString *)groupId complete:(void (^)(RCGroup *groupInfo))completeBlock;

- (RCGroup *)getGroupInfoFromCacheOnly:(NSString *)groupId;

- (void)updateGroupInfo:(RCGroup *)groupInfo forGroupId:(NSString *)groupId;

- (void)clearGroupInfoNetworkCacheOnly:(NSString *)groupId;

- (void)clearGroupInfo:(NSString *)groupId;

- (void)clearAllGroupInfo;

#pragma mark - PublicServiceProfile
- (RCPublicServiceProfile *)getPublicServiceProfile:(NSString *)serviceId;

- (void)updatePublicServiceProfileInfo:(RCPublicServiceProfile *)profileInfo forServiceId:(NSString *)serviceId;

@end
