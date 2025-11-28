//
//  RCFullScreenEditView.m
//  RongIMKit
//
//  Created by RongCloud Code on 2025/7/17.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCFullScreenEditView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCEmojiBoardView.h"

#define Height_EmojiBoardView 223.5f

@interface RCFullScreenEditView ()<RCEditInputBarControlDelegate, RCEditInputBarControlDataSource>

/// 背景遮罩视图
@property (nonatomic, strong) UIView *backgroundView;

/// 当前布局状态
@property (nonatomic, assign) KBottomBarStatus currentLayoutState;

/// 编辑容器底部约束
@property (nonatomic, strong) NSLayoutConstraint *editInputBarControlBottomConstraint;

/// 底部占位视图（用于键盘和表情面板）
@property (nonatomic, strong) UIView *bottomPlaceholderView;

/// 底部占位视图底部约束
@property (nonatomic, strong) NSLayoutConstraint *bottomPlaceholderConstraint;

/// 底部占位视图高度约束
@property (nonatomic, strong) NSLayoutConstraint *bottomPlaceholderHeightConstraint;

@end

@implementation RCFullScreenEditView

#pragma mark - 初始化

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.currentLayoutState = KBottomBarDefaultStatus;
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // 清理约束引用
    self.bottomPlaceholderHeightConstraint = nil;
}

#pragma mark - UI 设置

- (void)setupUI {
    // 设置背景 - 初始为透明，将在动画中渐变到半透明
    self.backgroundColor = [UIColor clearColor];
    
    self.backgroundView = [[UIView alloc] init];
    self.backgroundView.backgroundColor = RCDynamicColor(@"common_background_color", @"0xF5F6F9", @"0x1c1c1c");
    self.backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.backgroundView];
    
    // 创建底部占位视图（用于键盘和表情面板）
    self.bottomPlaceholderView = [[UIView alloc] init];
    self.bottomPlaceholderView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:self.bottomPlaceholderView];
}

- (void)setupConstraints {
    CGFloat safeAreaTop = [RCKitUtility getWindowSafeAreaInsets].top;
    CGFloat safeAreaBottom = [RCKitUtility getWindowSafeAreaInsets].bottom;
    CGFloat topOffset = safeAreaTop;
    
    // 背景视图约束
    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundView.topAnchor constraintEqualToAnchor:self.topAnchor constant:topOffset],
        [self.backgroundView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.backgroundView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.backgroundView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    
    // 底部占位视图约束
    self.bottomPlaceholderConstraint = [self.bottomPlaceholderView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-safeAreaBottom];
    self.bottomPlaceholderHeightConstraint = [self.bottomPlaceholderView.heightAnchor constraintEqualToConstant:0];
    [NSLayoutConstraint activateConstraints:@[
        [self.bottomPlaceholderView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.bottomPlaceholderView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        self.bottomPlaceholderConstraint,
        self.bottomPlaceholderHeightConstraint,
    ]];
    
    // 设置编辑容器约束
    [self setupEditInputContainerConstraints];
}

- (void)setupEditInputContainerConstraints {
    // 确保使用约束布局
    self.editInputBarControl.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 先添加到背景视图
    [self.backgroundView addSubview:self.editInputBarControl];
    
    self.editInputBarControlBottomConstraint = [self.editInputBarControl.bottomAnchor 
                                               constraintEqualToAnchor:self.bottomPlaceholderView.topAnchor];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.editInputBarControl.topAnchor constraintEqualToAnchor:self.backgroundView.topAnchor],
        [self.editInputBarControl.leadingAnchor constraintEqualToAnchor:self.backgroundView.leadingAnchor],
        [self.editInputBarControl.trailingAnchor constraintEqualToAnchor:self.backgroundView.trailingAnchor],
        self.editInputBarControlBottomConstraint
    ]];
}

#pragma mark - 显示/隐藏方法

- (void)showWithConfig:(RCEditInputBarConfig *)config animation:(BOOL)animated {
    [self.editInputBarControl showWithConfig:config];
    if (animated) {
        // 初始状态：位置在底部，背景透明
        self.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(self.bounds));
        self.backgroundColor = [UIColor clearColor];
        
        [UIView animateWithDuration:0.3 animations:^{
            // 内容滑入，背景渐变到半透明
            self.transform = CGAffineTransformIdentity;
            self.backgroundColor = RCMASKCOLOR(0x000000, 0.5);
        } completion:^(BOOL finished) {
            [self.editInputBarControl restoreFocus];
        }];
    } else {
        // 非动画模式直接设置最终状态
        self.backgroundColor = RCMASKCOLOR(0x000000, 0.5);
        [self.editInputBarControl restoreFocus];
    }
}

- (void)hideWithAnimation:(BOOL)animated completion:(void(^_Nullable)(void))completion {
    // 确保输入框失去焦点
    [self.editInputBarControl.editInputContainer resignInputViewFirstResponder];
    
    self.backgroundColor = [UIColor clearColor];
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            // 内容滑出，背景渐变到透明
            self.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(self.bounds));
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
            if (completion) completion();
        }];
    } else {
        [self removeFromSuperview];
        if (completion) completion();
    }
}

#pragma mark - RCEditInputBarControlDelegate

- (void)editInputBarControlCollapseFromFullScreenEdit:(RCEditInputBarControl *)editInputBarControl {
    if ([self.delegate respondsToSelector:@selector(fullScreenEditViewCollapse:)]) {
        [self.delegate fullScreenEditViewCollapse:self];
    }
}

- (void)editInputBarControl:(RCEditInputBarControl *)editInputBarControl didConfirmWithText:(NSString *)text {
    if ([self.delegate respondsToSelector:@selector(fullScreenEditView:didConfirmWithText:)]) {
        [self.delegate fullScreenEditView:self didConfirmWithText:text];
    }
}

- (void)editInputBarControlDidCancel:(RCEditInputBarControl *)editInputBarControl {
    if ([self.delegate respondsToSelector:@selector(fullScreenEditViewCancel:)]) {
        [self.delegate fullScreenEditViewCancel:self];
    }
}

- (void)editInputBarControl:(RCEditInputBarControl *)editInputBarControl
           showUserSelector:(void (^)(RCUserInfo *selectedUser))selectedBlock
                     cancel:(void (^)(void))cancelBlock {
    if ([self.delegate respondsToSelector:@selector(fullScreenEditView:showUserSelector:cancel:)]) {
        [self.delegate fullScreenEditView:self showUserSelector:selectedBlock cancel:cancelBlock];
    }
}

- (void)editInputBarControl:(RCEditInputBarControl *)editInputBarControl shouldChangeFrame:(CGRect)frame {
    // 处理 bottomPlaceholderHeightConstraint 的约束
    self.bottomPlaceholderHeightConstraint.constant = frame.size.height;
    [self layoutIfNeeded];
}

#pragma mark - Getter Methods

- (void)setIsMentionedEnabled:(BOOL)isMentionedEnabled {
    _isMentionedEnabled = isMentionedEnabled;
    self.editInputBarControl.isMentionedEnabled = isMentionedEnabled;
}

- (RCEditInputBarControl *)editInputBarControl {
    if (!_editInputBarControl) {
        _editInputBarControl = [[RCEditInputBarControl alloc] initWithIsFullScreen:YES];
        _editInputBarControl.conversationType = self.conversationType;
        _editInputBarControl.targetId = self.targetId;
        _editInputBarControl.delegate = self;
        _editInputBarControl.dataSource = self;
        _editInputBarControl.bottomPanelsContainerView = self.bottomPlaceholderView;
    }
    return _editInputBarControl;
}


@end
