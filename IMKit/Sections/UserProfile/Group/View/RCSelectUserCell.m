//
//  RCSelectUserCell.m
//  RongIMKit
//
//  Created by zgh on 2024/8/26.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCSelectUserCell.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
NSString  * const RCSelectUserCellIdentifier = @"RCSelectUserCellIdentifier";

#define RCSelectUserCellSelectLeading 20
#define RCSelectUserCellSelectSize 20
#define RCSelectUserCellPortraitLeading 8
#define RCSelectUserCellPortraitSize 40
#define RCSelectUserCellNameFont 17
#define RCSelectUserCellNameLeadingSpace 12

@interface RCSelectUserCell ()

@end

@implementation RCSelectUserCell

- (void)setupView {
    self.contentView.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                         darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
    [self.contentView addSubview:self.portraitImageView];
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.selectImageView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.selectImageView.frame = CGRectMake(RCSelectUserCellSelectLeading, (self.frame.size.height - RCSelectUserCellSelectSize)/2, RCSelectUserCellSelectSize, RCSelectUserCellSelectSize);
    self.portraitImageView.frame = CGRectMake(CGRectGetMaxY(self.selectImageView.frame) + RCSelectUserCellPortraitLeading, (self.frame.size.height - RCSelectUserCellPortraitSize)/2, RCSelectUserCellPortraitSize, RCSelectUserCellPortraitSize);
    [self.nameLabel sizeToFit];
    self.nameLabel.center = CGPointMake(CGRectGetMaxX(self.portraitImageView.frame)+RCSelectUserCellNameLeadingSpace+self.nameLabel.frame.size.width/2, self.portraitImageView.center.y);
    CGRect frame = self.nameLabel.frame;
    frame.size.width = self.contentView.frame.size.width - CGRectGetMaxX(self.portraitImageView.frame) - RCSelectUserCellNameLeadingSpace;
    self.nameLabel.frame = frame;
}

- (void)updateSelectState:(RCSelectState)state {
    switch (state) {
        case RCSelectStateUnselect:
            self.selectImageView.image = RCDynamicImage(@"conversation_msg_cell_unselect_img", @"message_cell_unselect");
            break;
        case RCSelectStateSelect:
            self.selectImageView.image = RCDynamicImage(@"conversation_msg_cell_select_img", @"message_cell_select");
            break;
        case RCSelectStateDisable:
            self.selectImageView.image = RCResourceImage(@"disable_select");
            break;
        default:
            break;
    }
}

#pragma mark - getter

- (RCloudImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[RCloudImageView alloc] init];
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = RCSelectUserCellPortraitSize/2;
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
        _nameLabel.font = [UIFont systemFontOfSize:RCSelectUserCellNameFont];
    }
    return _nameLabel;
}

- (RCBaseImageView *)selectImageView {
   if (!_selectImageView) {
       _selectImageView = [[RCBaseImageView alloc] init];
   }
   return _selectImageView;
}

@end
