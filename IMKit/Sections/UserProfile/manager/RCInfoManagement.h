//
//  RCInfoManagement.h
//  RongIMKit
//
//  Created by zgh on 2024/8/29.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCInfoManagement : NSObject

+ (instancetype)sharedInstance;

#pragma mark -- userInfo

//从cache现取，没有值直接返回nil，并调用信息托管接口
- (nullable RCUserInfo *)getUserInfo:(NSString *)userId;

//仅从 cache 取
- (nullable RCUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId;

- (void)getUserInfo:(NSString *)userId complete:(nullable void (^)(RCUserInfo *user))complete;

/// 加载用户信息（优先使用缓存，缓存未命中自动触发网络请求）
/// @param userIds 用户ID数组
/// @note 数据更新后会发送通知
- (void)loadUserInfos:(NSArray<NSString *> *)userIds;

- (void)refreshUserInfo:(RCUserInfo *)userInfo;

- (void)clearUserInfo:(NSString *)userId;

- (void)clearAllUserInfo;

#pragma mark -- groupMember

//仅从 cache 取
- (nullable RCUserInfo *)getGroupMemberFromCacheOnly:(NSString *)userId withGroupId:(NSString *)groupId;

//从cache现取，没有值直接返回nil，并调用信息托管接口
- (nullable RCUserInfo *)getGroupMember:(NSString *)userId withGroupId:(NSString *)groupId;

- (void)getGroupMember:(NSString *)userId withGroupId:(NSString *)groupId complete:(nullable void (^)( RCUserInfo *_Nullable user))complete;

/// 加载群成员信息（优先使用缓存，缓存未命中自动触发网络请求）
/// @param userIds 用户ID数组
/// @param groupId 群组ID
/// @note 数据更新后会发送通知
- (void)preloadGroupMembers:(NSArray<NSString *> *)userIds
                 inGroup:(NSString *)groupId;

- (void)refreshGroupMember:(RCUserInfo *)userInfo withGroupId:(NSString *)groupId;

- (void)clearGroupMember:(NSString *)userId inGroup:(NSString *)groupId;

- (void)clearAllGroupMember;

#pragma mark -- group

//从cache现取，没有值直接返回nil，并调用信息托管接口
- (nullable RCGroup *)getGroupInfo:(NSString *)groupId;

//仅从 cache 取
- (nullable RCGroup *)getGroupInfoFromCacheOnly:(NSString *)groupId;

- (void)getGroupInfo:(NSString *)groupId complete:(nullable void (^)(RCGroup * _Nullable group))complete;

/// 加载群组信息（优先使用缓存，缓存未命中自动触发网络请求）
/// @param groupIds 群组ID数组
/// @note 数据更新后会发送通知
- (void)preloadGroupInfos:(NSArray<NSString *> *)groupIds;

- (void)refreshGroupInfo:(RCGroup *)groupInfo;

- (void)clearGroupInfo:(NSString *)groupId;

- (void)clearAllGroupInfo;

- (void)updateMyUserProfile:(RCUserProfile *)profile
                    success:(void (^)(void))successBlock
                      error:(nullable void (^)(RCErrorCode errorCode, NSString * _Nullable errorKey))errorBlock;

- (void)updateMyUserProfile:(RCUserProfile *)profile
               successBlock:(void (^)(void))successBlock
                 errorBlock:(nullable void (^)(RCErrorCode errorCode,  NSArray<NSString *> * _Nullable errorKeys))errorBlock;

- (void)setFriendInfo:(NSString *)userId
               remark:(nullable NSString *)remark
           extProfile:(nullable NSDictionary<NSString *, NSString*> *)extProfile
              success:(void (^)(void))successBlock
                error:(void (^)(RCErrorCode errorCode))errorBlock;

- (void)setFriendInfo:(NSString *)userId
               remark:(nullable NSString *)remark
           extProfile:(nullable NSDictionary<NSString *, NSString*> *)extProfile
         successBlock:(void (^)(void))successBlock
           errorBlock:(void (^)(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys))errorBlock;

- (void)updateGroupInfo:(RCGroupInfo *)groupInfo
                success:(void (^)(void))successBlock
                  error:(void (^)(RCErrorCode errorCode, NSString *errorKey))errorBlock;

- (void)updateGroupInfo:(RCGroupInfo *)groupInfo
           successBlock:(void (^)(void))successBlock
             errorBlock:(void (^)(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys))errorBlock;

- (void)setGroupRemark:(NSString *)groupId
                remark:(nullable NSString *)remark
               success:(void (^)(void))successBlock
                 error:(void (^)(RCErrorCode errorCode))errorBlock;

- (void)setGroupMemberInfo:(NSString *)groupId
                    userId:(NSString *)userId
                  nickname:(nullable NSString *)nickname
                     extra:(nullable NSString *)extra
                   success:(void (^)(void))successBlock
                     error:(void (^)(RCErrorCode errorCode))errorBlock;

- (void)setGroupMemberInfo:(NSString *)groupId
                    userId:(NSString *)userId
                  nickname:(nullable NSString *)nickname
                     extra:(nullable NSString *)extra
              successBlock:(void (^)(void))successBlock
                errorBlock:(void (^)(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys))errorBlock;
@end

NS_ASSUME_NONNULL_END
