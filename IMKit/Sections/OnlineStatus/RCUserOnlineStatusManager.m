//
//  RCUserOnlineStatusManager.m
//  RongIMKit
//
//  Created by Lang on 11/4/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCUserOnlineStatusManager.h"
#import "RCIM.h"

#pragma mark - 内部类定义

/**
 * 订阅策略结果类（内部使用）
 * 用于封装订阅超限处理时的策略计算结果
 */
@interface RCSubscriptionPlan : NSObject

/// 需要保留的用户ID列表（不包含需要取消订阅和新增订阅的用户）
@property (nonatomic, copy) NSArray<NSString *> *keepUserIds;

/// 需要取消订阅的用户ID列表
@property (nonatomic, copy) NSArray<NSString *> *unsubscribeUserIds;

/// 需要新增订阅的用户ID列表（包含新用户和需要重新订阅的用户）
@property (nonatomic, copy) NSArray<NSString *> *subscribeUserIds;

@end

@implementation RCSubscriptionPlan
@end

/// 默认订阅有效期：7天（单位：秒）
static const NSInteger kRCOnlineStatusDefaultSubscribeExpiry = 7 * 24 * 60 * 60;

/// 订阅过期时间阈值：小于此时间需要重新订阅（1天，单位：秒）
static const NSInteger kRCOnlineStatusSubscribeExpiryThreshold = 1 * 24 * 60 * 60;

/// 默认最大订阅数量
static const NSInteger kRCOnlineStatusMaxSubscribeCount = 1000;

/// 好友查询接口分批最大数量
static const NSInteger kRCOnlineStatusFriendQueryBatchSize = 100;

/// 订阅接口分批最大数量
static const NSInteger kRCOnlineStatusSubscribeBatchSize = 20;

/// 订阅超限后重新订阅的分批大小（逐个订阅，避免再次触发超限）
static const NSInteger kRCOnlineStatusSubscribeMinBatchSize = 1;

/// 批量请求默认重试延迟 500 毫秒（纳秒，用于 dispatch_after）
static const int64_t kRCOnlineStatusBatchRetryDelay = (500 * NSEC_PER_MSEC);

typedef void (^RCBatchRetryBlock)(NSArray * _Nullable retryItems);
typedef void (^RCBatchFailBlock)(RCErrorCode status);
typedef NSArray * _Nonnull (^RCBatchPendingSnapshotBlock)(void);

/// 批量请求结果回调
typedef void (^RCBatchCompletion)(void);

/// - Parameters:
///   - batch: 本批次数据
///   - context: 上下文数据
///   - pendingSnapshot: 获取当前待处理数据快照
///   - batchCompletion: 结果回调，继续处理下一批次数据（整批完成时调用）
///   - retry: 重试回调，retryItems 为 nil 表示按原批次重试（如超频），非空表示只重试指定用户
///   - fail: 失败回调，终止流程（失败时调用）
typedef void (^RCBatchExecutorBlock)(NSArray *batch,
                                     id context,
                                     RCBatchPendingSnapshotBlock pendingSnapshot,
                                     RCBatchCompletion batchCompletion,
                                     RCBatchRetryBlock retry,
                                     RCBatchFailBlock fail);

@interface RCUserOnlineStatusManager ()<RCSubscribeEventDelegate, RCConnectionStatusChangeDelegate, RCFriendEventDelegate>

/// 串行队列，保证线程安全
@property (nonatomic, strong) dispatch_queue_t cacheQueue;

/// 使用 NSCache 缓存在线状态，自动管理内存
/// 注意：NSCache 可能在内存压力时自动淘汰对象，需通过 objectForKey: 查询实际存在性
@property (nonatomic, strong) NSCache<NSString *, RCSubscribeUserOnlineStatus *> *statusCache;

/// 正在请求的用户ID集合，避免重复请求
@property (nonatomic, strong) NSMutableSet<NSString *> *fetchingUserIds;

/// 已订阅的用户ID列表
@property (nonatomic, strong) NSMutableSet<NSString *> *subscribedUserIds;

/// 好友用户ID缓存（用于快速判断好友关系，避免重复查询）
@property (nonatomic, strong) NSMutableSet<NSString *> *friendUserIds;

/// 好友在线状态同步完成标志，这个回调后可以代表用户信息同步完成。
@property (nonatomic, assign) BOOL friendOnlineStatusSyncCompleted;

/// 等待好友用户信息同步完成的用户ID集合
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> *pendingFriendProfileUserIds;

/// 等待好友在线状态同步完成的用户ID集合
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> *pendingFriendOnlineStatusUserIds;

@end

@implementation RCUserOnlineStatusManager

+ (instancetype)sharedManager {
    static RCUserOnlineStatusManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[RCUserOnlineStatusManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化缓存
        _statusCache = [[NSCache alloc] init];
        _statusCache.countLimit = 5000; // 最多缓存 5000 个用户的状态
        _statusCache.name = @"com.rongcloud.onlinestatus.cache";
        
        // 初始化请求集合
        _fetchingUserIds = [NSMutableSet set];
        
        // 初始化已订阅用户ID列表（有序）
        _subscribedUserIds = [NSMutableSet set];
        
        // 初始化好友用户ID缓存
        _friendUserIds = [NSMutableSet set];
        
        // 初始化待处理用户ID集合（保持顺序）
        _pendingFriendProfileUserIds = [NSMutableOrderedSet orderedSet];
        _pendingFriendOnlineStatusUserIds = [NSMutableOrderedSet orderedSet];
        
        // 创建串行队列，保证线程安全
        _cacheQueue = dispatch_queue_create("com.rongcloud.onlinestatus.cache", DISPATCH_QUEUE_SERIAL);
        
        // 注册为订阅事件的监听者
        [[RCCoreClient sharedCoreClient] addSubscribeEventDelegate:self];
        
        // 注册连接状态监听
        [[RCCoreClient sharedCoreClient] addConnectionStatusChangeDelegate:self];
        
        // 注册好友关系变更监听
        [[RCCoreClient sharedCoreClient] addFriendEventDelegate:self];
    }
    return self;
}

- (void)dealloc {
    // 移除监听
    [[RCCoreClient sharedCoreClient] removeSubscribeEventDelegate:self];
    [[RCCoreClient sharedCoreClient] removeConnectionStatusChangeDelegate:self];
    [[RCCoreClient sharedCoreClient] removeFriendEventDelegate:self];
}

#pragma mark - 公开方法

- (void)fetchOnlineStatus:(NSArray<NSString *> *)userIds {
    [self fetchOnlineStatusForUsers:userIds processSubscribeLimit:YES];
}

- (void)fetchOnlineStatus:(NSString *)userId processSubscribeLimit:(BOOL)processSubscribeLimit {
    if (!userId || userId.length == 0) {
        RCLogD(@"Fetch online status, user id is invalid");
        return;
    }
    [self fetchOnlineStatusForUsers:@[userId] processSubscribeLimit:processSubscribeLimit];
}

- (void)fetchFriendOnlineStatus:(NSArray<NSString *> *)userIds {
    if (userIds.count == 0) {
        RCLogD(@"Fetch friend online status, no users to fetch");
        return;
    }
    RCLogD(@"Fetch friend online status, users:%@", userIds);
    if (![self isFriendOnlineStatusSubscribeEnable]) {
        RCLogD(@"fetchFriendOnlineStatus, friend online status subscribe is not enabled");
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.cacheQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        if (!strongSelf.friendOnlineStatusSyncCompleted) {
            // 好友在线状态尚未同步完成，将用户ID加入待处理集合（保持顺序、自动去重）
            NSUInteger beforeCount = strongSelf.pendingFriendOnlineStatusUserIds.count;
            [strongSelf.pendingFriendOnlineStatusUserIds addObjectsFromArray:userIds];
            NSUInteger addedCount = strongSelf.pendingFriendOnlineStatusUserIds.count - beforeCount;
            
            RCLogD(@"Friend online status sync not completed, queuing %lu users (%lu new, %lu duplicates, total pending: %lu)", 
                   (unsigned long)userIds.count, (unsigned long)addedCount, (unsigned long)(userIds.count - addedCount), 
                   (unsigned long)strongSelf.pendingFriendOnlineStatusUserIds.count);
        } else {
            // 好友在线状态已同步完成，切换到全局队列执行请求（避免在 cacheQueue 中调用会再次访问 cacheQueue 的方法导致死锁）
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [strongSelf getSubscribeUsersOnlineStatus:userIds];
            });
        }
    });
}

- (RCSubscribeUserOnlineStatus *)getCachedOnlineStatus:(NSString *)userId {
    if (!userId || userId.length == 0) {
        return nil;
    }
    __block RCSubscribeUserOnlineStatus *status = nil;
    dispatch_sync(self.cacheQueue, ^{
        status = [self.statusCache objectForKey:userId];
    });
    if (status) {
        RCLogD(@"Get cached online status, user:%@, isOnline:%@", userId, status.isOnline ? @"YES" : @"NO");
    }
    return status;
}

- (void)clearCache {
    dispatch_async(self.cacheQueue, ^{
        [self.statusCache removeAllObjects];
        [self.fetchingUserIds removeAllObjects];
        [self.subscribedUserIds removeAllObjects];
        [self.friendUserIds removeAllObjects];
        [self.pendingFriendProfileUserIds removeAllObjects];
        [self.pendingFriendOnlineStatusUserIds removeAllObjects];
        self.friendOnlineStatusSyncCompleted = NO;
    });
}

#pragma mark - RCConnectionStatusChangeDelegate（连接状态监听）

- (void)onConnectionStatusChanged:(RCConnectionStatus)status {
    if (status == ConnectionStatus_Connected) {
        // 连接成功时，检查是否更换了登录用户
        NSString *currentUserId = [RCCoreClient sharedCoreClient].currentUserInfo.userId;
        RCLogD(@"Connected as user: %@", currentUserId);
    } else if (status == ConnectionStatus_SignOut) {
        // 用户切换，清空所有缓存和订阅记录
        NSString *currentUserId = [RCCoreClient sharedCoreClient].currentUserInfo.userId;
        RCLogD(@"User signOut %@ , clearing all cache and subscriptions", currentUserId);
        [self clearCache];
    }
}

#pragma mark - RCSubscribeEventDelegate (订阅事件监听)

- (void)onSubscriptionSyncCompleted:(RCSubscribeType)type {
    if (type == RCSubscribeTypeFriendOnlineStatus) {
        RCLogD(@"Friend online status sync completed");
        
        // 在串行队列中原子性地设置标志并处理待处理请求
        dispatch_async(self.cacheQueue, ^{
            // 设置同步完成标志
            self.friendOnlineStatusSyncCompleted = YES;
            
            [self handlePendingFetchOnlineStatus];
        });
    }
}

- (void)onSubscriptionChangedOnOtherDevices:(NSArray<RCSubscribeEvent *> *)subscribeEvents {
    NSMutableArray<NSString *> *subscribedUsers = [NSMutableArray array];
    NSMutableArray<NSString *> *unsubscribedUsers = [NSMutableArray array];
    
    for (RCSubscribeEvent *event in subscribeEvents) {
        if (event.subscribeType == RCSubscribeTypeOnlineStatus && event.userId.length > 0) {
            if (event.operationType == RCSubscribeOperationTypeSubscribe) {
                [subscribedUsers addObject:event.userId];
            } else {
                [unsubscribedUsers addObject:event.userId];
            }
        }
    }
    if (subscribedUsers.count == 0 && unsubscribedUsers.count == 0) return;
    
    NSArray<NSString *> *addSnapshot = [subscribedUsers copy];
    NSArray<NSString *> *removeSnapshot = [unsubscribedUsers copy];
    dispatch_async(self.cacheQueue, ^{
        // 处理订阅事件：主动获取在线状态
        if (addSnapshot.count > 0) {
            [self.subscribedUserIds addObjectsFromArray:addSnapshot];
            
            RCLogD(@"Other device subscribed users:%@, fetching online status", addSnapshot);
            [self getSubscribeUsersOnlineStatus:addSnapshot];
        }
        
        // 处理取消订阅事件：清除缓存并通知 UI
        if (removeSnapshot.count > 0) {
            [self.subscribedUserIds minusSet:[NSSet setWithArray:removeSnapshot]];
            
            RCLogD(@"Other device unsubscribed users:%@, clearing cache", removeSnapshot);
            [self clearOnlineStatusCache:removeSnapshot];
        }
    });
}

/**
 * 订阅事件变化回调（实时状态变化）
 * 当用户在其他端上线/下线时，SDK 会自动推送到这个方法
 */
- (void)onEventChange:(NSArray<RCSubscribeInfoEvent *> *)subscribeEvents {
    if (!subscribeEvents || subscribeEvents.count == 0) {
        return;
    }
    NSMutableArray<NSString *> *userIds = [NSMutableArray array];
    
    for (RCSubscribeInfoEvent *event in subscribeEvents) {
        // 只处理在线状态事件
        if (event.subscribeType == RCSubscribeTypeOnlineStatus ||
            event.subscribeType == RCSubscribeTypeFriendOnlineStatus) {
            [userIds addObject:event.userId];
        }
    }
    RCLogD(@"Event change, userIds:%@", userIds);
    [self getSubscribeUsersOnlineStatus:userIds.copy];
}

#pragma mark - RCFriendEventDelegate（好友关系变更监听）

/// 添加好友回调
/// 好友不需要订阅即可查询在线状态，因此添加好友后需要取消订阅
/// 但如果缓存中没有该用户的状态，需要主动获取
- (void)onFriendAdd:(NSString *)userId
               name:(NSString *)name
        portraitUri:(NSString *)portraitUri
      directionType:(RCDirectionType)directionType
      operationTime:(long long)operationTime {
    if (!userId || userId.length == 0) {
        return;
    }
    RCLogD(@"onFriendAdd, userId:%@", userId);
    // 更新好友缓存
    dispatch_async(self.cacheQueue, ^{
        [self.friendUserIds addObject:userId];
    });
    
    // 取消订阅（好友不需要订阅）
    [self unsubscribeUsers:@[userId] completion:nil];
    
    if ([self isFriendOnlineStatusSubscribeEnable]) {
        // 开启《客户端好友在线状态变更通知》后，才可以获取好友在线状态
        [self fetchFriendOnlineStatus:@[userId]];
    } else {
        RCLogD(@"onFriendAdd, friend online status subscribe is not enabled");
    }
}

/// 删除好友回调
/// 删除好友后，用户从"好友"变为"非好友"
/// 如果缓存中有该用户的数据，说明之前关注过，需要订阅才能继续获取在线状态
- (void)onFriendDelete:(NSArray<NSString *> *)userIds
         directionType:(RCDirectionType)directionType
         operationTime:(long long)operationTime {
    if (!userIds || userIds.count == 0) {
        return;
    }
    // 更新好友缓存，移除这些用户
    dispatch_async(self.cacheQueue, ^{
        for (NSString *userId in userIds) {
            if (userId && userId.length > 0) {
                [self.friendUserIds removeObject:userId];
            }
        }
    });
    // 订阅这些用户（因为非好友需要订阅）
    [self subscribeUsers:userIds pageSize:0 processSubscribeLimit:YES];
}

/// 清空好友回调
/// 清空所有好友时，缓存中的所有用户都变成了非好友，需要订阅
- (void)onFriendCleared:(long long)operationTime {
    dispatch_async(self.cacheQueue, ^{
        NSArray *subscribeUserIds = [self.friendUserIds copy];
        [self.friendUserIds removeAllObjects];
        // 订阅这些用户（因为他们从好友变成了非好友，需要订阅才能继续获取在线状态）
        [self subscribeUsers:subscribeUserIds pageSize:0 processSubscribeLimit:YES];
    });
}

#pragma mark - 私有方法

/// 判断好友在线状态通知是否开启，此开关在开发者后台配置。
- (BOOL)isFriendOnlineStatusSubscribeEnable {
    return [RCCoreClient sharedCoreClient].getAppSettings.isFriendOnlineStatusSubscribeEnable;
}

- (void)handlePendingFetchOnlineStatus {
    // 处理所有待处理的用户ID
    if (self.pendingFriendProfileUserIds.count > 0) {
        RCLogD(@"Processing %lu pending users after friend profile sync completed",
               (unsigned long)self.pendingFriendProfileUserIds.count);
        
        NSArray<NSString *> *userIdsToProcess = [self.pendingFriendProfileUserIds.array copy];
        [self.pendingFriendProfileUserIds removeAllObjects];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self filterAndFetchOnlineStatus:userIdsToProcess processSubscribeLimit:YES];
        });
    }
    
    // 处理所有待处理的好友在线状态用户ID
    if (self.pendingFriendOnlineStatusUserIds.count > 0) {
        RCLogD(@"Processing %lu pending friend online status users after sync completed",
               (unsigned long)self.pendingFriendOnlineStatusUserIds.count);
        
        NSArray<NSString *> *userIdsToProcess = [self.pendingFriendOnlineStatusUserIds.array copy];
        [self.pendingFriendOnlineStatusUserIds removeAllObjects];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self getSubscribeUsersOnlineStatus:userIdsToProcess];
        });
    }
}

- (void)fetchOnlineStatusForUsers:(NSArray<NSString *> *)userIds
            processSubscribeLimit:(BOOL)processSubscribeLimit {
    if (userIds.count == 0) {
        RCLogD(@"Fetch online status, no users to fetch");
        return;
    }
    RCLogD(@"Fetch online status, users:%@", userIds);
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.cacheQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        if (![strongSelf friendOnlineStatusSyncCompleted]) {
            // 好友信息尚未同步完成，将用户ID加入待处理集合
            NSUInteger beforeCount = strongSelf.pendingFriendProfileUserIds.count;
            [strongSelf.pendingFriendProfileUserIds addObjectsFromArray:userIds];
            NSUInteger addedCount = strongSelf.pendingFriendProfileUserIds.count - beforeCount;
            
            RCLogD(@"Friend sync not completed, queuing %lu users (%lu new, %lu duplicates, total pending: %lu)",
                   (unsigned long)userIds.count, (unsigned long)addedCount, (unsigned long)(userIds.count - addedCount),
                   (unsigned long)strongSelf.pendingFriendProfileUserIds.count);
        } else {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [strongSelf filterAndFetchOnlineStatus:userIds processSubscribeLimit:processSubscribeLimit];
            });
        }
    });
}

- (void)filterAndFetchOnlineStatus:(NSArray<NSString *> *)userIds
             processSubscribeLimit:(BOOL)processSubscribeLimit {
    if (userIds.count == 0) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self filterFriendAndNonFriendUserIds:userIds
                           perBatchResult:^(NSArray<NSString *> * _Nullable friendUserIds,
                                             NSArray<NSString *> * _Nullable nonFriendUserIds) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (nonFriendUserIds.count > 0) {
            [strongSelf subscribeUsers:nonFriendUserIds pageSize:0 processSubscribeLimit:processSubscribeLimit];
        }
        // 如果《客户端好友在线状态变更通知》没有打开，获取好友在线状态是获取不到的
        if (friendUserIds.count > 0 && [strongSelf isFriendOnlineStatusSubscribeEnable]) {
            [strongSelf getSubscribeUsersOnlineStatus:friendUserIds];
        } else {
            RCLogD(@"filterAndFetchOnlineStatus, friend online status subscribe is %@", [strongSelf isFriendOnlineStatusSubscribeEnable] ? @"enabled" : @"disabled");
        }
    } completion:^(BOOL success) {
        if (!success) {
            RCLogD(@"Filter friend/non-friend failed, skip fetching online status");
        }
    }];
}

/// 筛选好友和非好友用户ID
- (void)filterFriendAndNonFriendUserIds:(NSArray<NSString *> *)userIds
                         perBatchResult:(void (^)(NSArray<NSString *> * _Nullable friendUserIds,
                                                  NSArray<NSString *> * _Nullable nonFriendUserIds))perBatchResult
                             completion:(void (^)(BOOL success))completion {
    __block BOOL completionCalled = NO;
    // 全部查询结束
    void (^finish)(BOOL) = ^(BOOL success) {
        if (completionCalled) {
            return;
        }
        completionCalled = YES;
        if (completion) {
            completion(success);
        }
    };
    if (userIds.count == 0) {
        finish(YES);
        return;
    }
    
    // 先从本地缓存 self.friendUserIds 中筛选出已知好友
    __block NSSet *friendCacheSnapshot = nil;
    dispatch_sync(self.cacheQueue, ^{
        friendCacheSnapshot = [self.friendUserIds copy];
    });
    NSMutableOrderedSet<NSString *> *knownFriendIds = [NSMutableOrderedSet orderedSet];
    NSMutableOrderedSet<NSString *> *unknownUserIds = [NSMutableOrderedSet orderedSet];
    for (NSString *userId in userIds) {
        if (![userId isKindOfClass:[NSString class]] || userId.length == 0) {
            continue;
        }
        if ([friendCacheSnapshot containsObject:userId]) {
            [knownFriendIds addObject:userId];
        } else {
            [unknownUserIds addObject:userId];
        }
    }
    
    // 已知好友先行处理
    if (knownFriendIds.count > 0 && perBatchResult) {
        RCLogD(@"Known friend ids:%@", knownFriendIds.array);
        perBatchResult([knownFriendIds.array copy], @[]);
    }

    // 如果剩余的用户ID为空，就直接返回
    if (unknownUserIds.count == 0) {
        RCLogD(@"No unknown user ids, finish");
        finish(YES);
        return;
    }

    __block NSMutableOrderedSet<NSString *> *pendingUnknownUserIds = [unknownUserIds mutableCopy];

    // 对剩余的用户ID进行分批查询
    [self batchQueryFriendsInfo:unknownUserIds.array
                perBatchResult:^(NSArray<NSString *> * _Nullable batchFriendUserIds,
                                  NSArray<NSString *> * _Nullable batchNonFriendUserIds) {
        RCLogD(@"perBatchResult, friendUserIds:%@, nonFriendUserIds:%@", batchFriendUserIds, batchNonFriendUserIds);
        if (batchFriendUserIds.count > 0) {
            NSSet *friendSet = [NSSet setWithArray:batchFriendUserIds];
            dispatch_async(self.cacheQueue, ^{
                // 缓存好友列表
                [self.friendUserIds unionSet:friendSet];
            });
        }
        if (perBatchResult) {
            perBatchResult(batchFriendUserIds, batchNonFriendUserIds);
        }
        
        // 更新剩余未知用户ID列表
        for (NSString *userId in batchFriendUserIds) {
            [pendingUnknownUserIds removeObject:userId];
        }
        for (NSString *userId in batchNonFriendUserIds) {
            [pendingUnknownUserIds removeObject:userId];
        }
    } completion:^(RCErrorCode status) {
        BOOL treatAsSuccess = (status == RC_SUCCESS || status == RC_USER_PROFILE_SERVICE_UNAVAILABLE);
        if (status == RC_USER_PROFILE_SERVICE_UNAVAILABLE &&
            perBatchResult &&
            pendingUnknownUserIds.count > 0) {
            // 当 RC_USER_PROFILE_SERVICE_UNAVAILABLE 时， 相当于没有查询到好友，所有用户视为非好友
            perBatchResult(@[], [pendingUnknownUserIds.array copy]);
        }
        if (!treatAsSuccess) {
            RCLogD(@"Filter failed with status:%ld", (long)status);
        }
        finish(treatAsSuccess);
    }];
}

- (void)batchQueryFriendsInfo:(NSArray<NSString *> *)userIds
              perBatchResult:(void (^)(NSArray<NSString *> * _Nullable friendUserIds,
                                       NSArray<NSString *> * _Nullable nonFriendUserIds))perBatchResult
                   completion:(void (^)(RCErrorCode status))completion {
    
    if (!userIds || userIds.count == 0) {
        if (completion) {
            completion(RC_SUCCESS);
        }
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self processQueueItems:userIds
                  batchSize:kRCOnlineStatusFriendQueryBatchSize
                    context:nil
                   executor:^(NSArray *batch,
                              id context,
                              RCBatchPendingSnapshotBlock pendingSnapshot,
                              RCBatchCompletion batchCompletion,
                              RCBatchRetryBlock retry,
                              RCBatchFailBlock fail) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            fail(ERRORCODE_UNKNOWN);
            return;
        }
        RCLogD(@"Querying friends batch users:%@", batch);
        
        [[RCCoreClient sharedCoreClient] getFriendsInfo:batch
                                                success:^(NSArray<RCFriendInfo *> * _Nonnull friendInfos) {
            NSMutableSet *friendIdSet = [NSMutableSet set];
            for (RCFriendInfo *friendInfo in friendInfos) {
                if (friendInfo.userId
                    && friendInfo.userId.length > 0
                    && friendInfo.directionType == RCDirectionTypeBoth) {
                    [friendIdSet addObject:friendInfo.userId];
                }
            }
            NSMutableArray *batchFriends = [NSMutableArray array];
            NSMutableArray *batchNonFriends = [NSMutableArray array];
            for (NSString *userId in batch) {
                if ([friendIdSet containsObject:userId]) {
                    [batchFriends addObject:userId];
                } else {
                    [batchNonFriends addObject:userId];
                }
            }
            if (perBatchResult) {
                perBatchResult([batchFriends copy], [batchNonFriends copy]);
            }
            // 整批成功，无需重试
            batchCompletion();
        } error:^(RCErrorCode errorCode) {
            RCLogD(@"batchQueryFriendsInfo error, code:%ld", (long)errorCode);
            if (errorCode == RC_REQUEST_OVERFREQUENCY) {
                RCLogD(@"batchQueryFriendsInfo over frequency, users:%@", batch);
                retry(nil);
            } else if (errorCode == RC_USER_PROFILE_SERVICE_UNAVAILABLE) {
                RCLogD(@"User profile service unavailable, treat all as non-friends");
                fail(RC_USER_PROFILE_SERVICE_UNAVAILABLE);
            } else {
                RCLogD(@"batchQueryFriendsInfo failed, code:%ld, users:%@", (long)errorCode, batch);
                fail(errorCode);
            }
        }];
    } completion:^(RCErrorCode status) {
        if (completion) {
            completion(status);
        }
    }];
}

- (void)getSubscribeUsersOnlineStatus:(NSArray<NSString *> *)userIds {
    // 过滤掉正在请求的用户ID，避免重复请求
    __block NSMutableArray *needFetchUserIds = [NSMutableArray array];
    dispatch_sync(self.cacheQueue, ^{
        for (NSString *userId in userIds) {
            if (userId.length > 0 && ![self.fetchingUserIds containsObject:userId]) {
                [needFetchUserIds addObject:userId];
                [self.fetchingUserIds addObject:userId];
            }
        }
    });
    
    // 如果所有用户都在请求中
    if (needFetchUserIds.count == 0) {
        RCLogD(@"Get subscribe users online status, no users to fetch");
        return;
    }
    RCLogD(@"Get subscribe users online status, users:%@", needFetchUserIds);

    [[RCCoreClient sharedCoreClient] getSubscribeUsersOnlineStatus:needFetchUserIds
                                                        completion:^(RCErrorCode code, NSArray<RCSubscribeUserOnlineStatus *> * _Nullable status) {
        RCLogD(@"getSubscribeUsersOnlineStatus, code:%ld", (long)code);
        // 从请求中集合移除
        dispatch_async(self.cacheQueue, ^{
            [self.fetchingUserIds minusSet:[NSSet setWithArray:needFetchUserIds]];
        });
        
        if (code == RC_SUCCESS && status) {
            [self cacheOnlineStatusesAndNotify:status];
        } else if (code == RC_REQUEST_OVERFREQUENCY) {
            RCLogD(@"getSubscribeUsersOnlineStatus over frequency, retry users:%@", needFetchUserIds);
            [self getSubscribeUsersOnlineStatus:needFetchUserIds];
        } else {
            RCLogD(@"getSubscribeUsersOnlineStatus failed, users:%@", needFetchUserIds);
        }
    }];
}

- (void)clearOnlineStatusCache:(NSArray<NSString *> *)userIds {
    if (!userIds || userIds.count == 0) {
        return;
    }
    
    // 在串行队列中执行清除操作
    dispatch_async(self.cacheQueue, ^{
        NSMutableArray *clearedUserIds = [NSMutableArray array];
        
        for (NSString *userId in userIds) {
            if (userId && userId.length > 0) {
                // 检查缓存中是否存在（只通知实际被清除的用户）
                if ([self.statusCache objectForKey:userId] != nil) {
                    // 从缓存中移除
                    [self.statusCache removeObjectForKey:userId];
                    [clearedUserIds addObject:userId];
                }
            }
        }
        
        RCLogD(@"Cleared online status cache for %lu users, users: %@",
               (unsigned long)clearedUserIds.count, [clearedUserIds copy]);
        
        // 如果有缓存被清除，通知外部（主线程）
        if (clearedUserIds.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:RCKitUserOnlineStatusChangedNotification
                                                                    object:nil
                                                                  userInfo:@{RCKitUserOnlineStatusChangedUserIdsKey: [clearedUserIds copy]}];
            });
        }
    });
}

/// 缓存在线状态并通知外部（缓存写入在 cacheQueue 中串行执行，通知在主线程）
- (void)cacheOnlineStatusesAndNotify:(NSArray<RCSubscribeUserOnlineStatus *> *)statuses {
    if (!statuses || statuses.count == 0) {
        return;
    }
    
    NSMutableArray<RCSubscribeUserOnlineStatus *> *validStatuses = [NSMutableArray array];
    
    for (RCSubscribeUserOnlineStatus *status in statuses) {
        if (status.userId.length > 0) {
            [validStatuses addObject:status];
        }
    }
    
    if (validStatuses.count == 0) {
        return;
    }
    
    NSArray<RCSubscribeUserOnlineStatus *> *statusSnapshot = [validStatuses copy];
    
    dispatch_async(self.cacheQueue, ^{
        NSMutableArray<NSString *> *changedUserIds = [NSMutableArray array];
        NSMutableDictionary <NSString *, NSString *> *changedStatus = [NSMutableDictionary dictionary];
        
        for (RCSubscribeUserOnlineStatus *status in statusSnapshot) {
            [self.statusCache setObject:status forKey:status.userId];
            [changedUserIds addObject:status.userId];
            [changedStatus setValue:status.isOnline ? @"YES" : @"NO" forKey:status.userId];
        }
        
        RCLogD(@"Cached online status for users:%@", changedStatus);
        
        if (changedUserIds.count > 0) {
            RCLogD(@"Notify changed online status for users:%@", changedUserIds);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:RCKitUserOnlineStatusChangedNotification
                                                                    object:nil
                                                                  userInfo:@{RCKitUserOnlineStatusChangedUserIdsKey: changedUserIds}];
            });
        }
    });
}

#pragma mark 订阅管理

/// 订阅用户在线状态
- (void)subscribeUsers:(NSArray<NSString *> *)userIds
              pageSize:(NSInteger)pageSize
 processSubscribeLimit:(BOOL)processSubscribeLimit {
    if (userIds.count == 0) {
        return;
    }
    NSInteger batchSize = pageSize > 0 ? pageSize : kRCOnlineStatusSubscribeBatchSize;
    
    __weak typeof(self) weakSelf = self;
    
    [self processQueueItems:userIds
                  batchSize:batchSize
                    context:nil
                   executor:^(NSArray *batch,
                              id context,
                              RCBatchPendingSnapshotBlock pendingSnapshot,
                              RCBatchCompletion batchCompletion,
                              RCBatchRetryBlock retry,
                              RCBatchFailBlock fail) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            fail(ERRORCODE_UNKNOWN);
            return;
        }
        
        RCLogD(@"Subscribing batch users:%@", batch);
        RCSubscribeEventRequest *request = [[RCSubscribeEventRequest alloc] init];
        request.subscribeType = RCSubscribeTypeOnlineStatus;
        request.userIds = batch;
        request.expiry = kRCOnlineStatusDefaultSubscribeExpiry;
        
        [[RCCoreClient sharedCoreClient] subscribeEvent:request completion:^(RCErrorCode status, NSArray<NSString *> * _Nullable failedUserIds) {
            RCLogD(@"subscribeEvent completion code:%ld, users:%@", (long)status, batch);
            switch (status) {
                case RC_SUCCESS: {
                    [strongSelf recordSubscribedUsers:batch];
                    [strongSelf getSubscribeUsersOnlineStatus:batch];
                    // 成功，当前批次无需重试
                    batchCompletion();
                    break;
                }
                case RC_SUBSCRIBE_ONLINE_SERVICE_UNAVAILABLE: {
                    // 在线状态订阅服务不可用，直接终止流程
                    RCLogD(@"Subscribe online service unavailable, terminate subscription process");
                    fail(status);
                    break;
                }
                case RC_BESUBSCRIBED_USERIDS_COUNT_EXCEED_LIMIT: {
                    // 用户被订阅的数量达到上限，failedUserIds 表示被拒绝的用户
                    NSArray *failedList = failedUserIds ?: @[];
                    RCLogD(@"Be-subscribed count exceeded limit for users:%@", failedList);
                    NSMutableArray *retryUsers = [batch mutableCopy];
                    if (failedList.count > 0) {
                        [retryUsers removeObjectsInArray:failedList];
                    }
                    // 被订阅数量超限：失败用户直接丢弃，剩余用户重新入队重试
                    retry([retryUsers copy]);
                    break;
                }
                case RC_SUBSCRIBED_USERIDS_EXCEED_LIMIT: {
                    RCLogD(@"Subscribe count exceeded limit, processSubscribeLimit:%@", processSubscribeLimit ? @"YES" : @"NO");
                    // 当前账号订阅数量超限
                    if (processSubscribeLimit) {
                        // 已经是逐个订阅仍然超限，终止订阅流程
                        // 订阅触发超限，交由淘汰策略处理
                        [strongSelf handleSubscribeExceedLimit];
                    }
                    fail(status);
                    break;
                }
                case RC_REQUEST_OVERFREQUENCY: {
                    // 请求频率过高，延迟默认时间后重试当前批次
                    RCLogD(@"subscribeEvent over frequency, retry users:%@", batch);
                    retry(nil);
                    break;
                }
                default: {
                    RCLogD(@"subscribeEvent failed");
                    fail(status);
                    break;
                }
            }
        }];
    } completion:^(RCErrorCode status) {
        
    }];
}

/// 取消订阅用户在线状态
- (void)unsubscribeUsers:(NSArray<NSString *> *)userIds completion:(void (^)(RCErrorCode status, NSArray<NSString *> * _Nullable failedUserIds))completion {
    if (!userIds || userIds.count == 0) {
        if (completion) {
            completion(INVALID_PARAMETER_USERIDLIST, nil);
        }
        return;
    }
    
    // 开始分批取消订阅
    [self batchUnsubscribeUsers:userIds
                      pageSize:0
               collectedFailed:[NSMutableArray array]
                    completion:completion];
}

- (void)batchUnsubscribeUsers:(NSArray<NSString *> *)userIds
                     pageSize:(NSInteger)pageSize
              collectedFailed:(NSMutableArray<NSString *> *)collectedFailed
                   completion:(void (^)(RCErrorCode status, NSArray<NSString *> * _Nullable failedUserIds))completion {
    if (userIds.count == 0) {
        if (completion) {
            completion(RC_SUCCESS, collectedFailed.count > 0 ? [collectedFailed copy] : nil);
        }
        return;
    }
    
    NSInteger batchSize = pageSize > 0 ? pageSize : kRCOnlineStatusSubscribeBatchSize;
    
    __weak typeof(self) weakSelf = self;
    [self processQueueItems:userIds
                  batchSize:batchSize
                    context:collectedFailed
                   executor:^(NSArray *batch,
                              NSMutableArray<NSString *> *failedContext,
                              RCBatchPendingSnapshotBlock pendingSnapshot,
                              RCBatchCompletion batchCompletion,
                              RCBatchRetryBlock retry,
                              RCBatchFailBlock fail) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            fail(ERRORCODE_UNKNOWN);
            return;
        }
        
        RCLogD(@"Unsubscribing batch users:%@", batch);
        RCSubscribeEventRequest *request = [[RCSubscribeEventRequest alloc] init];
        request.subscribeType = RCSubscribeTypeOnlineStatus;
        request.userIds = batch;
        
        [[RCCoreClient sharedCoreClient] unSubscribeEvent:request completion:^(RCErrorCode status, NSArray<NSString *> * _Nullable failedUserIds) {
            RCLogD(@"unSubscribeEvent completion code:%ld, users:%@, failedUserIds:%@", (long)status, batch, failedUserIds);
            if (status == RC_SUCCESS) {
                [strongSelf removeSubscribedUsers:batch];
                
                NSArray<NSString *> *successUserIds = batch;
                if (failedUserIds.count > 0) {
                    NSMutableArray *successful = [batch mutableCopy];
                    [successful removeObjectsInArray:failedUserIds];
                    successUserIds = [successful copy];
                    [failedContext addObjectsFromArray:failedUserIds];
                }
                [strongSelf clearOnlineStatusCache:successUserIds];                
                // 成功，当前批次无需重试
                batchCompletion();
            } else if (status == RC_REQUEST_OVERFREQUENCY) {
                RCLogD(@"unSubscribeEvent over frequency");
                retry(nil);
            } else {
                if (failedUserIds.count > 0) {
                    [failedContext addObjectsFromArray:failedUserIds];
                }
                RCLogD(@"unSubscribeEvent failed");
                fail(status);
            }
        }];
    } completion:^(RCErrorCode status) {
        RCLogD(@"batchUnsubscribeUsers completion code:%ld", (long)status);
        if (completion) {
            completion(status, collectedFailed.count > 0 ? [collectedFailed copy] : nil);
        }
    }];
}

/// 记录已订阅的用户
- (void)recordSubscribedUsers:(NSArray<NSString *> *)userIds {
    if (!userIds || userIds.count == 0) {
        return;
    }
    dispatch_async(self.cacheQueue, ^{
        RCLogD(@"Recorded subscribed users, users:%@", userIds);
        [self.subscribedUserIds addObjectsFromArray:userIds];
    });
}

/// 从已订阅列表中移除用户
- (void)removeSubscribedUsers:(NSArray<NSString *> *)userIds {
    if (!userIds || userIds.count == 0) {
        return;
    }
    
    dispatch_async(self.cacheQueue, ^{
        [self.subscribedUserIds minusSet:[NSSet setWithArray:userIds]];
        RCLogD(@"Removed subscribed users, users:%@", userIds);
    });
}

/// 处理订阅超限情况
/// 使用代理提供的用户列表，取消订阅旧用户，保留优先级高的用户
- (void)handleSubscribeExceedLimit {
    // 必须通过代理获取需要显示在线状态的用户列表
    if (!self.delegate) {
        RCLogD(@"Delegate is not set, cannot handle subscribe exceed limit");
        return;
    }
    
    NSArray<NSString *> *allUserIds = [self.delegate userIdsNeedOnlineStatus:self];
    
    // 如果代理返回空，表示没有用户需要显示在线状态，停止流程
    if (!allUserIds || allUserIds.count == 0) {
        RCLogD(@"Delegate returned empty user list, no users need online status");
        return;
    }
    
    // 使用缓存的好友ID过滤出非好友用户
    // 注意：能走到这里，说明已经通过 p_filterAndFetchOnlineStatus 查询过好友关系，缓存是准确的
    __block NSMutableArray *nonFriendUserIds = [NSMutableArray array];
    dispatch_sync(self.cacheQueue, ^{
        for (NSString *userId in allUserIds) {
            if (userId && userId.length > 0 && ![self.friendUserIds containsObject:userId]) {
                [nonFriendUserIds addObject:userId];
            }
        }
    });
    
    if (nonFriendUserIds.count > 0) {
        // 使用基于优先级的处理策略（只处理非好友）
        RCLogD(@"Delegate provided users:%@, filtered to users:%@ non-friends for subscription",
               allUserIds, nonFriendUserIds);
        
        // 查询所有已订阅的事件信息（包含过期时间）
        [self getAllSubscribedEvents:^(NSArray<RCSubscribeInfoEvent *> * _Nullable allSubscribedEvents) {
            if (!allSubscribedEvents) {
                // 查询失败，直接终止流程
                RCLogD(@"Query all subscribed events failed, cannot handle subscribe exceed limit");
                return;
            }
            
            // 计算订阅策略
            RCSubscriptionPlan *plan = [self calculateSubscriptionStrategy:allSubscribedEvents
                                                          nonFriendUserIds:nonFriendUserIds];
            [self executeSubscriptionPlan:plan];
        }];
        
    } else {
        // 没有非好友用户，全部都是好友，不需要订阅
        RCLogD(@"All users are friends, no subscription needed");
    }
}

/// 查找需要重新订阅的用户（过期时间不大于 1 天）
- (NSArray<NSString *> *)findUsersNeedResubscribe:(NSArray<RCSubscribeInfoEvent *> *)events {
    NSMutableArray *resubscribeList = [NSMutableArray array];
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970] * 1000; // 当前时间（毫秒）
    
    for (RCSubscribeInfoEvent *event in events) {
        if (event.userId && event.userId.length > 0) {
            // 计算剩余过期时间
            NSTimeInterval remainingTime = event.subscribeTime - currentTime;
            
            // 如果剩余时间小于等于阈值（1天），需要重新订阅
            if (remainingTime > 0 && remainingTime <= kRCOnlineStatusSubscribeExpiryThreshold) {
                [resubscribeList addObject:event.userId];
                RCLogD(@"User %@ will expire in %.0f seconds (<= %ld seconds), need resubscribe",
                       event.userId, remainingTime, (long)kRCOnlineStatusSubscribeExpiryThreshold);
            }
        }
    }
    return [resubscribeList copy];
}

/// 计算订阅策略
/// - Parameters:
///   - allSubscribedEvents: 所有已订阅的事件信息
///   - nonFriendUserIds: 需要订阅的非好友用户ID数组（按优先级排序）
/// - Returns: 订阅策略结果
- (RCSubscriptionPlan *)calculateSubscriptionStrategy:(NSArray<RCSubscribeInfoEvent *> *)allSubscribedEvents
                                      nonFriendUserIds:(NSArray<NSString *> *)nonFriendUserIds {
    // 提取已订阅用户ID
    NSMutableArray<NSString *> *allSubscribedUserIds = [NSMutableArray array];
    for (RCSubscribeInfoEvent *event in allSubscribedEvents) {
        if (event.userId && event.userId.length > 0) {
            [allSubscribedUserIds addObject:event.userId];
        }
    }
    
    __block NSArray<NSString *> *usersToKeep = nil;
    __block NSArray<NSString *> *usersToUnsubscribe = nil;
    __block NSArray<NSString *> *usersToSubscribe = nil;
    __block NSArray<NSString *> *usersToResubscribe = nil;
    
    dispatch_sync(self.cacheQueue, ^{
        // 1. 截取优先级列表，确保不超过最大订阅数量
        NSInteger maxCount = kRCOnlineStatusMaxSubscribeCount;
        usersToKeep = nonFriendUserIds.count > maxCount
                    ? [nonFriendUserIds subarrayWithRange:NSMakeRange(0, maxCount)]
                    : nonFriendUserIds;
        
        // 2. 计算需要取消订阅的用户 = 当前已订阅 - 需要保留的
        NSSet *keepSet = [NSSet setWithArray:usersToKeep];
        NSMutableArray *unsubscribeList = [NSMutableArray array];
        
        for (NSString *subscribedUserId in allSubscribedUserIds) {
            if (![keepSet containsObject:subscribedUserId]) {
                [unsubscribeList addObject:subscribedUserId];
            }
        }
        usersToUnsubscribe = [unsubscribeList copy];
        
        // 3. 检查已订阅用户的过期时间，找出需要重新订阅的用户
        usersToResubscribe = [self findUsersNeedResubscribe:allSubscribedEvents];
        
        // 4. 计算需要订阅的用户 = 需要保留的 - 当前已订阅
        NSSet *subscribedSet = [NSSet setWithArray:allSubscribedUserIds];
        NSMutableArray *subscribeList = [NSMutableArray array];
        
        for (NSString *userId in usersToKeep) {
            if (![subscribedSet containsObject:userId]) {
                [subscribeList addObject:userId];
            }
        }
        usersToSubscribe = [subscribeList copy];
        
        RCLogD(@"Priority-based handling - keep: %@, unsubscribe: %@, subscribe: %@, resubscribe: %@, limit: %ld",
            usersToKeep, usersToUnsubscribe, usersToSubscribe, usersToResubscribe, (long)maxCount);
    });
    
    // 5. 合并需要订阅的用户和需要重新订阅的用户
    NSMutableSet *allUsersToSubscribeSet = [NSMutableSet set];
    if (usersToSubscribe) {
        [allUsersToSubscribeSet addObjectsFromArray:usersToSubscribe];
    }
    if (usersToResubscribe) {
        [allUsersToSubscribeSet addObjectsFromArray:usersToResubscribe];
    }

    // 计算未变动的用户ID列表
    NSMutableArray *keepUserIds = [NSMutableArray arrayWithArray:usersToKeep];
    [keepUserIds removeObjectsInArray:usersToUnsubscribe];
    [keepUserIds removeObjectsInArray:usersToSubscribe];
    
    RCSubscriptionPlan *plan = [[RCSubscriptionPlan alloc] init];
    plan.keepUserIds = keepUserIds;
    plan.unsubscribeUserIds = usersToUnsubscribe;
    plan.subscribeUserIds = [allUsersToSubscribeSet allObjects];

    return plan;
}

- (void)executeSubscriptionPlan:(RCSubscriptionPlan *)plan {
    if (plan.keepUserIds.count > 0) {
        RCLogD(@"Refreshing keep users:%@", plan.keepUserIds);
        [self getSubscribeUsersOnlineStatus:plan.keepUserIds];
    }
    // 如果没有需要取消或新增的用户，直接返回成功
    if (plan.unsubscribeUserIds.count == 0 && plan.subscribeUserIds.count == 0) {
        RCLogD(@"No users to unsubscribe or subscribe, completed");
        return;
    }
    
    void (^handleSubscribe)(void) = ^{
        RCLogD(@"handleSubscribe");
        if (plan.subscribeUserIds.count > 0) {
            RCLogD(@"Subscribing users:%@", plan.subscribeUserIds);
            [self subscribeUsers:plan.subscribeUserIds pageSize:kRCOnlineStatusSubscribeMinBatchSize processSubscribeLimit:NO];
        } else {
            RCLogD(@"No users to subscribe, completed");
        }
    };
    
    // 处理流程：先取消订阅 -> 再订阅新用户 + 重新订阅即将过期的用户
    if (plan.unsubscribeUserIds.count > 0) {
        // 1. 先取消订阅旧的用户
        [self unsubscribeUsers:plan.unsubscribeUserIds completion:^(RCErrorCode status, NSArray<NSString *> * _Nullable failedUserIds) {
            if (status == RC_SUCCESS) {
                // 2. 取消订阅成功后，订阅需要订阅的用户（包括新用户和需要重新订阅的用户）
                handleSubscribe();
            } else {
                RCLogD(@"Unsubscribe failed, cannot subscribe new users");
            }
        }];
    } else {
        RCLogD(@"No users to unsubscribe");
        handleSubscribe();
    }
}

/// 查询所有已订阅的事件信息（包含过期时间）
- (void)getAllSubscribedEvents:(void (^)(NSArray<RCSubscribeInfoEvent *> * _Nullable events))completion {
    // 从 startIndex 0 开始查询
    [self batchQuerySubscribedEvents:0
                     collectedEvents:[NSMutableArray array]
                          completion:completion];
}

/// 分批查询已订阅的事件信息（内部递归方法）
/// - Parameters:
///   - startIndex: 起始索引
///   - collectedEvents: 已收集的事件信息数组
///   - completion: 完成回调
- (void)batchQuerySubscribedEvents:(NSInteger)startIndex
                   collectedEvents:(NSMutableArray<RCSubscribeInfoEvent *> *)collectedEvents
                        completion:(void (^)(NSArray<RCSubscribeInfoEvent *> * _Nullable events))completion {
    RCSubscribeEventRequest *request = [[RCSubscribeEventRequest alloc] init];
    request.subscribeType = RCSubscribeTypeOnlineStatus;

    [[RCCoreClient sharedCoreClient] querySubscribeEvent:request 
                                                pageSize:kRCOnlineStatusSubscribeBatchSize
                                              startIndex:startIndex 
                                              completion:^(RCErrorCode status, NSArray<RCSubscribeInfoEvent *> * _Nullable subscribeEvents) {
        if (status == RC_SUCCESS) {
            if (subscribeEvents && subscribeEvents.count > 0) {
                [collectedEvents addObjectsFromArray:subscribeEvents];
                
                RCLogD(@"querySubscribeEvent fetched %lu subscribed events from index %ld, total collected: %lu", 
                       (unsigned long)subscribeEvents.count,
                       (long)startIndex,
                       (unsigned long)collectedEvents.count);
                
                // 继续查询下一页
                [self batchQuerySubscribedEvents:startIndex + subscribeEvents.count
                                 collectedEvents:collectedEvents
                                      completion:completion];
            } else {
                // subscribeEvents 为空，表示拉取完成
                RCLogD(@"querySubscribeEvent finished fetching all subscribed events, total: %lu", 
                       (unsigned long)collectedEvents.count);
                
                if (completion) {
                    completion([collectedEvents copy]);
                }
            }
        } else if (status == RC_REQUEST_OVERFREQUENCY) {
            // 请求过于频繁，延迟后重试
            RCLogD(@"querySubscribeEvent over frequency at index %ld", (long)startIndex);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kRCOnlineStatusBatchRetryDelay), dispatch_get_main_queue(), ^{
                [self batchQuerySubscribedEvents:startIndex collectedEvents:collectedEvents completion:completion];
            });
        } else {
            // 查询失败
            RCLogD(@"querySubscribeEvent failed at index %ld, status: %ld", (long)startIndex, (long)status);
            if (completion) {
                completion(nil);
            }
        }
    }];
}

/// 通用队列批处理工具
- (void)processQueueItems:(NSArray *)items
                batchSize:(NSInteger)batchSize
                  context:(id)context
                 executor:(RCBatchExecutorBlock)executor
               completion:(void (^)(RCErrorCode status))completion {
    if (!items || items.count == 0) {
        if (completion) {
            completion(RC_SUCCESS);
        }
        return;
    }
    
    NSInteger safeBatchSize = batchSize > 0 ? batchSize : items.count;
    NSArray *fullItems = [items copy];
    // 使用串行队列驱动批处理，避免递归 block 造成的 retain cycle，并统一控制线程上下文
    dispatch_queue_t workerQueue = dispatch_queue_create("com.rongcloud.rcbatch.queue", DISPATCH_QUEUE_SERIAL);
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(workerQueue, ^{
        [weakSelf executeBatchItems:fullItems
                          batchSize:safeBatchSize
                          startIndex:0
                            context:context
                           executor:executor
                         completion:completion
                        workerQueue:workerQueue];
    });
}

- (void)executeBatchItems:(NSArray *)fullItems
                batchSize:(NSInteger)batchSize
                startIndex:(NSInteger)startIndex
                  context:(id)context
                 executor:(RCBatchExecutorBlock)executor
               completion:(void (^)(RCErrorCode status))completion
              workerQueue:(dispatch_queue_t)workerQueue {
    if (startIndex >= fullItems.count) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(RC_SUCCESS);
            });
        }
        return;
    }
    // 基于当前 startIndex 提取窗口数据，保证批次始终是连续的切片
    NSInteger remainingCount = fullItems.count - startIndex;
    NSInteger currentBatchSize = MIN(batchSize, remainingCount);
    // 记录当前批次在总数组中的位置，用于后续滑动窗口与重试时复用
    NSRange batchRange = NSMakeRange(startIndex, currentBatchSize);
    NSArray *batch = [fullItems subarrayWithRange:batchRange];
    
    // snapshotBlock 始终返回从当前 startIndex 开始的剩余视图，供 executor 在调试或限流策略里参考
    RCBatchPendingSnapshotBlock snapshotBlock = ^{
        NSRange snapshotRange = NSMakeRange(startIndex, fullItems.count - startIndex);
        return [[fullItems subarrayWithRange:snapshotRange] copy];
    };
    
    [self runBatchItems:batch
              fullItems:fullItems
             batchRange:batchRange
              batchSize:batchSize
                context:context
       snapshotProvider:snapshotBlock
               executor:executor
             completion:completion
            workerQueue:workerQueue];
}

- (void)runBatchItems:(NSArray *)currentItems
            fullItems:(NSArray *)fullItems
           batchRange:(NSRange)batchRange
            batchSize:(NSInteger)batchSize
              context:(id)context
     snapshotProvider:(RCBatchPendingSnapshotBlock)snapshotBlock
             executor:(RCBatchExecutorBlock)executor
           completion:(void (^)(RCErrorCode status))completion
          workerQueue:(dispatch_queue_t)workerQueue {
    __weak typeof(self) weakSelf = self;
    executor(currentItems, context, snapshotBlock, ^{
        dispatch_async(workerQueue, ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            NSInteger nextStartIndex = NSMaxRange(batchRange);
            [strongSelf executeBatchItems:fullItems
                                batchSize:batchSize
                                startIndex:nextStartIndex
                                  context:context
                                 executor:executor
                               completion:completion
                              workerQueue:workerQueue];
        });
    }, ^(NSArray *retryItems) {
        dispatch_async(workerQueue, ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if (retryItems.count > 0) {
                // 部分重试时，不是接口调用超频，无需延时
                [strongSelf runBatchItems:retryItems
                                fullItems:fullItems
                               batchRange:batchRange
                                batchSize:batchSize
                                  context:context
                         snapshotProvider:snapshotBlock
                                 executor:executor
                               completion:completion
                              workerQueue:workerQueue];
            } else {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kRCOnlineStatusBatchRetryDelay), workerQueue, ^{
                    [strongSelf runBatchItems:currentItems
                                     fullItems:fullItems
                                    batchRange:batchRange
                                    batchSize:batchSize
                                      context:context
                             snapshotProvider:snapshotBlock
                                     executor:executor
                                   completion:completion
                                  workerQueue:workerQueue];
                });
            }
        });
    }, ^(RCErrorCode status) { // fail block
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(status);
            });
        }
    });
}

@end
