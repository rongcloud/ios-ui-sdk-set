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

#define RCGroupMemberHeaderCellPortraitSize 51
#define RCGroupMemberHeaderCellNameHeight 15
#define RCGroupMemberHeaderCellNameFont 11
@implementation RCGroupMemberHeaderCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.portraitImageView.frame = CGRectMake((self.contentView.frame.size.width-RCGroupMemberHeaderCellPortraitSize)/2, 0, RCGroupMemberHeaderCellPortraitSize, RCGroupMemberHeaderCellPortraitSize);
    if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
        RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
        self.portraitImageView.layer.cornerRadius = RCGroupMemberHeaderCellPortraitSize / 2;
    }else{
        self.portraitImageView.layer.cornerRadius = 5.f;
    }
    self.nameLabel.frame = CGRectMake(0, self.contentView.frame.size.height - RCGroupMemberHeaderCellNameHeight, self.contentView.frame.size.width, RCGroupMemberHeaderCellNameHeight);
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
    }
    return _portraitImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = RCDYCOLOR(0x111f2c, 0x9f9f9f);
        _nameLabel.font = [UIFont systemFontOfSize:RCGroupMemberHeaderCellNameFont];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _nameLabel;
}
@end
