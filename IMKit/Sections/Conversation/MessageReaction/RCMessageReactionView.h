//
//  RCMessageReactionView.h
//  RongIMKit
//
//  Created by RC on 2026/6/2.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RCMessageModel;
@class RCMessageReaction;
@class RCMessageReactionView;

@protocol RCMessageReactionViewInternalDelegate <NSObject>

- (void)messageReactionView:(RCMessageReactionView *)reactionView didTapReaction:(RCMessageReaction *)reaction message:(RCMessageModel *)message;
- (void)messageReactionView:(RCMessageReactionView *)reactionView didTapReactionDetail:(RCMessageReaction *)reaction message:(RCMessageModel *)message;

@end

@interface RCMessageReactionView : UIView

@property (nonatomic, weak, nullable) id<RCMessageReactionViewInternalDelegate> delegate;

- (void)updateWithMessageModel:(RCMessageModel *)model;
+ (CGSize)sizeForMessageModel:(RCMessageModel *)model maxWidth:(CGFloat)maxWidth;
+ (CGFloat)heightForMessageModel:(RCMessageModel *)model maxWidth:(CGFloat)maxWidth;

@end

NS_ASSUME_NONNULL_END
