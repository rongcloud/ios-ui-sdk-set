//
//  RCInfoManagement.m
//  RongIMKit
//
//  Created by zgh on 2024/8/29.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCInfoManagement.h"
#import "RCUserInfo+RCExtented.h"
#import "RCUserInfo+RCGroupMember.h"
#import "RCGroup+RCExtented.h"
#import "RCUserInfoCacheManager.h"
#import "RCInfoManagementCache.h"
#import "RCInfoNotificationCenter.h"
@interface RCInfoManagement ()<RCGroupEventDelegate, RCFriendEventDelegate, RCConnectionStatusChangeDelegate>

@property (nonatomic, strong) RCInfoManagementCache *cache;

@property (nonatomic, copy) NSString *userId;

@end

@implementation RCInfoManagement

+ (instancetype)sharedInstance {
    static RCInfoManagement *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.userId = [RCCoreClient sharedCoreClient].currentUserInfo.userId;
        [[RCCoreClient sharedCoreClient] addGroupEventDelegate:instance];
        [[RCCoreClient sharedCoreClient] addFriendEventDelegate:instance];
        [[RCCoreClient sharedCoreClient] addConnectionStatusChangeDelegate:instance];
    });
    return instance;
}

#pragma mark -- public sync

- (nullable RCUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId {
    if (userId.length == 0) {
        return nil;
    }
    RCUserInfo *user = [self.cache getUserCache:userId];
    return user;
}

- (nullable RCUserInfo *)getGroupMemberFromCacheOnly:(NSString *)userId withGroupId:(NSString *)groupId {
    if (userId.length == 0 || groupId.length == 0) {
        return nil;
    }
    RCUserInfo *user = [self.cache getGroupMemberCache:userId groupId:groupId];
    return user;
}

- (nullable RCGroup *)getGroupInfoFromCacheOnly:(NSString *)groupId {
    if (groupId.length == 0) {
        return nil;
    }
    RCGroup *group = [self.cache getGroupCache:groupId];
    return group;
}

- (void)refreshUserInfo:(RCUserInfo *)userInfo {
    if (userInfo.userId.length == 0) {
        return;
    }
    [self refreshUserInfo:userInfo complete:^(BOOL ret) {
        if (ret) {
            [self.cache cacheUser:userInfo];
            [RCInfoNotificationCenter postUserUpdateNotification:userInfo];
        }
    }];
}

- (RCUserInfo *)getUserInfo:(NSString *)userId {
    if (userId.length == 0) {
        return nil;
    }
    RCUserInfo *user = [self.cache getUserCache:userId];
    if (user) {
        return user;
    }
    [self p_getUserInfo:userId complete:^(RCUserInfo *user) {
        if (user) {
            [self.cache cacheUser:user];
            [RCInfoNotificationCenter postUserUpdateNotification:user];
        }
    }];
    return nil;
}

- (void)getUserInfo:(NSString *)userId complete:(void (^)(RCUserInfo * _Nonnull))complete {
    [self p_getUserInfo:userId complete:^(RCUserInfo *user) {
        [self.cache cacheUser:user];
        complete(user);
    }];
}

- (void)clearUserInfo:(NSString *)userId {
    [self.cache removeUserCache:userId];
}

- (void)clearAllUserInfo {
    [self.cache removeAllUserCache];
}

- (RCUserInfo *)getGroupMember:(NSString *)userId withGroupId:(NSString *)groupId{
    if (userId.length == 0 || groupId.length == 0) {
        return nil;
    }
    RCUserInfo *user = [self.cache getGroupMemberCache:userId groupId:groupId];
    if (user) {
        return user;
    }
    [self p_getGroupMember:userId withGroupId:groupId complete:^(RCUserInfo * _Nullable user) {
        if (user) {
            [self.cache cacheGroupMember:user groupId:groupId];
            [RCInfoNotificationCenter postGroupMemberUpdateNotification:user groupId:groupId];
        }
    }];
    return nil;
}

- (void)getGroupMember:(NSString *)userId withGroupId:(NSString *)groupId complete:(void (^)(RCUserInfo * _Nullable))complete {
    [self p_getGroupMember:userId withGroupId:groupId complete:^(RCUserInfo * _Nullable user) {
        [self.cache cacheGroupMember:user groupId:groupId];
        complete(user);
    }];
}

- (void)refreshGroupMember:(RCUserInfo *)userInfo withGroupId:(NSString *)groupId {
    if (userInfo.userId.length == 0  || groupId.length == 0) {
        return;
    }
    [self refreshGroupMember:userInfo withGroupId:groupId complete:^(BOOL ret) {
        if (ret) {
            [self.cache cacheGroupMember:userInfo groupId:groupId];
            [RCInfoNotificationCenter postGroupMemberUpdateNotification:userInfo groupId:groupId];
        }
    }];
}

- (void)clearGroupMember:(NSString *)userId inGroup:(NSString *)groupId {
    [self.cache removeGroupMemberCache:userId groupId:groupId];
}

- (void)clearAllGroupMember {
    [self.cache removeAllGroupMemberCache];
}

- (RCGroup *)getGroupInfo:(NSString *)groupId {
    if (groupId.length == 0) {
        return nil;
    }
    RCGroup *group = [self.cache getGroupCache:groupId];
    if (group) {
        return group;
    }
    [self p_getGroupInfo:groupId complete:^(RCGroup * _Nullable group) {
        if (group) {
            [self.cache cacheGroup:group];
            [RCInfoNotificationCenter postGroupUpdateNotification:group];
        }
    }];
    return nil;
}

- (void)getGroupInfo:(NSString *)groupId complete:(void (^)(RCGroup * _Nullable))complete {
    [self p_getGroupInfo:groupId complete:^(RCGroup * _Nullable groupInfo) {
        [self.cache cacheGroup:groupInfo];
        complete(groupInfo);
    }];
}

- (void)refreshGroupInfo:(RCGroup *)groupInfo {
    if (groupInfo.groupId.length == 0) {
        return;
    }
    [self refreshGroupInfo:groupInfo complete:^(BOOL ret) {
        if (ret) {
            [self.cache cacheGroup:groupInfo];
            [RCInfoNotificationCenter postGroupUpdateNotification:groupInfo];
        }
    }];
}

- (void)clearGroupInfo:(NSString *)groupId {
    [self.cache removeGroupCache:groupId];
}

- (void)clearAllGroupInfo {
    [self.cache removeAllGroupCache];
}

#pragma mark -- private async

- (void)refreshUserInfo:(RCUserInfo *)userInfo complete:(void (^)(BOOL))complete {
    if ([userInfo.userId isEqualToString:[RCCoreClient sharedCoreClient].currentUserInfo.userId]) {
        [[RCCoreClient sharedCoreClient] updateMyUserProfile:userInfo.rc_profile success:^{
            complete(YES);
        } error:^(RCErrorCode errorCode, NSString * _Nullable errorKey) {
            complete(NO);
        }];
    } else if (userInfo.rc_friendInfo){
        [[RCCoreClient sharedCoreClient] setFriendInfo:userInfo.userId remark:userInfo.rc_friendInfo.remark extProfile:userInfo.rc_friendInfo.extProfile success:^{
            complete(YES);
        } error:^(RCErrorCode errorCode) {
            complete(NO);
        }];
    } else {
        complete(NO);
    }
}

- (void)p_getUserInfo:(NSString *)userId complete:(void (^)(RCUserInfo *))complete {
    if (userId == nil) {
        return complete(nil);
    }
    if ([[RCCoreClient sharedCoreClient].currentUserInfo.userId isEqualToString:userId]) {
        [[RCCoreClient sharedCoreClient] getMyUserProfile:^(RCUserProfile * _Nonnull userProfile) {
            if (userProfile) {
                RCUserInfo *user = [RCUserInfo new];
                user.rc_profile = userProfile;
                complete(user);
            } else {
                complete(nil);
            }
        } error:^(RCErrorCode errorCode) {
            complete(nil);
        }];
    } else {
        [[RCCoreClient sharedCoreClient] getUserProfiles:@[userId] success:^(NSArray<RCUserProfile *> * _Nonnull userProfiles) {
            if (userProfiles.firstObject) {
                RCUserInfo *user = [RCUserInfo new];
                user.rc_profile = userProfiles.firstObject;
                [[RCCoreClient sharedCoreClient] getFriendsInfo:@[userId] success:^(NSArray<RCFriendInfo *> * _Nonnull friendInfos) {
                    user.rc_friendInfo = friendInfos.firstObject;
                    complete(user);
                } error:^(RCErrorCode errorCode) {
                    complete(user);
                }];
            } else {
                complete(nil);
            }
        } error:^(RCErrorCode errorCode) {
            complete(nil);
        }];
    }
}

- (void)refreshGroupMember:(RCUserInfo *)userInfo withGroupId:(NSString *)groupId complete:(void (^)(BOOL))complete {
    [[RCCoreClient sharedCoreClient] setGroupMemberInfo:groupId userId:userInfo.rc_member.userId nickname:userInfo.rc_member.nickname extra:userInfo.rc_member.extra success:^{
        complete(YES);
    } error:^(RCErrorCode errorCode) {
        complete(NO);
    }];
}

- (void)p_getGroupMember:(NSString *)userId withGroupId:(NSString *)groupId complete:(void (^)( RCUserInfo *_Nullable user))complete {
    if (userId == nil || groupId == nil) {
        return complete(nil);
    }
    [[RCCoreClient sharedCoreClient] getGroupMembers:groupId userIds:@[userId] success:^(NSArray<RCGroupMemberInfo *> * _Nonnull groupMembers) {
        if (groupMembers.firstObject) {
            RCUserInfo *user = [RCUserInfo new];
            user.rc_member = groupMembers.firstObject;
            complete(user);
        } else {
            complete(nil);
        }
    } error:^(RCErrorCode errorCode) {
        complete(nil);
    }];
}

- (void)p_getGroupInfo:(NSString *)groupId complete:(void (^)(RCGroup * _Nullable))complete {
    if (groupId == nil) {
        return complete(nil);
    }
    [[RCCoreClient sharedCoreClient] getGroupsInfo:@[groupId] success:^(NSArray<RCGroupInfo *> * _Nonnull groupInfos) {
        if (groupInfos.firstObject) {
            RCGroup *group = [RCGroup new];
            group.rc_group = groupInfos.firstObject;
            complete(group);
        } else {
            complete(nil);
        }
    } error:^(RCErrorCode errorCode) {
        complete(nil);
    }];
}

- (void)refreshGroupInfo:(RCGroup *)groupInfo complete:(void (^)(BOOL))complete {
    [[RCCoreClient sharedCoreClient] updateGroupInfo:groupInfo.rc_group success:^{
        complete(YES);
    } error:^(RCErrorCode errorCode, NSString * _Nonnull errorKey) {
        complete(NO);
    }];
}

#pragma mark --

/// 群组资料变更回调
/// - Parameter operatorInfo: 操作者信息
/// - Parameter groupInfo: 群组信息，只有包含在 updateKeys 中的属性值有效
/// - Parameter updateKeys: 群组信息内容有变更的属性
/// - Parameter operationTime: 操作时间
- (void)onGroupInfoChanged:(RCGroupMemberInfo *)operatorInfo
                 groupInfo:(RCGroupInfo *)groupInfo
                updateKeys:(NSArray<RCGroupInfoKeys> *)updateKeys
             operationTime:(long long)operationTime {
    RCGroup *group = [RCGroup new];
    group.rc_group = groupInfo;
    [self.cache cacheGroup:group];
}

/// 群成员资料变更回调
/// - Parameter groupId: 群组ID
/// - Parameter operatorInfo: 操作人成员资料
/// - Parameter memberInfo: 有变更的群成员资料
/// - Parameter operationTime: 操作时间
- (void)onGroupMemberInfoChanged:(NSString *)groupId
                    operatorInfo:(RCGroupMemberInfo *)operatorInfo
                      memberInfo:(RCGroupMemberInfo *)memberInfo
                   operationTime:(long long)operationTime {
    RCUserInfo *user = [RCUserInfo new];
    user.rc_member = memberInfo;
    [self.cache cacheGroupMember:user groupId:groupId];
}

#pragma mark -- RCFriendEventDelegate

- (void)onFriendCleared:(long long)operationTime {
    [self.cache removeAllUserCache];
}

- (void)onFriendDelete:(nonnull NSArray<NSString *> *)userIds directionType:(RCDirectionType)directionType operationTime:(long long)operationTime {
    for (NSString *userId in userIds) {
        [self.cache removeUserCache:userId];
    }
}

- (void)onFriendInfoChangedSync:(nonnull NSString *)userId remark:(nullable NSString *)remark extProfile:(nullable NSDictionary<NSString *,NSString *> *)extProfile operationTime:(long long)operationTime {
    RCUserInfo *user = [self.cache getUserCache:userId];
    if (user && user.rc_friendInfo) {
        RCFriendInfo *friendInfo = user.rc_friendInfo;
        friendInfo.remark = remark;
        friendInfo.extProfile = extProfile;
        user.rc_friendInfo = friendInfo;
        [self.cache cacheUser:user];
    }
}

#pragma mark -- getter

- (RCInfoManagementCache *)cache {
    if (!_cache) {
        _cache = [RCInfoManagementCache new];
    }
    return _cache;
}

#pragma mark -- RCIMConnectionStatusDelegate
- (void)onConnectionStatusChanged:(RCConnectionStatus)status { 
    if (status == ConnectionStatus_Connected && self.userId != [RCCoreClient sharedCoreClient].currentUserInfo.userId) {
        self.userId = [RCCoreClient sharedCoreClient].currentUserInfo.userId;
        [self.cache removeAllUserCache];
        [self.cache removeAllGroupCache];
        [self.cache removeAllGroupMemberCache];
    }
}

@end
