//
//  RCSearchFriendsViewController.m
//  RongIMKit
//
//  Created by RobinCui on 2024/9/4.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCSearchFriendsViewController.h"
#import "RCFriendListView.h"
#import "RCKitCommonDefine.h"
#import "RCAlertView.h"
@interface RCSearchFriendsViewController ()<UITableViewDelegate, UITableViewDataSource,RCListViewModelResponder>

@property (nonatomic, strong) RCSearchFriendsViewModel *viewModel;
@property (nonatomic, strong) RCFriendListView *listView;
@end

@implementation RCSearchFriendsViewController
- (instancetype)initWithViewModel:(RCSearchFriendsViewModel *)viewModel
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

- (void)setupView {
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self.viewModel registerCellForTableView:self.listView.tableView];
    if (!self.title) {
        self.title = RCLocalizedString(@"SearchFriendTitle");
    }
    [self configureSearchBar];
    [self configureRightNaviItems];
}

- (void)configureSearchBar {
    UISearchBar *bar = [self.viewModel configureSearchBarForViewController:self];
    [self.listView configureSearchBar:bar];
}

- (void)configureRightNaviItems {
    NSArray *items = [self.viewModel configureRightNaviItemsForViewController:self];
    self.navigationItem.rightBarButtonItems = items;
}

#pragma mark - RCFriendListViewModelResponder
- (void)reloadData:(BOOL)isEmpty {
    [self.listView.tableView reloadData];
    [self.listView.tableView setNeedsLayout];
    [self.listView.tableView layoutIfNeeded];
    self.listView.labEmpty.hidden = !isEmpty;
}

- (void)showTips:(NSString *)tips {
    [RCAlertView showAlertController:nil
                             message:tips
                    hiddenAfterDelay:2];
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
    return 56;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

//如果没有该方法，tableView会默认显示footerView，其高度与headerView等高
//另外如果return 0或者0.0f是没有效果的
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark - Property

- (RCFriendListView *)listView {
    if (!_listView) {
        RCFriendListView *listView = [RCFriendListView new];
        listView.tableView.dataSource = self;
        listView.tableView.delegate = self;
        _listView = listView;
    }
    return _listView;
}
@end
