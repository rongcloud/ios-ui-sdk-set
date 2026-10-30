//
//  RCMessageReactionItemView.h
//  RongIMKit
//
//  Created by RC on 2026/6/12.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RongIMLibCore/RongIMLibCore.h>

NS_ASSUME_NONNULL_BEGIN

@class RCMessageModel;
@class RCMessageReaction;
@class RCMessageReactionItemTextLayout;
typedef NS_ENUM(NSInteger, RCMessageReactionDisplayMode);

UIKIT_EXTERN CGFloat const RCMessageReactionItemViewHeight;

@interface RCMessageReactionItemView : UIView

@property (nonatomic, strong, readonly, nullable) RCMessageReaction *reaction;
@property (nonatomic, copy, nullable) void (^reactionTapHandler)(RCMessageReaction *reaction);
@property (nonatomic, copy, nullable) void (^detailTapHandler)(RCMessageReaction *reaction);

- (void)updateWithReaction:(RCMessageReaction *)reaction
               displayMode:(RCMessageReactionDisplayMode)displayMode
          messageDirection:(RCMessageDirection)messageDirection
              messageModel:(RCMessageModel *)messageModel;
- (void)updateTextLayout:(RCMessageReactionItemTextLayout *)textLayout;

+ (CGFloat)widthForReaction:(RCMessageReaction *)reaction
                displayMode:(RCMessageReactionDisplayMode)displayMode
               messageModel:(RCMessageModel *)messageModel
                   maxWidth:(CGFloat)maxWidth;
+ (RCMessageReactionItemTextLayout *)textLayoutForReaction:(RCMessageReaction *)reaction
                                               displayMode:(RCMessageReactionDisplayMode)displayMode
                                              messageModel:(RCMessageModel *)messageModel
                                                  maxWidth:(CGFloat)maxWidth;
+ (CGFloat)labelMaxWidthForReactionId:(NSString *)reactionId itemWidth:(CGFloat)itemWidth;

@end

NS_ASSUME_NONNULL_END
