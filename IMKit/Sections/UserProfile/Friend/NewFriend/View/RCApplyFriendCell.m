//
//  RCFriendApplyCell.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCApplyFriendCell.h"
#import "RCloudImageView.h"
#import <CoreText/CoreText.h>
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

NSString  * const RCFriendApplyCellIdentifier = @"RCFriendApplyCellIdentifier";
NSInteger const RCFriendApplyCellMargin = 10;
NSInteger const RCFriendApplyCellPortraitWidth = 32;


@interface RCApplyFriendCell()<RCSizeCalculateLabelDelegate>

/// 底部容器 subtitle + btnExpan
@property (nonatomic, strong) UIStackView *bottomStackView;

/// 右侧容器 topStackView + bottomStackView
@property (nonatomic, strong) UIStackView *rightStackView;

/// 内容容器 portraitImageView + rightStackView
@property (nonatomic, strong) UIStackView *contentStackView;
@end

@implementation RCApplyFriendCell


- (void)setupView {
    [super setupView];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.paddingContainerView addSubview:self.contentStackView];
    
    [self.contentStackView addArrangedSubview:self.portraitImageView];
    [self.contentStackView addArrangedSubview:self.rightStackView];
    
    [self.rightStackView addArrangedSubview:self.topStackView];
    [self.topStackView addArrangedSubview:self.labName];
    [self.topStackView addArrangedSubview:self.labStatus];
    
    [self.rightStackView addArrangedSubview:self.bottomStackView];
    [self.bottomStackView addArrangedSubview:self.labRemark];
    
    UIView *viewHolder = [UIView new];
    viewHolder.translatesAutoresizingMaskIntoConstraints = NO;
    [viewHolder addSubview:self.btnExpand];
    [NSLayoutConstraint activateConstraints:@[
            [self.btnExpand.leadingAnchor constraintEqualToAnchor:viewHolder.leadingAnchor],
            [self.btnExpand.trailingAnchor constraintEqualToAnchor:viewHolder.trailingAnchor],
            [self.btnExpand.topAnchor constraintEqualToAnchor:viewHolder.topAnchor],
            [self.btnExpand.bottomAnchor constraintEqualToAnchor:viewHolder.bottomAnchor]
        ]];
    [self.bottomStackView addArrangedSubview:viewHolder];
}

- (void)setupConstraints {
    [super setupConstraints];
    [self updateLineViewConstraints:RCUserManagementImageCellLineLeading
                           trailing:-RCUserManagementImageCellLineTrailing];
    [NSLayoutConstraint activateConstraints:@[
           [self.contentStackView.leadingAnchor constraintEqualToAnchor:self.paddingContainerView.leadingAnchor constant:RCUserManagementPadding],
           [self.contentStackView.trailingAnchor constraintEqualToAnchor:self.paddingContainerView.trailingAnchor constant:-RCUserManagementPadding],
           [self.contentStackView.topAnchor constraintEqualToAnchor:self.paddingContainerView.topAnchor constant:RCFriendApplyCellMargin],
           [self.contentStackView.bottomAnchor constraintEqualToAnchor:self.paddingContainerView.bottomAnchor constant:-RCFriendApplyCellMargin],
           
           [self.portraitImageView.widthAnchor constraintEqualToConstant:RCFriendApplyCellPortraitWidth],
           [self.portraitImageView.heightAnchor constraintEqualToConstant:RCFriendApplyCellPortraitWidth],
           [self.topStackView.heightAnchor constraintEqualToConstant:34]
           
       ]];
}

- (void)showPortrait:(NSString *)url {
    if (url) {
        [self.portraitImageView setImageURL:[NSURL URLWithString:url]];
    } else {
        [self.portraitImageView setImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
    }
}

- (void)updateWithViewModel:(RCApplyFriendCellViewModel *)viewModel {
    self.viewModel = viewModel;
    self.labName.text = viewModel.application.name;
    [self showPortrait:viewModel.application.portraitUri];
    self.labRemark.text = self.viewModel.application.extra;
    switch (viewModel.application.applicationStatus) {
        case RCFriendApplicationStatusAccepted:
            self.labStatus.text = RCLocalizedString(@"FriendApplicationAccepted");
            break;
        case RCFriendApplicationStatusRefused:
            self.labStatus.text = RCLocalizedString(@"FriendApplicationRefused");
            break;
        case RCFriendApplicationStatusExpired:
            self.labStatus.text = RCLocalizedString(@"FriendApplicationExpired");
            break;
        default:
            self.labStatus.text = RCLocalizedString(@"FriendApplicationUnHandled");
            break;
    }
    
}

- (void)btnExpandClick:(id)sender {
    [self.viewModel expandRemark];
}

#pragma mark - RCSizeCalculateLabelDelegate

- (void)labelLayoutFinished:(UILabel *)label
                 natureSize:(CGSize)natureSize {
    BOOL ret = [self.viewModel shouldHideExpandButton:label.bounds.size
                                           natureSize:natureSize];
    self.btnExpand.hidden = ret;
}
#pragma mark - GETTER

- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [RCloudImageView new];
        if (RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_CYCLE &&
            RCKitConfigCenter.ui.globalMessageAvatarStyle == RC_USER_AVATAR_CYCLE) {
            _portraitImageView.layer.cornerRadius = RCFriendApplyCellPortraitWidth/2;
        } else {
            _portraitImageView.layer.cornerRadius = 5.f;
        }
        _portraitImageView.layer.masksToBounds = YES;
        [_portraitImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
        _portraitImageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _portraitImageView;
}

- (UILabel *)labName {
    if (!_labName) {
        UILabel *lab = [UILabel new];
        lab.font = [UIFont boldSystemFontOfSize:17];
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [lab setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        _labName = lab;
    }
    return _labName;
}

- (RCSizeCalculateLabel *)labRemark {
    if (!_labRemark) {
        RCSizeCalculateLabel *lab = [RCSizeCalculateLabel new];
        lab.delegate = self;
        lab.textColor = RCDynamicColor(@"text_secondary_color", @"0xA0A5Ab", @"0x878787");
        lab.font = [UIFont systemFontOfSize:14];
        lab.numberOfLines = 0;
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab setContentHuggingPriority:UILayoutPriorityDefaultLow
                               forAxis:UILayoutConstraintAxisHorizontal];

        _labRemark = lab;
    }
    return _labRemark;
}


- (UILabel *)labStatus {
    if (!_labStatus) {
        UILabel *lab = [UILabel new];
        lab.textColor = RCDynamicColor(@"text_primary_color", @"0xA0A5Ab", @"0x878787");
        lab.font = [UIFont systemFontOfSize:13];
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [lab setContentHuggingPriority:UILayoutPriorityRequired
                               forAxis:UILayoutConstraintAxisHorizontal];
        _labStatus = lab;
    }
    return _labStatus;
}

- (UIButton *)btnExpand {
    if (!_btnExpand) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:RCLocalizedString(@"FriendApplicationExpand")
             forState:UIControlStateNormal];
        btn.hidden = YES;
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        [btn addTarget:self
                action:@selector(btnExpandClick:)
      forControlEvents:UIControlEventTouchUpInside];
        [btn setTitleColor:RCDynamicColor(@"primary_color", @"0x0099ff", @"0x0099ff") forState:UIControlStateNormal];
        [btn sizeToFit];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [btn setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [btn setContentHuggingPriority:UILayoutPriorityRequired
                               forAxis:UILayoutConstraintAxisHorizontal];
        _btnExpand = btn;
    }
    return _btnExpand;
}

- (UIStackView *)topStackView {
    if (!_topStackView) {
        _topStackView = [[UIStackView alloc] init];
        _topStackView.axis = UILayoutConstraintAxisHorizontal;
        _topStackView.alignment = UIStackViewAlignmentFill;
        _topStackView.distribution = UIStackViewDistributionFill;
        _topStackView.spacing = 10;
        _topStackView.translatesAutoresizingMaskIntoConstraints = NO;
        _topStackView.accessibilityLabel = @"topStackView";
    }
    return _topStackView;
}

- (UIStackView *)bottomStackView {
    if (!_bottomStackView) {
        _bottomStackView = [[UIStackView alloc] init];
        _bottomStackView.accessibilityLabel = @"bottomStackView";
        _bottomStackView.axis = UILayoutConstraintAxisHorizontal;
        _bottomStackView.alignment = UIStackViewAlignmentCenter;
        _bottomStackView.distribution = UIStackViewDistributionFill;
        _bottomStackView.spacing = 10;
        _bottomStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _bottomStackView;
}

- (UIStackView *)rightStackView {
    if (!_rightStackView) {
        _rightStackView = [[UIStackView alloc] init];
        _rightStackView.accessibilityLabel = @"rightStackView";
        _rightStackView.axis = UILayoutConstraintAxisVertical;
        _rightStackView.alignment = UIStackViewAlignmentFill;
        _rightStackView.distribution = UIStackViewDistributionFill;
        _rightStackView.spacing = 3;
        _rightStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _rightStackView;
}

- (UIStackView *)contentStackView {
    if (!_contentStackView) {
        _contentStackView = [[UIStackView alloc] init];
        _contentStackView.accessibilityLabel = @"contentStackView";
        _contentStackView.axis = UILayoutConstraintAxisHorizontal;
        _contentStackView.alignment = UIStackViewAlignmentCenter;
        _contentStackView.distribution = UIStackViewDistributionFill;
        _contentStackView.spacing = 12;
        _contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _contentStackView;
}
@end
