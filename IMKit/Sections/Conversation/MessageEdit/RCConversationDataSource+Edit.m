//
//  RCConversationDataSource+Edit.m
//  RongIMKit
//
//  Created by Lang on 2025/7/26.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationDataSource+Edit.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCConversationViewController.h"
#import "RCKitCommonDefine.h"
#import "RCMessageModel+Edit.h"

@interface RCConversationDataSource ()

@property (nonatomic, weak) RCConversationViewController *chatVC;

@end

@implementation RCConversationDataSource (Edit)

- (void)edit_refreshReferenceMessage:(NSArray<RCMessage *> *)messages
                            complete:(void (^)(NSArray<RCMessage *> * _Nonnull))complete {
    
    if (self.chatVC.conversationType != ConversationType_PRIVATE
        && self.chatVC.conversationType != ConversationType_GROUP) {
        if (complete) {
            complete(messages);
        }
        return;
    }
    // 筛选出 引用消息
    NSMutableArray *referenceMessages = [NSMutableArray array];
    for (RCMessage *message in messages) {
        if ([message.content isMemberOfClass:[RCReferenceMessage class]]) {
            RCReferenceMessage *refMsg = (RCReferenceMessage *)message.content;
            if (refMsg.referMsgStatus == RCReferenceMessageStatusDefault
                || refMsg.referMsgStatus == RCReferenceMessageStatusModified) {
                if (message.messageUId.length > 0) {
                    [referenceMessages addObject:message.messageUId];
                }
            }
        }
    }
    if (referenceMessages.count == 0) {
        if (complete) {
            complete(messages);
        }
        return;
    }
    
    RCRefreshReferenceMessageParams *params = [[RCRefreshReferenceMessageParams alloc] init];
    RCConversationIdentifier *conversationIdentifier = [[RCConversationIdentifier alloc] init];
    conversationIdentifier.type = self.chatVC.conversationType;
    conversationIdentifier.targetId = self.chatVC.targetId;
    params.conversationIdentifier = conversationIdentifier;
    params.messageUIds = referenceMessages;
    
    // 初始化合并回调状态
    [self edit_setupCombineCallbackWithMessages:messages complete:complete];
    
    [[RCCoreClient sharedCoreClient] refreshReferenceMessageWithParams:params localMessageBlock:^(NSArray<RCMessageResult *> * _Nonnull results) {
        [self edit_handleLocalResults:results];
    } remoteMessageBlock:^(NSArray<RCMessageResult *> * _Nonnull results) {
        [self edit_handleRemoteResults:results];
    } errorBlock:^(RCErrorCode code) {
        [self edit_handleError:code];
    }];
}

// 传入被引用消息的 UId 数组，设置指定的消息编辑状态, 最后更新列表指定项
- (void)edit_setUIReferenceMessagesEditStatus:(RCReferenceMessageStatus)status
                        forMessageUIds:(NSArray<NSString *> *)messageUIds {
    if (messageUIds.count == 0) {
        return;
    }
    NSSet<NSString *> *uidSet = [NSSet setWithArray:messageUIds];
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSArray<RCMessageModel *> *repository = self.chatVC.conversationDataRepository;
    for (NSUInteger i = 0; i < repository.count; i++) {
        RCMessageModel *model = repository[i];
        if (![model.content isKindOfClass:[RCReferenceMessage class]]) {
            continue;
        }
        RCReferenceMessage *refMsg = (RCReferenceMessage *)model.content;
        if (refMsg.referMsgUid.length > 0 && [uidSet containsObject:refMsg.referMsgUid]) {
            refMsg.referMsgStatus = status;
            model.cellSize = CGSizeZero;
            [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
        }
    }
    if (indexPaths.count == 0) {
        return;
    }
    dispatch_main_async_safe(^{
        [self.chatVC.conversationMessageCollectionView reloadItemsAtIndexPaths:indexPaths];
    });
}

- (void)edit_refreshUIMessagesEditedStatus:(NSArray<RCMessageModel *> *)models {
    if (models.count == 0 || self.chatVC.conversationDataRepository.count == 0) {
        return;
    }
    
    NSDictionary<NSString *, RCMessageModel *> *newMessageDict = [self edit_buildUIdToModelDict:models];
    if (newMessageDict.count == 0) {
        return;
    }

    void (^updateCallback)(void) = ^{
        NSArray<RCMessageModel *> *repository = self.chatVC.conversationDataRepository;
        NSMutableDictionary<NSString *, NSNumber *> *uidToIndex = [NSMutableDictionary dictionaryWithCapacity:repository.count];
        NSMutableDictionary<NSString *, NSMutableIndexSet *> *referUidToIndexes = [NSMutableDictionary dictionary];

        [self edit_buildRepositoryIndexes:repository
                               uidToIndex:uidToIndex
                        referUidToIndexes:referUidToIndexes];

        NSIndexSet *needUpdateIndexes = [self edit_applyUpdatesWithNewMessageDict:newMessageDict
                                                                       repository:repository
                                                                       uidToIndex:uidToIndex
                                                                referUidToIndexes:referUidToIndexes];
        if (needUpdateIndexes.count > 0) {
            [self reloadCollectionViewAtIndexes:needUpdateIndexes];
        }
    };
    
    // 确保在主线程执行 UI 更新
    if ([NSThread isMainThread]) {
        updateCallback();
    } else {
        dispatch_async(dispatch_get_main_queue(), updateCallback);
    }
}

#pragma mark - 私有辅助方法

// 构建 messageUId -> model 的字典
- (NSDictionary<NSString *, RCMessageModel *> *)edit_buildUIdToModelDict:(NSArray<RCMessageModel *> *)models {
    if (models.count == 0) {
        return @{};
    }
    NSMutableDictionary<NSString *, RCMessageModel *> *dict = [NSMutableDictionary dictionaryWithCapacity:models.count];
    for (RCMessageModel *model in models) {
        if (model.messageUId.length > 0 && model.content) {
            dict[model.messageUId] = model;
        }
    }
    return dict.copy;
}

// 构建 messageUId -> index 的字典，以及 referMsgUid -> index 集合的字典
- (void)edit_buildRepositoryIndexes:(NSArray<RCMessageModel *> *)repository
                         uidToIndex:(NSMutableDictionary<NSString *, NSNumber *> *)uidToIndex
                  referUidToIndexes:(NSMutableDictionary<NSString *, NSMutableIndexSet *> *)referUidToIndexes {
    for (NSUInteger idx = 0; idx < repository.count; idx++) {
        RCMessageModel *model = repository[idx];
        if (model.messageUId.length > 0) {
            uidToIndex[model.messageUId] = @(idx);
        }
        if ([model.content isKindOfClass:[RCReferenceMessage class]]) {
            RCReferenceMessage *ref = (RCReferenceMessage *)model.content;
            if (ref.referMsgUid.length > 0) {
                NSMutableIndexSet *set = referUidToIndexes[ref.referMsgUid];
                if (!set) {
                    set = [NSMutableIndexSet indexSet];
                    referUidToIndexes[ref.referMsgUid] = set;
                }
                [set addIndex:idx];
            }
        }
    }
}

// 应用更新，返回需要更新的 index 集合
- (NSIndexSet *)edit_applyUpdatesWithNewMessageDict:(NSDictionary<NSString *, RCMessageModel *> *)newMessageDict
                                         repository:(NSArray<RCMessageModel *> *)repository
                                         uidToIndex:(NSDictionary<NSString *, NSNumber *> *)uidToIndex
                                  referUidToIndexes:(NSDictionary<NSString *, NSMutableIndexSet *> *)referUidToIndexes {
    NSMutableIndexSet *needUpdateIndexes = [NSMutableIndexSet indexSet];
    
    [newMessageDict enumerateKeysAndObjectsUsingBlock:^(NSString *uid, RCMessageModel *newModel, BOOL *stop) {
        NSNumber *indexNumber = uidToIndex[uid];
        if (indexNumber) {
            NSUInteger idx = indexNumber.unsignedIntegerValue;
            RCMessageModel *oldModel = repository[idx];
            
            if ([oldModel.content isKindOfClass:[RCReferenceMessage class]] &&
                [newModel.content isKindOfClass:[RCReferenceMessage class]]) {
                RCReferenceMessage *oldRef = (RCReferenceMessage *)oldModel.content;
                RCReferenceMessage *newRef = (RCReferenceMessage *)newModel.content;
                if (oldRef.referMsgStatus > newRef.referMsgStatus) {
                    newRef.referMsgStatus = oldRef.referMsgStatus;
                }
            }
            
            oldModel.content = newModel.content;
            oldModel.modifyInfo = newModel.modifyInfo;
            oldModel.hasChanged = newModel.hasChanged;
            oldModel.cellSize = CGSizeZero;
            [needUpdateIndexes addIndex:idx];
        }
        
        NSMutableIndexSet *refIndexes = referUidToIndexes[uid];
        if (refIndexes.count > 0) {
            [refIndexes enumerateIndexesUsingBlock:^(NSUInteger refIdx, BOOL *stopRef) {
                RCMessageModel *refModel = repository[refIdx];
                RCReferenceMessage *refMsg = (RCReferenceMessage *)refModel.content;
                
                if (newModel.hasChanged) {
                    refMsg.referMsgStatus = RCReferenceMessageStatusModified;
                }
                
                if ([newModel.content isKindOfClass:[RCTextMessage class]] &&
                    [refMsg.referMsg isKindOfClass:[RCTextMessage class]]) {
                    ((RCTextMessage *)refMsg.referMsg).content = ((RCTextMessage *)newModel.content).content;
                } else if ([newModel.content isKindOfClass:[RCReferenceMessage class]] &&
                           [refMsg.referMsg isKindOfClass:[RCReferenceMessage class]]) {
                    ((RCReferenceMessage *)refMsg.referMsg).content = ((RCReferenceMessage *)newModel.content).content;
                }
                
                refModel.cellSize = CGSizeZero;
                [needUpdateIndexes addIndex:refIdx];
            }];
        }
    }];
    
    return needUpdateIndexes.copy;
}

/// 批量更新 CollectionView
- (void)reloadCollectionViewAtIndexes:(NSIndexSet *)indexes {
    if (indexes.count == 0) return;
    
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray arrayWithCapacity:indexes.count];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:0]];
    }];
    
    @try {
        [self.chatVC.conversationMessageCollectionView reloadItemsAtIndexPaths:indexPaths];
    } @catch (NSException *exception) {
        NSLog(@"CollectionView reload failed: %@", exception.reason);
        // 降级方案：重新加载整个 CollectionView
        [self.chatVC.conversationMessageCollectionView reloadData];
    }
}

#pragma mark - 合并回调优化方法

/**
 * 设置合并回调的初始状态和计时器
 * @param messages 原始消息列表
 * @param complete 完成回调
 */
- (void)edit_setupCombineCallbackWithMessages:(NSArray<RCMessage *> *)messages 
                                complete:(void (^)(NSArray<RCMessage *> *))complete {
    // 重置合并状态
    [self edit_cleanupCombineState];
    
    // 缓存原始数据
    self.pendingLocalMessages = messages;
    self.pendingCompleteBlock = complete;
    self.isWaitingForRemoteResults = YES;
    
    // 设置合并超时计时器 (1000ms)
    __weak typeof(self) weakSelf = self;
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.combineTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(self.combineTimer, dispatch_time(DISPATCH_TIME_NOW, 1000 * NSEC_PER_MSEC), DISPATCH_TIME_FOREVER, 0);
    dispatch_source_set_event_handler(self.combineTimer, ^{
        [weakSelf edit_handleCombineTimeout];
    });
    dispatch_resume(self.combineTimer);
}

/**
 * 处理本地查询结果
 * @param results 本地查询到的消息结果
 */
- (void)edit_handleLocalResults:(NSArray<RCMessageResult *> *)results {
    if (!self.isWaitingForRemoteResults) {
        return;
    }
    
    // 如果有本地结果，替换消息内容
    if (results.count > 0) {
        NSArray *updatedMessages = [self edit_replaceMessages:self.pendingLocalMessages withResults:results];
        self.pendingLocalMessages = updatedMessages;
    }
    
    // 本地结果处理完成，继续等待远程结果或超时
}

/**
 * 处理远程查询结果
 * @param results 远程查询到的消息结果
 */
- (void)edit_handleRemoteResults:(NSArray<RCMessageResult *> *)results {
    if (!self.isWaitingForRemoteResults) {
        // 如果合并时间窗口已过，按原有方式单独处理远程结果
        [self edit_handleRemoteReferenceMessageResults:results];
        return;
    }
    
    // 远程结果在时间窗口内到达，进行合并处理
    self.pendingRemoteResults = results;
    [self edit_executeCombinedCallback];
}

/**
 * 处理合并超时情况
 */
- (void)edit_handleCombineTimeout {
    if (!self.isWaitingForRemoteResults) {
        return;
    }
    
    // 超时处理：只返回本地结果，远程结果将单独处理
    [self edit_executeCombinedCallback];
}

/**
 * 处理查询错误
 * @param code 错误码
 */
- (void)edit_handleError:(RCErrorCode)code {
    void (^completeBlock)(NSArray<RCMessage *> *) = self.pendingCompleteBlock;
    NSArray<RCMessage *> *originalMessages = self.pendingLocalMessages;
    
    [self edit_cleanupCombineState];
    
    if (completeBlock) {
        // 发生错误时，返回原始消息列表
        completeBlock(originalMessages);
    }
}

/**
 * 执行合并回调逻辑
 */
- (void)edit_executeCombinedCallback {
    if (!self.isWaitingForRemoteResults) {
        return;
    }
    
    // 获取当前状态数据
    NSArray<RCMessage *> *localMessages = self.pendingLocalMessages;
    NSArray<RCMessageResult *> *remoteResults = self.pendingRemoteResults;
    void (^completeBlock)(NSArray<RCMessage *> *) = self.pendingCompleteBlock;
    
    // 清理状态（重要：在使用数据前清理，避免重复调用）
    [self edit_cleanupCombineState];
    
    if (completeBlock) {
        // 1. 处理本地和远程结果的消息替换
        NSArray *finalMessages = localMessages;
        if (remoteResults.count > 0) {
            finalMessages = [self edit_replaceMessages:finalMessages withResults:remoteResults];
        }
        // 2. 返回最终处理后的消息列表
        completeBlock(finalMessages);
    }
}

/**
 * 清理合并回调状态
 */
- (void)edit_cleanupCombineState {
    self.isWaitingForRemoteResults = NO;
    
    // 取消并清理计时器
    if (self.combineTimer) {
        dispatch_source_cancel(self.combineTimer);
        self.combineTimer = nil;
    }
    
    // 清理缓存数据
    self.pendingRemoteResults = nil;
    self.pendingLocalMessages = nil;
    self.pendingCompleteBlock = nil;
}

#pragma mark - Private Methods

- (NSArray<RCMessage *> *)edit_replaceMessages:(NSArray<RCMessage *> *)messages
                                   withResults:(NSArray<RCMessageResult *> *)results {
    if (messages.count == 0 && results.count == 0) {
        return nil;
    }
    if (results.count == 0) {
        return messages;
    }
    // 构建 UID -> Message 的字典，避免 O(n*m) 嵌套循环
    NSMutableDictionary<NSString *, RCMessage *> *uidToMessage = [NSMutableDictionary dictionaryWithCapacity:results.count];
    for (RCMessageResult *result in results) {
        if (result.messageUId.length > 0 && result.message) {
            uidToMessage[result.messageUId] = result.message;
        }
    }
    if (uidToMessage.count == 0) {
        return messages;
    }
    NSMutableArray *finalMessages = [NSMutableArray arrayWithCapacity:messages.count];
    for (RCMessage *message in messages) {
        RCMessage *replacement = uidToMessage[message.messageUId];
        [finalMessages addObject:(replacement ?: message)];
    }
    return finalMessages;
}

- (void)edit_handleRemoteReferenceMessageResults:(NSArray<RCMessageResult *> *)results {
    if (results.count == 0) {
            return;
    }
    NSMutableArray *models = [NSMutableArray array];
    for (RCMessageResult *result in results) {
        if (result.message.content) {
            RCMessageModel *model = [RCMessageModel modelWithMessage:result.message];
            if (model) {
                [models addObject:model];
            }
        }
    }
    [self edit_refreshUIMessagesEditedStatus:models];
}

@end
