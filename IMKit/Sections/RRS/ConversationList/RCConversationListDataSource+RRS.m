//
//  RCConversationListDataSource+RRS.m
//  RongIMKit
//
//  Created by RobinCui on 2025/6/3.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationListDataSource+RRS.h"
#import "RCKitConfig.h"
#import "RCConversationCellUpdateInfo.h"
#import "RCMessageModel+RRS.h"
#import "RCConversationModel+RRS.h"
#import "RCRRSDataContext.h"
#import "RCRRSUtil.h"

const NSInteger RCReadReceiptParamsMaxCount = 100;

@implementation RCConversationListDataSource (RRS)

- (void)rrs_didReceiveMessageReadReceiptResponses:(NSArray<RCReadReceiptResponseV5 *> *)responses {
    [RCRRSDataContext refreshCacheWithResponse:responses];
    for (RCReadReceiptResponseV5 *res in responses) {
        if (res.identifier.type != ConversationType_PRIVATE) {
            continue;
        }
        if (![self.displayConversationTypeArray containsObject:@(ConversationType_PRIVATE)]) {
            continue;
        }
        if (![RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(res.identifier.type)]) {
            continue;
        }
        for (RCConversationModel *model in self.dataList) {
            if ([model isMatching:res.identifier.type targetId:res.identifier.targetId]) {
                if (model.lastestMessageDirection == MessageDirection_SEND
                    && model.needReceipt
                    && model.readReceiptInfoV5.readCount == 0) {
                    model.readReceiptInfoV5 = [RCRRSUtil infoFromResponse:res];
                    
                    RCConversationCellUpdateInfo *updateInfo =
                    [[RCConversationCellUpdateInfo alloc] init];
                    updateInfo.model = model;
                    updateInfo.updateType = RCConversationCell_SentStatus_Update;
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:RCKitConversationCellUpdateNotification
                     object:updateInfo
                     userInfo:nil];
                }
            }
        }
    }
}

- (void)rrs_refreshCachedAndFetchReceiptInfo:(NSArray <RCConversationModel *>*)conversations {
    if (conversations.count == 0) {
        return;
    }
    [RCRRSDataContext refreshConversationsCachedIfNeeded:conversations];
    [self rrs_fetchReadReceiptInfo:conversations];
}

- (void)rrs_fetchReadReceiptInfo:(NSArray<RCConversationModel *>* )conversations {
    if ([[RCCoreClient sharedCoreClient] getConnectionStatus] == ConnectionStatus_Connected) {// IM已连接
        [self rrs_fetchReadReceiptInfoWithConversations:conversations];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self rrs_fetchReadReceiptInfoWithConversations:conversations];
        });
    }
}

- (void)rrs_fetchReadReceiptInfoWithConversations:(NSArray<RCConversationModel *>* )conversations {
    NSMutableArray *array = [NSMutableArray array];
    for (RCConversationModel *model in conversations) {
        if ([model rrs_shouldFetchConversationReadReceipt]) {// 是否应该获取
            [array addObject:model];
        }
    }
    if (array.count > RCReadReceiptParamsMaxCount) {// 超限, 拆分发送
        NSArray *result = [self rrs_splitArray:array withSize:RCReadReceiptParamsMaxCount];
        for (int i = 0; i<result.count; i++) {
            NSArray *tmp = result[i];
            [self rrs_fetchReadReceiptInfoInLimit:tmp];
        }
    } else {
        [self rrs_fetchReadReceiptInfoInLimit:array];
    }
}

// 方法1：使用 subarrayWithRange
- (NSArray *)rrs_splitArray:(NSArray *)array withSize:(NSInteger)size {
    NSMutableArray *result = [NSMutableArray array];
    NSInteger count = array.count;
    
    for (NSInteger i = 0; i < count; i += size) {
        NSInteger length = MIN(size, count - i);
        NSArray *subArray = [array subarrayWithRange:NSMakeRange(i, length)];
        [result addObject:subArray];
    }
    
    return result;
}

- (void)rrs_fetchReadReceiptInfoInLimit:(NSArray<RCConversationModel *>* )conversations {
    
    NSMutableArray *array = [NSMutableArray array];
    for (RCConversationModel *model in conversations) {
        if ([model rrs_shouldFetchConversationReadReceipt]) {// 是否应该获取
            if (model.readReceiptInfoV5.readCount > 0 && model.readReceiptInfoV5.unreadCount == 0) {
                continue;
            }
            RCMessageIdentifier *identifier = [model rrs_messageIdentifier];
            if (identifier) {
                [array addObject:identifier];
            }
        }
    }
    if (array.count == 0) {
        return;
    }
    
    [[RCCoreClient sharedCoreClient] getMessageReadReceiptInfoV5ByIdentifiers:array completion:^(NSArray<RCReadReceiptInfoV5 *> * _Nullable infoList, RCErrorCode code) {
        if (code == RC_SUCCESS) {
            [RCRRSDataContext refreshCacheWithReceiptInfo:infoList];
            [self rrs_postReadReceiptNotification:infoList conversations:conversations];
        }
    }];
}

- (void)rrs_postReadReceiptNotification:(NSArray<RCReadReceiptInfoV5 *> *)infoList
                          conversations:(NSArray<RCConversationModel *>* )conversations {
    for (RCReadReceiptInfoV5 *res in infoList) {
        if (res.readCount == 0) {// 已读为0 , 不处理
            continue;
        }
        for (RCConversationModel *model in conversations) {// 先刷请求数据
            if ([model isMatching:res.identifier.type targetId:res.identifier.targetId]) {
                if (model.lastestMessageDirection == MessageDirection_SEND) {
                    model.readReceiptInfoV5 = res;
                }
            }
        }
        for (RCConversationModel *model in self.dataList) {
            if ([conversations containsObject:model]) {// 已在请求中包含, 直接发通知
                RCConversationCellUpdateInfo *updateInfo =
                [[RCConversationCellUpdateInfo alloc] init];
                updateInfo.model = model;
                updateInfo.updateType = RCConversationCell_SentStatus_Update;
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:RCKitConversationCellUpdateNotification
                 object:updateInfo
                 userInfo:nil];
                continue;
            }
            if ([model isMatching:res.identifier.type targetId:res.identifier.targetId]) {// 处理不在请求列表中的数据
                if (model.lastestMessageDirection == MessageDirection_SEND) {
                    model.readReceiptInfoV5 = res;
                    RCConversationCellUpdateInfo *updateInfo =
                    [[RCConversationCellUpdateInfo alloc] init];
                    updateInfo.model = model;
                    updateInfo.updateType = RCConversationCell_SentStatus_Update;
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:RCKitConversationCellUpdateNotification
                     object:updateInfo
                     userInfo:nil];
                }
            }
        }
    }
}

@end
