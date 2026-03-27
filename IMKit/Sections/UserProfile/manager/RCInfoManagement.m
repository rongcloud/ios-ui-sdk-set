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

static NSUInteger const RC_KIT_FETCH_INFO_UINT_3 = 3;
static float const RC_KIT_FETCH_INFO_DELAY_TIME = 0.5;


@interface RCInfoManagement ()<RCGroupEventDelegate, RCFriendEventDelegate, RCConnectionStatusChangeDelegate, RCSubscribeEventDelegate>

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
        [[RCCoreClient sharedCoreClient] addSubscribeEventDelegate:instance];
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
    return [self p_getMemberCache:user];
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
        if (complete) {
            complete(user);
        }
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
        return [self p_getMemberCache:user];
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
        if (complete) {
            complete(user);
        }
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
        if (complete) {
            complete(groupInfo);
        }
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

- (void)updateMyUserProfile:(RCUserProfile *)profile
                    success:(void (^)(void))successBlock
                      error:(nullable void (^)(RCErrorCode errorCode, NSString * _Nullable errorKey))errorBlock {
    [[RCCoreClient sharedCoreClient] updateMyUserProfile:profile success:^{
        [self getUserInfo:profile.userId complete:nil];
        if (successBlock) {
            successBlock();
        }
    } error:errorBlock];
}

- (void)updateMyUserProfile:(RCUserProfile *)profile
               successBlock:(void (^)(void))successBlock
                 errorBlock:(nullable void (^)(RCErrorCode errorCode,  NSArray<NSString *> * _Nullable errorKeys))errorBlock {
    [[RCCoreClient sharedCoreClient] updateMyUserProfile:profile successBlock:^{
        [self getUserInfo:profile.userId complete:nil];
        if (successBlock) {
            successBlock();
        }
    } errorBlock:errorBlock];
}


- (void)setFriendInfo:(NSString *)userId
               remark:(nullable NSString *)remark
           extProfile:(nullable NSDictionary<NSString *, NSString*> *)extProfile
              success:(void (^)(void))successBlock
                error:(void (^)(RCErrorCode errorCode))errorBlock {
    [[RCCoreClient sharedCoreClient] setFriendInfo:userId remark:remark extProfile:extProfile success:^{
        [self getUserInfo:userId complete:nil];
        if (successBlock) {
            successBlock();
        }
    } error:errorBlock];
}

- (void)setFriendInfo:(NSString *)userId
               remark:(nullable NSString *)remark
           extProfile:(nullable NSDictionary<NSString *, NSString*> *)extProfile
         successBlock:(void (^)(void))successBlock
           errorBlock:(void (^)(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys))errorBlock {
    [[RCCoreClient sharedCoreClient] setFriendInfo:userId remark:remark extProfile:extProfile successBlock:^{
        [self getUserInfo:userId complete:nil];
        if (successBlock) {
            successBlock();
        }
    } errorBlock:errorBlock];
}

- (void)updateGroupInfo:(RCGroupInfo *)groupInfo
                success:(void (^)(void))successBlock
                  error:(void (^)(RCErrorCode errorCode, NSString *errorKey))errorBlock {
    [[RCCoreClient sharedCoreClient] updateGroupInfo:groupInfo success:^{
        [self getGroupInfo:groupInfo.groupId complete:nil];
        if (successBlock) {
            successBlock();
        }
    } error:errorBlock];
}

- (void)updateGroupInfo:(RCGroupInfo *)groupInfo
           successBlock:(void (^)(void))successBlock
             errorBlock:(void (^)(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys))errorBlock {
    [[RCCoreClient sharedCoreClient] updateGroupInfo:groupInfo
                                        successBlock:^{
        [self getGroupInfo:groupInfo.groupId complete:nil];
        if (successBlock) {
            successBlock();
        }
    } errorBlock:errorBlock];
}

- (void)setGroupRemark:(NSString *)groupId remark:(NSString *)remark success:(void (^)(void))successBlock error:(void (^)(RCErrorCode))errorBlock {
    [[RCCoreClient sharedCoreClient] setGroupRemark:groupId remark:remark success:^{
        [self getGroupInfo:groupId complete:nil];
        if (successBlock) {
            successBlock();
        }
    } error:errorBlock];
}

- (void)setGroupMemberInfo:(NSString *)groupId
                    userId:(NSString *)userId
                  nickname:(nullable NSString *)nickname
                     extra:(nullable NSString *)extra
                   success:(void (^)(void))successBlock
                     error:(void (^)(RCErrorCode errorCode))errorBlock {
    [[RCCoreClient sharedCoreClient] setGroupMemberInfo:groupId userId:userId nickname:nickname extra:extra success:^{
        [self getGroupMember:userId withGroupId:groupId complete:nil];
        if (successBlock) {
            successBlock();
        }
    } error:errorBlock];
}

- (void)setGroupMemberInfo:(NSString *)groupId
                    userId:(NSString *)userId
                  nickname:(nullable NSString *)nickname
                     extra:(nullable NSString *)extra
              successBlock:(void (^)(void))successBlock
                errorBlock:(void (^)(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys))errorBlock {
    [[RCCoreClient sharedCoreClient] setGroupMemberInfo:groupId
                                                 userId:userId
                                               nickname:nickname
                                                  extra:extra
                                           successBlock:^{
        [self getGroupMember:userId withGroupId:groupId complete:nil];
        if (successBlock) {
            successBlock();
        }
    }
                                             errorBlock:errorBlock];
}
#pragma mark -- private async

- (void)refreshUserInfo:(RCUserInfo *)userInfo complete:(void (^)(BOOL))complete {
    if ([userInfo.userId isEqualToString:[RCCoreClient sharedCoreClient].currentUserInfo.userId]) {
        [[RCCoreClient sharedCoreClient] updateMyUserProfile:userInfo.rc_profile successBlock:^{
            complete(YES);
        } errorBlock:^(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys) {
            complete(NO);
        }];
    } else if (userInfo.rc_friendInfo){
        [[RCCoreClient sharedCoreClient] setFriendInfo:userInfo.userId remark:userInfo.rc_friendInfo.remark extProfile:userInfo.rc_friendInfo.extProfile successBlock:^{
            complete(YES);
        } errorBlock:^(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys) {
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
        [self p_getMyProflieByRetry:RC_KIT_FETCH_INFO_UINT_3 complete:complete];
    } else {
        [self p_getFriendsInfoByRetry:userId retryCount:RC_KIT_FETCH_INFO_UINT_3 complete:^(RCUserInfo * _Nullable user) {
            if (user) {
                complete(user);
            } else {
                [self p_getUserProfileByRetry:userId retryCount:RC_KIT_FETCH_INFO_UINT_3 complete:complete];
            }
        }];
    }
}

- (void)refreshGroupMember:(RCUserInfo *)userInfo withGroupId:(NSString *)groupId complete:(void (^)(BOOL))complete {
    [[RCCoreClient sharedCoreClient] setGroupMemberInfo:groupId userId:userInfo.rc_member.userId nickname:userInfo.rc_member.nickname extra:userInfo.rc_member.extra
                                           successBlock:^{
        complete(YES);
    } errorBlock:^(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys) {
        complete(NO);
    }];
}

- (void)p_getGroupMember:(NSString *)userId withGroupId:(NSString *)groupId complete:(void (^)( RCUserInfo *_Nullable user))complete {
    if (userId == nil || groupId == nil) {
        return complete(nil);
    }
    [self p_getGroupMemberByRetry:userId withGroupId:groupId retryCount:RC_KIT_FETCH_INFO_UINT_3 complete:complete];
}

- (void)p_getGroupInfo:(NSString *)groupId complete:(void (^)(RCGroup * _Nullable))complete {
    if (groupId == nil) {
        return complete(nil);
    }
    [self p_getGroupInfoByRetry:groupId retryCount:RC_KIT_FETCH_INFO_UINT_3 complete:complete];
}

- (void)p_getMyProflieByRetry:(int)retryCount complete:(void (^)( RCUserInfo *_Nullable user))complete {
    [[RCCoreClient sharedCoreClient] getMyUserProfile:^(RCUserProfile * _Nonnull userProfile) {
        RCUserInfo *user = [RCUserInfo new];
        user.rc_profile = userProfile;
        complete(user);
    } error:^(RCErrorCode errorCode) {
        if (errorCode == NET_DATA_IS_SYNCHRONIZING && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_getMyProflieByRetry:retryCount-1 complete:complete];
            });
        } else {
            complete(nil);
        }
    }];
}

- (void)p_getFriendsInfoByRetry:(NSString *)userId retryCount:(int)retryCount complete:(void (^)( RCUserInfo *_Nullable user))complete {
    [[RCCoreClient sharedCoreClient] getFriendsInfo:@[userId] success:^(NSArray<RCFriendInfo *> * _Nonnull friendInfos) {
        if (friendInfos.firstObject) {
            RCUserInfo *user = [RCUserInfo new];
            user.rc_friendInfo = friendInfos.firstObject;
            complete(user);
        } else {
            complete(nil);
        }
    } error:^(RCErrorCode errorCode) {
        if (errorCode == NET_DATA_IS_SYNCHRONIZING && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_getFriendsInfoByRetry:userId retryCount:retryCount-1 complete:complete];
            });
        } else {
            complete(nil);
        }
    }];
}

- (void)p_getUserProfileByRetry:(NSString *)userId retryCount:(int)retryCount complete:(void (^)( RCUserInfo *_Nullable user))complete {
    [[RCCoreClient sharedCoreClient] getUserProfiles:@[userId] success:^(NSArray<RCUserProfile *> * _Nonnull userProfiles) {
        if (userProfiles.firstObject) {
            RCUserInfo *user = [RCUserInfo new];
            user.rc_profile = userProfiles.firstObject;
            complete(user);
        } else {
            complete(nil);
        }
    } error:^(RCErrorCode errorCode) {
        if (errorCode == NET_DATA_IS_SYNCHRONIZING && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_getUserProfileByRetry:userId retryCount:retryCount-1 complete:complete];
            });
        } else {
            complete(nil);
        }
    }];
}


- (void)p_getGroupMemberByRetry:(NSString *)userId withGroupId:(NSString *)groupId retryCount:(int)retryCount complete:(void (^)( RCUserInfo *_Nullable user))complete {
    [[RCCoreClient sharedCoreClient] getGroupMembers:groupId userIds:@[userId] success:^(NSArray<RCGroupMemberInfo *> * _Nonnull groupMembers) {
        if (groupMembers.firstObject) {
            RCUserInfo *user = [RCUserInfo new];
            user.rc_member = groupMembers.firstObject;
            complete(user);
        } else {
            complete(nil);
        }
    } error:^(RCErrorCode errorCode) {
        if (errorCode == NET_DATA_IS_SYNCHRONIZING && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_getGroupMemberByRetry:userId withGroupId:groupId retryCount:retryCount-1 complete:complete];
            });
        } else {
            complete(nil);
        }
    }];
}

- (void)p_getGroupInfoByRetry:(NSString *)groupId retryCount:(int)retryCount complete:(void (^)(RCGroup * _Nullable))complete {
    [[RCCoreClient sharedCoreClient] getGroupsInfo:@[groupId] success:^(NSArray<RCGroupInfo *> * _Nonnull groupInfos) {
        if (groupInfos.firstObject) {
            RCGroup *group = [RCGroup new];
            group.rc_group = groupInfos.firstObject;
            complete(group);
        } else {
            complete(nil);
        }
    } error:^(RCErrorCode errorCode) {
        if (errorCode == NET_DATA_IS_SYNCHRONIZING && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_getGroupInfoByRetry:groupId retryCount:retryCount-1 complete:complete];
            });
        } else {
            complete(nil);
        }
    }];
}

- (void)refreshGroupInfo:(RCGroup *)groupInfo complete:(void (^)(BOOL))complete {
    [[RCCoreClient sharedCoreClient] updateGroupInfo:groupInfo.rc_group
                                        successBlock:^{
        complete(YES);
    } errorBlock:^(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys) {
        complete(NO);
    }];
}

- (RCUserInfo *)p_getMemberCache:(RCUserInfo *)member {
    if (!member) {
        return member;
    }
    RCUserInfo *tempUser = [self.cache getUserCache:member.userId];
    if (!tempUser) {
        return member;
    }
    // 群成员信息除群成员昵称外以用户信息缓存为主
    if (member.rc_member.nickname.length == 0) {
        member.name = tempUser.name;
    }
    member.portraitUri = tempUser.portraitUri;
    member.extra = tempUser.extra;
    return member;
}

#pragma mark -- RCGroupEventDelegate

/// 群组资料变更回调
/// - Parameter operatorInfo: 操作者信息
/// - Parameter groupInfo: 群组信息，只有包含在 updateKeys 中的属性值有效
/// - Parameter updateKeys: 群组信息内容有变更的属性
/// - Parameter operationTime: 操作时间
- (void)onGroupInfoChanged:(RCGroupMemberInfo *)operatorInfo
                 groupInfo:(RCGroupInfo *)groupInfo
                updateKeys:(NSArray<RCGroupInfoKeys> *)updateKeys
             operationTime:(long long)operationTime {
    [self getGroupInfo:groupInfo.groupId complete:nil];
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
    [self getGroupMember:memberInfo.userId withGroupId:groupId complete:nil];
}

- (void)onGroupRemarkChangedSync:(NSString *)groupId operationType:(RCGroupOperationType)operationType groupRemark:(NSString *)groupRemark operationTime:(long long)operationTime {
    [self getGroupInfo:groupId complete:nil];
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
    [self getUserInfo:userId complete:nil];
}

#pragma mark -- RCSubscribeEventDelegate
- (void)onEventChange:(NSArray<RCSubscribeInfoEvent *> *)subscribeEvents {
    for (RCSubscribeInfoEvent *event in subscribeEvents) {
        if (event.subscribeType == RCSubscribeTypeUserProfile ||
            event.subscribeType == RCSubscribeTypeFriendUserProfile) {
            [self.cache removeUserCache:event.userId];
        }
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
