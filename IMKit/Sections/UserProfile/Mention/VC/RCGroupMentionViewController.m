//
//  RCGroupMentionViewController.m
//  RongIMKit
//
//  Created by RobinCui on 2025/11/19.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCGroupMentionViewController.h"
#import "RCGroupMemberListViewModel.h"
#import "RCKitCommonDefine.h"
#import "RCSearchBarListView.h"
@interface RCGroupMentionViewController ()<
UITableViewDelegate,
UITableViewDataSource,
RCListViewModelResponder
>

@property (nonatomic, strong) RCSearchBarListView *membersView;

@property (nonatomic, strong) RCGroupMentionViewModel *viewModel;

@end

@implementation RCGroupMentionViewController

- (instancetype)initWithViewModel:(RCGroupMentionViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self.viewModel bindResponder:self];
        self.title = RCLocalizedString(@"SelectMentionedUser");
    }
    return self;
}

- (void)loadView {
    self.view = self.membersView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.viewModel registerCellForTableView:self.membersView.tableView];
    [self setNavigationBarItems];
    [self setupView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.viewModel fetchGroupMembersByPage];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.viewModel endEditingState];
}

#pragma mark -- private

- (void)setNavigationBarItems {
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

- (void)setupView {
    [self.membersView configureSearchBar:[self.viewModel configureSearchBar]];
}

#pragma mark -- action

- (void)leftBarButtonItemPressed {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.viewModel selectionCanceled];
}

#pragma mark -- RCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.membersView.tableView reloadData];
    self.membersView.labEmpty.hidden = !isEmpty;
}

- (UIViewController *)currentViewController {
    return self;
}

#pragma mark -- UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModel numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel tableView:tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark -- UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.viewModel numberOfSections];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self tableView:tableView didSelectRow:indexPath];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > self.viewModel.memberList.count - 10) {
        [self.viewModel fetchGroupMembersByPage];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self.viewModel heightForHeaderInSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [self.viewModel tableView:tableView viewForHeaderInSection:section];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark -- getter

- (RCSearchBarListView *)membersView {
    if (!_membersView) {
        _membersView = [RCSearchBarListView new];
        _membersView.tableView.delegate = self;
        _membersView.tableView.dataSource = self;
        _membersView.labEmpty.text = RCLocalizedString(@"NotUserFound");
    }
    return _membersView;
}


@end
