//
//  RCMessageReadDetailViewController.m
//  RongIMKit
//
//  Created by Lang on 10/15/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCMessageReadDetailViewController.h"
#import "RCMessageReadDetailViewModel.h"
#import "RCMessageReadDetailView.h"
#import "RCMessageModel.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCKitCommonDefine.h"
#import "RCMessageReadDetailCell.h"

@interface RCMessageReadDetailViewController ()<UITableViewDelegate, UITableViewDataSource, RCMessageReadDetailViewModelResponder, RCMessageReadDetailViewDelegate>

@property (nonatomic, strong) RCMessageReadDetailViewModel *viewModel;

/// 头部视图
@property (nonatomic, strong) UIView *headerView;

/// 主视图
@property (nonatomic, strong) RCMessageReadDetailView *mainView;

@end

@implementation RCMessageReadDetailViewController

- (instancetype)initWithViewModel:(RCMessageReadDetailViewModel *)viewModel {
    self = [super init];
    if (self) {
        _viewModel = viewModel;
        [_viewModel bindResponder:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = RCLocalizedString(@"MessageReadStatus");
    self.view.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xf5f6f9", @"0x1c1c1c");
    
    [self setupView];
    [self setupNavigationBar];
    [self.viewModel loadData];
}

#pragma mark - UI Setup

- (void)setupView {
    // 获取头部视图
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(viewController:headerViewWithMessage:)]) {
        self.headerView = [self.dataSource viewController:self headerViewWithMessage:self.viewModel.messageModel];
    }
    
    // 添加头部视图（如果有）
    if (self.headerView) {
        self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:self.headerView];
    }
    
    // 添加主视图
    self.mainView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.mainView];
    
    // 设置约束
    [self setupConstraints];
    
    // 设置已读/未读数量
    NSInteger readCount = self.viewModel.messageModel.readReceiptInfoV5.readCount;
    NSInteger unreadCount = self.viewModel.messageModel.readReceiptInfoV5.unreadCount;
    [self.mainView setupReadCount:readCount unreadCount:unreadCount];
}

- (void)setupConstraints {
    NSLayoutAnchor *topAnchor;
    if (@available(iOS 11.0, *)) {
        topAnchor = self.view.safeAreaLayoutGuide.topAnchor;
    } else {
        topAnchor = self.view.topAnchor;
    }
    
    // 如果有头部视图，先设置头部视图约束
    if (self.headerView) {
        [NSLayoutConstraint activateConstraints:@[
            [self.headerView.topAnchor constraintEqualToAnchor:topAnchor],
            [self.headerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [self.headerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
        ]];
        topAnchor = self.headerView.bottomAnchor;
    }
    
    // 主视图约束
    [NSLayoutConstraint activateConstraints:@[
        [self.mainView.topAnchor constraintEqualToAnchor:topAnchor],
        [self.mainView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.mainView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.mainView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)setupNavigationBar {
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    RCMessageReadDetailTabType tabType = [self.mainView tabTypeForTableView:tableView];
    return [self.viewModel numberOfSectionsForTabType:tabType];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    RCMessageReadDetailTabType tabType = [self.mainView tabTypeForTableView:tableView];
    return [self.viewModel numberOfRowsForTabType:tabType inSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCMessageReadDetailTabType tabType = [self.mainView tabTypeForTableView:tableView];
    return [self.viewModel cellHeightForTabType:tabType atIndex:indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCMessageReadDetailTabType tabType = [self.mainView tabTypeForTableView:tableView];
    
    RCMessageReadDetailCellViewModel *cellViewModel = [self.viewModel cellViewModelForTabType:tabType atIndex:indexPath.row];
    if (!cellViewModel) {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
    }
    
    RCMessageReadDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:[RCMessageReadDetailCell reuseIdentifier] forIndexPath:indexPath];
    [cell bindViewModel:cellViewModel];
    cell.contentView.backgroundColor = tableView.backgroundColor;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark - RCMessageReadDetailViewDelegate

/// 处理 Tab 切换事件
- (void)readReceiptUserListView:(RCMessageReadDetailView *)view didSwitchToTab:(RCMessageReadDetailTabType)tabType {
    [self.viewModel switchTabToType:tabType];
    
    // 判断列表是否为空
    BOOL isEmpty = (tabType == RCMessageReadDetailTabTypeRead) 
        ? (self.viewModel.readUserList.count == 0) 
        : (self.viewModel.unreadUserList.count == 0);
    
    // 更新视图状态
    [self.mainView switchToTabType:tabType isEmpty:isEmpty];
    
    // 更新空视图文字
    if (isEmpty) {
        [self updateEmptyViewTextForTabType:tabType];
    }
}

/// 处理加载更多数据请求
- (void)readReceiptUserListView:(RCMessageReadDetailView *)view needLoadMoreForTabType:(RCMessageReadDetailTabType)tabType {
    [self.viewModel loadMoreData];
}

#pragma mark - RCMessageReadDetailViewModelResponder

/// 更新用户列表
/// @param tabType 列表类型（已读/未读）
/// @param isEmpty 列表是否为空
/// @param hasMoreData 是否有更多数据
- (void)updateUserListForTabType:(RCMessageReadDetailTabType)tabType
                         isEmpty:(BOOL)isEmpty
                     hasMoreData:(BOOL)hasMoreData {
    // 刷新列表数据并结束加载状态
    [self.mainView reloadDataForTabType:tabType hasMoreData:hasMoreData];
    
    // 只在当前 tab 为此列表时才更新 UI
    // 避免并发加载时不同 tab 的数据互相影响
    if (self.viewModel.currentTabType == tabType) {
        if (isEmpty) {
            [self updateEmptyViewTextForTabType:tabType];
        }
        [self.mainView switchToTabType:tabType isEmpty:isEmpty];
    }
}

- (UIViewController *)currentViewController {
    return self;
}

/// 更新 tab 视图中已读/未读数量显示
- (void)updateTabViewWithReadCount:(NSInteger)readCount unreadCount:(NSInteger)unreadCount {
    [self.mainView setupReadCount:readCount unreadCount:unreadCount];
}

#pragma mark - Private Methods

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

/// 根据 tab 类型更新空状态提示文字
- (void)updateEmptyViewTextForTabType:(RCMessageReadDetailTabType)tabType {
    NSString *text;
    if (tabType == RCMessageReadDetailTabTypeRead) {
        text = RCLocalizedString(@"MessageReadStatusNoneRead");
    } else {
        text = RCLocalizedString(@"MessageReadStatusAllRead");
    }
    [self.mainView updateEmptyViewText:text];
}

#pragma mark - Getter

- (RCMessageReadDetailView *)mainView {
    if (!_mainView) {
        CGFloat tabHeight = self.viewModel.config.tabHeight;
        _mainView = [[RCMessageReadDetailView alloc] initWithFrame:CGRectZero tabHeight:tabHeight];
        _mainView.delegate = self;
        
        // 设置 tableView 的 delegate 和 dataSource
        _mainView.readTableView.delegate = self;
        _mainView.readTableView.dataSource = self;
        _mainView.unreadTableView.delegate = self;
        _mainView.unreadTableView.dataSource = self;
        
        // 注册 cell
        [_mainView.readTableView registerClass:[RCMessageReadDetailCell class] forCellReuseIdentifier:[RCMessageReadDetailCell reuseIdentifier]];
        [_mainView.unreadTableView registerClass:[RCMessageReadDetailCell class] forCellReuseIdentifier:[RCMessageReadDetailCell reuseIdentifier]];
    }
    return _mainView;
}

@end
