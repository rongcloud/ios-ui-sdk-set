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
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (int i = 0; i < self.chatVC.conversationDataRepository.count; i++) {
        RCMessageModel *model = (self.chatVC.conversationDataRepository)[i];
        if ([model.content isKindOfClass:[RCReferenceMessage class]]) {
            RCReferenceMessage *refMsg = (RCReferenceMessage *)model.content;
            if ([messageUIds containsObject:refMsg.referMsgUid]) {
                refMsg.referMsgStatus = status;
                model.cellSize = CGSizeZero;
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
                [indexPaths addObject:indexPath];
            }
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
    
    // 创建新消息 UID 的快速查找字典，同时过滤无效数据
    NSMutableDictionary<NSString *, RCMessageModel *> *newMessageDict = [NSMutableDictionary dictionaryWithCapacity:models.count];
    for (RCMessageModel *newModel in models) {
        if (newModel.messageUId.length > 0 && newModel.content) {
            newMessageDict[newModel.messageUId] = newModel;
        }
    }
    
    // 如果没有有效的新消息，直接返回
    if (newMessageDict.count == 0) {
        return;
    }
    
    void (^updateCallback)(void) = ^{
        NSMutableIndexSet *needUpdateIndexes = [NSMutableIndexSet indexSet];
        NSArray<RCMessageModel *> *messages = self.chatVC.conversationDataRepository;
        
        // 遍历现有消息，进行匹配和更新
        [messages enumerateObjectsUsingBlock:^(RCMessageModel *oldModel, NSUInteger idx, BOOL *stop) {
            BOOL needUpdate = NO;
            
            // 确保 oldModel 有效
            if (!oldModel.messageUId.length) {
                return;
            }
            
            if ([oldModel.content isKindOfClass:[RCReferenceMessage class]]) {
                needUpdate = [self updateUIReferenceMessage:oldModel withNewMessages:newMessageDict];
            } else {
                needUpdate = [self updateUIRegularMessage:oldModel withNewMessages:newMessageDict];
            }
            
            if (needUpdate) {
                // 重新计算高度
                oldModel.cellSize = CGSizeZero;
                [needUpdateIndexes addIndex:idx];
            }
        }];
        
        // 批量更新 UI
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

/// 更新引用消息
- (BOOL)updateUIReferenceMessage:(RCMessageModel *)oldModel
               withNewMessages:(NSDictionary<NSString *, RCMessageModel *> *)newMessageDict {
    RCReferenceMessage *refMsg = (RCReferenceMessage *)oldModel.content;
    BOOL needUpdate = NO;
    
    // 1. 检查引用消息本身是否被编辑
    RCMessageModel *matchingNewModel = newMessageDict[oldModel.messageUId];
    if (matchingNewModel && [matchingNewModel.content isKindOfClass:[RCReferenceMessage class]]) {
        RCReferenceMessage *newRefMsg = (RCReferenceMessage *)matchingNewModel.content;
        if (refMsg.referMsgStatus > newRefMsg.referMsgStatus) {
            // 编辑状态只可递增，不可回滚
            newRefMsg.referMsgStatus = refMsg.referMsgStatus;
        }
        oldModel.content = newRefMsg;
        oldModel.modifyInfo = matchingNewModel.modifyInfo;
        oldModel.hasChanged = matchingNewModel.hasChanged;
        needUpdate = YES;
    }
    
    // 2. 检查被引用的消息是否被编辑
    if (refMsg.referMsgUid.length > 0) {
        RCMessageModel *newReferencedModel = newMessageDict[refMsg.referMsgUid];
        if (newReferencedModel) {
            if (newReferencedModel.hasChanged) {
                refMsg.referMsgStatus = RCReferenceMessageStatusModified;
            }
            if ([newReferencedModel.content isKindOfClass:[RCTextMessage class]]
                && [refMsg.referMsg isKindOfClass:[RCTextMessage class]]) {
                
                NSString *newContent = ((RCTextMessage *)newReferencedModel.content).content;
                ((RCTextMessage *)refMsg.referMsg).content = newContent;
                
            } else if ([newReferencedModel.content isKindOfClass:[RCReferenceMessage class]]
                       && [refMsg.referMsg isKindOfClass:[RCReferenceMessage class]]){
                
                NSString *newContent = ((RCReferenceMessage *)newReferencedModel.content).content;
                ((RCReferenceMessage *)refMsg.referMsg).content = newContent;
            }
            needUpdate = YES;
        }
    }
    
    return needUpdate;
}

/// 更新普通消息
- (BOOL)updateUIRegularMessage:(RCMessageModel *)oldModel
             withNewMessages:(NSDictionary<NSString *, RCMessageModel *> *)newMessageDict {
    RCMessageModel *matchingNewModel = newMessageDict[oldModel.messageUId];
    if (!matchingNewModel) {
        return NO;
    }
    oldModel.content = matchingNewModel.content;
    oldModel.modifyInfo = matchingNewModel.modifyInfo;
    oldModel.hasChanged = matchingNewModel.hasChanged;
    return YES;
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
    NSMutableArray *finalMessages = [NSMutableArray arrayWithArray:messages];
    for (RCMessageResult *result in results) {
        for (int i = 0; i < finalMessages.count; i++) {
            RCMessage *message = finalMessages[i];
            if ([message.messageUId isEqualToString:result.messageUId] && result.message) {
                [finalMessages replaceObjectAtIndex:i withObject:result.message];
            }
        }
    }
    return finalMessages;
}

- (void)edit_handleRemoteReferenceMessageResults:(NSArray<RCMessageResult *> *)results {
    if (results.count == 0) {
            return;
    }
    NSMutableArray *models = [NSMutableArray array];
    for (RCMessageResult *result in results) {
        if (result.message && result.message.content) {
            RCMessageModel *model = [RCMessageModel modelWithMessage:result.message];
            if (model) {
                [models addObject:model];
            }
        }
    }
    [self edit_refreshUIMessagesEditedStatus:models];
}

@end
