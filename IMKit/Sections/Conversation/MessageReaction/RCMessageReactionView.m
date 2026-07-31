//
//  RCMessageReactionView.m
//  RongIMKit
//
//  Created by RC on 2026/6/2.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageReactionView.h"
#import "RCMessageReactionItemView.h"
#import "RCMessageModel+MessageReaction.h"
#import "RCMessageModel.h"
#import "RCKitConfig.h"
#import <RongIMLibCore/RongIMLibCore.h>

static CGFloat const RCMessageReactionViewSpacing = 4.0;
static CGFloat const RCMessageReactionViewLineSpacing = 6.0;
static CGFloat const RCMessageReactionViewTopMargin = 0.0;
static CGFloat const RCMessageReactionViewBottomMargin = 6.0;
static CGFloat const RCMessageReactionViewContainerHorizontalInset = 12.0;
static CGFloat const RCMessageReactionViewContainerVerticalInset = 0.0;

@interface RCMessageReactionView ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) NSMutableArray<RCMessageReactionItemView *> *itemViews;
@property (nonatomic, weak) RCMessageModel *model;

@end

@implementation RCMessageReactionView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _itemViews = [NSMutableArray array];
        [self addSubview:self.containerView];
    }
    return self;
}

- (void)updateWithMessageModel:(RCMessageModel *)model {
    self.model = model;
    NSArray<RCMessageReaction *> *reactions = [model rc_visibleReactions];
    self.hidden = reactions.count == 0;
    while (self.itemViews.count < reactions.count) {
        RCMessageReactionItemView *itemView = [[RCMessageReactionItemView alloc] initWithFrame:CGRectZero];
        __weak typeof(self) weakSelf = self;
        itemView.reactionTapHandler = ^(RCMessageReaction *reaction) {
            [weakSelf notifyDidTapReaction:reaction];
        };
        itemView.detailTapHandler = ^(RCMessageReaction *reaction) {
            [weakSelf notifyDidTapReactionDetail:reaction];
        };
        [self.itemViews addObject:itemView];
        [self.containerView addSubview:itemView];
    }
    [self.itemViews enumerateObjectsUsingBlock:^(RCMessageReactionItemView *itemView, NSUInteger idx, BOOL *stop) {
        if (idx < reactions.count) {
            itemView.hidden = NO;
            [itemView updateWithReaction:reactions[idx]
                             displayMode:RCKitConfigCenter.message.messageReactionDisplayMode
                        messageDirection:model.messageDirection
                             messageModel:model];
        } else {
            itemView.hidden = YES;
        }
    }];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat maxWidth = self.bounds.size.width;
    NSArray<RCMessageReaction *> *reactions = [self.model rc_visibleReactions];
    CGSize containerSize = [self.class containerSizeForReactions:reactions messageModel:self.model maxWidth:maxWidth];
    self.containerView.frame = CGRectMake(0, RCMessageReactionViewTopMargin, containerSize.width, containerSize.height);

    NSArray<NSValue *> *itemFrames = [self.class itemFramesForReactions:reactions
                                                            messageModel:self.model
                                                                maxWidth:containerSize.width];
    NSUInteger visibleIndex = 0;
    for (RCMessageReactionItemView *itemView in self.itemViews) {
        if (itemView.hidden) {
            continue;
        }
        if (visibleIndex >= itemFrames.count) {
            itemView.frame = CGRectZero;
            continue;
        }
        CGRect itemFrame = itemFrames[visibleIndex].CGRectValue;
        itemView.frame = itemFrame;
        CGFloat labelMaxWidth = [RCMessageReactionItemView labelMaxWidthForReactionId:itemView.reaction.reactionId itemWidth:CGRectGetWidth(itemFrame)];
        RCMessageReactionItemTextLayout *textLayout = [RCMessageReactionItemView textLayoutForReaction:itemView.reaction
                                                                                           displayMode:RCKitConfigCenter.message.messageReactionDisplayMode
                                                                                          messageModel:self.model
                                                                                              maxWidth:labelMaxWidth];
        [itemView updateTextLayout:textLayout];
        visibleIndex += 1;
    }
}

+ (CGFloat)heightForMessageModel:(RCMessageModel *)model maxWidth:(CGFloat)maxWidth {
    return [self sizeForMessageModel:model maxWidth:maxWidth].height;
}

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model maxWidth:(CGFloat)maxWidth {
    NSArray<RCMessageReaction *> *reactions = [model rc_visibleReactions];
    if (reactions.count == 0 || maxWidth <= 0) {
        return CGSizeZero;
    }
    CGSize containerSize = [self containerSizeForReactions:reactions messageModel:model maxWidth:maxWidth];
    if (containerSize.height <= 0) {
        return CGSizeZero;
    }
    return CGSizeMake(containerSize.width, RCMessageReactionViewTopMargin + containerSize.height + RCMessageReactionViewBottomMargin);
}

+ (CGSize)containerSizeForReactions:(NSArray<RCMessageReaction *> *)reactions
                        messageModel:(RCMessageModel *)messageModel
                           maxWidth:(CGFloat)maxWidth {
    NSArray<NSValue *> *itemFrames = [self itemFramesForReactions:reactions messageModel:messageModel maxWidth:maxWidth];
    if (itemFrames.count == 0) {
        return CGSizeZero;
    }
    CGFloat contentRight = 0;
    CGFloat contentBottom = 0;
    for (NSValue *itemFrameValue in itemFrames) {
        CGRect itemFrame = itemFrameValue.CGRectValue;
        contentRight = MAX(contentRight, CGRectGetMaxX(itemFrame));
        contentBottom = MAX(contentBottom, CGRectGetMaxY(itemFrame));
    }
    CGFloat containerWidth = MIN(maxWidth, contentRight + RCMessageReactionViewContainerHorizontalInset);
    CGFloat containerHeight = contentBottom + RCMessageReactionViewContainerVerticalInset;
    return CGSizeMake(ceil(containerWidth), ceil(containerHeight));
}

+ (NSArray<NSValue *> *)itemFramesForReactions:(NSArray<RCMessageReaction *> *)reactions
                                  messageModel:(RCMessageModel *)messageModel
                                      maxWidth:(CGFloat)maxWidth {
    if (reactions.count == 0 || maxWidth <= 0) {
        return @[];
    }
    CGFloat innerMaxWidth = MAX(maxWidth - RCMessageReactionViewContainerHorizontalInset * 2, 0);
    if (innerMaxWidth <= 0) {
        return @[];
    }
    NSMutableArray<NSValue *> *itemFrames = [NSMutableArray arrayWithCapacity:reactions.count];
    CGFloat x = RCMessageReactionViewContainerHorizontalInset;
    CGFloat y = RCMessageReactionViewContainerVerticalInset;
    CGFloat right = maxWidth - RCMessageReactionViewContainerHorizontalInset;
    for (RCMessageReaction *reaction in reactions) {
        CGFloat preferredWidth = [RCMessageReactionItemView widthForReaction:reaction
                                                                 displayMode:RCKitConfigCenter.message.messageReactionDisplayMode
                                                                messageModel:messageModel
                                                                    maxWidth:0];
        CGFloat width = MIN(preferredWidth, innerMaxWidth);
        BOOL isFirstItemInLine = x <= RCMessageReactionViewContainerHorizontalInset;
        if (!isFirstItemInLine && x + width > right) {
            x = RCMessageReactionViewContainerHorizontalInset;
            y += RCMessageReactionItemViewHeight + RCMessageReactionViewLineSpacing;
            width = MIN(preferredWidth, innerMaxWidth);
        }
        CGRect itemFrame = CGRectMake(x, y, width, RCMessageReactionItemViewHeight);
        [itemFrames addObject:[NSValue valueWithCGRect:itemFrame]];
        x = CGRectGetMaxX(itemFrame) + RCMessageReactionViewSpacing;
    }
    return itemFrames.copy;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:CGRectZero];
        _containerView.backgroundColor = UIColor.clearColor;
        _containerView.layer.cornerRadius = 8;
        _containerView.layer.masksToBounds = YES;
    }
    return _containerView;
}

- (void)notifyDidTapReaction:(RCMessageReaction *)reaction {
    if ([self.delegate respondsToSelector:@selector(messageReactionView:didTapReaction:message:)]) {
        [self.delegate messageReactionView:self didTapReaction:reaction message:self.model];
    }
}

- (void)notifyDidTapReactionDetail:(RCMessageReaction *)reaction {
    if ([self.delegate respondsToSelector:@selector(messageReactionView:didTapReactionDetail:message:)]) {
        [self.delegate messageReactionView:self didTapReactionDetail:reaction message:self.model];
    }
}

@end
