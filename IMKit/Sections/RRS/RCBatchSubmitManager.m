//
//  RCBatchSubmitManager.m
//  RongIMKit
//
//  Created by AI Assistant on 2025/10/13.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCBatchSubmitManager.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import <pthread.h>

/// 日志标签
static NSString *const kRCBatchSubmitManagerTag = @"RCBatchSubmitManager";

/// 默认延迟时间（毫秒）
static const NSInteger kDefaultDelayMs = 100;

/// 单次最多提交条数
static const NSInteger kMaxBatchSize = 100;

/**
 批量提交状态枚举
 */
typedef NS_ENUM(NSInteger, RCSubmitState) {
    RCSubmitStateIdle,      // 空闲状态：没有待处理数据，没有安排任务
    RCSubmitStateActive     // 活跃状态：有待处理数据或正在处理中
};

@interface RCBatchSubmitManager () <RCConnectionStatusChangeDelegate> {
    /// 高性能互斥锁（pthread_mutex 兼容所有 iOS 版本，性能优秀）
    pthread_mutex_t _lock;
}

/// 待提交的数据集合（使用 NSMutableOrderedSet 保持插入顺序并去重）
@property (nonatomic, strong) NSMutableOrderedSet *pendingItems;

/// 当前状态
@property (nonatomic, assign) RCSubmitState currentState;

/// 延迟时间（毫秒）
@property (nonatomic, assign) NSInteger delayMs;

/// 批量提交回调
@property (nonatomic, copy, nullable) RCBatchSubmitCallback submitCallback;

/// GCD 延迟任务句柄（用于取消）
@property (nonatomic, strong) dispatch_block_t batchSubmitBlock;

/// 连接状态标志
@property (nonatomic, assign) BOOL isConnected;

@end

@implementation RCBatchSubmitManager

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化高性能互斥锁
        pthread_mutex_init(&_lock, NULL);
        
        _pendingItems = [NSMutableOrderedSet orderedSet];
        _currentState = RCSubmitStateIdle;
        _delayMs = kDefaultDelayMs;
        _isConnected = [[RCCoreClient sharedCoreClient] getConnectionStatus] == ConnectionStatus_Connected;
        
        // 注册连接状态监听
        [[RCCoreClient sharedCoreClient] addConnectionStatusChangeDelegate:self];
    }
    return self;
}

- (void)dealloc {
    [self invalidate];
    // 销毁互斥锁
    pthread_mutex_destroy(&_lock);
}

#pragma mark - Public Methods

- (void)setupSubmitCallback:(RCBatchSubmitCallback)callback {
    _submitCallback = callback;
}

- (void)addSubmitTask:(id)item {
    if (!item) {
        return;
    }
    
    pthread_mutex_lock(&_lock);
    
    // 添加到待处理队列（NSMutableOrderedSet 保持插入顺序并通过 isEqual: 和 hash 去重）
    if ([self.pendingItems containsObject:item]) {
        pthread_mutex_unlock(&_lock);
        RCLogD(@"[%@] Item already exists in pending queue, skipped", kRCBatchSubmitManagerTag);
        return;
    }
    
    [self.pendingItems addObject:item];
    
    RCLogD(@"[%@] ➕ Added item to pending queue, total: %lu, state: %ld, connected: %d",
          kRCBatchSubmitManagerTag,
          (unsigned long)self.pendingItems.count,
          (long)self.currentState,
          self.isConnected);
    
    // 只有在连接状态且空闲状态时才需要安排新的延迟任务
    if (self.isConnected && self.currentState == RCSubmitStateIdle) {
        RCLogD(@"[%@] Scheduling delayed submit (state: IDLE -> ACTIVE)", kRCBatchSubmitManagerTag);
        [self scheduleDelayedSubmit];
        self.currentState = RCSubmitStateActive;
    } else {
        RCLogD(@"[%@] Not scheduling: connected=%d, state=%ld", 
              kRCBatchSubmitManagerTag,
              self.isConnected,
              (long)self.currentState);
    }
    // 非连接状态下只添加到队列，不启动延迟任务
    pthread_mutex_unlock(&_lock);
}

- (void)invalidate {
    // 移除连接状态监听器，停止接收新的连接状态通知
    [[RCCoreClient sharedCoreClient] removeConnectionStatusChangeDelegate:self];
    RCLogD(@"[%@] Connection status listener removed", kRCBatchSubmitManagerTag);
}

#pragma mark - Private Methods

/**
 安排延迟提交任务
 
 @warning 此方法必须在已持有 _lock 锁的上下文中调用
 */
- (void)scheduleDelayedSubmit {
    // 注意：此方法假设调用者已经持有 _lock 锁
    // 不在此方法内部加锁是为了避免重复加锁
    
    // 取消之前的任务（如果存在）
    if (self.batchSubmitBlock) {
        dispatch_block_cancel(self.batchSubmitBlock);
        self.batchSubmitBlock = nil;
    }
    
    // 创建新的延迟任务
    __weak typeof(self) weakSelf = self;
    dispatch_block_t block = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf executeBatchSubmit];
        }
    });
    
    self.batchSubmitBlock = block;
    
    // 延迟执行（在锁外安排，避免阻塞）
    NSTimeInterval delay = _delayMs / 1000.0;  // 直接访问 ivar，因为在锁内
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(),
                   block);
}

/**
 执行批量提交
 */
- (void)executeBatchSubmit {
    NSArray *itemsToSubmit = nil;
    RCBatchSubmitCallback callback = nil;
    
    pthread_mutex_lock(&_lock);
    if (self.pendingItems.count == 0) {
        // 没有待处理数据，回到空闲状态
        self.currentState = RCSubmitStateIdle;
        pthread_mutex_unlock(&_lock);
        return;
    }
    
    // 单次最多提交 100 条，超过的部分留在队列中
    NSInteger count = MIN(self.pendingItems.count, kMaxBatchSize);
    NSRange range = NSMakeRange(0, count);
    itemsToSubmit = [[self.pendingItems objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]] copy];
    
    // 从待处理队列中移除本次要提交的数据
    [self.pendingItems removeObjectsInRange:range];
    
    callback = self.submitCallback;
    
    RCLogD(@"[%@] Preparing to submit %lu items, remaining: %lu",
          kRCBatchSubmitManagerTag,
          (unsigned long)itemsToSubmit.count,
          (unsigned long)self.pendingItems.count);
    pthread_mutex_unlock(&_lock);
    
    if (itemsToSubmit.count > 0 && callback) {
        __weak typeof(self) weakSelf = self;
        @try {
            callback(itemsToSubmit, ^(NSInteger code, BOOL refillData) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                RCLogD(@"[%@] Batch submit result: %ld, refillData: %d",
                      kRCBatchSubmitManagerTag,
                      (long)code,
                      refillData);
                
                // 提交失败，将数据回填到待处理队列头部（保证失败重试的数据优先处理）
                if (refillData) {
                    [strongSelf refillData:itemsToSubmit];
                }
                
                [strongSelf onBatchSubmitComplete];
            });
        } @catch (NSException *exception) {
            RCLogD(@"[%@] Exception during batch submit: %@", kRCBatchSubmitManagerTag, exception);
            // 发生异常，将数据回填到待处理队列头部
            [self refillData:itemsToSubmit];
            [self onBatchSubmitComplete];
        }
    } else {
        if (!callback) {
            RCLogD(@"[%@] Callback is null during cleanup, discarding %lu items",
                  kRCBatchSubmitManagerTag,
                  (unsigned long)itemsToSubmit.count);
        }
        [self onBatchSubmitComplete];
    }
}

/**
 将数据回填到队列头部
 
 @param itemsToRefill 需要回填的数据
 */
- (void)refillData:(NSArray *)itemsToRefill {
    if (!itemsToRefill || itemsToRefill.count == 0) {
        return;
    }
    
    pthread_mutex_lock(&_lock);
    // 创建新的有序集合，先添加回填数据，再添加现有数据
    NSMutableOrderedSet *newPendingItems = [NSMutableOrderedSet orderedSetWithArray:itemsToRefill];
    [newPendingItems unionOrderedSet:_pendingItems];
    
    _pendingItems = newPendingItems;
    
    RCLogD(@"[%@] Refilled %lu items to queue head, total pending: %lu",
          kRCBatchSubmitManagerTag,
          (unsigned long)itemsToRefill.count,
          (unsigned long)_pendingItems.count);
    pthread_mutex_unlock(&_lock);
}

/**
 批量提交完成后的处理
 */
- (void)onBatchSubmitComplete {
    pthread_mutex_lock(&_lock);
    RCLogD(@"[%@] onBatchSubmitComplete called, pending items: %lu, state: %ld, connected: %d",
          kRCBatchSubmitManagerTag,
          (unsigned long)_pendingItems.count,
          (long)_currentState,
          self.isConnected);
    
    if (_pendingItems.count == 0) {
        // 没有新数据，回到空闲状态
        _currentState = RCSubmitStateIdle;
        RCLogD(@"[%@] No pending items, state -> IDLE", kRCBatchSubmitManagerTag);
    } else if (self.isConnected) {
        // 有新数据且处于连接状态，安排下一轮提交，保持 ACTIVE 状态
        RCLogD(@"[%@] Has %lu pending items, scheduling next batch", 
              kRCBatchSubmitManagerTag, 
              (unsigned long)_pendingItems.count);
        [self scheduleDelayedSubmit];
    } else {
        // 有新数据但未连接，回到空闲状态，等待连接恢复后重新启动
        _currentState = RCSubmitStateIdle;
        RCLogD(@"[%@] Has pending items but not connected, waiting for connection restore", kRCBatchSubmitManagerTag);
    }
    pthread_mutex_unlock(&_lock);
}

#pragma mark - RCConnectionStatusChangeDelegate

/**
 连接状态变化回调
 */
- (void)onConnectionStatusChanged:(RCConnectionStatus)status {
    pthread_mutex_lock(&_lock);
    self.isConnected = (status == ConnectionStatus_Connected);
    RCLogD(@"[%@] Connection status changed: %ld, pending items: %lu",
          kRCBatchSubmitManagerTag,
          (long)status,
          (unsigned long)self.pendingItems.count);
    
    if (self.isConnected) {
        // 连接恢复，如果有待处理数据且当前是空闲状态，则启动延迟任务
        if (self.pendingItems.count > 0 && self.currentState == RCSubmitStateIdle) {
            [self scheduleDelayedSubmit];
            self.currentState = RCSubmitStateActive;
        }
    }
    pthread_mutex_unlock(&_lock);
}

@end
