//
//  RCMessageReadDetailView.m
//  RongIMKit
//
//  Created by Lang on 10/15/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCMessageReadDetailView.h"
#import "RCMessageReadDetailTabView.h"
#import "RCKitConfig.h"
#import "RCKitCommonDefine.h"
#import "RCMJRefresh.h"
#import "RCloudImageView.h"

@interface RCMessageReadDetailView () <RCReadReceiptDetailTabViewDelegate>

/// 已读、未读切换按钮视图
@property (nonatomic, strong, readwrite) RCMessageReadDetailTabView *tabView;

/// 列表容器视图
@property (nonatomic, strong) UIView *tableContainerView;

/// 已读列表视图
@property (nonatomic, strong, readwrite) UITableView *readTableView;

/// 未读列表视图
@property (nonatomic, strong, readwrite) UITableView *unreadTableView;

/// 空视图容器
@property (nonatomic, strong) UIView *emptyContainerView;

/// 空视图图片
@property (nonatomic, strong) UIImageView *emptyImageView;

/// 空视图文字
@property (nonatomic, strong) UILabel *emptyLabel;

/// Tab 高度
@property (nonatomic, assign) CGFloat tabHeight;

@end

@implementation RCMessageReadDetailView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame tabHeight:(CGFloat)tabHeight {
    self = [super initWithFrame:frame];
    if (self) {
        _tabHeight = tabHeight;
        [self setupView];
    }
    return self;
}

#pragma mark - UI Setup

- (void)setupView {
    self.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xf5f6f9", @"0x1c1c1c");
    
    // 1. Tab 切换视图
    self.tabView = [[RCMessageReadDetailTabView alloc] initWithFrame:CGRectZero];
    [self.tabView setupSelectedColor:RCDynamicColor(@"primary_color", @"0x0047FF", @"0x0047FF")
                   unselectedColor:RCDynamicColor(@"text_secondary_color", @"0x020814", @"0xFFFFFF")];
    self.tabView.delegate = self;
    self.tabView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.tabView];
    
    // 2. 列表容器
    self.tableContainerView = [[UIView alloc] init];
    self.tableContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.tableContainerView];
    
    // 3. 已读列表
    self.readTableView = [self createTableView];
    [self.tableContainerView addSubview:self.readTableView];
    
    // 4. 未读列表
    self.unreadTableView = [self createTableView];
    self.unreadTableView.hidden = YES;
    [self.tableContainerView addSubview:self.unreadTableView];
    
    // 5. 空状态视图
    [self.tableContainerView addSubview:self.emptyContainerView];
    
    [self setupConstraints];
}

- (UITableView *)createTableView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.backgroundColor = self.backgroundColor;
    tableView.rowHeight = 54;
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (@available(iOS 11.0, *)) {
        tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    }
    
    CGFloat leftOffset = [RCKitConfig defaultConfig].ui.globalConversationPortraitSize.width + 12;
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        tableView.separatorInset = UIEdgeInsetsMake(0, leftOffset, 0, 0);
    }
    
    __weak typeof(self) weakSelf = self;
    RCMJRefreshAutoNormalFooter *footer = [RCMJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(readReceiptUserListView:needLoadMoreForTabType:)]) {
            // 根据当前显示的 tableView 判断是哪个 tab
            RCMessageReadDetailTabType tabType = tableView == strongSelf.readTableView 
                ? RCMessageReadDetailTabTypeRead 
                : RCMessageReadDetailTabTypeUnread;
            [strongSelf.delegate readReceiptUserListView:strongSelf needLoadMoreForTabType:tabType];
        }
    }];
    footer.refreshingTitleHidden = YES;
    tableView.rcmj_footer = footer;
    
    return tableView;
}

- (void)setupConstraints {
    // Tab 视图约束
    [NSLayoutConstraint activateConstraints:@[
        [self.tabView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.tabView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.tabView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.tabView.heightAnchor constraintEqualToConstant:self.tabHeight]
    ]];
    
    // 列表容器约束
    [NSLayoutConstraint activateConstraints:@[
        [self.tableContainerView.topAnchor constraintEqualToAnchor:self.tabView.bottomAnchor],
        [self.tableContainerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.tableContainerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.tableContainerView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    
    // TableView 约束
    [self setupTableViewConstraints:self.readTableView];
    [self setupTableViewConstraints:self.unreadTableView];
    
    // Empty view 约束
    self.emptyContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyContainerView.centerXAnchor constraintEqualToAnchor:self.tableContainerView.centerXAnchor],
        [self.emptyContainerView.centerYAnchor constraintEqualToAnchor:self.tableContainerView.centerYAnchor],
        [self.emptyContainerView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.tableContainerView.leadingAnchor constant:20],
        [self.emptyContainerView.trailingAnchor constraintLessThanOrEqualToAnchor:self.tableContainerView.trailingAnchor constant:-20]
    ]];
}

- (void)setupTableViewConstraints:(UITableView *)tableView {
    [NSLayoutConstraint activateConstraints:@[
        [tableView.topAnchor constraintEqualToAnchor:self.tableContainerView.topAnchor],
        [tableView.leadingAnchor constraintEqualToAnchor:self.tableContainerView.leadingAnchor],
        [tableView.trailingAnchor constraintEqualToAnchor:self.tableContainerView.trailingAnchor],
        [tableView.bottomAnchor constraintEqualToAnchor:self.tableContainerView.bottomAnchor]
    ]];
}

#pragma mark - Public Methods

- (void)setupReadCount:(NSInteger)readCount unreadCount:(NSInteger)unreadCount {
    [self.tabView setupReadCount:readCount unreadCount:unreadCount];
}

- (void)switchToTabType:(RCMessageReadDetailTabType)tabType isEmpty:(BOOL)isEmpty {
    BOOL isReadTab = (tabType == RCMessageReadDetailTabTypeRead);
    
    // 切换 tableView 显示状态
    self.readTableView.hidden = !isReadTab;
    self.unreadTableView.hidden = isReadTab;
    
    // 更新空状态视图
    self.emptyContainerView.hidden = !isEmpty;
}

- (void)updateEmptyViewText:(NSString *)text {
    self.emptyLabel.text = text;
}

- (void)reloadDataForTabType:(RCMessageReadDetailTabType)tabType hasMoreData:(BOOL)hasMoreData {
    // 获取对应的 tableView
    UITableView *tableView = tabType == RCMessageReadDetailTabTypeRead
        ? self.readTableView
        : self.unreadTableView;
    
    // 刷新列表数据
    [tableView reloadData];
    
    // 结束下拉刷新动画
    if (hasMoreData) {
        [tableView.rcmj_footer endRefreshing];
    } else {
        [tableView.rcmj_footer endRefreshingWithNoMoreData];
    }
}

- (RCMessageReadDetailTabType)tabTypeForTableView:(UITableView *)tableView {
    if (tableView == self.readTableView) {
        return RCMessageReadDetailTabTypeRead;
    }
    return RCMessageReadDetailTabTypeUnread;
}

#pragma mark - RCReadReceiptDetailTabViewDelegate

- (void)tabView:(RCMessageReadDetailTabView *)tabView didSelectTabAtIndex:(RCMessageReadDetailTabType)tabType {
    if ([self.delegate respondsToSelector:@selector(readReceiptUserListView:didSwitchToTab:)]) {
        [self.delegate readReceiptUserListView:self didSwitchToTab:tabType];
    }
}

#pragma mark - Getter

- (UIView *)emptyContainerView {
    if (!_emptyContainerView) {
        UIView *containerView = [[UIView alloc] init];
        containerView.hidden = YES;
        
        // 创建图标
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = RCDynamicImage(@"conversation_msg_v5_read_list_empty_img", @"msg_v5_read_list_empty");
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [containerView addSubview:imageView];
        self.emptyImageView = imageView;
        
        // 创建文字
        UILabel *label = [[UILabel alloc] init];
        label.textColor = RCDynamicColor(@"text_primary_color", @"0x939393", @"0x666666");
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [containerView addSubview:label];
        
        // 保存 label 引用以便后续更新文字
        self.emptyLabel = label;
        
        // 设置内部约束
        [NSLayoutConstraint activateConstraints:@[
            // 图标约束
            [imageView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
            [imageView.centerXAnchor constraintEqualToAnchor:containerView.centerXAnchor],
            [imageView.widthAnchor constraintEqualToConstant:52],
            [imageView.heightAnchor constraintEqualToConstant:52],
            
            // 文字约束
            [label.topAnchor constraintEqualToAnchor:imageView.bottomAnchor constant:10],
            [label.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
            [label.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
            [label.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor]
        ]];
        
        _emptyContainerView = containerView;
    }
    return _emptyContainerView;
}

@end

