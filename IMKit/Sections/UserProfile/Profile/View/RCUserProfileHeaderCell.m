//
//  RCUUserProfileHeaderCell.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/19.
//

#import "RCUserProfileHeaderCell.h"
#import "RCOnlineStatusView.h"
#import "RCKitConfig.h"
#import "RCKitCommonDefine.h"

#define RCUUserProfileHeaderCellSize 60
#define RCUUserProfileHeaderCellNameFont 11
#define RCUUserProfileHeaderCellRemarkFont 17
#define RCUUserProfileHeaderCellPortraitLeft 15
#define RCUUserProfileHeaderCellPortraitTop 11
#define RCUUserProfileHeaderCellRemarkLeadingSpace 17
#define RCUUserProfileHeaderCellRemarkTop 21

NSString  * const RCUUserProfileHeaderCellIdentifier = @"RCUUserProfileHeaderCellIdentifier";

@interface RCUserProfileHeaderCell ()
@property (nonatomic, strong) UIStackView *labelStackView; // 垂直 StackView：remarkStackView + 名称
@property (nonatomic, strong) UIStackView *remarkStackView; // 水平 StackView：在线状态 + 备注
@end

@implementation RCUserProfileHeaderCell

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.onlineStatusView reset];
}

- (void)setupView {
    [super setupView];
    [self.contentView addSubview:self.portraitImageView];
    [self.contentView addSubview:self.labelStackView];
    
    // 将在线状态和备注添加到水平 StackView
    [self.remarkStackView addArrangedSubview:self.onlineStatusView];
    [self.remarkStackView addArrangedSubview:self.remarkLabel];
    
    // 将 remarkStackView 和 nameLabel 添加到垂直 StackView
    [self.labelStackView addArrangedSubview:self.remarkStackView];
    [self.labelStackView addArrangedSubview:self.nameLabel];
    
    // 设置约束
    [self setupConstraints];
}

- (void)setupConstraints {
    self.portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.labelStackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.remarkLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                           forAxis:UILayoutConstraintAxisHorizontal];
    
    [NSLayoutConstraint activateConstraints:@[
        // portraitImageView 约束
        [self.portraitImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:RCUUserProfileHeaderCellPortraitLeft],
        [self.portraitImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:RCUUserProfileHeaderCellPortraitTop],
        [self.portraitImageView.widthAnchor constraintEqualToConstant:RCUUserProfileHeaderCellSize],
        [self.portraitImageView.heightAnchor constraintEqualToConstant:RCUUserProfileHeaderCellSize],
        [self.portraitImageView.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-RCUUserProfileHeaderCellPortraitTop],
        
        // labelStackView 约束
        [self.labelStackView.leadingAnchor constraintEqualToAnchor:self.portraitImageView.trailingAnchor constant:RCUUserProfileHeaderCellRemarkLeadingSpace],
        [self.labelStackView.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor constant:-RCUUserProfileHeaderCellRemarkLeadingSpace],
        [self.labelStackView.centerYAnchor constraintEqualToAnchor:self.portraitImageView.centerYAnchor]
    ]];
}

- (void)hiddenNameLabel:(BOOL)hidden {
    self.nameLabel.hidden = hidden;
}

- (void)hiddenOnlineStatusView:(BOOL)hidden {
    self.onlineStatusView.hidden = hidden;
}

- (void)updateOnlineStatus:(BOOL)isOnline {
    self.onlineStatusView.online = isOnline;
}

#pragma mark - getter

- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[RCloudImageView alloc] init];
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = RCUUserProfileHeaderCellSize/2;
        }else{
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
    }
    return _portraitImageView;
}

- (UIStackView *)labelStackView {
    if (!_labelStackView) {
        _labelStackView = [[UIStackView alloc] init];
        _labelStackView.axis = UILayoutConstraintAxisVertical;
        _labelStackView.alignment = UIStackViewAlignmentLeading;
        _labelStackView.distribution = UIStackViewDistributionFill;
        _labelStackView.spacing = 5;
    }
    return _labelStackView;
}

- (UIStackView *)remarkStackView {
    if (!_remarkStackView) {
        _remarkStackView = [[UIStackView alloc] init];
        _remarkStackView.axis = UILayoutConstraintAxisHorizontal;
        _remarkStackView.alignment = UIStackViewAlignmentCenter;
        _remarkStackView.distribution = UIStackViewDistributionFill;
        _remarkStackView.spacing = 5;
    }
    return _remarkStackView;
}

- (RCOnlineStatusView *)onlineStatusView {
    if (!_onlineStatusView) {
        _onlineStatusView = [[RCOnlineStatusView alloc] init];
        _onlineStatusView.hidden = YES;
    }
    return _onlineStatusView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = RCDYCOLOR(0xA0A5Ab, 0x878787);
        _nameLabel.font = [UIFont systemFontOfSize:RCUUserProfileHeaderCellNameFont];
    }
    return _nameLabel;
}

- (UILabel *)remarkLabel {
    if (!_remarkLabel) {
        _remarkLabel = [[UILabel alloc] init];
        _remarkLabel.textColor =RCDYCOLOR(0x111f2c, 0x9f9f9f);
        _remarkLabel.font = [UIFont systemFontOfSize:RCUUserProfileHeaderCellRemarkFont];
    }
    return _remarkLabel;
}


@end
