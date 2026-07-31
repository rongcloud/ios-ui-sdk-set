//
//  RCFriendApplyOperationCell.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCApplyFriendOperationCell.h"
#import "RCKitCommonDefine.h"
#import "RCloudImageView.h"

NSString  * const RCFriendApplyOperationCellIdentifier = @"RCFriendApplyOperationCellIdentifier";
NSInteger const RCApplyFriendOperationCellBtnMinWidth = 45;
NSInteger const RCApplyFriendOperationCellBtnSpace = 10;
@implementation RCApplyFriendOperationCell

- (void)setupView {
    [super setupView];
    self.labStatus.hidden = YES;
    [self.topStackView addArrangedSubview:self.btnReject];
    [self.topStackView addArrangedSubview:self.btnApprove];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self updateCGColorUI];
}

#pragma mark -- private

- (void)updateCGColorUI {
    UIColor *borderColor = RCDynamicColor(@"line_background_color", @"0xCFCFCF", @"0x3C3C3C");
    self.btnReject.layer.borderColor = borderColor.CGColor;
}

#pragma mark -- getter

- (UIButton *)btnReject {
    if (!_btnReject) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:RCLocalizedString(@"FriendApplicationRefuse") forState:UIControlStateNormal];
        btn.backgroundColor =
        RCDynamicColor(@"common_background_color", @"0xffffff", @"0x3C3C3C");
        [btn setTitleColor:RCDynamicColor(@"hint_color",@"0x000000", @"0xD3E1EE") forState:UIControlStateNormal];
        UIColor *borderColor = RCDynamicColor(@"line_background_color", @"0x0000001A", @"0xFFFFFF1A");
        btn.layer.borderColor = borderColor.CGColor;
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        btn.layer.borderWidth = 1;
        btn.layer.cornerRadius = 4;
        btn.contentEdgeInsets = UIEdgeInsetsMake(5, 17, 5, 17);
        [btn sizeToFit];

        [btn addTarget:self
                action:@selector(rejectApplication)
      forControlEvents:UIControlEventTouchUpInside];
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
        [btn setTitleColor:RCDynamicColor(@"control_title_white_color",@"0xFFFFFF", @"0x0D0D0D") forState:UIControlStateNormal];
        btn.layer.cornerRadius = 4;
        btn.contentEdgeInsets = UIEdgeInsetsMake(5, 17, 5, 17);
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        [btn sizeToFit];
        [btn addTarget:self
                action:@selector(approveApplication)
      forControlEvents:UIControlEventTouchUpInside];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [btn setContentCompressionResistancePriority:UILayoutPriorityRequired
                                             forAxis:UILayoutConstraintAxisHorizontal];
        [btn setContentHuggingPriority:UILayoutPriorityRequired
                               forAxis:UILayoutConstraintAxisHorizontal];
        _btnApprove = btn;
    }
    return _btnApprove;
}

- (void)approveApplication {
    [self.viewModel approveApplication];
}

- (void)rejectApplication {
    [self.viewModel rejectApplication];
}
@end
