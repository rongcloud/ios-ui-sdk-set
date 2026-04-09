//
//  RCGroupMemberAddtionalCell.m
//  RongIMKit
//
//  Created by RobinCui on 2025/11/11.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCGroupMemberAdditionalCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

NSString * _Nullable const RCGroupMemberAdditionalCellIdentifier = @"RCGroupMemberAdditionalCellIdentifier";

@implementation RCGroupMemberAdditionalCell
- (void)setupView {
    [super setupView];
    self.contentStackView.spacing = 12;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentStackView addArrangedSubview:self.portraitImageView];
    [self.contentStackView addArrangedSubview:self.labName];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:RCUserManagementImageCellLineLeading
                           trailing:-RCUserManagementImageCellLineTrailing];
    CGFloat portraitWidth = 32;
    
    [NSLayoutConstraint activateConstraints:@[
        // portraitImageView 约束
        [self.portraitImageView.widthAnchor constraintEqualToConstant:portraitWidth],
        [self.portraitImageView.heightAnchor constraintEqualToConstant:portraitWidth],
    ]];
}


- (void)showPortraitByImage:(UIImage *)image {
}


- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [UIImageView new];
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = 16.f;
        } else {
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
    }
    return _portraitImageView;
}


- (UILabel *)labName {
    if (!_labName) {
        UILabel *lab = [UILabel new];
        lab.textColor = RCDynamicColor(@"text_primary_color", @"0x020814", @"0xFFFFFF");
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        _labName = lab;
    }
    return _labName;
}
@end
