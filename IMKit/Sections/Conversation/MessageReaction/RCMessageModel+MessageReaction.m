//
//  RCMessageModel+MessageReaction.m
//  RongIMKit
//
//  Created by RC on 2026/6/8.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageModel+MessageReaction.h"
#import "RCIM.h"
#import "RCKitConfig.h"
#import "RCKitUtility.h"
#import <RongIMLibCore/RongIMLibCore.h>

@implementation RCMessageModel (MessageReaction)

- (BOOL)rc_hasVisibleReactions {
    if (!RCKitConfigCenter.message.enableMessageReaction) {
        return NO;
    }
    for (RCMessageReaction *reaction in self.messageReactions) {
        if ([self rc_isVisibleReaction:reaction]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray<RCMessageReaction *> *)rc_visibleReactions {
    if (!RCKitConfigCenter.message.enableMessageReaction) {
        return @[];
    }
    NSMutableArray<RCMessageReaction *> *items = [NSMutableArray array];
    for (RCMessageReaction *reaction in self.messageReactions) {
        if ([self rc_isVisibleReaction:reaction]) {
            [items addObject:reaction];
        }
    }
    return items.copy;
}

- (BOOL)rc_isVisibleReaction:(RCMessageReaction *)reaction {
    return reaction.reactionId.length > 0 && reaction.totalCount > 0;
}

- (NSString *)rc_displayNameForReactionUserId:(NSString *)userId {
    if (userId.length <= 0) {
        return @"";
    }
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement &&
        [self.content.senderUserInfo.userId isEqualToString:userId]) {
        NSString *senderDisplayName = [RCKitUtility getDisplayName:self.content.senderUserInfo];
        if (senderDisplayName.length > 0) {
            return senderDisplayName;
        }
    }

    NSString *groupId = self.conversationType == ConversationType_GROUP ? self.targetId : nil;
    RCUserInfo *userInfo = [RCKitUtility userInfoForDisplayWithUserId:userId groupId:groupId];
    NSString *displayName = [RCKitUtility getDisplayName:userInfo];
    return displayName.length > 0 ? displayName : userId;
}

- (NSArray<NSString *> *)rc_previewUserIdsForMessageReaction:(RCMessageReaction *)reaction limit:(NSUInteger)limit {
    if (limit == 0 || !reaction) {
        return @[];
    }

    NSMutableArray<NSString *> *userIds = [NSMutableArray arrayWithCapacity:limit];
    NSString *currentUserId = [RCIM sharedRCIM].currentUserInfo.userId;
    if (reaction.hasCurrentUserReacted && currentUserId.length > 0) {
        [userIds addObject:currentUserId];
    }

    for (RCMessageReactionUser *user in reaction.users) {
        if (userIds.count >= limit) {
            break;
        }
        if (user.userId.length <= 0) {
            continue;
        }
        if (currentUserId.length > 0 && [user.userId isEqualToString:currentUserId]) {
            continue;
        }
        if ([userIds containsObject:user.userId]) {
            continue;
        }
        [userIds addObject:user.userId];
    }
    return userIds.copy;
}

- (NSString *)rc_cachedDisplayNameForReactionUserId:(NSString *)userId {
    if (userId.length <= 0) {
        return @"";
    }
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement &&
        [self.content.senderUserInfo.userId isEqualToString:userId]) {
        NSString *senderDisplayName = [RCKitUtility getDisplayName:self.content.senderUserInfo];
        if (senderDisplayName.length > 0) {
            return senderDisplayName;
        }
    }

    NSString *groupId = self.conversationType == ConversationType_GROUP ? self.targetId : nil;
    RCUserInfo *userInfo = [RCKitUtility userInfoForDisplayFromCacheOnlyWithUserId:userId groupId:groupId];
    NSString *displayName = [RCKitUtility getDisplayName:userInfo];
    return displayName.length > 0 ? displayName : userId;
}

@end
