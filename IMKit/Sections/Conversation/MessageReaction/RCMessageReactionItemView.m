//
//  RCMessageReactionItemView.m
//  RongIMKit
//
//  Created by RC on 2026/6/12.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageReactionItemView.h"
#import "RCIM.h"
#import "RCMessageModel+MessageReaction.h"
#import "RCKitCommonDefine.h"
#import "RCKitMessageConf.h"
#import "RCKitUtility.h"

CGFloat const RCMessageReactionItemViewHeight = 24.0;

static CGFloat const RCMessageReactionItemHorizontalInset = 6.0;
static CGFloat const RCMessageReactionItemElementSpacing = 4.0;
static CGFloat const RCMessageReactionItemSeparatorWidth = 1.0;
static CGFloat const RCMessageReactionItemSeparatorVerticalInset = 4.0;
static CGFloat const RCMessageReactionItemFontSize = 14.0;
static NSUInteger const RCMessageReactionPreviewUserLimit = 10;

@interface RCMessageReactionItemTextLayout : NSObject

@property (nonatomic, copy) NSString *prefixText;
@property (nonatomic, copy) NSString *detailText;
@property (nonatomic, copy) NSString *labelText;
@property (nonatomic, assign) BOOL detailEnabled;

@end

@implementation RCMessageReactionItemTextLayout

@end

@interface RCMessageReactionItemView ()

@property (nonatomic, strong) UILabel *emojiLabel;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UILabel *prefixLabel;
@property (nonatomic, strong) UIButton *reactionButton;
@property (nonatomic, strong) UIButton *detailButton;
@property (nonatomic, strong, readwrite, nullable) RCMessageReaction *reaction;
@property (nonatomic, strong) RCMessageReactionItemTextLayout *textLayout;

@end

@implementation RCMessageReactionItemView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = RCMessageReactionItemViewHeight / 2.0;
        self.layer.borderWidth = 0.5;
        self.layer.masksToBounds = YES;
        [self addSubview:self.emojiLabel];
        [self addSubview:self.separatorView];
        [self addSubview:self.prefixLabel];
        [self addSubview:self.detailButton];
        [self addSubview:self.reactionButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat emojiWidth = [self.class widthForText:self.emojiLabel.text];
    CGFloat x = RCMessageReactionItemHorizontalInset;
    self.emojiLabel.frame = CGRectMake(x, 0, emojiWidth, CGRectGetHeight(self.bounds));
    x += emojiWidth + RCMessageReactionItemElementSpacing;
    self.separatorView.frame = CGRectMake(x, RCMessageReactionItemSeparatorVerticalInset,
                                          RCMessageReactionItemSeparatorWidth,
                                          MAX(CGRectGetHeight(self.bounds) - RCMessageReactionItemSeparatorVerticalInset * 2, 0));
    self.reactionButton.frame = CGRectMake(0, 0, CGRectGetMinX(self.separatorView.frame), CGRectGetHeight(self.bounds));
    x += RCMessageReactionItemSeparatorWidth + RCMessageReactionItemElementSpacing;
    CGFloat availableWidth = MAX(CGRectGetWidth(self.bounds) - x - RCMessageReactionItemHorizontalInset, 0);
    CGFloat detailWidth = self.textLayout.detailEnabled ? MIN([self.class widthForText:self.textLayout.detailText], availableWidth) : 0;
    CGFloat prefixWidth = MAX(availableWidth - detailWidth, 0);
    if (self.textLayout.prefixText.length > 0) {
        self.prefixLabel.frame = CGRectMake(x, 0, prefixWidth, CGRectGetHeight(self.bounds));
        x = CGRectGetMaxX(self.prefixLabel.frame);
    } else {
        self.prefixLabel.frame = CGRectZero;
    }
    self.detailButton.hidden = !self.textLayout.detailEnabled;
    self.detailButton.frame = self.textLayout.detailEnabled ? CGRectMake(x, 0, detailWidth, CGRectGetHeight(self.bounds)) : CGRectZero;
}

- (void)updateWithReaction:(RCMessageReaction *)reaction
               displayMode:(RCMessageReactionDisplayMode)displayMode
          messageDirection:(RCMessageDirection)messageDirection
              messageModel:(RCMessageModel *)messageModel {
    self.reaction = reaction;
    self.emojiLabel.text = reaction.reactionId ?: @"";
    [self updateTextLayout:[self.class textLayoutForReaction:reaction
                                                 displayMode:displayMode
                                                messageModel:messageModel
                                                    maxWidth:0]];
    BOOL selected = [self.class shouldShowSelectedStateForReaction:reaction];
    if (selected) {
        self.backgroundColor = RCDynamicColor(@"message_reaction_selected_background_color", @"0xBED4FF", @"0x2052B7");
        self.layer.borderColor = RCDynamicColor(@"message_reaction_selected_border_color", @"0x0047FFCC", @"0x4177FFCC").CGColor;
    } else {
        self.backgroundColor = RCDynamicColor(@"message_reaction_default_background_color", @"0xF0F0F0", @"0xFFFFFF33");
        self.layer.borderColor = UIColor.clearColor.CGColor;
    }
}

- (void)updateTextLayout:(RCMessageReactionItemTextLayout *)textLayout {
    self.textLayout = textLayout;
    self.prefixLabel.text = textLayout.prefixText;
    [self.detailButton setTitle:textLayout.detailText forState:UIControlStateNormal];
    self.detailButton.hidden = !textLayout.detailEnabled;
    [self setNeedsLayout];
}

- (void)onReactionButtonClick:(id)sender {
    if (self.reactionTapHandler) {
        self.reactionTapHandler(self.reaction);
    }
}

- (void)onDetailButtonClick:(id)sender {
    if (self.detailTapHandler) {
        self.detailTapHandler(self.reaction);
    }
}

+ (BOOL)shouldShowSelectedStateForReaction:(RCMessageReaction *)reaction {
    return reaction.hasCurrentUserReacted;
}

+ (CGFloat)widthForReaction:(RCMessageReaction *)reaction
                displayMode:(RCMessageReactionDisplayMode)displayMode
               messageModel:(RCMessageModel *)messageModel
                   maxWidth:(CGFloat)maxWidth {
    RCMessageReactionItemTextLayout *textLayout = [self textLayoutForReaction:reaction
                                                                  displayMode:displayMode
                                                                 messageModel:messageModel
                                                                     maxWidth:0];
    CGFloat width = [self itemWidthForReactionId:reaction.reactionId labelText:textLayout.labelText];
    if (maxWidth > 0) {
        width = MIN(width, maxWidth);
    }
    return width;
}

+ (CGFloat)widthForText:(NSString *)text {
    CGFloat width = [RCKitUtility getTextDrawingSize:text
                                                font:[UIFont systemFontOfSize:RCMessageReactionItemFontSize]
                                     constrainedSize:CGSizeMake(CGFLOAT_MAX, RCMessageReactionItemViewHeight)].width;
    return ceil(width);
}

+ (CGFloat)itemWidthForReactionId:(NSString *)reactionId labelText:(NSString *)labelText {
    CGFloat width = RCMessageReactionItemHorizontalInset * 2;
    width += [self widthForText:reactionId ?: @""];
    width += RCMessageReactionItemElementSpacing + RCMessageReactionItemSeparatorWidth + RCMessageReactionItemElementSpacing;
    width += [self widthForText:labelText ?: @""];
    return MAX(RCMessageReactionItemViewHeight, ceil(width));
}

+ (CGFloat)labelMaxWidthForReactionId:(NSString *)reactionId itemWidth:(CGFloat)itemWidth {
    CGFloat chromeWidth = RCMessageReactionItemHorizontalInset * 2;
    chromeWidth += [self widthForText:reactionId ?: @""];
    chromeWidth += RCMessageReactionItemElementSpacing + RCMessageReactionItemSeparatorWidth + RCMessageReactionItemElementSpacing;
    return MAX(itemWidth - chromeWidth, 0);
}

+ (RCMessageReactionItemTextLayout *)textLayoutForReaction:(RCMessageReaction *)reaction
                                               displayMode:(RCMessageReactionDisplayMode)displayMode
                                              messageModel:(RCMessageModel *)messageModel
                                                  maxWidth:(CGFloat)maxWidth {
    NSString *countText = reaction.totalCount > 99 ? @"99+" : [NSString stringWithFormat:@"%@", @(MAX(reaction.totalCount, 0))];
    if (displayMode == RCMessageReactionDisplayModeCountOnly) {
        NSString *detailText = [NSString stringWithFormat:@"%@%@", countText, RCLocalizedString(@"MessageReactionUserCountSuffix")];
        return [self textLayoutWithPrefixText:@"" detailText:detailText detailEnabled:YES];
    }
    if (displayMode == RCMessageReactionDisplayModeDetail && (reaction.users.count > 0 || reaction.hasCurrentUserReacted)) {
        NSMutableArray<NSString *> *userNames = [NSMutableArray array];
        NSString *currentUserId = [RCIM sharedRCIM].currentUserInfo.userId;
        if (reaction.hasCurrentUserReacted) {
            NSString *currentUserDisplayName = [self currentUserDisplayNameForMessageModel:messageModel];
            if (currentUserDisplayName.length > 0) {
                [userNames addObject:currentUserDisplayName];
            }
        }
        for (RCMessageReactionUser *user in reaction.users) {
            if (user.userId.length <= 0) {
                continue;
            }
            if (currentUserId.length > 0 && [user.userId isEqualToString:currentUserId]) {
                continue;
            }
            if (userNames.count >= RCMessageReactionPreviewUserLimit) {
                break;
            }
            NSString *displayName = [messageModel rc_cachedDisplayNameForReactionUserId:user.userId];
            if (displayName.length > 0) {
                [userNames addObject:displayName];
            }
        }
        if (userNames.count > 0) {
            return [self textLayoutWithUserNames:userNames countText:countText maxWidth:maxWidth];
        }
    }
    return [self textLayoutWithPrefixText:countText detailText:@"" detailEnabled:NO];
}

+ (NSString *)currentUserDisplayNameForMessageModel:(RCMessageModel *)messageModel {
    RCUserInfo *currentUserInfo = [RCIM sharedRCIM].currentUserInfo;
    NSString *displayName = [RCKitUtility getDisplayName:currentUserInfo];
    if (displayName.length > 0) {
        return displayName;
    }

    NSString *currentUserId = currentUserInfo.userId;
    if (currentUserId.length > 0) {
        displayName = [messageModel rc_cachedDisplayNameForReactionUserId:currentUserId];
        if (displayName.length > 0) {
            return displayName;
        }
        return currentUserId;
    }

    return @"";
}

+ (RCMessageReactionItemTextLayout *)textLayoutWithUserNames:(NSArray<NSString *> *)userNames
                                                   countText:(NSString *)countText
                                                    maxWidth:(CGFloat)maxWidth {
    NSString *userSummary = [userNames componentsJoinedByString:@", "];
    if (maxWidth <= 0 || [self widthForText:userSummary] <= maxWidth) {
        return [self textLayoutWithPrefixText:userSummary detailText:@"" detailEnabled:NO];
    }
    NSString *overflowSuffix = [NSString stringWithFormat:@"...%@%@", countText, RCLocalizedString(@"MessageReactionUserCountSuffix")];
    if ([self widthForText:overflowSuffix] > maxWidth) {
        return [self textLayoutWithPrefixText:@"" detailText:overflowSuffix detailEnabled:YES];
    }
    NSString *bestPrefix = @"";
    NSInteger low = 0;
    NSInteger high = userSummary.length;
    while (low <= high) {
        NSInteger mid = (low + high) / 2;
        NSString *prefix = [self normalizedUserSummaryPrefix:userSummary length:mid];
        NSString *candidateText = prefix.length > 0 ? [NSString stringWithFormat:@"%@%@", prefix, overflowSuffix] : overflowSuffix;
        if ([self widthForText:candidateText] <= maxWidth) {
            bestPrefix = prefix;
            low = mid + 1;
        } else {
            high = mid - 1;
        }
    }
    return [self textLayoutWithPrefixText:bestPrefix detailText:overflowSuffix detailEnabled:YES];
}

+ (RCMessageReactionItemTextLayout *)textLayoutWithPrefixText:(NSString *)prefixText
                                                   detailText:(NSString *)detailText
                                                detailEnabled:(BOOL)detailEnabled {
    RCMessageReactionItemTextLayout *layout = [[RCMessageReactionItemTextLayout alloc] init];
    layout.prefixText = prefixText ?: @"";
    layout.detailText = detailText ?: @"";
    layout.detailEnabled = detailEnabled && layout.detailText.length > 0;
    layout.labelText = [NSString stringWithFormat:@"%@%@", layout.prefixText, layout.detailText];
    return layout;
}

+ (NSString *)normalizedUserSummaryPrefix:(NSString *)userSummary length:(NSInteger)length {
    if (userSummary.length == 0 || length <= 0) {
        return @"";
    }
    NSRange range = [userSummary rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, MIN((NSUInteger)length, userSummary.length))];
    NSString *prefix = [userSummary substringWithRange:range];
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    prefix = [prefix stringByTrimmingCharactersInSet:whitespaceSet];
    while ([prefix hasSuffix:@","]) {
        prefix = [prefix substringToIndex:prefix.length - 1];
        prefix = [prefix stringByTrimmingCharactersInSet:whitespaceSet];
    }
    return prefix;
}

- (UIButton *)reactionButton {
    if (!_reactionButton) {
        _reactionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _reactionButton.backgroundColor = UIColor.clearColor;
        [_reactionButton addTarget:self action:@selector(onReactionButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _reactionButton;
}

- (UIButton *)detailButton {
    if (!_detailButton) {
        _detailButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _detailButton.backgroundColor = UIColor.clearColor;
        _detailButton.titleLabel.font = [UIFont systemFontOfSize:RCMessageReactionItemFontSize];
        _detailButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [_detailButton setTitleColor:RCDynamicColor(@"message_reaction_item_text_color", @"0x565960", @"0xFFFFFF")
                             forState:UIControlStateNormal];
        [_detailButton addTarget:self action:@selector(onDetailButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _detailButton;
}

- (UILabel *)emojiLabel {
    if (!_emojiLabel) {
        _emojiLabel = [self createLabel];
        _emojiLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _emojiLabel;
}

- (UIView *)separatorView {
    if (!_separatorView) {
        _separatorView = [[UIView alloc] initWithFrame:CGRectZero];
        _separatorView.backgroundColor = RCDynamicColor(@"message_reaction_divider_color", @"0xA6A6A6", @"0xFFFFFF");
    }
    return _separatorView;
}

- (UILabel *)prefixLabel {
    if (!_prefixLabel) {
        _prefixLabel = [self createLabel];
    }
    return _prefixLabel;
}

- (UILabel *)createLabel {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.font = [UIFont systemFontOfSize:RCMessageReactionItemFontSize];
    label.textColor = RCDynamicColor(@"message_reaction_item_text_color", @"0x565960", @"0xFFFFFF");
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    return label;
}

@end
