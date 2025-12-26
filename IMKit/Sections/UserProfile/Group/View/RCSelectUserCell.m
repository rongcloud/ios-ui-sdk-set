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

#define RCSelectUserCellSelectLeading 12
#define RCSelectUserCellSelectSize 20
#define RCSelectUserCellPortraitLeading 8
#define RCSelectUserCellPortraitSize 32
#define RCSelectUserCellNameFont 17
#define RCSelectUserCellNameLeadingSpace 12

@interface RCSelectUserCell ()
@end

@implementation RCSelectUserCell

- (void)setupView {
    [super setupView];
    self.contentStackView.spacing = RCSelectUserCellSelectLeading;
    [self.contentStackView addArrangedSubview:self.selectImageView];
    [self.contentStackView addArrangedSubview:self.portraitImageView];
    [self.contentStackView addArrangedSubview:self.nameLabel];

}

- (void)appendViewAtEnd:(UIView *)view {
    if (view) {
        [self.contentStackView addArrangedSubview:view];
    }
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:80 trailing:-10];
    [NSLayoutConstraint activateConstraints:@[
        [self.portraitImageView.widthAnchor constraintEqualToConstant:RCSelectUserCellPortraitSize],
        [self.portraitImageView.heightAnchor constraintEqualToConstant:RCSelectUserCellPortraitSize],
        
        [self.selectImageView.widthAnchor constraintEqualToConstant:RCSelectUserCellSelectSize],
        [self.selectImageView.heightAnchor constraintEqualToConstant:RCSelectUserCellSelectSize]
    ]];
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
            self.selectImageView.image = RCDynamicImage(@"group_member_disable_select_img", @"disable_select");
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
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _portraitImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x9f9f9f");
        _nameLabel.font = [UIFont systemFontOfSize:RCSelectUserCellNameFont];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_nameLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [_nameLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        _nameLabel.textAlignment = NSTextAlignmentNatural;
    }
    return _nameLabel;
}

- (RCBaseImageView *)selectImageView {
   if (!_selectImageView) {
       _selectImageView = [[RCBaseImageView alloc] init];
       _selectImageView.translatesAutoresizingMaskIntoConstraints = NO;
   }
   return _selectImageView;
}

@end
