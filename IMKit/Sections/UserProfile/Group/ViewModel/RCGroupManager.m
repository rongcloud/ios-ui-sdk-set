//
//  RCGroupManager.m
//  RongIMKit
//
//  Created by zgh on 2024/8/27.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupManager.h"
#import "NSMutableArray+RCOperation.h"

@interface RCPagingQueryResult<T> ()

/// 当前分页的数据
@property (nonatomic, copy) NSArray<T> *data;

@end


@implementation RCGroupManager
+ (void)getGroupMembers:(NSString *)groupId option:(RCPagingQueryOption *)option role:(RCGroupMemberRole)role complete:(void (^)(RCPagingQueryResult<RCGroupMemberInfo *> * _Nullable))complete {
    [self getGroupMembers:3 groupId:groupId option:option role:role complete:complete];
}

+ (void)getGroupMembers:(NSInteger)count groupId:(NSString *)groupId option:(RCPagingQueryOption *)option role:(RCGroupMemberRole)role complete:(void (^)(RCPagingQueryResult<RCGroupMemberInfo *> * _Nullable))complete {
    //最多尝试3次
    if (count <= 0) {
        return complete(nil);
    }
    if (role == RCGroupMemberRoleUndef) {
        
        [[RCCoreClient sharedCoreClient] getGroupMembersByRole:groupId role:(RCGroupMemberRoleOwner) option:option success:^(RCPagingQueryResult<RCGroupMemberInfo *> * _Nonnull ownerResult) {
            option.count = option.count - ownerResult.data.count;
            if (option.count < 0) {
                complete(ownerResult);
                return;
            }
            [[RCCoreClient sharedCoreClient] getGroupMembersByRole:groupId role:(RCGroupMemberRoleManager) option:option success:^(RCPagingQueryResult<RCGroupMemberInfo *> * _Nonnull managerResult) {
                option.count = option.count - managerResult.data.count;
                if (option.count < 0) {
                    RCPagingQueryResult *queryResult = managerResult;
                    NSMutableArray *list = [NSMutableArray array];
                    if (ownerResult.data.count > 0) {
                        [list addObjectsFromArray:ownerResult.data];
                    }
                    if (managerResult.data.count > 0) {
                        [list addObjectsFromArray:managerResult.data];
                    }
                    queryResult.data = list.copy;
                    complete(queryResult);
                    return;
                }
                [[RCCoreClient sharedCoreClient] getGroupMembersByRole:groupId role:(RCGroupMemberRoleNormal) option:option success:^(RCPagingQueryResult<RCGroupMemberInfo *> * _Nonnull normalResult) {
                    RCPagingQueryResult *queryResult = normalResult;
                    NSMutableArray *list = [NSMutableArray array];
                    if (ownerResult.data.count > 0) {
                        [list addObjectsFromArray:ownerResult.data];
                    }
                    if (managerResult.data.count > 0) {
                        [list addObjectsFromArray:managerResult.data];
                    }
                    if (normalResult.data.count > 0) {
                        [list addObjectsFromArray:normalResult.data];
                    }
                    queryResult.data = list.copy;
                    complete(queryResult);
                } error:^(RCErrorCode errorCode) {
                    complete(nil);
                    RCLogE(@"获取群成员 error: %@",@(errorCode));
                }];
            } error:^(RCErrorCode errorCode) {
                complete(nil);
                RCLogE(@"获取群成员 error: %@",@(errorCode));
            }];
        } error:^(RCErrorCode errorCode) {
            RCLogE(@"获取群成员 error: %@",@(errorCode));
            if (errorCode == NET_DATA_IS_SYNCHRONIZING) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self getGroupMembers:count - 1 groupId:groupId option:option role:role complete:complete];
                });
            } else {
                complete(nil);
            }
        }];
    } else {
        [[RCCoreClient sharedCoreClient] getGroupMembersByRole:groupId role:role option:option success:^(RCPagingQueryResult<RCGroupMemberInfo *> * _Nonnull normalResult) {
            complete(normalResult);
        } error:^(RCErrorCode errorCode) {
            RCLogE(@"获取群成员 error: %@",@(errorCode));
            if (errorCode == NET_DATA_IS_SYNCHRONIZING) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self getGroupMembers:count - 1 groupId:groupId option:option role:role complete:complete];
                });
            } else {
                complete(nil);
            }
        }];
    }
}

+ (void)fetchFriendInfos:(NSArray *)members complete:(void (^)(NSArray<RCFriendInfo *> * _Nullable))complete {
    NSMutableArray *userIdList = [NSMutableArray array];
    for (RCGroupMemberInfo *member in members) {
        [userIdList rclib_addObject:member.userId];
    }
    if (userIdList.count == 0) {
        return complete(nil);
    }
    [[RCCoreClient sharedCoreClient] getFriendsInfo:userIdList success:^(NSArray<RCFriendInfo *> * _Nonnull friendInfos) {
        complete(friendInfos);
    } error:^(RCErrorCode errorCode) {
        complete(nil);
    }];
}

+ (nullable RCFriendInfo *)friendWithUserId:(NSString *)userId inFriendInfos:(NSArray<RCFriendInfo *> *)friendInfos {
    for (RCFriendInfo *info in friendInfos) {
        if ([info.userId isEqualToString:userId]) {
            return info;
        }
    }
    return nil;
}
@end
