//
//  RCInfoManagementCache.h
//  RongIMKit
//
//  Created by zgh on 2024/9/3.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCInfoManagementCache : NSObject

#pragma mark -- user

- (RCUserInfo *)getUserCache:(NSString *)userId;

- (void)cacheUser:(RCUserInfo *)useInfo;

- (void)removeUserCache:(NSString *)userId;

- (void)removeAllUserCache;

#pragma mark -- group

- (RCGroup *)getGroupCache:(NSString *)groupId;

- (void)cacheGroup:(RCGroup *)group;

- (void)removeGroupCache:(NSString *)groupId;

- (void)removeAllGroupCache;

- (RCUserInfo *)getGroupMemberCache:(NSString *)userId groupId:(NSString *)groupId;

- (void)cacheGroupMember:(RCUserInfo *)member groupId:(NSString *)groupId;

- (void)removeGroupMemberCache:(NSString *)userId groupId:(NSString *)groupId;;

- (void)removeAllGroupMemberCache;
@end

NS_ASSUME_NONNULL_END
