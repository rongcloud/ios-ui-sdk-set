//
//  RCMessageReadDetailTabView.m
//  RongIMKit
//
//  Created by Lang on 10/15/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCMessageReadDetailTabView.h"
#import "RCKitCommonDefine.h"

@interface RCMessageReadDetailTabView ()

@property (nonatomic, assign) NSInteger readCount;
@property (nonatomic, assign) NSInteger unreadCount;

@property (nonatomic, assign) RCMessageReadDetailTabType currentTab;

/// 指示器的 leading 约束，用于切换动画
@property (nonatomic, strong) NSLayoutConstraint *indicatorLeadingConstraint;

@end

@implementation RCMessageReadDetailTabView

- (void)setupView {
    // 已读按钮
    self.readButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.readButton.titleLabel.font = [UIFont systemFontOfSize:14];
    self.readButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.readButton addTarget:self action:@selector(readButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.readButton];
    
    // 未读按钮
    self.unreadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.unreadButton.titleLabel.font = [UIFont systemFontOfSize:14];
    self.unreadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.unreadButton addTarget:self action:@selector(unreadButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.unreadButton];
    
    // 分隔线
    self.separatorLine = [[UIView alloc] init];
    self.separatorLine.translatesAutoresizingMaskIntoConstraints = NO;    
    self.separatorLine.backgroundColor = RCDynamicColor(@"line_background_color", @"0x141414", @"0xFFFFFF1A");
    [self addSubview:self.separatorLine];
    
    // 指示器
    self.indicatorView = [[UIView alloc] init];
    self.indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    self.indicatorView.backgroundColor = self.selectedColor;
    [self addSubview:self.indicatorView];
    
    // 设置约束
    [self setupConstraints];
    
    // 更新标题
    [self updateButtonTitles];
    
    // 设置默认选中
    [self selectTabAtIndex:RCMessageReadDetailTabTypeRead];
}

/// 设置约束布局
- (void)setupConstraints {
    // 常量定义
    CGFloat horizontalMargin = 16;
    CGFloat lineHeight = 1;
    
    // 已读按钮约束
    [NSLayoutConstraint activateConstraints:@[
        [self.readButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:horizontalMargin],
        [self.readButton.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.readButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-lineHeight]
    ]];
    
    // 未读按钮约束
    [NSLayoutConstraint activateConstraints:@[
        [self.unreadButton.leadingAnchor constraintEqualToAnchor:self.readButton.trailingAnchor],
        [self.unreadButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-horizontalMargin],
        [self.unreadButton.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.unreadButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-lineHeight],
        [self.unreadButton.widthAnchor constraintEqualToAnchor:self.readButton.widthAnchor]
    ]];
    
    // 分隔线约束
    [NSLayoutConstraint activateConstraints:@[
        [self.separatorLine.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:horizontalMargin],
        [self.separatorLine.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-horizontalMargin],
        [self.separatorLine.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.separatorLine.heightAnchor constraintEqualToConstant:lineHeight]
    ]];
    
    // 指示器约束（初始位置在已读按钮下方）
    self.indicatorLeadingConstraint = [self.indicatorView.leadingAnchor constraintEqualToAnchor:self.readButton.leadingAnchor];
    [NSLayoutConstraint activateConstraints:@[
        self.indicatorLeadingConstraint,
        [self.indicatorView.widthAnchor constraintEqualToAnchor:self.readButton.widthAnchor],
        [self.indicatorView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.indicatorView.heightAnchor constraintEqualToConstant:lineHeight]
    ]];
}

/// 设置颜色
- (void)setupSelectedColor:(UIColor *)selectedColor unselectedColor:(UIColor *)unselectedColor {
    self.selectedColor = selectedColor;
    self.unselectedColor = unselectedColor;
    [self updateColorConfiguration];
}

- (void)setupReadCount:(NSInteger)readCount unreadCount:(NSInteger)unreadCount {
    self.readCount = readCount;
    self.unreadCount = unreadCount;
    [self updateButtonTitles];
}

- (void)updateButtonTitles {
    NSString *readTitle = [NSString stringWithFormat:@"%@(%ld)", RCLocalizedString(@"read"), (long)self.readCount];
    NSString *unreadTitle = [NSString stringWithFormat:@"%@(%ld)", RCLocalizedString(@"unread"), (long)self.unreadCount];
    
    [self.readButton setTitle:readTitle forState:UIControlStateNormal];
    [self.unreadButton setTitle:unreadTitle forState:UIControlStateNormal];
}

/// 更新按钮标题颜色
- (void)updateButtonTitleColors {
    if (self.currentTab == RCMessageReadDetailTabTypeRead) {
        [self.readButton setTitleColor:self.selectedColor forState:UIControlStateNormal];
        [self.unreadButton setTitleColor:self.unselectedColor forState:UIControlStateNormal];
    } else {
        [self.readButton setTitleColor:self.unselectedColor forState:UIControlStateNormal];
        [self.unreadButton setTitleColor:self.selectedColor forState:UIControlStateNormal];
    }
}

/// 更新颜色配置
- (void)updateColorConfiguration {
    self.indicatorView.backgroundColor = self.selectedColor;
    // 更新按钮颜色
    [self updateButtonTitleColors];
}

- (void)selectTabAtIndex:(RCMessageReadDetailTabType)tabType {
    // 如果 tab 没有改变，无需更新
    if (self.currentTab == tabType) {
        return;
    }
    self.currentTab = tabType;
    
    // 更新指示器位置约束
    [self updateIndicatorConstraint];
    
    // 执行动画
    [UIView animateWithDuration:0.25 animations:^{
        [self updateButtonTitleColors];
        [self layoutIfNeeded];
    }];
    
    if ([self.delegate respondsToSelector:@selector(tabView:didSelectTabAtIndex:)]) {
        [self.delegate tabView:self didSelectTabAtIndex:tabType];
    }
}

/// 更新指示器约束
- (void)updateIndicatorConstraint {
    // 停用旧约束
    self.indicatorLeadingConstraint.active = NO;
    
    // 根据当前选中的 tab 创建新约束
    if (self.currentTab == RCMessageReadDetailTabTypeRead) {
        self.indicatorLeadingConstraint = [self.indicatorView.leadingAnchor constraintEqualToAnchor:self.readButton.leadingAnchor];
    } else {
        self.indicatorLeadingConstraint = [self.indicatorView.leadingAnchor constraintEqualToAnchor:self.unreadButton.leadingAnchor];
    }
    
    // 激活新约束
    self.indicatorLeadingConstraint.active = YES;
}

#pragma mark - Actions

- (void)readButtonTapped {
    [self selectTabAtIndex:RCMessageReadDetailTabTypeRead];
    
}

- (void)unreadButtonTapped {
    [self selectTabAtIndex:RCMessageReadDetailTabTypeUnread];
}

@end

