//
//  RCGroupMemberHeaderCell.m
//  RongIMKit
//
//  Created by zgh on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCKitConfig.h"
#import "RCKitCommonDefine.h"
#import "RCGroupMemberHeaderCell.h"

NSString  * const RCGroupMemberHeaderCellIdentifier = @"RCGroupMemberHeaderCellIdentifier";

#define RCGroupMemberHeaderCellPortraitSize 48
#define RCGroupMemberHeaderCellNameHeight 15
#define RCGroupMemberHeaderCellNameFont 12
@implementation RCGroupMemberHeaderCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
        [self setupViewConstraints];
    }
    return self;
}

- (void)setupViewConstraints {
    [NSLayoutConstraint activateConstraints:@[
           [self.portraitImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
           [self.portraitImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
           [self.portraitImageView.heightAnchor constraintEqualToConstant:RCGroupMemberHeaderCellPortraitSize],
           [self.portraitImageView.widthAnchor constraintEqualToConstant:RCGroupMemberHeaderCellPortraitSize],
           
           [self.nameLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
           [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
           [self.nameLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor]
       ]];
}

- (void)setupView {
    [self.contentView addSubview:self.portraitImageView];
    [self.contentView addSubview:self.nameLabel];
}

#pragma mark - getter
- (RCloudImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[RCloudImageView alloc] init];
        _portraitImageView.layer.masksToBounds = YES;
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = RCGroupMemberHeaderCellPortraitSize / 2;
        }else{
            _portraitImageView.layer.cornerRadius = 5.f;
        }
    }
    return _portraitImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0x111f2c", @"0x9f9f9f");
        _nameLabel.font = [UIFont systemFontOfSize:RCGroupMemberHeaderCellNameFont];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _nameLabel;
}
@end
