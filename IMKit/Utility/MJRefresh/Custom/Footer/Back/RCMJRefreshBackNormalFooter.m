//
//  RCMJRefreshBackNormalFooter.m
//  RCMJRefreshExample
//
//  Created by MJ Lee on 15/4/24.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//

#import "RCMJRefreshBackNormalFooter.h"

@interface RCMJRefreshBackNormalFooter () {
    __unsafe_unretained UIImageView *_arrowView;
}
@property (weak, nonatomic) UIActivityIndicatorView *loadingView;
@end

@implementation RCMJRefreshBackNormalFooter
#pragma mark - 懒加载子控件
- (UIImageView *)arrowView {
    if (!_arrowView) {
        UIImageView *arrowView = [[UIImageView alloc] initWithImage:nil];
        [self addSubview:_arrowView = arrowView];
    }
    return _arrowView;
}

- (UIActivityIndicatorView *)loadingView {
    if (!_loadingView) {
        UIActivityIndicatorView *loadingView =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:self.activityIndicatorViewStyle];
        loadingView.hidesWhenStopped = YES;
        [self addSubview:_loadingView = loadingView];
    }
    return _loadingView;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)activityIndicatorViewStyle {
    _activityIndicatorViewStyle = activityIndicatorViewStyle;

    self.loadingView = nil;
    [self setNeedsLayout];
}
#pragma mark - 重写父类的方法
- (void)prepare {
    [super prepare];

    self.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
}

- (void)placeSubviews {
    [super placeSubviews];

    // 箭头的中心点
    CGFloat arrowCenterX = self.rcmj_w * 0.5;
    if (!self.stateLabel.hidden) {
        arrowCenterX -= self.labelLeftInset + self.stateLabel.rcmj_textWidth * 0.5;
    }
    CGFloat arrowCenterY = self.rcmj_h * 0.5;
    CGPoint arrowCenter = CGPointMake(arrowCenterX, arrowCenterY);

    // 箭头
    if (self.arrowView.constraints.count == 0) {
        self.arrowView.rcmj_size = self.arrowView.image.size;
        self.arrowView.center = arrowCenter;
    }

    // 圈圈
    if (self.loadingView.constraints.count == 0) {
        self.loadingView.center = arrowCenter;
    }

    self.arrowView.tintColor = self.stateLabel.textColor;
}

- (void)setState:(RCMJRefreshState)state {
    RCMJRefreshCheckState

        // 根据状态做事情
        if (state == RCMJRefreshStateIdle) {
        if (oldState == RCMJRefreshStateRefreshing) {
            self.arrowView.transform = CGAffineTransformMakeRotation(0.000001 - M_PI);
            [UIView animateWithDuration:RCMJRefreshSlowAnimationDuration
                animations:^{
                    self.loadingView.alpha = 0.0;
                }
                completion:^(BOOL finished) {
                    // 防止动画结束后，状态已经不是RCMJRefreshStateIdle
                    if (state != RCMJRefreshStateIdle)
                        return;

                    self.loadingView.alpha = 1.0;
                    [self.loadingView stopAnimating];

                    self.arrowView.hidden = NO;
                }];
        } else {
            self.arrowView.hidden = NO;
            [self.loadingView stopAnimating];
            [UIView animateWithDuration:RCMJRefreshFastAnimationDuration
                             animations:^{
                                 self.arrowView.transform = CGAffineTransformMakeRotation(0.000001 - M_PI);
                             }];
        }
    }
    else if (state == RCMJRefreshStatePulling) {
        self.arrowView.hidden = NO;
        [self.loadingView stopAnimating];
        [UIView animateWithDuration:RCMJRefreshFastAnimationDuration
                         animations:^{
                             self.arrowView.transform = CGAffineTransformIdentity;
                         }];
    }
    else if (state == RCMJRefreshStateRefreshing) {
        self.arrowView.hidden = YES;
        [self.loadingView startAnimating];
    }
    else if (state == RCMJRefreshStateNoMoreData) {
        self.arrowView.hidden = YES;
        [self.loadingView stopAnimating];
    }
}

@end
