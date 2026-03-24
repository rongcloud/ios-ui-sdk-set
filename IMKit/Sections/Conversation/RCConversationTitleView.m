//
//  RCConversationTitleView.m
//  RongIMKit
//
//  Created by Lang on 11/7/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationTitleView.h"
#import "RCOnlineStatusView.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

@interface RCConversationTitleView ()

/// 内容 StackView（水平布局）
@property (nonatomic, strong) UIStackView *contentStackView;

/// 在线状态视图
@property (nonatomic, strong, readwrite) RCOnlineStatusView *onlineStatusView;

/// 标题标签
@property (nonatomic, strong, readwrite) UILabel *titleLabel;

@end

@implementation RCConversationTitleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    [self addSubview:self.contentStackView];
    
    // 添加在线状态和标题到 StackView
    [self.contentStackView addArrangedSubview:self.onlineStatusView];
    [self.contentStackView addArrangedSubview:self.titleLabel];
    
    // 设置约束
    self.contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.contentStackView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor],
        [self.contentStackView.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor],
        [self.contentStackView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.contentStackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.contentStackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor]
    ]];
}

#pragma mark - Public Methods

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
    [self sizeToFit];
}

- (void)updateOnlineStatus:(BOOL)isOnline {
    self.onlineStatusView.online = isOnline;
}

- (CGSize)intrinsicContentSize {
    CGSize stackSize = [self.contentStackView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return stackSize;
}

- (void)sizeToFit {
    [super sizeToFit];
    CGSize size = [self intrinsicContentSize];
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, size.width, size.height);
}

#pragma mark - Getters

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
        _onlineStatusView.hidden = NO;
    }
    return _onlineStatusView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:17];
        _titleLabel.textColor = RCDynamicColor(@"primary_text_color", @"0x111f2c", @"0xffffff");
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

@end


