//
//  RCUserInfoCacheManager.m
//  RongIMKit
//
//  Created by 岑裕 on 16/1/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCUserInfoCacheManager.h"
#import "RCInfoProvider.h"
#import "RCInfoManagement.h"

@interface RCUserInfoCacheManager ()

@end

@implementation RCUserInfoCacheManager

+ (instancetype)sharedManager {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - UserInfo

//从cache现取，没有值直接返回nil，并调用用户信息提供者
- (RCUserInfo *)getUserInfo:(NSString *)userId {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        return [[RCInfoManagement sharedInstance] getUserInfo:userId];
    } else {
        return [[RCInfoProvider sharedManager] getUserInfo:userId];
    }
}

//从cache和用户信息提供者取
- (void)getUserInfo:(NSString *)userId complete:(void (^)(RCUserInfo *userInfo))completeBlock {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        [[RCInfoManagement sharedInstance] getUserInfo:userId complete:completeBlock];
    } else {
        [[RCInfoProvider sharedManager] getUserInfo:userId complete:completeBlock];
    }
}

//只获取当前cache中的用户信息，不进行任何回调
- (RCUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        return [[RCInfoManagement sharedInstance] getUserInfoFromCacheOnly:userId];
    } else {
        return [[RCInfoProvider sharedManager] getUserInfoFromCacheOnly:userId];
    }
}

- (void)updateUserInfo:(RCUserInfo *)userInfo forUserId:(NSString *)userId {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        [[RCInfoManagement sharedInstance] refreshUserInfo:userInfo];
    } else {
        [[RCInfoProvider sharedManager] updateUserInfo:userInfo forUserId:userId];
    }
}

- (void)clearUserInfo:(NSString *)userId {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        [[RCInfoManagement sharedInstance] clearUserInfo:userId];
    } else {
        [[RCInfoProvider sharedManager] clearUserInfo:userId];
    }
}

- (void)clearAllUserInfo {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        [[RCInfoManagement sharedInstance] clearAllUserInfo];
    } else {
        [[RCInfoProvider sharedManager] clearAllUserInfo];
    }
}

#pragma mark - GroupUserInfo (sugar for ConversationUserInfo)

- (RCUserInfo *)getUserInfo:(NSString *)userId inGroupId:(NSString *)groupId {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        return [[RCInfoManagement sharedInstance] getGroupMember:userId withGroupId:groupId];
    } else {
        return [[RCInfoProvider sharedManager] getUserInfo:userId inGroupId:groupId];
    }
}

- (void)getUserInfo:(NSString *)userId
          inGroupId:(NSString *)groupId
           complete:(void (^)(RCUserInfo *userInfo))completeBlock {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        [[RCInfoManagement sharedInstance] getGroupMember:userId withGroupId:groupId complete:completeBlock];
    } else {
        [[RCInfoProvider sharedManager] getUserInfo:userId inGroupId:groupId complete:completeBlock];
    }
}

- (RCUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId inGroupId:(NSString *)groupId {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        return [[RCInfoManagement sharedInstance] getGroupMemberFromCacheOnly:userId withGroupId:groupId];
    } else {
        return [[RCInfoProvider sharedManager] getUserInfoFromCacheOnly:userId inGroupId:groupId];
    }
}

- (void)updateUserInfo:(RCUserInfo *)userInfo forUserId:(NSString *)userId inGroup:(NSString *)groupId {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        [[RCInfoManagement sharedInstance] refreshGroupMember:userInfo withGroupId:groupId];
    } else {
        [[RCInfoProvider sharedManager] updateUserInfo:userInfo forUserId:userId inGroup:groupId];
    }
}

- (void)clearGroupUserInfo:(NSString *)userId inGroup:(NSString *)groupId {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        [[RCInfoManagement sharedInstance] clearGroupMember:userId inGroup:groupId];
    } else {
        [[RCInfoProvider sharedManager] clearGroupUserInfo:userId inGroup:groupId];
    }
}

- (void)clearAllGroupUserInfo {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        [[RCInfoManagement sharedInstance] clearAllGroupMember];
    } else {
        [[RCInfoProvider sharedManager] clearAllGroupUserInfo];
    }
}

#pragma mark - GroupInfo (sugar for ConversationInfo)

- (RCGroup *)getGroupInfo:(NSString *)groupId {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        return [[RCInfoManagement sharedInstance] getGroupInfo:groupId];
    } else {
        return [[RCInfoProvider sharedManager] getGroupInfo:groupId];
    }
}

- (void)getGroupInfo:(NSString *)groupId complete:(void (^)(RCGroup *groupInfo))completeBlock {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        [[RCInfoManagement sharedInstance] getGroupInfo:groupId complete:completeBlock];
    } else {
        [[RCInfoProvider sharedManager] getGroupInfo:groupId complete:completeBlock];
    }
}

- (RCGroup *)getGroupInfoFromCacheOnly:(NSString *)groupId {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        return [[RCInfoManagement sharedInstance] getGroupInfoFromCacheOnly:groupId];
    } else {
        return [[RCInfoProvider sharedManager] getGroupInfoFromCacheOnly:groupId];
    }
}

- (void)updateGroupInfo:(RCGroup *)groupInfo forGroupId:(NSString *)groupId {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        [[RCInfoManagement sharedInstance] refreshGroupInfo:groupInfo];
    } else {
        [[RCInfoProvider sharedManager] updateGroupInfo:groupInfo forGroupId:groupId];
    }
}

- (void)clearGroupInfo:(NSString *)groupId {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        [[RCInfoManagement sharedInstance] clearGroupInfo:groupId];
    } else {
        [[RCInfoProvider sharedManager] clearGroupInfo:groupId];
    }
}

- (void)clearAllGroupInfo {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement) {
        [[RCInfoManagement sharedInstance] clearAllGroupInfo];
    } else {
        [[RCInfoProvider sharedManager] clearAllGroupInfo];
    }
}

#pragma mark -- PublicService

- (RCPublicServiceProfile *)getPublicServiceProfile:(NSString *)serviceId {
    return [[RCInfoProvider sharedManager] getPublicServiceProfile:serviceId];
}

- (void)updatePublicServiceProfileInfo:(RCPublicServiceProfile *)profileInfo forServiceId:(NSString *)serviceId {
    [self updatePublicServiceProfileInfo:profileInfo forServiceId:serviceId];
}

@end
