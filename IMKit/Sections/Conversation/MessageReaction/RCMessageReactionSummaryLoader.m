//
//  RCMessageReactionSummaryLoader.m
//  RongIMKit
//
//  Created by RC on 2026/6/3.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageReactionSummaryLoader.h"
#import "RCMessageModel.h"

static NSInteger const RCMessageReactionSummaryBatchLimit = 100;

@interface RCMessageReactionSummaryLoader ()

@property (nonatomic, strong) NSMutableSet<NSString *> *loadingMessageReactionUIds;

@end

@implementation RCMessageReactionSummaryLoader

- (void)loadSummariesForModels:(NSArray<RCMessageModel *> *)models
         conversationIdentifier:(RCConversationIdentifier *)conversationIdentifier
                     completion:(nullable void (^)(NSDictionary<NSString *, NSArray<RCMessageReaction *> *> *reactionsMap))completion {
    if (models.count == 0 || !conversationIdentifier) {
        return;
    }
    NSArray<NSString *> *messageUIds = [self messageUIdsNeedingSummaryForModels:models];
    if (messageUIds.count == 0) {
        return;
    }
    for (NSInteger index = 0; index < messageUIds.count; index += RCMessageReactionSummaryBatchLimit) {
        NSInteger length = MIN(RCMessageReactionSummaryBatchLimit, messageUIds.count - index);
        NSArray<NSString *> *chunkUIds = [messageUIds subarrayWithRange:NSMakeRange(index, length)];
        [self addLoadingMessageUIds:chunkUIds];
        __weak typeof(self) weakSelf = self;
        [[RCCoreClient sharedCoreClient] batchGetMessageReactionSummaries:conversationIdentifier
                                                               messageUIds:chunkUIds
                                                                completion:^(NSDictionary<NSString *,NSArray<RCMessageReaction *> *> *reactionsMap, RCErrorCode errorCode) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }
                [strongSelf removeLoadingMessageUIds:chunkUIds];
                if (errorCode != RC_SUCCESS || reactionsMap.count == 0) {
                    return;
                }
                !completion ?: completion(reactionsMap);
            });
        }];
    }
}

- (NSArray<NSString *> *)messageUIdsNeedingSummaryForModels:(NSArray<RCMessageModel *> *)models {
    NSMutableArray<NSString *> *messageUIds = [NSMutableArray array];
    NSMutableSet<NSString *> *dedupUIds = [NSMutableSet set];
    for (RCMessageModel *model in models) {
        NSString *messageUId = model.messageUId;
        BOOL shouldLoadSummary = model.hasReactions && model.messageReactions.count == 0;
        if (shouldLoadSummary && messageUId.length > 0 &&
            ![dedupUIds containsObject:messageUId] && ![self.loadingMessageReactionUIds containsObject:messageUId]) {
            [dedupUIds addObject:messageUId];
            [messageUIds addObject:messageUId];
        }
    }
    return messageUIds.copy;
}

- (void)addLoadingMessageUIds:(NSArray<NSString *> *)messageUIds {
    for (NSString *messageUId in messageUIds) {
        if (messageUId.length > 0) {
            [self.loadingMessageReactionUIds addObject:messageUId];
        }
    }
}

- (void)removeLoadingMessageUIds:(NSArray<NSString *> *)messageUIds {
    for (NSString *messageUId in messageUIds) {
        [self.loadingMessageReactionUIds removeObject:messageUId];
    }
}

- (NSMutableSet<NSString *> *)loadingMessageReactionUIds {
    if (!_loadingMessageReactionUIds) {
        _loadingMessageReactionUIds = [NSMutableSet set];
    }
    return _loadingMessageReactionUIds;
}

@end
