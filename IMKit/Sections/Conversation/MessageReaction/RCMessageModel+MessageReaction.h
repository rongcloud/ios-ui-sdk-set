//
//  RCMessageModel+MessageReaction.h
//  RongIMKit
//
//  Created by RC on 2026/6/8.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

@class RCMessageReaction;

@interface RCMessageModel (MessageReaction)

- (BOOL)rc_hasVisibleReactions;
- (NSArray<RCMessageReaction *> *)rc_visibleReactions;
- (NSString *)rc_displayNameForReactionUserId:(NSString *)userId;
- (NSArray<NSString *> *)rc_previewUserIdsForMessageReaction:(RCMessageReaction *)reaction limit:(NSUInteger)limit;
- (NSString *)rc_cachedDisplayNameForReactionUserId:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
