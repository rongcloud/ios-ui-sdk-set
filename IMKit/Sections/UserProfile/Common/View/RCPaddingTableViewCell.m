//
//  RCPaddingTableViewCell.m
//  RongIMKit
//
//  Created by RobinCui on 2025/11/11.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCPaddingTableViewCell.h"
#import "RCKitCommonDefine.h"

NSInteger const RCUserManagementPadding = 16;
NSInteger const RCUserManagementImageCellLineLeading = 60;
NSInteger const RCUserManagementImageCellLineTrailing = 10;

@interface RCPaddingTableViewCell()
@property (nonatomic, strong) NSLayoutConstraint *paddingLeadingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *paddingTrailingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *lineLeadingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *lineTrailingConstraint;
@end
@implementation RCPaddingTableViewCell

- (void)setupView {
    [super setupView];
    // cell 背景透明，显示 tableView 的背景色
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor =  [UIColor clearColor];
    [self.contentView addSubview:self.paddingContainerView];
    [self.paddingContainerView addSubview:self.lineView];
}

- (void)setupConstraints {
    [super setupConstraints];
    
   self.paddingLeadingConstraint = [self.paddingContainerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:RCUserManagementPadding];
   self.paddingTrailingConstraint = [self.paddingContainerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-RCUserManagementPadding];
    // contentView 缩小，左右各留 16px 透明间隙
    [NSLayoutConstraint activateConstraints:@[
        self.paddingLeadingConstraint,
        self.paddingTrailingConstraint,
        [self.paddingContainerView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.paddingContainerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
    ]];
}

- (void)updatePaddingContainer:(NSInteger)leading
                      trailing:(NSInteger)trailing {
    NSInteger leadingConstant = self.paddingLeadingConstraint.constant;
    NSInteger trailingConstant = self.paddingTrailingConstraint.constant;
    if (leadingConstant == leading && trailingConstant == trailing) {
        return;
    }
    NSInteger trailingDiff = trailingConstant - trailing;
    NSInteger leadingDiff = leadingConstant - leading;

    self.paddingLeadingConstraint.constant = leading;
    self.paddingTrailingConstraint.constant = trailing;
    if (self.lineLeadingConstraint) {
        self.lineLeadingConstraint.constant = self.lineLeadingConstraint.constant+leadingDiff;
    }
    if (self.lineTrailingConstraint) {
        self.lineTrailingConstraint.constant = self.lineTrailingConstraint.constant+trailingDiff;
    }
}


- (void)updateLineViewConstraints:(NSInteger)leading trailing:(NSInteger)trailing {
    if (self.lineLeadingConstraint && self.lineTrailingConstraint) {
        self.lineLeadingConstraint.constant = leading;
        self.lineTrailingConstraint.constant = trailing;
        return;
    } else {
        self.lineLeadingConstraint.active = NO;
        self.lineTrailingConstraint.active = NO;
    }
    self.lineLeadingConstraint = [self.lineView.leadingAnchor constraintEqualToAnchor:self.paddingContainerView.leadingAnchor constant:leading];
    
    self.lineTrailingConstraint = [self.lineView.trailingAnchor constraintEqualToAnchor:self.paddingContainerView.trailingAnchor constant:trailing];
    
    [NSLayoutConstraint activateConstraints:@[
        self.lineLeadingConstraint,
        self.lineTrailingConstraint,
        [self.lineView.heightAnchor constraintEqualToConstant:1],
        [self.lineView.bottomAnchor constraintEqualToAnchor:self.paddingContainerView.bottomAnchor]
    ]];
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [UIView new];
        _lineView.backgroundColor = RCDynamicColor(@"line_background_color", @"0xE3E5E6", @"0x272727");
        _lineView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _lineView;
}

- (UIView *)paddingContainerView {
    if (!_paddingContainerView) {
        _paddingContainerView = [UIView new];
        _paddingContainerView.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0x1c1c1e");
        _paddingContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _paddingContainerView;
}

- (void)setHideSeparatorLine:(BOOL)hideSeparatorLine {
    _hideSeparatorLine = hideSeparatorLine;
    self.lineView.hidden = hideSeparatorLine;
}
@end
