//
//  RCMessageReactionSummaryLoader.h
//  RongIMKit
//
//  Created by RC on 2026/6/3.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>

NS_ASSUME_NONNULL_BEGIN

@class RCMessageModel;

@interface RCMessageReactionSummaryLoader : NSObject

- (void)loadSummariesForModels:(NSArray<RCMessageModel *> *)models
         conversationIdentifier:(RCConversationIdentifier *)conversationIdentifier
                     completion:(nullable void (^)(NSDictionary<NSString *, NSArray<RCMessageReaction *> *> *reactionsMap))completion;

@end

NS_ASSUME_NONNULL_END
