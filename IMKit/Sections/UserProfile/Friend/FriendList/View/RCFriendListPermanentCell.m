//
//  RCFriendListPermanentCell.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCFriendListPermanentCell.h"
#import "RCOnlineStatusView.h"
#import "RCloudImageView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
NSString  * const RCFriendListPermanentCellIdentifier = @"RCFriendListPermanentCellIdentifier";
NSInteger const RCFriendListPermanentCellPortraitWidth = 32;

@implementation RCFriendListPermanentCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.onlineStatusView reset];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setupView {
    [super setupView];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // 将在线状态和名称添加到 StackView
    UIView *portraitContainerView = [self portraitContainerView];
    [self.contentStackView addArrangedSubview:portraitContainerView];
    [self.contentStackView addArrangedSubview:self.onlineStatusView];
    [self.contentStackView addArrangedSubview:self.labName];
}

- (UIView *)portraitContainerView {
    UIView *view = [UIView new];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view setContentHuggingPriority:UILayoutPriorityRequired
                            forAxis:UILayoutConstraintAxisHorizontal];
    [view addSubview:self.portraitImageView];
    [NSLayoutConstraint activateConstraints:@[
            [self.portraitImageView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
            [self.portraitImageView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-8],
            [self.portraitImageView.centerYAnchor constraintEqualToAnchor:view.centerYAnchor],
            [self.portraitImageView.widthAnchor constraintEqualToConstant:RCFriendListPermanentCellPortraitWidth],
            [self.portraitImageView.heightAnchor constraintEqualToConstant:RCFriendListPermanentCellPortraitWidth],
        ]];
    return view;
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:RCUserManagementImageCellLineLeading
                           trailing:-RCUserManagementImageCellLineTrailing];
}

- (void)showPortraitByImage:(UIImage *)image {
    [self.portraitImageView setImage:image];
}

- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [RCloudImageView new];
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = RCFriendListPermanentCellPortraitWidth/2;
        } else {
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_portraitImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
    }
    return _portraitImageView;
}

- (RCOnlineStatusView *)onlineStatusView {
    if (!_onlineStatusView) {
        _onlineStatusView = [[RCOnlineStatusView alloc] init];
        [_onlineStatusView setContentHuggingPriority:UILayoutPriorityRequired
                                forAxis:UILayoutConstraintAxisHorizontal];
        _onlineStatusView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _onlineStatusView;
}

- (UILabel *)labName {
    if (!_labName) {
        UILabel *lab = [UILabel new];
        lab.textColor = RCDynamicColor(@"text_primary_color", @"0x020814", @"0xFFFFFF"); 
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab setContentHuggingPriority:UILayoutPriorityDefaultLow
                               forAxis:UILayoutConstraintAxisHorizontal];
        _labName = lab;
    }
    return _labName;
}
@end
