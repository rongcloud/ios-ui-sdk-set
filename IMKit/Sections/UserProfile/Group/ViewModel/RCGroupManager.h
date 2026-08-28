//
//  RCGroupManager.h
//  RongIMKit
//
//  Created by zgh on 2024/8/27.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>
NS_ASSUME_NONNULL_BEGIN

@interface RCGroupManager : NSObject

+ (void)getGroupMembers:(NSString *)groupId
                 option:(RCPagingQueryOption *)option
                   role:(RCGroupMemberRole)role
               complete:(void (^)( RCPagingQueryResult<RCGroupMemberInfo *> * _Nullable result))complete;

+ (void)fetchFriendInfos:(NSArray <RCGroupMemberInfo *> *)members
                complete:(void (^)(NSArray<RCFriendInfo *> * _Nullable friendInfos))complete;

+ (nullable RCFriendInfo *)friendWithUserId:(NSString *)userId
                              inFriendInfos:(NSArray<RCFriendInfo *> *)friendInfos;

/// 格式化群操作失败用户名称，按当前语言处理连接符。
+ (nullable NSString *)groupLimitExceededMemberNames:(nullable NSArray<RCGroupMemberInfo *> *)members;

@end

NS_ASSUME_NONNULL_END
