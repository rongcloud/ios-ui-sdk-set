//
//  RCInputKeyboardManager.m
//  RongIMKit
//
//  Created by RongCloud Code on 2024/12/01.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCInputKeyboardManager.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"

// 标准系统状态栏高度
#define SYS_STATUSBAR_HEIGHT 20
// 热门栏高度
#define HOTSPOT_STATUSBAR_HEIGHT 20
#define APP_STATUSBAR_HEIGHT (CGRectGetHeight([UIApplication sharedApplication].statusBarFrame))
#define IS_HOTSPOT_CONNECTED (APP_STATUSBAR_HEIGHT == (SYS_STATUSBAR_HEIGHT + HOTSPOT_STATUSBAR_HEIGHT) ? YES : NO)

@interface RCInputKeyboardManager ()

/// 当前键盘高度
@property (nonatomic, assign, readwrite) CGFloat currentKeyboardHeight;

/// 当前键盘frame
@property (nonatomic, assign, readwrite) CGRect currentKeyboardFrame;

/// 键盘是否可见
@property (nonatomic, assign, readwrite) BOOL isKeyboardVisible;

/// 是否正在监听
@property (nonatomic, assign) BOOL isMonitoring;

@end

@implementation RCInputKeyboardManager

#pragma mark - 生命周期

- (instancetype)init {
    self = [super init];
    if (self) {
        [self resetKeyboardState];
    }
    return self;
}

- (void)dealloc {
    [self stopMonitoring];
}

#pragma mark - 公共方法

- (void)startMonitoring {
    if (self.isMonitoring) {
        return;
    }
    
    // 注册键盘通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHideNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    self.isMonitoring = YES;
}

- (void)stopMonitoring {
    if (!self.isMonitoring) {
        return;
    }
    
    // 移除键盘通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    self.isMonitoring = NO;
    [self resetKeyboardState];
}

#pragma mark - 私有方法

- (void)resetKeyboardState {
    self.currentKeyboardHeight = 0;
    self.currentKeyboardFrame = CGRectZero;
    self.isKeyboardVisible = NO;
}

#pragma mark - 键盘通知处理

- (void)keyboardWillShowNotification:(NSNotification *)notification {
    // 询问代理是否应该处理键盘事件
    if ([self.delegate respondsToSelector:@selector(keyboardManagerShouldHandleKeyboardEvent:)]) {
        if (![self.delegate keyboardManagerShouldHandleKeyboardEvent:self]) {
            return;
        }
    }
    
    // 解析键盘通知参数
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardEndFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // 解析动画参数
    UIViewAnimationCurve animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    NSTimeInterval animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    // 更新键盘状态
    self.currentKeyboardFrame = keyboardEndFrame;
    self.currentKeyboardHeight = keyboardEndFrame.size.height;
    self.isKeyboardVisible = YES;
    
    // 通知代理
    if ([self.delegate respondsToSelector:@selector(keyboardManager:willShowWithHeight:frame:animationDuration:animationCurve:)]) {
        [self.delegate keyboardManager:self 
                    willShowWithHeight:self.currentKeyboardHeight 
                                 frame:self.currentKeyboardFrame
                     animationDuration:animationDuration 
                        animationCurve:animationCurve];
    }
}

- (void)keyboardWillHideNotification:(NSNotification *)notification {
    // 询问代理是否应该处理键盘事件
    if ([self.delegate respondsToSelector:@selector(keyboardManagerShouldHandleKeyboardEvent:)]) {
        if (![self.delegate keyboardManagerShouldHandleKeyboardEvent:self]) {
            return;
        }
    }
    
    // 更新键盘状态
    self.isKeyboardVisible = NO;
    // 注意：这里不重置frame和height，保持最后的值，因为在隐藏动画期间可能还需要这些值
    
    // 通知代理
    if ([self.delegate respondsToSelector:@selector(keyboardManagerWillHide:)]) {
        [self.delegate keyboardManagerWillHide:self];
    }
}

#pragma mark - 工具方法（类方法）

+ (CGFloat)screenBottomY {
    CGFloat gap = (RC_IOS_SYSTEM_VERSION_LESS_THAN(@"7.0")) ? 64 : 0;
    CGFloat safeAreaBottom = [RCKitUtility getWindowSafeAreaInsets].bottom;
    gap += safeAreaBottom;
    
    if (safeAreaBottom > 0) {
        // 刘海屏的热点栏不影响statusBar高度
        return [UIScreen mainScreen].bounds.size.height - gap;
    } else {
        return [self isHotspotConnected] ? [UIScreen mainScreen].bounds.size.height - gap - 20
                                         : [UIScreen mainScreen].bounds.size.height - gap;
    }
}

+ (BOOL)isHotspotConnected {
    return IS_HOTSPOT_CONNECTED;
}

- (CGFloat)calculateInputBarYWithInputBarHeight:(CGFloat)inputBarHeight {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    UIEdgeInsets safeAreaInsets = [RCKitUtility getWindowSafeAreaInsets];
    CGFloat screenBottomY = CGRectGetMaxY(screenBounds);
    
    CGFloat result;
    if (self.isKeyboardVisible && !CGRectIsEmpty(self.currentKeyboardFrame)) {
        // 使用内部维护的键盘frame，确保数据一致性
        result = CGRectGetMinY(self.currentKeyboardFrame) - inputBarHeight;
    } else {
        // 外接键盘或键盘隐藏：Y = 屏幕底部 - 安全区域底部 - 输入栏高度
        result = screenBottomY - safeAreaInsets.bottom - inputBarHeight;
    }
    return result;
}

@end 
