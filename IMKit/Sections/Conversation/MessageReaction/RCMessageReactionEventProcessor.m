//
//  RCMessageReactionEventProcessor.m
//  RongIMKit
//
//  Created by RC on 2026/6/24.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageReactionEventProcessor.h"
#import "RCMessageModel+MessageReaction.h"
#import "RCMessageModel.h"
#import "RCIM.h"

@implementation RCMessageReactionEventProcessResult

- (instancetype)init {
    self = [super init];
    if (self) {
        _updatedModels = @[];
        _updatedIndexPaths = @[];
        _modelsNeedingUserInfoPreload = @[];
    }
    return self;
}

@end

@interface RCMessageReactionEventProcessor ()

@property (nonatomic, strong) NSMutableArray<RCMessageReactionEventData *> *pendingEvents;
@property (nonatomic, assign) BOOL flushScheduled;

- (NSArray<RCMessageReactionUser *> *)mergedReactionUsers:(NSArray<RCMessageReactionUser *> *)currentUsers
                                               eventUsers:(NSArray<RCMessageReactionUser *> *)eventUsers
                                                    limit:(NSUInteger)limit;
- (NSArray<RCMessageReactionUser *> *)limitedReactionUsers:(NSArray<RCMessageReactionUser *> *)users
                                                     limit:(NSUInteger)limit
                                                totalCount:(NSInteger)totalCount;
- (NSArray<RCMessageReactionUser *> *)reactionUsers:(NSArray<RCMessageReactionUser *> *)currentUsers
                                      removingUsers:(NSArray<RCMessageReactionUser *> *)eventUsers;
- (BOOL)messageReactionUsersContainCurrentUser:(NSArray<RCMessageReactionUser *> *)users;
- (NSDictionary<NSString *, NSArray<NSString *> *> *)previewUserIdsByReactionIdForModel:(RCMessageModel *)model
                                                                        previewUserLimit:(NSUInteger)previewUserLimit;

@end

@implementation RCMessageReactionEventProcessor

- (void)enqueueEvents:(NSArray<RCMessageReactionEventData *> *)events
       modelsProvider:(RCMessageReactionEventModelsProvider)modelsProvider
     previewUserLimit:(NSUInteger)previewUserLimit
trackPreviewUserChangesProvider:(RCMessageReactionEventPreviewTrackingProvider)trackPreviewUserChangesProvider
           completion:(nullable void (^)(RCMessageReactionEventProcessResult *result))completion {
    if (events.count == 0 || !modelsProvider) {
        return;
    }
    void (^enqueueBlock)(void) = ^{
        [self.pendingEvents addObjectsFromArray:events];
        if (self.flushScheduled) {
            return;
        }
        self.flushScheduled = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray<RCMessageReactionEventData *> *pendingEvents = [self.pendingEvents copy];
            [self.pendingEvents removeAllObjects];
            self.flushScheduled = NO;
            NSMutableArray<RCMessageModel *> *models = modelsProvider();
            BOOL trackPreviewUserChanges = trackPreviewUserChangesProvider ? trackPreviewUserChangesProvider() : YES;
            RCMessageReactionEventProcessResult *result = [self processEvents:pendingEvents
                                                                        models:models
                                                              previewUserLimit:previewUserLimit
                                                       trackPreviewUserChanges:trackPreviewUserChanges];
            if (result.updatedModels.count > 0 && completion) {
                completion(result);
            }
        });
    };
    if ([NSThread isMainThread]) {
        enqueueBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), enqueueBlock);
    }
}

- (RCMessageReactionEventProcessResult *)processEvents:(NSArray<RCMessageReactionEventData *> *)events
                                                models:(NSMutableArray<RCMessageModel *> *)models
                                      previewUserLimit:(NSUInteger)previewUserLimit
                               trackPreviewUserChanges:(BOOL)trackPreviewUserChanges {
    RCMessageReactionEventProcessResult *result = [[RCMessageReactionEventProcessResult alloc] init];
    if (events.count == 0 || models.count == 0) {
        return result;
    }

    NSMutableSet<NSString *> *pendingMessageUIds = [NSMutableSet set];
    for (RCMessageReactionEventData *data in events) {
        if ([self isValidEventData:data]) {
            [pendingMessageUIds addObject:data.messageUId];
        }
    }
    if (pendingMessageUIds.count == 0) {
        return result;
    }

    NSMutableDictionary<NSString *, NSNumber *> *messageUIdToIndex = [NSMutableDictionary dictionary];
    [models enumerateObjectsUsingBlock:^(RCMessageModel *model, NSUInteger index, BOOL *stop) {
        NSString *messageUId = model.messageUId;
        if (messageUId.length > 0 && [pendingMessageUIds containsObject:messageUId] && !messageUIdToIndex[messageUId]) {
            messageUIdToIndex[messageUId] = @(index);
            if (messageUIdToIndex.count == pendingMessageUIds.count) {
                *stop = YES;
            }
        }
    }];
    if (messageUIdToIndex.count == 0) {
        return result;
    }

    NSMutableDictionary<NSString *, NSDictionary<NSString *, NSArray<NSString *> *> *> *previewUserIdsBeforeUpdate =
        [NSMutableDictionary dictionary];
    NSMutableOrderedSet<RCMessageModel *> *updatedModels = [NSMutableOrderedSet orderedSet];
    NSMutableOrderedSet<NSIndexPath *> *updatedIndexPaths = [NSMutableOrderedSet orderedSet];
    for (RCMessageReactionEventData *data in events) {
        if (![self isValidEventData:data]) {
            continue;
        }
        NSNumber *indexNumber = messageUIdToIndex[data.messageUId];
        if (!indexNumber) {
            continue;
        }
        NSUInteger index = indexNumber.unsignedIntegerValue;
        if (index >= models.count) {
            continue;
        }
        RCMessageModel *model = models[index];
        if (trackPreviewUserChanges && model.messageUId.length > 0 && !previewUserIdsBeforeUpdate[model.messageUId]) {
            previewUserIdsBeforeUpdate[model.messageUId] =
                [self previewUserIdsByReactionIdForModel:model previewUserLimit:previewUserLimit];
        }
        if ([self applyEvent:data operationType:data.operationType model:model previewUserLimit:previewUserLimit]) {
            model.cellSize = CGSizeZero;
            [updatedModels addObject:model];
            [updatedIndexPaths addObject:[NSIndexPath indexPathForItem:index inSection:0]];
        }
    }

    result.updatedModels = updatedModels.array;
    result.updatedIndexPaths = updatedIndexPaths.array;
    if (updatedModels.count == 0 || !trackPreviewUserChanges) {
        return result;
    }

    NSMutableArray<RCMessageModel *> *modelsNeedingUserInfoPreload = [NSMutableArray array];
    for (RCMessageModel *model in updatedModels) {
        NSString *messageUId = model.messageUId;
        NSDictionary<NSString *, NSArray<NSString *> *> *beforePreviewUserIds =
            messageUId.length > 0 ? (previewUserIdsBeforeUpdate[messageUId] ?: @{}) : @{};
        NSDictionary<NSString *, NSArray<NSString *> *> *afterPreviewUserIds =
            [self previewUserIdsByReactionIdForModel:model previewUserLimit:previewUserLimit];
        if (![beforePreviewUserIds isEqualToDictionary:afterPreviewUserIds]) {
            [modelsNeedingUserInfoPreload addObject:model];
        }
    }
    result.modelsNeedingUserInfoPreload = modelsNeedingUserInfoPreload.copy;
    return result;
}

- (BOOL)isValidEventData:(RCMessageReactionEventData *)data {
    if (data.messageUId.length == 0) {
        return NO;
    }
    if (data.operationType != RCMessageReactionOperationTypeCleared && data.reactionId.length == 0) {
        return NO;
    }
    return YES;
}

- (NSArray<RCMessageReactionUser *> *)mergedReactionUsers:(NSArray<RCMessageReactionUser *> *)currentUsers
                                               eventUsers:(NSArray<RCMessageReactionUser *> *)eventUsers
                                                    limit:(NSUInteger)limit {
    if (limit == 0) {
        return @[];
    }
    if (eventUsers.count == 0) {
        if (currentUsers.count == 0) {
            return @[];
        }
        return [currentUsers subarrayWithRange:NSMakeRange(0, MIN(currentUsers.count, limit))];
    }
    NSMutableArray<RCMessageReactionUser *> *mergedUsers = [NSMutableArray arrayWithArray:currentUsers ?: @[]];
    NSMutableDictionary<NSString *, NSNumber *> *userIdToIndex = [NSMutableDictionary dictionary];
    for (NSUInteger index = 0; index < mergedUsers.count; index++) {
        NSString *userId = mergedUsers[index].userId;
        if (userId.length > 0) {
            userIdToIndex[userId] = @(index);
        }
    }
    for (RCMessageReactionUser *eventUser in eventUsers) {
        if (eventUser.userId.length == 0) {
            continue;
        }
        NSNumber *existingIndex = userIdToIndex[eventUser.userId];
        if (existingIndex) {
            mergedUsers[existingIndex.unsignedIntegerValue] = eventUser;
        } else if (mergedUsers.count < limit) {
            userIdToIndex[eventUser.userId] = @(mergedUsers.count);
            [mergedUsers addObject:eventUser];
        }
    }
    if (mergedUsers.count > limit) {
        [mergedUsers removeObjectsInRange:NSMakeRange(limit, mergedUsers.count - limit)];
    }
    return mergedUsers.copy;
}

- (NSArray<RCMessageReactionUser *> *)limitedReactionUsers:(NSArray<RCMessageReactionUser *> *)users
                                                     limit:(NSUInteger)limit
                                                totalCount:(NSInteger)totalCount {
    NSUInteger effectiveLimit = limit;
    if (totalCount >= 0) {
        effectiveLimit = MIN(effectiveLimit, (NSUInteger)totalCount);
    }
    if (effectiveLimit == 0 || users.count == 0) {
        return @[];
    }
    return [users subarrayWithRange:NSMakeRange(0, MIN(users.count, effectiveLimit))];
}

- (NSArray<RCMessageReactionUser *> *)reactionUsers:(NSArray<RCMessageReactionUser *> *)currentUsers
                                      removingUsers:(NSArray<RCMessageReactionUser *> *)eventUsers {
    if (currentUsers.count == 0 || eventUsers.count == 0) {
        return currentUsers;
    }
    NSMutableSet<NSString *> *removedUserIds = [NSMutableSet set];
    for (RCMessageReactionUser *eventUser in eventUsers) {
        if (eventUser.userId.length > 0) {
            [removedUserIds addObject:eventUser.userId];
        }
    }
    if (removedUserIds.count == 0) {
        return currentUsers;
    }
    NSMutableArray<RCMessageReactionUser *> *remainingUsers = [NSMutableArray array];
    for (RCMessageReactionUser *user in currentUsers) {
        if (user.userId.length == 0 || ![removedUserIds containsObject:user.userId]) {
            [remainingUsers addObject:user];
        }
    }
    return remainingUsers.copy;
}

- (BOOL)messageReactionUsersContainCurrentUser:(NSArray<RCMessageReactionUser *> *)users {
    NSString *currentUserId = [RCIM sharedRCIM].currentUserInfo.userId;
    if (currentUserId.length == 0) {
        return NO;
    }
    for (RCMessageReactionUser *user in users) {
        if ([user.userId isEqualToString:currentUserId]) {
            return YES;
        }
    }
    return NO;
}

- (NSDictionary<NSString *, NSArray<NSString *> *> *)previewUserIdsByReactionIdForModel:(RCMessageModel *)model
                                                                        previewUserLimit:(NSUInteger)previewUserLimit {
    if (!model) {
        return @{};
    }
    NSMutableDictionary<NSString *, NSArray<NSString *> *> *previewUserIdsByReactionId = [NSMutableDictionary dictionary];
    for (RCMessageReaction *reaction in [model rc_visibleReactions]) {
        if (reaction.reactionId.length == 0) {
            continue;
        }
        previewUserIdsByReactionId[reaction.reactionId] = [model rc_previewUserIdsForMessageReaction:reaction
                                                                                                limit:previewUserLimit];
    }
    return previewUserIdsByReactionId.copy;
}

- (BOOL)applyEvent:(RCMessageReactionEventData *)eventData
     operationType:(RCMessageReactionOperationType)operationType
             model:(RCMessageModel *)model
  previewUserLimit:(NSUInteger)previewUserLimit {
    if (!model) {
        return NO;
    }
    if (operationType == RCMessageReactionOperationTypeCleared && eventData.reactionId.length == 0) {
        model.messageReactions = @[];
        model.hasReactions = NO;
        return YES;
    }
    if (eventData.reactionId.length == 0) {
        return NO;
    }
    NSMutableArray<RCMessageReaction *> *reactions = [NSMutableArray arrayWithArray:model.messageReactions ?: @[]];
    RCMessageReaction *targetReaction = nil;
    for (RCMessageReaction *reaction in reactions) {
        if ([reaction.reactionId isEqualToString:eventData.reactionId]) {
            targetReaction = reaction;
            break;
        }
    }
    BOOL eventContainsCurrentUser = [self messageReactionUsersContainCurrentUser:eventData.users];
    if (operationType == RCMessageReactionOperationTypeAdded) {
        if (!targetReaction) {
            targetReaction = [[RCMessageReaction alloc] init];
            targetReaction.messageUId = model.messageUId;
            targetReaction.reactionId = eventData.reactionId;
            [reactions addObject:targetReaction];
        }
        targetReaction.totalCount = eventData.totalCount > 0 ? eventData.totalCount : MAX(targetReaction.totalCount + 1, 1);
        targetReaction.hasCurrentUserReacted = targetReaction.hasCurrentUserReacted || eventContainsCurrentUser;
        if (eventData.users.count > 0) {
            targetReaction.users = [self mergedReactionUsers:targetReaction.users
                                                  eventUsers:eventData.users
                                                       limit:previewUserLimit];
        }
        targetReaction.users = [self limitedReactionUsers:targetReaction.users
                                                    limit:previewUserLimit
                                               totalCount:targetReaction.totalCount];
        targetReaction.reactionTime = eventData.users.firstObject.reactionTime;
    } else if (operationType == RCMessageReactionOperationTypeRemoved) {
        if (!targetReaction) {
            return NO;
        }
        // 协议栈事件中的 totalCount 表示服务端总数，移除后总数为 0 也是有效值。
        targetReaction.totalCount = MAX(eventData.totalCount, 0);
        if (eventContainsCurrentUser) {
            targetReaction.hasCurrentUserReacted = NO;
        }
        if (eventData.users.count > 0) {
            targetReaction.users = [self reactionUsers:targetReaction.users removingUsers:eventData.users];
        }
        if (targetReaction.totalCount <= 0) {
            [reactions removeObject:targetReaction];
        } else {
            targetReaction.users = [self limitedReactionUsers:targetReaction.users
                                                        limit:previewUserLimit
                                                   totalCount:targetReaction.totalCount];
        }
    } else if (operationType == RCMessageReactionOperationTypeCleared) {
        if (!targetReaction) {
            return NO;
        }
        [reactions removeObject:targetReaction];
    } else {
        return NO;
    }
    model.messageReactions = reactions.copy;
    model.hasReactions = model.messageReactions.count > 0;
    return YES;
}

- (NSMutableArray<RCMessageReactionEventData *> *)pendingEvents {
    if (!_pendingEvents) {
        _pendingEvents = [NSMutableArray array];
    }
    return _pendingEvents;
}

@end
