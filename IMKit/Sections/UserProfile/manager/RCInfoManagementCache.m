//
//  RCInfoManagementCache.m
//  RongIMKit
//
//  Created by zgh on 2024/9/3.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCInfoManagementCache.h"
#import "RCThreadSafeMutableDictionary.h"
#import "NSMutableDictionary+RCOperation.h"
#import "NSMutableArray+RCOperation.h"
#import "RCIMThreadLock.h"
#import "RCUserInfo+RCExtented.h"
#import "RCUserInfo+RCGroupMember.h"
#import "RCGroup+RCExtented.h"
#import "RCGroupInfo+Private.h"

#define RCInfoManagementCacheMaxSize 1000

@interface RCInfoManagementCache ()

@property (nonatomic, strong) RCThreadSafeMutableDictionary *userCache;

@property (nonatomic, strong) NSMutableArray *cacheUserIds;

@property (nonatomic, strong) RCIMThreadLock *userThreadLock;

@property (nonatomic, strong) RCThreadSafeMutableDictionary *groupCache;

@property (nonatomic, strong) NSMutableArray *cacheGroupIds;

@property (nonatomic, strong) RCIMThreadLock *groupThreadLock;

@property (nonatomic, strong) RCThreadSafeMutableDictionary *memberCache;

@property (nonatomic, strong) NSMutableArray *cacheMemberIds;

@property (nonatomic, strong) RCIMThreadLock *memberThreadLock;

@end

@implementation RCInfoManagementCache

#pragma mark -- user

- (RCUserInfo *)getUserCache:(NSString *)userId {
    RCUserInfo *info = [self.userCache objectForKey:userId];
    if (!info) {
        return nil;
    }
    RCUserInfo *copyInfo = [self copyUserInfo:info];
    return copyInfo;
}

- (void)cacheUser:(RCUserInfo *)useInfo {
    RCUserInfo *copyInfo = [self copyUserInfo:useInfo];
    [self.userCache rclib_setObject:copyInfo forKey:copyInfo.userId];
    [self.userThreadLock performWriteLockBlock:^{
        if ([self.cacheUserIds containsObject:copyInfo.userId]) {
            return;
        }
        [self.cacheUserIds rclib_addObject:copyInfo.userId];
        if (self.cacheUserIds.count > RCInfoManagementCacheMaxSize) {
            NSString *userId = self.cacheUserIds.firstObject;
            [self.cacheUserIds removeObject:userId];
            [self.userCache rclib_removeObjectForKey:userId];
        }
    }];
}

- (void)removeUserCache:(NSString *)userId {
    [self.userCache rclib_removeObjectForKey:userId];
    [self.userThreadLock performWriteLockBlock:^{
        [self.cacheUserIds removeObject:userId];
    }];
}

- (void)removeAllUserCache {
    [self.userCache removeAllObjects];
    [self.userThreadLock performWriteLockBlock:^{
        [self.cacheUserIds removeAllObjects];
    }];
}

#pragma mark -- group

- (RCGroup *)getGroupCache:(NSString *)groupId {
    RCGroup *info = [self.groupCache objectForKey:groupId];
    if (!info) {
        return nil;
    }
    RCGroup *copyInfo = [self copyGroup:info];
    return copyInfo;
}

- (void)cacheGroup:(RCGroup *)group {
    RCGroup *copyInfo = [self copyGroup:group];
    [self.groupCache rclib_setObject:copyInfo forKey:copyInfo.groupId];
    [self.groupThreadLock performWriteLockBlock:^{
        if ([self.cacheGroupIds containsObject:copyInfo.groupId]) {
            return;
        }
        [self.cacheGroupIds rclib_addObject:copyInfo.groupId];
        if (self.cacheGroupIds.count > RCInfoManagementCacheMaxSize) {
            NSString *groupId = self.cacheGroupIds.firstObject;
            [self.cacheGroupIds removeObject:groupId];
            [self.groupCache rclib_removeObjectForKey:groupId];
        }
    }];
}

- (void)removeGroupCache:(NSString *)groupId {
    [self.groupCache rclib_removeObjectForKey:groupId];
    [self.groupThreadLock performWriteLockBlock:^{
        [self.cacheGroupIds removeObject:groupId];
    }];
}

- (void)removeAllGroupCache {
    [self.groupCache removeAllObjects];
    [self.groupThreadLock performWriteLockBlock:^{
        [self.cacheGroupIds removeAllObjects];
    }];
}

- (RCUserInfo *)getGroupMemberCache:(NSString *)userId groupId:(NSString *)groupId {
    RCUserInfo *info = [self.memberCache objectForKey:[userId stringByAppendingString:groupId]];
    if (!info) {
        return nil;
    }
    RCUserInfo *copyInfo = [self copyUserInfo:info];
    return copyInfo;

}

- (void)cacheGroupMember:(RCUserInfo *)member groupId:(NSString *)groupId {
    RCUserInfo *copyInfo = [self copyUserInfo:member];
    NSString *key = [copyInfo.userId stringByAppendingString:groupId];
    [self.memberCache rclib_setObject:copyInfo forKey:key];
    [self.memberThreadLock performWriteLockBlock:^{
        if ([self.cacheMemberIds containsObject:key]) {
            return;
        }
        [self.cacheMemberIds rclib_addObject:key];
        if (self.cacheMemberIds.count > RCInfoManagementCacheMaxSize) {
            NSString *value = self.cacheMemberIds.firstObject;
            [self.cacheMemberIds removeObject:value];
            [self.memberCache rclib_removeObjectForKey:value];
        }
    }];
}

- (void)removeGroupMemberCache:(NSString *)userId groupId:(NSString *)groupId {
    NSString *key = [userId stringByAppendingString:groupId];
    [self.memberCache rclib_removeObjectForKey:key];
    [self.memberThreadLock performWriteLockBlock:^{
        [self.cacheMemberIds removeObject:key];
    }];
}

- (void)removeAllGroupMemberCache {
    [self.memberCache removeAllObjects];
    [self.memberThreadLock performWriteLockBlock:^{
        [self.cacheMemberIds removeAllObjects];
    }];
}

#pragma mark -- private

- (RCUserInfo *)copyUserInfo:(RCUserInfo *)user {
    RCUserInfo *copyUser = [RCUserInfo new];
    if (user.rc_profile) {
        RCUserProfile *profile = [RCUserProfile new];
        profile.userId = user.rc_profile.userId;
        profile.userExtProfile = [NSDictionary dictionaryWithDictionary:user.rc_profile.userExtProfile];
        profile.name = user.rc_profile.name;
        profile.portraitUri = user.rc_profile.portraitUri;
        profile.uniqueId = user.rc_profile.uniqueId;
        profile.email = user.rc_profile.email;
        profile.birthday = user.rc_profile.birthday;
        profile.gender = user.rc_profile.gender;
        profile.location = user.rc_profile.location;
        profile.role = user.rc_profile.role;
        profile.level = user.rc_profile.level;
        copyUser.rc_profile = profile;
    }
    if (user.rc_friendInfo) {
        RCFriendInfo *info = [RCFriendInfo new];
        info.userId = user.rc_friendInfo.userId;
        info.name = user.rc_friendInfo.name;
        info.portraitUri = user.rc_friendInfo.portraitUri;
        info.remark = user.rc_friendInfo.remark;
        info.extProfile = [NSDictionary dictionaryWithDictionary:user.rc_friendInfo.extProfile];
        info.addTime = user.rc_friendInfo.addTime;
        info.directionType = user.rc_friendInfo.directionType;
        copyUser.rc_friendInfo = info;
    }
    if (user.rc_member) {
        RCGroupMemberInfo *member = [RCGroupMemberInfo new];
        member.userId = user.rc_member.userId;
        member.portraitUri = user.rc_member.portraitUri;
        member.name = user.rc_member.name;
        member.nickname = user.rc_member.nickname;
        member.extra = user.rc_member.extra;
        member.joinedTime = user.rc_member.joinedTime;
        member.role = user.rc_member.role;
        copyUser.rc_member = member;
    }
    return copyUser;
}

- (RCGroup *)copyGroup:(RCGroup *)groupInfo {
    RCGroup *copyGroup = [RCGroup new];
    if (groupInfo.rc_group) {
        RCGroupInfo *group = [RCGroupInfo new];
        group.groupId = groupInfo.rc_group.groupId;
        group.extProfile = [NSDictionary dictionaryWithDictionary:groupInfo.rc_group.extProfile];
        group.creatorId = groupInfo.rc_group.creatorId;
        group.ownerId = groupInfo.rc_group.ownerId;
        group.remark = groupInfo.rc_group.remark;
        group.createTime = groupInfo.rc_group.createTime;
        group.membersCount = groupInfo.rc_group.membersCount;
        group.joinedTime = groupInfo.rc_group.joinedTime;
        group.role = groupInfo.rc_group.role;
        group.groupName = groupInfo.rc_group.groupName;
        group.portraitUri = groupInfo.rc_group.portraitUri;
        group.introduction = groupInfo.rc_group.introduction;
        group.notice = groupInfo.rc_group.notice;
        group.joinPermission = groupInfo.rc_group.joinPermission;
        group.removeMemberPermission = groupInfo.rc_group.removeMemberPermission;
        group.invitePermission = groupInfo.rc_group.invitePermission;
        group.inviteHandlePermission = groupInfo.rc_group.inviteHandlePermission;
        group.groupInfoEditPermission = groupInfo.rc_group.groupInfoEditPermission;
        group.memberInfoEditPermission = groupInfo.rc_group.memberInfoEditPermission;
        copyGroup.rc_group = group;
    }
    return copyGroup;
}

#pragma mark -- getter
- (RCThreadSafeMutableDictionary *)userCache {
    if (!_userCache) {
        _userCache = [[RCThreadSafeMutableDictionary alloc] initWithCapacity:RCInfoManagementCacheMaxSize];
    }
    return _userCache;
}

- (RCThreadSafeMutableDictionary *)groupCache {
    if (!_groupCache) {
        _groupCache = [[RCThreadSafeMutableDictionary alloc] initWithCapacity:RCInfoManagementCacheMaxSize];
    }
    return _groupCache;
}

- (RCThreadSafeMutableDictionary *)memberCache {
    if (!_memberCache) {
        _memberCache = [[RCThreadSafeMutableDictionary alloc] initWithCapacity:RCInfoManagementCacheMaxSize];
    }
    return _memberCache;
}

- (NSMutableArray *)cacheUserIds {
    if (!_cacheUserIds) {
        _cacheUserIds = [NSMutableArray new];
    }
    return _cacheUserIds;
}

- (NSMutableArray *)cacheGroupIds {
    if (!_cacheGroupIds) {
        _cacheGroupIds = [NSMutableArray new];
    }
    return _cacheGroupIds;
}

- (NSMutableArray *)cacheMemberIds {
    if (!_cacheMemberIds) {
        _cacheMemberIds = [NSMutableArray new];;
    }
    return _cacheMemberIds;
}

- (RCIMThreadLock *)userThreadLock {
    if (!_userThreadLock) {
        _userThreadLock = [RCIMThreadLock new];
    }
    return _userThreadLock;
}

- (RCIMThreadLock *)groupThreadLock {
    if (!_groupThreadLock) {
        _groupThreadLock = [RCIMThreadLock new];
    }
    return _groupThreadLock;
}

- (RCIMThreadLock *)memberThreadLock {
    if (!_memberThreadLock) {
        _memberThreadLock = [RCIMThreadLock new];
    }
    return _memberThreadLock;
}
@end
