//
//  RCMyGroupsViewController.m
//  RongIMKit
//
//  Created by RobinCui on 2024/11/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCMyGroupsViewController.h"
#import "RCMyGroupsView.h"
#import "RCKitCommonDefine.h"
#import "RCAlertView.h"

@interface RCMyGroupsViewController ()<UITableViewDelegate, UITableViewDataSource,RCListViewModelResponder>

@property (nonatomic, strong) RCMyGroupsViewModel *viewModel;
@property (nonatomic, strong) RCMyGroupsView *listView;
@end


@implementation RCMyGroupsViewController

- (instancetype)initWithViewModel:(RCMyGroupsViewModel *)viewModel
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
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setupView];
    [self.viewModel fetchData];
}

- (void)setupView {
    [self.viewModel registerCellForTableView:self.listView.tableView];
    if (!self.title) {
        self.title = RCLocalizedString(@"MyGroups");
    }
    [self configureSearchBar];
    [self configureRightNaviItems];
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)configureSearchBar {
    UISearchBar *bar = [self.viewModel configureSearchBarForViewController:self];
    [self.listView configureSearchBar:bar];
}

- (void)configureRightNaviItems {
    NSArray *items = [self.viewModel configureRightNaviItemsForViewController:self];
    self.navigationItem.rightBarButtonItems = items;
}

- (void)loadMore {
    [self.viewModel loadMoreData];
}
#pragma mark - RCFriendListViewModelResponder
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
    return [self.viewModel tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark - Property

- (RCMyGroupsView *)listView {
    if (!_listView) {
        RCMyGroupsView *listView = [RCMyGroupsView new];
        listView.tableView.dataSource = self;
        listView.tableView.delegate = self;
        [listView addRefreshingTarget:self withSelector:@selector(loadMore)];
        _listView = listView;
    }
    return _listView;
}
@end
