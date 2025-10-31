//
//  RCGroupMembersViewController.m
//  RongIMKit
//
//  Created by zgh on 2024/8/26.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupMemberListViewController.h"
#import "RCGroupMemberListViewModel.h"
#import "RCKitCommonDefine.h"
#import "RCBaseTableView.h"
@interface RCGroupMemberListViewController ()<
UITableViewDelegate,
UITableViewDataSource,
RCListViewModelResponder
>

@property (nonatomic, strong) RCBaseTableView *membersView;

@property (nonatomic, strong) RCGroupMemberListViewModel *viewModel;

@property (nonatomic, strong) UILabel *emptyLabel;

@end

@implementation RCGroupMemberListViewController

- (instancetype)initWithViewModel:(RCGroupMemberListViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self.viewModel bindResponder:self];
        self.title = RCLocalizedString(@"GroupMembers");
    }
    return self;
}

- (void)loadView {
    self.view = self.membersView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.viewModel registerCellForTableView:self.membersView];
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
    self.membersView.tableHeaderView = [self.viewModel configureSearchBar];
    [self.membersView addSubview:self.emptyLabel];
}

#pragma mark -- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -- RCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.membersView reloadData];
    self.emptyLabel.hidden = !isEmpty;
    if (!self.emptyLabel.hidden) {
        self.emptyLabel.text = RCLocalizedString(@"NotUserFound");
        [self.emptyLabel sizeToFit];
        self.emptyLabel.center = CGPointMake(self.view.center.x, 150);
    }
}

- (UIViewController *)currentViewController {
    return self;
}

#pragma mark -- UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.memberList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel.memberList[indexPath.row] tableView:tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark -- UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self tableView:tableView didSelectRow:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel.memberList[indexPath.row] tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > self.viewModel.memberList.count - 10) {
        [self.viewModel fetchGroupMembersByPage];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark -- getter

- (RCBaseTableView *)membersView {
    if (!_membersView) {
        _membersView = [RCBaseTableView new];
        _membersView.delegate = self;
        _membersView.dataSource = self;
        _membersView.tableFooterView = [UIView new];
        if ([_membersView respondsToSelector:@selector(setSeparatorInset:)]) {
            _membersView.separatorInset = UIEdgeInsetsMake(0, 64, 0, 0);
        }
        if ([_membersView respondsToSelector:@selector(setLayoutMargins:)]) {
            _membersView.layoutMargins = UIEdgeInsetsMake(0, 64, 0, 0);
        }
    }
    return _membersView;
}

- (UILabel *)emptyLabel {
    if (!_emptyLabel) {
        UILabel *lab = [[UILabel alloc] init];
        lab.textColor = RCDYCOLOR(0x939393, 0x666666);
        lab.font = [UIFont systemFontOfSize:17];
        lab.textAlignment = NSTextAlignmentCenter;
        lab.hidden = YES;
        [lab sizeToFit];
        _emptyLabel = lab;
    }
    return _emptyLabel;
}

@end
