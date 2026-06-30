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
#import "RCSemanticContext.h"

NSString  * const RCGroupMemberCellIdentifier = @"RCGroupMemberCellIdentifier";

#define RCGroupMemberCellPortraitSize 40
#define RCGroupMemberCellNameFont 17
#define RCGroupMemberCellViewSpace 12
#define RCGroupMemberCellArrowWidth 8
#define RCGroupMemberCellArrowHeight 14


@interface RCGroupMemberCell()
@end

@implementation RCGroupMemberCell

- (void)setupView {
    [super setupView];
    self.contentStackView.spacing = RCGroupMemberCellViewSpace;
    [self.contentStackView addArrangedSubview:self.portraitImageView];
    [self.contentStackView addArrangedSubview:self.nameLabel];
    [self.contentStackView addArrangedSubview:self.roleLabel];
    [self.contentStackView addArrangedSubview:self.arrowView];
}


- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:60
                           trailing:-10];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.arrowView.widthAnchor constraintEqualToConstant:RCGroupMemberCellArrowWidth],
        [self.arrowView.heightAnchor constraintEqualToConstant:RCGroupMemberCellArrowHeight],
        [self.portraitImageView.widthAnchor constraintEqualToConstant:RCGroupMemberCellPortraitSize],
        [self.portraitImageView.heightAnchor constraintEqualToConstant:RCGroupMemberCellPortraitSize]
    ]];
}

- (void)hiddenArrow:(BOOL)hiddenArrow {
    self.arrowView.hidden = hiddenArrow;
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
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_portraitImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
    }
    return _portraitImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x9f9f9f");
        _nameLabel.font = [UIFont systemFontOfSize:RCGroupMemberCellNameFont];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_nameLabel setContentHuggingPriority:UILayoutPriorityDefaultLow
                                      forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _nameLabel;
}

- (UILabel *)roleLabel {
    if (!_roleLabel) {
        _roleLabel = [[UILabel alloc] init];
        _roleLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xA0A5Ab", @"0x878787");
        _roleLabel.font = [UIFont systemFontOfSize:RCGroupMemberCellNameFont];
        _roleLabel.textAlignment = NSTextAlignmentRight;
        _roleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_roleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _roleLabel;
}

- (RCBaseImageView *)arrowView {
   if (!_arrowView) {
       UIImage *image = RCDynamicImage(@"cell_right_arrow_img", @"right_arrow");
       _arrowView = [[RCBaseImageView alloc] initWithImage: [RCSemanticContext imageflippedForRTL:image]];
       _arrowView.translatesAutoresizingMaskIntoConstraints = NO;
   }
   return _arrowView;
}

@end
