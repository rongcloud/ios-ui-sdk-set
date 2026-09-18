//
//  RCInfoNotificationCenter.m
//  RongIMKit
//
//  Created by zgh on 2024/9/3.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCInfoNotificationCenter.h"

NSString *const RCKitDispatchUserInfoUpdateNotification = @"RCKitDispatchUserInfoUpdateNotification";
NSString *const RCKitDispatchGroupUserInfoUpdateNotification = @"RCKitDispatchGroupUserInfoUpdateNotification";
NSString *const RCKitDispatchGroupInfoUpdateNotification = @"RCKitDispatchGroupInfoUpdateNotification";
NSString *const RCKitDispatchPublicServiceInfoNotification = @"RCKitDispatchPublicServiceInfoNotification";

@implementation RCInfoNotificationCenter
#pragma mark -- post notification

+ (void)postUserUpdateNotification:(RCUserInfo *)userInfo {
    if (userInfo.userId) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchUserInfoUpdateNotification
                                                            object:@{
                                                                @"userId" : userInfo.userId,
                                                                @"userInfo" : userInfo
                                                            }];
    }
}

+ (void)postGroupMemberUpdateNotification:(RCUserInfo *)userInfo
                                groupId:(NSString *)groupId {
    if (groupId && userInfo.userId) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchGroupUserInfoUpdateNotification
                                                            object:@{
                                                                @"userId" : userInfo.userId,
                                                                @"userInfo" : userInfo,
                                                                @"inGroupId" : groupId
                                                            }];
    }
}

+ (void)postGroupUpdateNotification:(RCGroup *)group {
    if (group.groupId) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchGroupInfoUpdateNotification
                                                            object:@{
            @"groupId" : group.groupId,
            @"groupInfo" : group
        }];
    }
}

+ (void)postPublicServiceUpdateNotification:(id)profileInfo forServiceId:(NSString *)serviceId {
    if (profileInfo && serviceId) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchPublicServiceInfoNotification
        object:@{
            @"serviceId" : serviceId,
            @"serviceInfo" : profileInfo
        }];
    }
}
@end
