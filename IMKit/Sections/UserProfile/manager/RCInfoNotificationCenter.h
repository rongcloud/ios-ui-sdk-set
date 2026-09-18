//
//  RCInfoNotificationCenter.h
//  RongIMKit
//
//  Created by zgh on 2024/9/3.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>
#import <RongPublicService/RongPublicService.h>

NS_ASSUME_NONNULL_BEGIN

//消息分发
FOUNDATION_EXPORT NSString *const RCKitDispatchUserInfoUpdateNotification;
FOUNDATION_EXPORT NSString *const RCKitDispatchGroupUserInfoUpdateNotification;
FOUNDATION_EXPORT NSString *const RCKitDispatchGroupInfoUpdateNotification;
FOUNDATION_EXPORT NSString *const RCKitDispatchPublicServiceInfoNotification;

@interface RCInfoNotificationCenter : NSObject
+ (void)postUserUpdateNotification:(RCUserInfo *)userInfo;

+ (void)postGroupMemberUpdateNotification:(RCUserInfo *)userInfo
                                  groupId:(NSString *)groupId;

+ (void)postGroupUpdateNotification:(RCGroup *)group;

+ (void)postPublicServiceUpdateNotification:(RCPublicServiceProfile *)profileInfo forServiceId:(NSString *)serviceId;
@end

NS_ASSUME_NONNULL_END
