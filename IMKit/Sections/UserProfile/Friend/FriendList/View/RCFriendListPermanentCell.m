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
    self.contentView.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                        darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.contentView addSubview:self.portraitImageView];
    [self.contentView addSubview:self.contentStackView];
    
    // 将在线状态和名称添加到 StackView
    [self.contentStackView addArrangedSubview:self.onlineStatusView];
    [self.contentStackView addArrangedSubview:self.labName];
}

- (void)setupConstraints {
    [super setupConstraints];
    CGFloat portraitWidth = 40;
    CGFloat marginWidth = 15;
    
    self.portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentStackView.translatesAutoresizingMaskIntoConstraints = NO;

    // onlineStatusView 压缩优先级
    [self.onlineStatusView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    [NSLayoutConstraint activateConstraints:@[
        // portraitImageView 约束
        [self.portraitImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:marginWidth],
        [self.portraitImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.portraitImageView.widthAnchor constraintEqualToConstant:portraitWidth],
        [self.portraitImageView.heightAnchor constraintEqualToConstant:portraitWidth],
        
        // contentStackView 约束
        [self.contentStackView.leadingAnchor constraintEqualToAnchor:self.portraitImageView.trailingAnchor constant:marginWidth],
        [self.contentStackView.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor constant:-marginWidth],
        [self.contentStackView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor]
    ]];
}

- (void)showPortraitByImage:(UIImage *)image {
    [self.portraitImageView setImage:image];
}

- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [RCloudImageView new];
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = 20.f;
        } else {
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
    }
    return _portraitImageView;
}

- (UIStackView *)contentStackView {
    if (!_contentStackView) {
        _contentStackView = [[UIStackView alloc] init];
        _contentStackView.axis = UILayoutConstraintAxisHorizontal;
        _contentStackView.alignment = UIStackViewAlignmentCenter;
        _contentStackView.distribution = UIStackViewDistributionFill;
        _contentStackView.spacing = 5;
    }
    return _contentStackView;
}

- (RCOnlineStatusView *)onlineStatusView {
    if (!_onlineStatusView) {
        _onlineStatusView = [[RCOnlineStatusView alloc] init];
    }
    return _onlineStatusView;
}

- (UILabel *)labName {
    if (!_labName) {
        UILabel *lab = [UILabel new];
        _labName = lab;
    }
    return _labName;
}
@end
