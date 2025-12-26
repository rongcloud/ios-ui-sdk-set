//
//  RCGroupNotificationCell.m
//  RongIMKit
//
//  Created by RobinCui on 2024/11/14.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupNotificationCell.h"
#import "RCloudImageView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
NSString  * const RCGroupNotificationCellIdentifier = @"RCGroupNotificationCellIdentifier";
NSInteger const RCGroupNotificationCellHorizontalMargin = 20;

NSInteger const RCGroupNotificationCellPortraitWidth = 32;
NSInteger const RCGroupNotificationOperationCellBtnMinWidth = 45;

@interface RCGroupNotificationCell()

/// 右侧容器 labTips + labName
@property (nonatomic, strong) UIStackView *rightStackView;

/// 顶部容器 portrait + rightStackView
@property (nonatomic, strong) UIStackView *topStackView;

/// 底部容器 labStatus + btnReject + btnApprove
@property (nonatomic, strong) UIStackView *bottomStackView;

/// 内容容器 topStackView + bottomStackView
@property (nonatomic, strong) UIStackView *contentStackView;
@end

@implementation RCGroupNotificationCell


- (void)setupView {
    [super setupView];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.paddingContainerView addSubview:self.contentStackView];
    
    [self.topStackView addArrangedSubview:self.portraitImageView];
    [self.rightStackView addArrangedSubview:self.labTips];
    [self.rightStackView addArrangedSubview:self.labName];

    [self.topStackView addArrangedSubview:self.rightStackView];

    [self.contentStackView addArrangedSubview:self.topStackView];
    [self.contentStackView addArrangedSubview:self.bottomStackView];
    
    UIView *placeholder = [UIView new];
    placeholder.translatesAutoresizingMaskIntoConstraints = NO;
    [placeholder setContentHuggingPriority:UILayoutPriorityDefaultLow
                                   forAxis:UILayoutConstraintAxisHorizontal];
    [self.bottomStackView addArrangedSubview:placeholder];
    [self.bottomStackView addArrangedSubview:self.btnReject];
    [self.bottomStackView addArrangedSubview:self.btnApprove];
    [self.bottomStackView addArrangedSubview:self.labStatus];

    [self updateCGColorUI];
    
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self updateCGColorUI];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:RCUserManagementImageCellLineLeading
                           trailing:-RCUserManagementImageCellLineTrailing];
    [NSLayoutConstraint activateConstraints:@[
           [self.contentStackView.leadingAnchor constraintEqualToAnchor:self.paddingContainerView.leadingAnchor constant:RCUserManagementPadding],
           [self.contentStackView.trailingAnchor constraintEqualToAnchor:self.paddingContainerView.trailingAnchor constant:-RCUserManagementPadding],
           [self.contentStackView.topAnchor constraintEqualToAnchor:self.paddingContainerView.topAnchor constant:RCUserManagementPadding],
           [self.contentStackView.bottomAnchor constraintEqualToAnchor:self.paddingContainerView.bottomAnchor constant:-RCUserManagementPadding],
           
           [self.portraitImageView.widthAnchor constraintEqualToConstant:RCGroupNotificationCellPortraitWidth],
           [self.portraitImageView.heightAnchor constraintEqualToConstant:RCGroupNotificationCellPortraitWidth],
           [self.btnReject.heightAnchor constraintEqualToConstant:34],
           [self.btnApprove.heightAnchor constraintEqualToConstant:34]
       ]];
}

- (void)showPortrait:(NSString *)url {
    if (url.length) {
        [self.portraitImageView setImageURL:[NSURL URLWithString:url]];
    } else {
        [self.portraitImageView setImage:RCDynamicImage(@"conversation-list_cell_group_portrait_img",@"default_group_portrait")];
    }
}

- (BOOL)shouldShowOperationView:(RCGroupApplicationInfo *)application {
    if (application.status == RCGroupApplicationStatusManagerRefused ||
        application.status == RCGroupApplicationStatusInviteeRefused ||
        application.status == RCGroupApplicationStatusJoined ||
        application.status == RCGroupApplicationStatusExpired) {
        return NO;
    }
    // 被邀请
    BOOL invited = application.status == RCGroupApplicationStatusInviteeUnHandled && application.direction == RCGroupApplicationDirectionInvitationReceived;
    if (invited) {
        return YES;
    }
    // 主动申请
    BOOL isApply = application.direction == RCGroupApplicationDirectionApplicationSent;
    if (isApply) {
        return NO;
    }
    // 主动邀请
    BOOL isInvite = application.direction == RCGroupApplicationDirectionInvitationSent;
    if(isInvite) {
        return NO;
    }
    
    if (application.status == RCGroupApplicationStatusManagerUnHandled) {
        return YES;
    }
    return NO;
}

- (void)updateWithViewModel:(RCGroupNotificationCellViewModel *)viewModel {
    self.viewModel = viewModel;
    BOOL isOperationView = [self shouldShowOperationView:viewModel.application];
    self.btnReject.hidden = !isOperationView;
    self.btnApprove.hidden = !isOperationView;
    self.labStatus.hidden = isOperationView;
    // 被邀请
    if (viewModel.application.direction == RCGroupApplicationDirectionInvitationReceived) {
        [self showPortrait:viewModel.application.inviterInfo.portraitUri];
    } else if (viewModel.application.direction == RCGroupApplicationDirectionApplicationReceived) {
        // 申请
        if (viewModel.application.inviterInfo) {//有邀请者
            [self showPortrait:viewModel.application.inviterInfo.portraitUri];
        } else {// 显示申请者
            [self showPortrait:viewModel.application.joinMemberInfo.portraitUri];
        }
      
    } else if (viewModel.application.direction == RCGroupApplicationDirectionApplicationSent) {
            // 显示申请者
        [self showPortrait:viewModel.application.joinMemberInfo.portraitUri];
    } else if (viewModel.application.direction == RCGroupApplicationDirectionInvitationSent) {
        // 显示邀请者
        [self showPortrait:viewModel.application.inviterInfo.portraitUri];
}
    self.labStatus.text = [self statusString:viewModel.application];
}

- (NSString *)statusString:(RCGroupApplicationInfo *)application {
    NSString *status= @"";
    switch (application.status) {
        case RCGroupApplicationStatusManagerUnHandled:
            status = RCLocalizedString(@"RCGroupApplicationStatusManagerUnHandled");
            break;
        case RCGroupApplicationStatusManagerRefused:
            status = RCLocalizedString(@"RCGroupApplicationStatusManagerRefused");
            break;
        case RCGroupApplicationStatusInviteeUnHandled:
            status = RCLocalizedString(@"RCGroupApplicationStatusInviteeUnHandled");
            break;
        case RCGroupApplicationStatusInviteeRefused:
            status = RCLocalizedString(@"RCGroupApplicationStatusInviteeRefused");
            break;
        case RCGroupApplicationStatusJoined:
            status = RCLocalizedString(@"RCGroupApplicationStatusJoined");
            break;
        case RCGroupApplicationStatusExpired:
            status = RCLocalizedString(@"RCGroupApplicationStatusExpired");
            break;
        default:
            self.labStatus.text = @"";
            break;
    }
    return status;
}

- (void)approveApplication {
    [self.viewModel approveApplication];
}

- (void)rejectApplication {
    [self.viewModel rejectApplication];
}
- (void)updateCGColorUI {
    UIColor *borderColor = RCDynamicColor(@"line_background_color", @"0xCFCFCF", @"0x3C3C3C");
    self.btnReject.layer.borderColor = borderColor.CGColor;
}

#pragma mark - GETTER

- (UIButton *)btnReject {
    if (!_btnReject) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:RCLocalizedString(@"FriendApplicationRefuse") forState:UIControlStateNormal];
        btn.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0x3C3C3C");
        [btn setTitleColor:RCDynamicColor(@"hint_color",@"0x000000", @"0xD3E1EE") forState:UIControlStateNormal];
        btn.layer.borderColor = RCDynamicColor(@"line_background_color", @"0x00000000", @"0x00000000").CGColor;
        btn.contentEdgeInsets = UIEdgeInsetsMake(7, 17, 7, 17);
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        btn.layer.borderWidth = 1;
        btn.layer.cornerRadius = 6;
        [btn addTarget:self
                action:@selector(rejectApplication)
      forControlEvents:UIControlEventTouchUpInside];
        [btn sizeToFit];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [btn setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [btn setContentHuggingPriority:UILayoutPriorityRequired
                               forAxis:UILayoutConstraintAxisHorizontal];
        _btnReject = btn;
    }
    return _btnReject;
}

- (UIButton *)btnApprove {
    if (!_btnApprove) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:RCLocalizedString(@"FriendApplicationAccept") forState:UIControlStateNormal];
        [btn setBackgroundColor:RCDynamicColor(@"primary_color",@"0x0099FF", @"0x1AA3FF")];
        [btn setTitleColor:RCDynamicColor(@"control_title_white_color",@"0xFFFFFF", @"0x0D0D0D")
                  forState:UIControlStateNormal];
        btn.contentEdgeInsets = UIEdgeInsetsMake(7, 17, 7, 17);
        btn.layer.cornerRadius = 6;
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        [btn addTarget:self
                action:@selector(approveApplication)
      forControlEvents:UIControlEventTouchUpInside];
        [btn sizeToFit];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [btn setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [btn setContentHuggingPriority:UILayoutPriorityRequired
                               forAxis:UILayoutConstraintAxisHorizontal];
        _btnApprove = btn;
    }
    return _btnApprove;
}

- (RCloudImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [RCloudImageView new];
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = RCGroupNotificationCellPortraitWidth/2;
        } else {
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.bounds = CGRectMake(0, 0, RCGroupNotificationCellPortraitWidth, RCGroupNotificationCellPortraitWidth);
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_group_portrait_img",@"default_group_portrait")];

    }
    return _portraitImageView;
}
 
- (UILabel *)labName {
    if (!_labName) {
        UILabel *lab = [UILabel new];
        lab.font = [UIFont systemFontOfSize:14];
        lab.textColor = RCDynamicColor(@"text_secondary_color", @"0x939393", @"0x666666");
        lab.accessibilityLabel = @"labName";
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab setContentHuggingPriority:UILayoutPriorityDefaultLow
                               forAxis:UILayoutConstraintAxisHorizontal];
        [lab setContentCompressionResistancePriority:UILayoutPriorityRequired
                                             forAxis:UILayoutConstraintAxisVertical];
        _labName = lab;
    }
    return _labName;
}

- (UILabel *)labTips {
    if (!_labTips) {
        UILabel *lab = [UILabel new];
        lab.lineBreakMode = NSLineBreakByTruncatingTail;
        lab.textColor = RCDynamicColor(@"text_primary_color", @"0xA0A5Ab", @"0x878787");
        lab.accessibilityLabel = @"labTips";
        lab.numberOfLines = 2;
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [lab setContentHuggingPriority:UILayoutPriorityDefaultLow
                               forAxis:UILayoutConstraintAxisHorizontal];
        [lab setContentCompressionResistancePriority:UILayoutPriorityRequired
                                             forAxis:UILayoutConstraintAxisVertical];
        _labTips = lab;
    }
    return _labTips;
}

- (UILabel *)labStatus {
    if (!_labStatus) {
        UILabel *lab = [UILabel new];
        lab.textColor = RCDynamicColor(@"text_secondary_color", @"0xA0A5Ab", @"0x878787");
        lab.font = [UIFont systemFontOfSize:12];
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [lab setContentHuggingPriority:UILayoutPriorityRequired
                               forAxis:UILayoutConstraintAxisHorizontal];
        _labStatus = lab;
    }
    return _labStatus;
}


- (UIStackView *)rightStackView {
    if (!_rightStackView) {
        _rightStackView = [[UIStackView alloc] init];
        _rightStackView.accessibilityLabel = @"rightStackView";
        _rightStackView.axis = UILayoutConstraintAxisVertical;
        _rightStackView.alignment = UIStackViewAlignmentFill;
        _rightStackView.distribution = UIStackViewDistributionFill;
        _rightStackView.spacing = 10;
        _rightStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _rightStackView;
}

- (UIStackView *)contentStackView {
    if (!_contentStackView) {
        _contentStackView = [[UIStackView alloc] init];
        _contentStackView.accessibilityLabel = @"contentStackView";
        _contentStackView.axis = UILayoutConstraintAxisVertical;
        _contentStackView.alignment = UIStackViewAlignmentFill;
        _contentStackView.distribution = UIStackViewDistributionFill;
        _contentStackView.spacing = 10;
        _contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _contentStackView;
}

- (UIStackView *)bottomStackView {
    if (!_bottomStackView) {
        _bottomStackView = [[UIStackView alloc] init];
        _bottomStackView.accessibilityLabel = @"bottomStackView";
        _bottomStackView.axis = UILayoutConstraintAxisHorizontal;
        _bottomStackView.alignment = UIStackViewAlignmentFill;
        _bottomStackView.distribution = UIStackViewDistributionFill;
        _bottomStackView.spacing = 10;
        _bottomStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _bottomStackView;
}


- (UIStackView *)topStackView {
    if (!_topStackView) {
        _topStackView = [[UIStackView alloc] init];
        _topStackView.axis = UILayoutConstraintAxisHorizontal;
        _topStackView.alignment = UIStackViewAlignmentCenter;
        _topStackView.distribution = UIStackViewDistributionFill;
        _topStackView.spacing = 12;
        _topStackView.translatesAutoresizingMaskIntoConstraints = NO;
        _topStackView.accessibilityLabel = @"topStackView";
    }
    return _topStackView;
}

@end
