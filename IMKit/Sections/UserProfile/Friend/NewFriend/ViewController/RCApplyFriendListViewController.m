//
//  RCFriendApplyListViewController.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCApplyFriendListViewController.h"
#import "RCApplyFriendListView.h"
#import "RCKitCommonDefine.h"
#import "RCAlertView.h"
@interface RCApplyFriendListViewController ()<UITableViewDelegate, UITableViewDataSource,RCListViewModelResponder>

@property (nonatomic, strong) RCApplyFriendListViewModel *viewModel;
@property (nonatomic, strong) RCApplyFriendListView *listView;
@end

@implementation RCApplyFriendListViewController
- (instancetype)initWithViewModel:(RCApplyFriendListViewModel *)viewModel
{
    self = [super init];
    if (self) {
        [viewModel bindResponder:self];
        self.viewModel = viewModel;
    }
    return self;
}

- (void)loadView {
    self.view = self.listView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.viewModel fetchData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)setupView {
    [self.viewModel registerCellForTableView:self.listView.tableView];
    if (!self.title) {
        self.title = RCLocalizedString(@"FriendApplicationNewFriend");
    }
    [self configureRightNaviItems];
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)configureRightNaviItems {
    NSArray *items = [self.viewModel configureRightNaviItemsForViewController:self];
    self.navigationItem.rightBarButtonItems = items;
}

- (void)loadMore {
    [self.viewModel loadMoreData];
}

#pragma mark - RCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.listView.tableView reloadData];
    [self.listView.tableView setNeedsLayout];
    [self.listView.tableView layoutIfNeeded];
    self.listView.labEmpty.hidden = !isEmpty;
}

- (void)refreshingFinished:(BOOL)success withTips:(NSString *)tips {
    [self.listView stopRefreshing];
    [self showTips:tips];
}

- (void)showTips:(NSString *)tips {
    if (tips.length == 0) {
        return;
    }
    [RCAlertView showAlertController:nil
                             message:tips
                    hiddenAfterDelay:2];
}

- (void)showAlert:(UIAlertController *)alert {
    [self presentViewController:alert animated:YES completion:nil];
}
#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self
                         tableView:tableView
                      didSelectRow:indexPath];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.viewModel numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModel numberOfRowsInSection:section];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return  [self.viewModel tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel tableView:tableView heightForRowAtIndexPath:indexPath];;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [self.viewModel tableView:tableView viewForHeaderInSection:section];;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self.viewModel tableView:tableView heightForHeaderInSection:section];;
}

//如果没有该方法，tableView会默认显示footerView，其高度与headerView等高
//另外如果return 0或者0.0f是没有效果的
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel tableView:tableView editActionsForRowAtIndexPath:indexPath];
}

#pragma mark - Property

- (RCApplyFriendListView *)listView {
    if (!_listView) {
        RCApplyFriendListView *listView = [RCApplyFriendListView new];
        listView.tableView.dataSource = self;
        listView.tableView.delegate = self;
        [listView addRefreshingTarget:self withSelector:@selector(loadMore)];
        _listView = listView;
    }
    return _listView;
}

@end
