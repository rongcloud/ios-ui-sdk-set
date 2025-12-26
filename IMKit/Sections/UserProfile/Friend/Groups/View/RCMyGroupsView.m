//
//  RCMyGroupsView.m
//  RongIMKit
//
//  Created by RobinCui on 2024/11/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCMyGroupsView.h"
#import "RCKitCommonDefine.h"
#import "RCMJRefreshAutoNormalFooter.h"
#import "RCNetworkIndicatorView.h"
#import "RCBaseTableView.h"

@interface RCMyGroupsView()
@property (nonatomic, strong) RCMJRefreshAutoNormalFooter *footer;
@property (nonatomic, strong) RCNetworkIndicatorView *networkIndicatorView;
/** 回调对象 */
@property (weak, nonatomic) id refreshingTarget;
/** 回调方法 */
@property (assign, nonatomic) SEL refreshingAction;

@end

@implementation RCMyGroupsView

- (void)setupView {
    [super setupView];
    self.tableView.rcmj_footer = self.footer;
}

- (void)addRefreshingTarget:(id)target withSelector:(SEL)selector {
    self.refreshingAction = selector;
    self.refreshingTarget = target;
}

- (void)loadMore {
    if (self.refreshingTarget) {
        if ([self.refreshingTarget respondsToSelector:self.refreshingAction]) {
            [self.refreshingTarget performSelector:self.refreshingAction];
        }
    }
}

- (void)stopRefreshing {
    [self.footer endRefreshing];
}

- (RCMJRefreshAutoNormalFooter *)footer {
    if(!_footer) {
        _footer = [RCMJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
        _footer.refreshingTitleHidden = YES;
    }
    return _footer;
}

- (RCNetworkIndicatorView *)networkIndicatorView {
    if (!_networkIndicatorView) {
        _networkIndicatorView = [[RCNetworkIndicatorView alloc]
            initWithText:RCLocalizedString(@"ConnectionIsNotReachable")];
        _networkIndicatorView.backgroundColor = RCDynamicColor(@"network_Indicator_view_bg_color", @"0xffdfdf", @"0x7D2C2C");
        [_networkIndicatorView setFrame:CGRectMake(0, 0, 48, 48)];
        _networkIndicatorView.hidden = YES;
    }
    return _networkIndicatorView;
}
@end
