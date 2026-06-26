//
//  RCMJRefreshAutoStateFooter.m
//  RCMJRefreshExample
//
//  Created by MJ Lee on 15/6/13.
//  Copyright © 2015年 小码哥. All rights reserved.
//

#import "RCMJRefreshAutoStateFooter.h"

@interface RCMJRefreshAutoStateFooter () {
    /** 显示刷新状态的label */
    __unsafe_unretained UILabel *_stateLabel;
}
/** 所有状态对应的文字 */
@property (strong, nonatomic) NSMutableDictionary *stateTitles;
@end

@implementation RCMJRefreshAutoStateFooter
#pragma mark - 懒加载
- (NSMutableDictionary *)stateTitles {
    if (!_stateTitles) {
        self.stateTitles = [NSMutableDictionary dictionary];
    }
    return _stateTitles;
}

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        [self addSubview:_stateLabel = [UILabel rcmj_label]];
    }
    return _stateLabel;
}

#pragma mark - 公共方法
- (void)setTitle:(NSString *)title forState:(RCMJRefreshState)state {
    if (title == nil)
        return;
    self.stateTitles[@(state)] = title;
    self.stateLabel.text = self.stateTitles[@(self.state)];
}

#pragma mark - 私有方法
- (void)stateLabelClick {
    if (self.state == RCMJRefreshStateIdle) {
        [self beginRefreshing];
    }
}

#pragma mark - 重写父类的方法
- (void)prepare {
    [super prepare];

    // 初始化间距
    self.labelLeftInset = RCMJRefreshLabelLeftInset;

    // 监听label
    self.stateLabel.userInteractionEnabled = YES;
    [self.stateLabel
        addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(stateLabelClick)]];
}

- (void)placeSubviews {
    [super placeSubviews];

    if (self.stateLabel.constraints.count)
        return;

    // 状态标签
    self.stateLabel.frame = self.bounds;
}

- (void)setState:(RCMJRefreshState)state {
    RCMJRefreshCheckState

        if (self.isRefreshingTitleHidden && state == RCMJRefreshStateRefreshing) {
        self.stateLabel.text = nil;
    }
    else {
        self.stateLabel.text = self.stateTitles[@(state)];
    }
}
@end
