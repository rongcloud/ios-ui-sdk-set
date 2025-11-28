//
//  RCGroupNotificationView.m
//  RongIMKit
//
//  Created by RobinCui on 2024/11/14.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupNotificationView.h"
#import "RCKitCommonDefine.h"
#import "RCMJRefreshAutoNormalFooter.h"
#import "RCNetworkIndicatorView.h"
#import "RCBaseTableView.h"

@interface RCGroupNotificationView()
@property (nonatomic, strong) RCMJRefreshAutoNormalFooter *footer;
@property (nonatomic, strong) RCNetworkIndicatorView *networkIndicatorView;
/** 回调对象 */
@property (weak, nonatomic) id refreshingTarget;
/** 回调方法 */
@property (assign, nonatomic) SEL refreshingAction;
@end

@implementation RCGroupNotificationView

- (void)addRefreshingTarget:(id)target withSelector:(SEL)selector {
    self.refreshingAction = selector;
    self.refreshingTarget = target;
}

- (void)setupView {
    [super setupView];
    [self addSubview:self.tableView];
    [self addSubview:self.labEmpty];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tableView.frame = self.bounds;
    self.labEmpty.center = CGPointMake(self.tableView.center.x, self.tableView.frame.size.height/3);;
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

- (UITableView *)tableView {
    if(!_tableView) {
        RCBaseTableView *tableView = [[RCBaseTableView alloc] initWithFrame:CGRectZero
                                                              style:UITableViewStyleGrouped];
        tableView.rcmj_footer = self.footer;
        tableView.separatorColor = RCDYCOLOR(0xE3E5E6, 0x272727);
        tableView.backgroundColor =  RCDYCOLOR(0xf5f6f9, 0x111111);
        tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.01)];
        tableView.sectionHeaderHeight = 0;
        if (@available(iOS 15.0, *)) {
            tableView.sectionHeaderTopPadding = 0;
        }
        //设置右侧索引
        tableView.sectionIndexBackgroundColor = [UIColor clearColor];
        tableView.sectionIndexColor = HEXCOLOR(0x6f6f6f);
        if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            tableView.separatorInset = UIEdgeInsetsMake(0, 64, 0, 0);
        }
        if ([tableView respondsToSelector:@selector(setLayoutMargins:)]) {
            tableView.layoutMargins = UIEdgeInsetsMake(0, 64, 0, 0);
        }
        
        _tableView = tableView;
    }
    return _tableView;
}

- (UILabel *)labEmpty {
    if (!_labEmpty) {
        UILabel *lab = [[UILabel alloc] init];
        lab.text = RCLocalizedString(@"NoData");
        lab.textColor = RCDYCOLOR(0x939393, 0x666666);
        lab.font = [UIFont systemFontOfSize:17];
        lab.textAlignment = NSTextAlignmentCenter;
        lab.hidden = YES;
        [lab sizeToFit];
        _labEmpty = lab;
    }
    return _labEmpty;
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
