//  代码地址: https://github.com/CoderMJLee/RCMJRefresh
//  代码地址:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  RCMJRefreshFooter.m
//  RCMJRefreshExample
//
//  Created by MJ Lee on 15/3/5.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//

#import "RCMJRefreshFooter.h"
#include "UIScrollView+RCMJRefresh.h"

@interface RCMJRefreshFooter ()

@end

@implementation RCMJRefreshFooter
#pragma mark - 构造方法
+ (instancetype)footerWithRefreshingBlock:(RCMJRefreshComponentRefreshingBlock)refreshingBlock {
    RCMJRefreshFooter *cmp = [[self alloc] init];
    cmp.refreshingBlock = refreshingBlock;
    return cmp;
}
+ (instancetype)footerWithRefreshingTarget:(id)target refreshingAction:(SEL)action {
    RCMJRefreshFooter *cmp = [[self alloc] init];
    [cmp setRefreshingTarget:target refreshingAction:action];
    return cmp;
}

#pragma mark - 重写父类的方法
- (void)prepare {
    [super prepare];

    // 设置自己的高度
    self.rcmj_h = RCMJRefreshFooterHeight;

    // 默认不会自动隐藏
    //    self.automaticallyHidden = NO;
}

#pragma mark - 公共方法
- (void)endRefreshingWithNoMoreData {
    RCMJRefreshDispatchAsyncOnMainQueue(self.state = RCMJRefreshStateNoMoreData;)
}

- (void)noticeNoMoreData {
    [self endRefreshingWithNoMoreData];
}

- (void)resetNoMoreData {
    RCMJRefreshDispatchAsyncOnMainQueue(self.state = RCMJRefreshStateIdle;)
}

- (void)setAutomaticallyHidden:(BOOL)automaticallyHidden {
    _automaticallyHidden = automaticallyHidden;
}
@end
