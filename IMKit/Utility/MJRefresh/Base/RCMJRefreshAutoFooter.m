//
//  RCMJRefreshAutoFooter.m
//  RCMJRefreshExample
//
//  Created by MJ Lee on 15/4/24.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//

#import "RCMJRefreshAutoFooter.h"

@interface RCMJRefreshAutoFooter ()
/** 一个新的拖拽 */
@property (assign, nonatomic, getter=isOneNewPan) BOOL oneNewPan;
@end

@implementation RCMJRefreshAutoFooter

#pragma mark - 初始化
- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];

    if (newSuperview) { // 新的父控件
        if (self.hidden == NO) {
            self.scrollView.rcmj_insetB += self.rcmj_h;
        }

        // 设置位置
        self.rcmj_y = _scrollView.rcmj_contentH;
    } else { // 被移除了
        if (self.hidden == NO) {
            self.scrollView.rcmj_insetB -= self.rcmj_h;
        }
    }
}

#pragma mark - 过期方法
- (void)setAppearencePercentTriggerAutoRefresh:(CGFloat)appearencePercentTriggerAutoRefresh {
    self.triggerAutomaticallyRefreshPercent = appearencePercentTriggerAutoRefresh;
}

- (CGFloat)appearencePercentTriggerAutoRefresh {
    return self.triggerAutomaticallyRefreshPercent;
}

#pragma mark - 实现父类的方法
- (void)prepare {
    [super prepare];

    // 默认底部控件100%出现时才会自动刷新
    self.triggerAutomaticallyRefreshPercent = 1.0;

    // 设置为默认状态
    self.automaticallyRefresh = YES;

    // 默认是当offset达到条件就发送请求（可连续）
    self.onlyRefreshPerDrag = YES;
}

- (void)scrollViewContentSizeDidChange:(NSDictionary *)change {
    [super scrollViewContentSizeDidChange:change];

    // 设置位置
    self.rcmj_y = self.scrollView.rcmj_contentH + self.ignoredScrollViewContentInsetBottom;
}

- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change {
    [super scrollViewContentOffsetDidChange:change];

    if (self.state != RCMJRefreshStateIdle || !self.automaticallyRefresh || self.rcmj_y == 0)
        return;

    if (_scrollView.rcmj_insetT + _scrollView.rcmj_contentH > _scrollView.rcmj_h) { // 内容超过一个屏幕
        // 这里的_scrollView.mj_contentH替换掉self.mj_y更为合理
        if (_scrollView.rcmj_offsetY >= _scrollView.rcmj_contentH - _scrollView.rcmj_h +
                                          self.rcmj_h * self.triggerAutomaticallyRefreshPercent + _scrollView.rcmj_insetB -
                                          self.rcmj_h) {
            // 防止手松开时连续调用
            CGPoint old = [change[@"old"] CGPointValue];
            CGPoint new = [ change[@"new"] CGPointValue ];
            if (new.y <= old.y)
                return;

            // 当底部刷新控件完全出现时，才刷新
            [self beginRefreshing];
        }
    }
}

- (void)scrollViewPanStateDidChange:(NSDictionary *)change {
    [super scrollViewPanStateDidChange:change];

    if (self.state != RCMJRefreshStateIdle)
        return;

    UIGestureRecognizerState panState = _scrollView.panGestureRecognizer.state;
    if (panState == UIGestureRecognizerStateEnded) {                               // 手松开
        if (_scrollView.rcmj_insetT + _scrollView.rcmj_contentH <= _scrollView.rcmj_h) { // 不够一个屏幕
            if (_scrollView.rcmj_offsetY >= -_scrollView.rcmj_insetT) {                // 向上拽
                [self beginRefreshing];
            }
        } else { // 超出一个屏幕
            if (_scrollView.rcmj_offsetY >= _scrollView.rcmj_contentH + _scrollView.rcmj_insetB - _scrollView.rcmj_h) {
                [self beginRefreshing];
            }
        }
    } else if (panState == UIGestureRecognizerStateBegan) {
        self.oneNewPan = YES;
    }
}

- (void)beginRefreshing {
    if (!self.isOneNewPan && self.isOnlyRefreshPerDrag)
        return;

    [super beginRefreshing];

    self.oneNewPan = NO;
}

- (void)setState:(RCMJRefreshState)state {
    RCMJRefreshCheckState

        if (state == RCMJRefreshStateRefreshing) {
        [self executeRefreshingCallback];
    }
    else if (state == RCMJRefreshStateNoMoreData || state == RCMJRefreshStateIdle) {
        if (RCMJRefreshStateRefreshing == oldState) {
            if (self.endRefreshingCompletionBlock) {
                self.endRefreshingCompletionBlock();
            }
        }
    }
}

- (void)setHidden:(BOOL)hidden {
    BOOL lastHidden = self.isHidden;

    [super setHidden:hidden];

    if (!lastHidden && hidden) {
        self.state = RCMJRefreshStateIdle;

        self.scrollView.rcmj_insetB -= self.rcmj_h;
    } else if (lastHidden && !hidden) {
        self.scrollView.rcmj_insetB += self.rcmj_h;

        // 设置位置
        self.rcmj_y = _scrollView.rcmj_contentH;
    }
}
@end
