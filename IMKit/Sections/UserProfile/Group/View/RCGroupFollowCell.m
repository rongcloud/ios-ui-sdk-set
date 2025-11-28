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

NSInteger const RCGroupFollowCellPortraitLeading = 12;
NSInteger const RCGroupFollowCellPortraitSize = 40;
NSInteger const RCGroupFollowCellNameFont = 17;
NSInteger const RCGroupFollowCellNameLeadingSpace = 12;
NSInteger const RCGroupFollowCellActionButtonHeight = 24;
NSInteger const RCGroupFollowCellActionButtonMinWidth = 45;
NSInteger const RCGroupFollowCellActionButtonSpace = 10;
NSInteger const RCGroupFollowCellActionButtonTrailingSpace = 16;
@implementation RCGroupFollowCell

- (void)setupView {
    self.contentView.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                           darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
    [self.contentView addSubview:self.portraitImageView];
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.actionButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.portraitImageView.frame = CGRectMake(RCGroupFollowCellPortraitLeading, (self.frame.size.height - RCGroupFollowCellPortraitSize)/2, RCGroupFollowCellPortraitSize, RCGroupFollowCellPortraitSize);
    [self.actionButton sizeToFit];
    
    CGFloat width = MAX(self.actionButton.frame.size.width + RCGroupFollowCellActionButtonSpace, RCGroupFollowCellActionButtonMinWidth);
    self.actionButton.frame = CGRectMake(self.contentView.frame.size.width - RCGroupFollowCellActionButtonTrailingSpace - width, (self.contentView.frame.size.height - RCGroupFollowCellActionButtonHeight)/2, width, RCGroupFollowCellActionButtonHeight);
    
    CGFloat x = RCGroupFollowCellNameLeadingSpace + CGRectGetMaxX(self.portraitImageView.frame);
    self.nameLabel.frame = CGRectMake(x, 0, self.actionButton.frame.origin.x - x, self.contentView.frame.size.height); CGPointMake(CGRectGetMaxX(self.portraitImageView.frame)+RCGroupFollowCellNameLeadingSpace+self.nameLabel.frame.size.width/2, self.portraitImageView.center.y);
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
        _nameLabel.textColor = RCDYCOLOR(0x111f2c, 0x9f9f9f);
        _nameLabel.font = [UIFont systemFontOfSize:RCGroupFollowCellNameFont];
    }
    return _nameLabel;
}

- (RCButton *)actionButton {
    if (!_actionButton) {
        RCButton *btn = [RCButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:RCLocalizedString(@"Remove") forState:UIControlStateNormal];
        btn.backgroundColor = RCDYCOLOR(0xDDDDDD, 0x3C3C3C);
        [btn setTitleColor:RCDYCOLOR(0x000000, 0xD3E1EE) forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:13];
        btn.layer.cornerRadius = 6;
        btn.layer.masksToBounds = YES;
        [btn addTarget:self
                action:@selector(actionButtonDidTap)
      forControlEvents:UIControlEventTouchUpInside];
        _actionButton = btn;
    }
    return _actionButton;
}

@end
