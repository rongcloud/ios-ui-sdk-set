//
//  RCGroupMemberCell.m
//  RongIMKit
//
//  Created by zgh on 2024/8/26.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupMemberCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
NSString  * const RCGroupMemberCellIdentifier = @"RCGroupMemberCellIdentifier";

#define RCGroupMemberCellPortraitLeading 12
#define RCGroupMemberCellPortraitSize 40
#define RCGroupMemberCellNameFont 17
#define RCGroupMemberCellNameLeadingSpace 12
#define RCGroupMemberCellRoleTrailingSpace 12
#define RCGroupMemberCellArrowTrailing 14
#define RCGroupMemberCellArrowWidth 8
#define RCGroupMemberCellArrowHeight 14
#define RCGroupMemberCellArrowLeading (SCREEN_WIDTH-RCGroupMemberCellArrowTrailing-RCGroupMemberCellArrowWidth)

@implementation RCGroupMemberCell

- (void)setupView {
    self.contentView.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                           darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
    [self.contentView addSubview:self.portraitImageView];
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.roleLabel];
    [self.contentView addSubview:self.arrowView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.portraitImageView.frame = CGRectMake(RCGroupMemberCellPortraitLeading, (self.frame.size.height - RCGroupMemberCellPortraitSize)/2, RCGroupMemberCellPortraitSize, RCGroupMemberCellPortraitSize);
    
    if (self.arrowView.hidden) {
        [self.roleLabel sizeToFit];
        self.roleLabel.center = CGPointMake(self.contentView.frame.size.width - RCGroupMemberCellArrowTrailing - self.roleLabel.frame.size.width / 2, self.portraitImageView.center.y);
    } else {
        self.arrowView.frame = CGRectMake(RCGroupMemberCellArrowLeading, (self.frame.size.height - RCGroupMemberCellArrowHeight)/2, RCGroupMemberCellArrowWidth, RCGroupMemberCellArrowHeight);
        [self.roleLabel sizeToFit];
        self.roleLabel.center = CGPointMake(CGRectGetMinX(self.arrowView.frame) - RCGroupMemberCellRoleTrailingSpace - self.roleLabel.frame.size.width / 2, self.portraitImageView.center.y);
    }
    
    CGFloat x = RCGroupMemberCellNameLeadingSpace + CGRectGetMaxX(self.portraitImageView.frame);
    self.nameLabel.frame = CGRectMake(x, 0, self.roleLabel.frame.origin.x - x, self.contentView.frame.size.height); CGPointMake(CGRectGetMaxX(self.portraitImageView.frame)+RCGroupMemberCellNameLeadingSpace+self.nameLabel.frame.size.width/2, self.portraitImageView.center.y);
}

- (void)hiddenArrow:(BOOL)hiddenArrow {
    self.arrowView.hidden = hiddenArrow;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - getter

- (RCloudImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[RCloudImageView alloc] init];
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = RCGroupMemberCellPortraitSize/2;
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
        _nameLabel.font = [UIFont systemFontOfSize:RCGroupMemberCellNameFont];
    }
    return _nameLabel;
}

- (UILabel *)roleLabel {
    if (!_roleLabel) {
        _roleLabel = [[UILabel alloc] init];
        _roleLabel.textColor = RCDYCOLOR(0xA0A5Ab, 0x878787);
        _roleLabel.font = [UIFont systemFontOfSize:RCGroupMemberCellNameFont];
        _roleLabel.textAlignment = NSTextAlignmentRight;
    }
    return _roleLabel;
}

- (RCBaseImageView *)arrowView {
   if (!_arrowView) {
       _arrowView = [[RCBaseImageView alloc] initWithImage:RCDynamicImage(@"cell_right_arrow_img", @"right_arrow")];
   }
   return _arrowView;
}

@end
