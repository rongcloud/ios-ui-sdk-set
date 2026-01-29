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
#import "RCKitCommonDefine.h"
#import "RCIMThreadLock.h"
#import "NSMutableArray+RCOperation.h"

static NSUInteger const RC_KIT_FETCH_INFO_UINT_6 = 6;
static float const RC_KIT_FETCH_INFO_DELAY_TIME = 0.5;
static NSUInteger const RC_KIT_BATCH_FETCH_SIZE = 100;

@interface RCInfoManagement ()<RCGroupEventDelegate, RCFriendEventDelegate, RCConnectionStatusChangeDelegate, RCSubscribeEventDelegate>

@property (nonatomic, strong) RCInfoManagementCache *cache;

@property (nonatomic, copy) NSString *userId;

/// 正在请求中的 userId 集合（使用 userFetchingLock 保护）
@property (nonatomic, strong) NSMutableSet<NSString *> *fetchingUserIds;

/// 正在请求中的群成员key集合（格式：groupId_userId）
@property (nonatomic, strong) NSMutableSet<NSString *> *fetchingGroupMemberKeys;

/// 正在请求中的群组ID集合
@property (nonatomic, strong) NSMutableSet<NSString *> *fetchingGroupIds;

/// 读写锁，用于保护 fetchingUserIds 的并发读、独占写
@property (nonatomic, strong) RCIMThreadLock *userFetchingLock;

/// 读写锁，用于保护 fetchingGroupMemberKeys 的并发读、独占写
@property (nonatomic, strong) RCIMThreadLock *memberFetchingLock;

/// 读写锁，用于保护 fetchingGroupIds 的并发读、独占写
@property (nonatomic, strong) RCIMThreadLock *groupFetchingLock;

@end

@implementation RCInfoManagement

+ (instancetype)sharedInstance {
    static RCInfoManagement *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.userId = [RCCoreClient sharedCoreClient].currentUserInfo.userId;
        
        // 初始化读写锁
        instance.userFetchingLock = [RCIMThreadLock new];
        instance.memberFetchingLock = [RCIMThreadLock new];
        instance.groupFetchingLock = [RCIMThreadLock new];
        
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
    
    // 判断是否正在请求中
    if ([self p_isUserFetching:userId]) {
        DebugLog(@"[InfoManagement] user is fetching: %@", userId);
        return nil;
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

- (NSArray<RCUserInfo *> *)getUserInfosFromCacheOnly:(NSArray<NSString *> *)userIds {
    if (userIds.count == 0) {
        return @[];
    }
    
    NSMutableArray *cachedUsers = [NSMutableArray array];
    for (NSString *userId in userIds) {
        RCUserInfo *user = [self.cache getUserCache:userId];
        if (user) {
            [cachedUsers addObject:user];
        }
    }
    
    return [cachedUsers copy];
}

- (void)loadUserInfos:(NSArray<NSString *> *)userIds {
    if (userIds.count == 0) {
        return;
    }
    
    // 1. 获取缓存数据
    NSArray<RCUserInfo *> *cachedUsers = [self getUserInfosFromCacheOnly:userIds];
    
    // 2. 计算缺失的 IDs
    NSMutableSet *cachedUserIdsSet = [NSMutableSet setWithArray:[cachedUsers valueForKey:@"userId"]];
    [cachedUserIdsSet removeObject:[NSNull null]];  // 过滤 nil 转换的 NSNull
    NSMutableSet *missingUserIdsSet = [NSMutableSet setWithArray:userIds];
    [missingUserIdsSet minusSet:cachedUserIdsSet];
    
    // 3. 如果全部命中缓存，立即返回
    if (missingUserIdsSet.count == 0) {
        return;
    }
    
    // 4. 过滤并标记正在请求中的，直接调用批量拉取（依赖通知更新，不使用回调）
    NSArray *userIdsToFetch = [self p_filterAndMarkFetchingUserIds:missingUserIdsSet.allObjects];
    if (userIdsToFetch.count > 0) {
        [self p_batchFetchUserInfos:userIdsToFetch complete:nil];
    }
}

- (void)fetchUserInfos:(NSArray<NSString *> *)userIds {
    if (userIds.count == 0) {
        return;
    }
    
    // 过滤并标记正在请求中的，直接调用批量拉取（依赖通知更新）
    NSArray *userIdsToFetch = [self p_filterAndMarkFetchingUserIds:userIds];
    if (userIdsToFetch.count > 0) {
        [self p_batchFetchUserInfos:userIdsToFetch complete:nil];
    }
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
    
    // 判断是否正在请求中
    if ([self p_isGroupMemberFetching:userId groupId:groupId]) {
        DebugLog(@"[InfoManagement] group member is fetching: %@ in group: %@", userId, groupId);
        return nil;
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

- (NSArray<RCUserInfo *> *)getGroupMembersFromCacheOnly:(NSArray<NSString *> *)userIds withGroupId:(NSString *)groupId {
    if (userIds.count == 0 || groupId.length == 0) {
        return @[];
    }
    NSMutableArray *cachedUsers = [NSMutableArray array];
    for (NSString *userId in userIds) {
        RCUserInfo *user = [self.cache getGroupMemberCache:userId groupId:groupId];
        if (user) {
            [cachedUsers addObject:user];
        }
    }
    return [cachedUsers copy];
}

- (void)preloadGroupMembers:(NSArray<NSString *> *)userIds 
                 inGroup:(NSString *)groupId {
    if (userIds.count == 0 || groupId.length == 0) {
        return;
    }
    
    // 1. 获取缓存数据
    NSArray<RCUserInfo *> *cachedMembers = [self getGroupMembersFromCacheOnly:userIds withGroupId:groupId];
    
    // 2. 计算缺失的 IDs
    NSMutableSet *cachedUserIdsSet = [NSMutableSet setWithArray:[cachedMembers valueForKey:@"userId"]];
    [cachedUserIdsSet removeObject:[NSNull null]];  // 过滤 nil 转换的 NSNull
    NSMutableSet *missingUserIdsSet = [NSMutableSet setWithArray:userIds];
    [missingUserIdsSet minusSet:cachedUserIdsSet];
    
    // 3. 如果全部命中缓存，立即返回
    if (missingUserIdsSet.count == 0) {
        return;
    }
    
    // 4. 过滤并标记正在请求中的，直接调用批量拉取
    NSArray *userIdsToFetch = [self p_filterAndMarkFetchingGroupMemberKeys:missingUserIdsSet.allObjects 
                                                                    groupId:groupId];
    if (userIdsToFetch.count > 0) {
        [self p_batchFetchGroupMembers:userIdsToFetch groupId:groupId complete:nil];
    }
}

- (void)fetchGroupMembers:(NSArray<NSString *> *)userIds withGroupId:(NSString *)groupId {
    if (userIds.count == 0 || !groupId) {
        return;
    }
    
    // 过滤并标记正在请求中的，直接调用批量拉取（依赖通知更新）
    NSArray *userIdsToFetch = [self p_filterAndMarkFetchingGroupMemberKeys:userIds groupId:groupId];
    if (userIdsToFetch.count > 0) {
        [self p_batchFetchGroupMembers:userIdsToFetch groupId:groupId complete:nil];
    }
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
    
    // 快速检查：用读锁并发判断是否正在请求中
    if ([self p_isGroupFetching:groupId]) {
        DebugLog(@"[InfoManagement] group is fetching: %@", groupId);
        return nil;
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

- (NSArray<RCGroup *> *)getGroupInfosFromCacheOnly:(NSArray<NSString *> *)groupIds {
    if (groupIds.count == 0) {
        return @[];
    }
    NSMutableArray *cachedGroups = [NSMutableArray array];
    for (NSString *groupId in groupIds) {
        RCGroup *group = [self.cache getGroupCache:groupId];
        if (group) {
            [cachedGroups addObject:group];
        }
    }
    return [cachedGroups copy];
}

- (void)preloadGroupInfos:(NSArray<NSString *> *)groupIds {
    if (groupIds.count == 0) {
        return;
    }
    
    // 1. 获取缓存数据
    NSArray<RCGroup *> *cachedGroups = [self getGroupInfosFromCacheOnly:groupIds];
    
    // 2. 计算缺失的 IDs
    NSMutableSet *cachedGroupIdsSet = [NSMutableSet setWithArray:[cachedGroups valueForKey:@"groupId"]];
    [cachedGroupIdsSet removeObject:[NSNull null]];
    NSMutableSet *missingGroupIdsSet = [NSMutableSet setWithArray:groupIds];
    [missingGroupIdsSet minusSet:cachedGroupIdsSet];
    
    // 3. 如果全部命中缓存，立即返回
    if (missingGroupIdsSet.count == 0) {
        return;
    }
    
    // 4. 过滤并标记正在请求中的，直接调用批量拉取（依赖通知更新，不使用回调）
    NSArray *groupIdsToFetch = [self p_filterAndMarkFetchingGroupIds:missingGroupIdsSet.allObjects];
    if (groupIdsToFetch.count > 0) {
        [self p_batchFetchGroupInfos:groupIdsToFetch complete:nil];
    }
}

- (void)fetchGroupInfos:(NSArray<NSString *> *)groupIds {
    if (groupIds.count == 0) {
        return;
    }
    
    // 过滤并标记正在请求中的，直接调用批量拉取（依赖通知更新）
    NSArray *groupIdsToFetch = [self p_filterAndMarkFetchingGroupIds:groupIds];
    if (groupIdsToFetch.count > 0) {
        [self p_batchFetchGroupInfos:groupIdsToFetch complete:nil];
    }
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
#pragma mark -- private batch fetch

/// 通用的批次递归处理
/// @param allItems 所有待处理项（ID 数组）
/// @param startIndex 当前批次起始索引
/// @param accumulatedResults 累积的结果数组
/// @param batchProcessor 批次处理 block，接收 (批次items, 批次范围起点, 批次范围终点, 继续回调)
- (void)p_processBatchItems:(NSArray *)allItems
                  startIndex:(NSUInteger)startIndex
          accumulatedResults:(NSMutableArray *)accumulatedResults
              batchProcessor:(void(^)(NSArray *batchItems, 
                                      NSUInteger batchStart, 
                                      NSUInteger batchEnd, 
                                      void(^continueNextBatch)(void)))batchProcessor
                    complete:(nullable void(^)(NSArray *results))complete {
    // 递归终止条件
    if (startIndex >= allItems.count) {
        if (complete) {
            complete([accumulatedResults copy]);
        }
        return;
    }
    
    // 计算当前批次范围
    NSUInteger endIndex = MIN(startIndex + RC_KIT_BATCH_FETCH_SIZE, allItems.count);
    NSArray *batchItems = [allItems subarrayWithRange:NSMakeRange(startIndex, endIndex - startIndex)];
    
    // 执行批次处理逻辑
    batchProcessor(batchItems, startIndex, endIndex, ^{
        // 继续处理下一批
        [self p_processBatchItems:allItems
                       startIndex:endIndex
               accumulatedResults:accumulatedResults
                   batchProcessor:batchProcessor
                         complete:complete];
    });
}

- (NSArray<NSString *> *)p_filterAndMarkFetching:(NSArray<NSString *> *)items
                                      fetchingSet:(NSMutableSet<NSString *> *)fetchingSet
                                             lock:(RCIMThreadLock *)lock {
    if (items.count == 0) {
        return @[];
    }
    NSMutableSet *itemsToFetchSet = [NSMutableSet setWithArray:items];
    [lock performWriteLockBlock:^{
        // 计算需要请求的 items
        [itemsToFetchSet minusSet:fetchingSet];
        // 标记为请求中
        [fetchingSet unionSet:itemsToFetchSet];
    }];
    return [itemsToFetchSet allObjects];
}

- (void)p_removeFetching:(NSArray<NSString *> *)items
             fetchingSet:(NSMutableSet<NSString *> *)fetchingSet
                    lock:(RCIMThreadLock *)lock {
    if (items.count == 0) {
        return;
    }
    NSSet *itemsSet = [NSSet setWithArray:items];
    [lock performWriteLockBlock:^{
        [fetchingSet minusSet:itemsSet];
    }];
}

/// 用户是否正在请求中，YES 表示正在请求中
- (BOOL)p_isUserFetching:(NSString *)userId {
    if (!userId) return NO;
    
    __block BOOL result = NO;
    [self.userFetchingLock performReadLockBlock:^{
        result = [self.fetchingUserIds containsObject:userId];
    }];
    return result;
}

/// 过滤掉正在请求中的 userId，并将新的 userId 标记为请求中，返回需要请求的 userId 数组
- (NSArray<NSString *> *)p_filterAndMarkFetchingUserIds:(NSArray<NSString *> *)userIds {
    return [self p_filterAndMarkFetching:userIds
                             fetchingSet:self.fetchingUserIds
                                    lock:self.userFetchingLock];
}

/// 请求完成后，从 fetchingUserIds 中移除
- (void)p_removeFetchingUserIds:(NSArray<NSString *> *)userIds {
    [self p_removeFetching:userIds
               fetchingSet:self.fetchingUserIds
                      lock:self.userFetchingLock];
}

/// 群成员是否正在请求中，YES 表示正在请求中
- (BOOL)p_isGroupMemberFetching:(NSString *)userId groupId:(NSString *)groupId {
    if (!userId || !groupId) return NO;
    
    __block BOOL result = NO;
    NSString *key = [NSString stringWithFormat:@"%@_%@", groupId, userId];
    [self.memberFetchingLock performReadLockBlock:^{
        result = [self.fetchingGroupMemberKeys containsObject:key];
    }];
    return result;
}

- (NSArray<NSString *> *)p_filterAndMarkFetchingGroupMemberKeys:(NSArray<NSString *> *)userIds
                                                        groupId:(NSString *)groupId {
    if (userIds.count == 0 || !groupId) {
        return @[];
    }
    
    // 构建所有 key
    NSMutableSet *inputKeys = [NSMutableSet setWithCapacity:userIds.count];
    for (NSString *userId in userIds) {
        NSString *key = [NSString stringWithFormat:@"%@_%@", groupId, userId];
        [inputKeys addObject:key];
    }
    
    [self.memberFetchingLock performWriteLockBlock:^{
        // 需要请求的 keys
        [inputKeys minusSet:self.fetchingGroupMemberKeys];
        // 标记为请求中
        [self.fetchingGroupMemberKeys unionSet:inputKeys];
    }];
    
    // 从 keys 还原为 userIds
    NSUInteger prefixLength = groupId.length + 1;  // "groupId_" 的长度
    NSMutableArray *userIdsToFetch = [NSMutableArray arrayWithCapacity:inputKeys.count];
    for (NSString *key in inputKeys) {
        // 从 "groupId_userId" 中提取 userId（跳过 "groupId_" 部分）
        if (key.length > prefixLength) {
            NSString *userId = [key substringFromIndex:prefixLength];
            [userIdsToFetch rclib_addObject:userId];
        }
    }
    return [userIdsToFetch copy];
}

/// 移除群成员请求中标记
- (void)p_removeFetchingGroupMemberKeys:(NSArray<NSString *> *)userIds
                                groupId:(NSString *)groupId {
    if (userIds.count == 0 || !groupId) {
        return;
    }
    
    NSMutableSet *keysToRemove = [NSMutableSet setWithCapacity:userIds.count];
    for (NSString *userId in userIds) {
        NSString *key = [NSString stringWithFormat:@"%@_%@", groupId, userId];
        [keysToRemove addObject:key];
    }
    
    
    [self.memberFetchingLock performWriteLockBlock:^{
        [self.fetchingGroupMemberKeys minusSet:keysToRemove];
    }];
}

/// 群组是否正在请求中，YES 表示正在请求中
- (BOOL)p_isGroupFetching:(NSString *)groupId {
    if (!groupId) return NO;
    
    __block BOOL result = NO;
    [self.groupFetchingLock performReadLockBlock:^{
        result = [self.fetchingGroupIds containsObject:groupId];
    }];
    return result;
}

/// 过滤并标记正在请求中的群组，返回需要请求的群组ID数组
- (NSArray<NSString *> *)p_filterAndMarkFetchingGroupIds:(NSArray<NSString *> *)groupIds {
    return [self p_filterAndMarkFetching:groupIds
                             fetchingSet:self.fetchingGroupIds
                                    lock:self.groupFetchingLock];
}

/// 移除群组请求中标记
- (void)p_removeFetchingGroupIds:(NSArray<NSString *> *)groupIds {
    [self p_removeFetching:groupIds
               fetchingSet:self.fetchingGroupIds
                      lock:self.groupFetchingLock];
}

/// 批量获取群成员信息
- (void)p_batchFetchGroupMembers:(NSArray<NSString *> *)userIds
                         groupId:(NSString *)groupId
                        complete:(nullable void (^)(NSArray<RCUserInfo *> *))complete {
    if (userIds.count == 0 || groupId.length == 0) {
        if (complete) {
            complete(@[]);
        }
        return;
    }
    
    NSMutableArray *accumulatedResults = [NSMutableArray array];
    [self p_processBatchItems:userIds
                   startIndex:0
           accumulatedResults:accumulatedResults
               batchProcessor:^(NSArray *batchUserIds, NSUInteger batchStart, NSUInteger batchEnd, void(^continueNextBatch)(void)) {
        
        [self p_batchGetGroupMembers:batchUserIds
                             groupId:groupId
                          retryCount:RC_KIT_FETCH_INFO_UINT_6
                            complete:^(NSArray<RCGroupMemberInfo *> *groupMembers) {
            
            // 处理获取到的群成员信息：缓存 + 发通知 + 触发回调 + 收集结果
            for (RCGroupMemberInfo *memberInfo in groupMembers) {
                RCUserInfo *user = [RCUserInfo new];
                user.rc_member = memberInfo;
                
                [self.cache cacheGroupMember:user groupId:groupId];
                [RCInfoNotificationCenter postGroupMemberUpdateNotification:user groupId:groupId];
                
                [accumulatedResults addObject:user];
            }
            
            // 移除当前批次的请求中标记
            [self p_removeFetchingGroupMemberKeys:batchUserIds groupId:groupId];
            
            // 继续处理下一批
            continueNextBatch();
        }];
    } complete:complete];
}

/// 批量获取群成员信息（带重试）
- (void)p_batchGetGroupMembers:(NSArray<NSString *> *)userIds
                       groupId:(NSString *)groupId
                    retryCount:(NSUInteger)retryCount
                      complete:(void (^)(NSArray<RCGroupMemberInfo *> *groupMembers))complete {
    [[RCCoreClient sharedCoreClient] getGroupMembers:groupId userIds:userIds success:^(NSArray<RCGroupMemberInfo *> *groupMembers) {
        if (complete) {
            complete(groupMembers ?: @[]);
        }
    } error:^(RCErrorCode errorCode) {
        // 数据同步中或网络不可用时重试
        if ((errorCode == NET_DATA_IS_SYNCHRONIZING || errorCode == RC_REQUEST_OVERFREQUENCY) && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_batchGetGroupMembers:userIds groupId:groupId retryCount:retryCount - 1 complete:complete];
            });
        } else {
            // 失败时返回空数组
            if (complete) {
                complete(@[]);
            }
        }
    }];
}

/// 批量获取群组信息（分批处理入口）
- (void)p_batchFetchGroupInfos:(NSArray<NSString *> *)groupIds
                      complete:(nullable void (^)(NSArray<RCGroup *> *))complete {
    if (groupIds.count == 0) {
        if (complete) {
            complete(@[]);
        }
        return;
    }
    
    NSMutableArray *accumulatedResults = [NSMutableArray array];
    [self p_processBatchItems:groupIds
                   startIndex:0
           accumulatedResults:accumulatedResults
               batchProcessor:^(NSArray *batchGroupIds, NSUInteger batchStart, NSUInteger batchEnd, void(^continueNextBatch)(void)) {
        
        [self p_batchGetGroupInfos:batchGroupIds
                        retryCount:RC_KIT_FETCH_INFO_UINT_6
                          complete:^(NSArray<RCGroupInfo *> *groupInfos) {
            
            // 处理获取到的群组信息：缓存 + 发通知 + 触发回调 + 收集结果
            for (RCGroupInfo *groupInfo in groupInfos) {
                RCGroup *group = [RCGroup new];
                group.rc_group = groupInfo;
                
                [self.cache cacheGroup:group];
                [RCInfoNotificationCenter postGroupUpdateNotification:group];
                
                [accumulatedResults addObject:group];
            }
            
            // 移除当前批次的请求中标记
            [self p_removeFetchingGroupIds:batchGroupIds];
            
            // 继续处理下一批
            continueNextBatch();
        }];
    } complete:complete];
}

/// 批量获取群组信息（带重试）
- (void)p_batchGetGroupInfos:(NSArray<NSString *> *)groupIds
                   retryCount:(NSUInteger)retryCount
                     complete:(void (^)(NSArray<RCGroupInfo *> *groupInfos))complete {
    [[RCCoreClient sharedCoreClient] getGroupsInfo:groupIds success:^(NSArray<RCGroupInfo *> *groupInfos) {
        if (complete) {
            complete(groupInfos ?: @[]);
        }
    } error:^(RCErrorCode errorCode) {
        // 数据同步中或网络不可用时重试
        if ((errorCode == NET_DATA_IS_SYNCHRONIZING || errorCode == RC_REQUEST_OVERFREQUENCY) && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_batchGetGroupInfos:groupIds retryCount:retryCount - 1 complete:complete];
            });
        } else {
            // 失败时返回空数组
            if (complete) {
                complete(@[]);
            }
        }
    }];
}

/// 批量获取用户信息入口，分批处理，带回调
- (void)p_batchFetchUserInfos:(NSArray<NSString *> *)userIds complete:(nullable void (^)(NSArray<RCUserInfo *> *users))complete {
    if (userIds.count == 0) {
        if (complete) {
            complete(@[]);
        }
        return;
    }
    
    NSMutableArray *accumulatedResults = [NSMutableArray array];
    [self p_processBatchItems:userIds
                   startIndex:0
           accumulatedResults:accumulatedResults
               batchProcessor:^(NSArray *batchUserIds, NSUInteger batchStart, NSUInteger batchEnd, void(^continueNextBatch)(void)) {
        
        // 第一步：批量获取好友信息
        [self p_batchGetFriendsInfo:batchUserIds
                         retryCount:RC_KIT_FETCH_INFO_UINT_6
                           complete:^(NSArray<RCFriendInfo *> *friendInfos) {
            
            // 处理获取到的好友信息：缓存 + 发通知 + 触发回调 + 收集结果
            NSMutableSet *foundUserIds = [NSMutableSet set];
            for (RCFriendInfo *friendInfo in friendInfos) {
                RCUserInfo *user = [RCUserInfo new];
                user.rc_friendInfo = friendInfo;
                
                [self.cache cacheUser:user];
                [RCInfoNotificationCenter postUserUpdateNotification:user];
                
                if (friendInfo.userId) {
                    [foundUserIds addObject:friendInfo.userId];
                }
                [accumulatedResults addObject:user];
            }
            
            // 移除已获取用户的请求中标记
            [self p_removeFetchingUserIds:[foundUserIds allObjects]];
            
            // 收集未获取到的用户 ID
            NSMutableArray *notFoundUserIds = [NSMutableArray array];
            for (NSString *userId in batchUserIds) {
                if (![foundUserIds containsObject:userId]) {
                    [notFoundUserIds addObject:userId];
                }
            }
            
            // 第二步：对未获取到的用户请求用户信息
            if (notFoundUserIds.count > 0) {
                [self p_batchGetUserProfiles:notFoundUserIds 
                                  retryCount:RC_KIT_FETCH_INFO_UINT_6 
                                    complete:^(NSArray<RCUserProfile *> *profiles) {
                    
                    // 处理获取到的用户信息
                    for (RCUserProfile *profile in profiles) {
                        RCUserInfo *user = [RCUserInfo new];
                        user.rc_profile = profile;
                        
                        [self.cache cacheUser:user];
                        [RCInfoNotificationCenter postUserUpdateNotification:user];
                        
                        [accumulatedResults addObject:user];
                    }
                    
                    // 移除所有未获取到好友信息用户的请求中标记（无论是否获取到 profile）
                    [self p_removeFetchingUserIds:notFoundUserIds];
                    
                    // 继续处理下一批
                    continueNextBatch();
                }];
            } else {
                // 当前批次全部从好友信息获取，继续下一批
                continueNextBatch();
            }
        }];
    } complete:complete];
}

/// 批量获取好友信息（带重试）
- (void)p_batchGetFriendsInfo:(NSArray<NSString *> *)userIds 
                   retryCount:(NSUInteger)retryCount 
                     complete:(void (^)(NSArray<RCFriendInfo *> *friendInfos))complete {
    [[RCCoreClient sharedCoreClient] getFriendsInfo:userIds success:^(NSArray<RCFriendInfo *> *friendInfos) {
        if (complete) {
            complete(friendInfos ?: @[]);
        }
    } error:^(RCErrorCode errorCode) {
        // 数据同步中时重试
        if ((errorCode == NET_DATA_IS_SYNCHRONIZING || errorCode == RC_REQUEST_OVERFREQUENCY) && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_batchGetFriendsInfo:userIds retryCount:retryCount - 1 complete:complete];
            });
        } else {
            // 失败时返回空数组，让后续逻辑去请求用户信息
            if (complete) {
                complete(@[]);
            }
        }
    }];
}

/// 批量获取用户信息（带重试）
- (void)p_batchGetUserProfiles:(NSArray<NSString *> *)userIds 
                    retryCount:(NSUInteger)retryCount 
                      complete:(void (^)(NSArray<RCUserProfile *> *profiles))complete {
    [[RCCoreClient sharedCoreClient] getUserProfiles:userIds success:^(NSArray<RCUserProfile *> *userProfiles) {
        if (complete) {
            complete(userProfiles ?: @[]);
        }
    } error:^(RCErrorCode errorCode) {
        // 数据同步中时重试
        if ((errorCode == NET_DATA_IS_SYNCHRONIZING || errorCode == RC_REQUEST_OVERFREQUENCY) && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RC_KIT_FETCH_INFO_DELAY_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_batchGetUserProfiles:userIds retryCount:retryCount - 1 complete:complete];
            });
        } else {
            // 失败时返回空数组
            if (complete) {
                complete(@[]);
            }
        }
    }];
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
        [self p_getMyProflieByRetry:RC_KIT_FETCH_INFO_UINT_6 complete:complete];
    } else {
        [self p_getFriendsInfoByRetry:userId retryCount:RC_KIT_FETCH_INFO_UINT_6 complete:^(RCUserInfo * _Nullable user) {
            if (user) {
                complete(user);
            } else {
                [self p_getUserProfileByRetry:userId retryCount:RC_KIT_FETCH_INFO_UINT_6 complete:complete];
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
    [self p_getGroupMemberByRetry:userId withGroupId:groupId retryCount:RC_KIT_FETCH_INFO_UINT_6 complete:complete];
}

- (void)p_getGroupInfo:(NSString *)groupId complete:(void (^)(RCGroup * _Nullable))complete {
    if (groupId == nil) {
        return complete(nil);
    }
    [self p_getGroupInfoByRetry:groupId retryCount:RC_KIT_FETCH_INFO_UINT_6 complete:complete];
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

- (NSMutableSet<NSString *> *)fetchingUserIds {
    if (!_fetchingUserIds) {
        _fetchingUserIds = [NSMutableSet set];
    }
    return _fetchingUserIds;
}

- (NSMutableSet<NSString *> *)fetchingGroupMemberKeys {
    if (!_fetchingGroupMemberKeys) {
        _fetchingGroupMemberKeys = [NSMutableSet set];
    }
    return _fetchingGroupMemberKeys;
}

- (NSMutableSet<NSString *> *)fetchingGroupIds {
    if (!_fetchingGroupIds) {
        _fetchingGroupIds = [NSMutableSet set];
    }
    return _fetchingGroupIds;
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
