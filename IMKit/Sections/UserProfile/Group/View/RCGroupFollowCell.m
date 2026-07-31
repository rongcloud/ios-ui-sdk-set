//
//  RCGroupFollowCell.m
//  RongIMKit
//
//  Created by zgh on 2024/11/21.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupFollowCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
#import "RCKitUtility.h"

NSString  * const RCGroupFollowCellIdentifier = @"RCGroupFollowCellIdentifier";

NSInteger const RCGroupFollowCellPortraitLeading = 16;
NSInteger const RCGroupFollowCellPortraitSize = 32;
NSInteger const RCGroupFollowCellNameFont = 17;
NSInteger const RCGroupFollowCellNameLeadingSpace = 12;
NSInteger const RCGroupFollowCellActionButtonHeight = 24;
NSInteger const RCGroupFollowCellActionButtonSpace = 10;
NSInteger const RCGroupFollowCellActionButtonTrailingSpace = 3;
@implementation RCGroupFollowCell

- (void)setupView {
    [super setupView];
    self.contentStackView.spacing = 12;
    [self.contentStackView addArrangedSubview:self.portraitImageView];
    [self.contentStackView addArrangedSubview:self.nameLabel];
    [self.contentStackView addArrangedSubview:self.actionButton];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:RCUserManagementImageCellLineLeading
                           trailing:-RCUserManagementImageCellLineTrailing];
    // 禁用自动转换 autoresizing mask
    self.portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nameLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.actionButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [NSLayoutConstraint activateConstraints:@[
        // 宽高 32x32
        [self.portraitImageView.widthAnchor constraintEqualToConstant:RCGroupFollowCellPortraitSize],
        [self.portraitImageView.heightAnchor constraintEqualToConstant:RCGroupFollowCellPortraitSize],
        // 高度 24
        [self.actionButton.heightAnchor constraintEqualToConstant:RCGroupFollowCellActionButtonHeight],
        // 最小宽度 45
    ]];
    
    
}

#pragma mark -- action

- (void)actionButtonDidTap {
    self.actionBlock();
}

#pragma mark - getter

- (RCloudImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[RCloudImageView alloc] init];
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = RCGroupFollowCellPortraitSize/2;
        }else{
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
    }
    return _portraitImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x9f9f9f");
        _nameLabel.font = [UIFont systemFontOfSize:RCGroupFollowCellNameFont];
        [_nameLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [_nameLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _nameLabel;
}

- (RCButton *)actionButton {
    if (!_actionButton) {
        RCButton *btn = [RCButton buttonWithType:UIButtonTypeCustom];
        [btn setImage:RCDynamicImage(@"group_follow_remove_btn_img", @"group_follow_remove_btn")
             forState:UIControlStateNormal];
        [btn addTarget:self
                action:@selector(actionButtonDidTap)
      forControlEvents:UIControlEventTouchUpInside];
        if ([RCKitUtility isRTL]) {
            btn.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 22);
        } else {
            btn.contentEdgeInsets = UIEdgeInsetsMake(0, 22, 0, 0);
        }
         _actionButton = btn;
    }
    return _actionButton;
}


@end
