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

- (void)getUserInfo:(NSString *)userId complete:(void (^)(RCUserInfo *))complete;

- (void)refreshUserInfo:(RCUserInfo *)userInfo;

- (void)clearUserInfo:(NSString *)userId;

- (void)clearAllUserInfo;

#pragma mark -- groupMember

//仅从 cache 取
- (nullable RCUserInfo *)getGroupMemberFromCacheOnly:(NSString *)userId withGroupId:(NSString *)groupId;

//从cache现取，没有值直接返回nil，并调用信息托管接口
- (nullable RCUserInfo *)getGroupMember:(NSString *)userId withGroupId:(NSString *)groupId;

- (void)getGroupMember:(NSString *)userId withGroupId:(NSString *)groupId complete:(void (^)( RCUserInfo *_Nullable user))complete;

- (void)refreshGroupMember:(RCUserInfo *)userInfo withGroupId:(NSString *)groupId;

- (void)clearGroupMember:(NSString *)userId inGroup:(NSString *)groupId;

- (void)clearAllGroupMember;

#pragma mark -- group

//从cache现取，没有值直接返回nil，并调用信息托管接口
- (nullable RCGroup *)getGroupInfo:(NSString *)groupId;

//仅从 cache 取
- (nullable RCGroup *)getGroupInfoFromCacheOnly:(NSString *)groupId;

- (void)getGroupInfo:(NSString *)groupId complete:(void (^)(RCGroup * _Nullable))complete;

- (void)refreshGroupInfo:(RCGroup *)groupInfo;

- (void)clearGroupInfo:(NSString *)groupId;

- (void)clearAllGroupInfo;

@end

NS_ASSUME_NONNULL_END
