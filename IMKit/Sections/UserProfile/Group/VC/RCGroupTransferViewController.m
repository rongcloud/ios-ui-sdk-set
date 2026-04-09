//
//  RCGroupTransferOwnerViewController.m
//  RongIMKit
//
//  Created by zgh on 2024/8/26.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupTransferViewController.h"
#import "RCKitCommonDefine.h"
#import "RCSelectUserView.h"
@interface RCGroupTransferViewController ()<
UITableViewDelegate,
UITableViewDataSource,
RCListViewModelResponder
>

@property (nonatomic, strong) RCSelectUserView *membersView;

@property (nonatomic, strong) RCGroupTransferViewModel *viewModel;

@property (nonatomic, strong) UILabel *emptyLabel;

@end

@implementation RCGroupTransferViewController

- (instancetype)initWithViewModel:(RCGroupTransferViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self.viewModel bindResponder:self];
        self.title = RCLocalizedString(@"GroupTransferVCTitle");
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
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -- RCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.membersView.tableView reloadData];
    self.membersView.emptyLabel.hidden = !isEmpty;
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

- (RCSelectUserView *)membersView {
    if (!_membersView) {
        _membersView = [RCSelectUserView new];
        _membersView.tableView.delegate = self;
        _membersView.tableView.dataSource = self;
        _membersView.emptyLabel.text = RCLocalizedString(@"NotUserFound");
    }
    return _membersView;
}



@end
