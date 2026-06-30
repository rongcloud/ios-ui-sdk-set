//
//  RCSelectGroupMemberViewController.m
//  RongIMKit
//
//  Created by zgh on 2024/11/15.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCSelectGroupMemberViewController.h"
#import "RCBaseButton.h"
#import "RCBaseTableView.h"
#import "RCKitCommonDefine.h"
#import "RCSelectUserView.h"

@interface RCSelectGroupMemberViewController ()<
UITableViewDelegate,
UITableViewDataSource,
RCListViewModelResponder
>

@property (nonatomic, strong) RCBaseButton *confirmButton;

@property (nonatomic, strong) RCSelectUserView *listView;

@property (nonatomic, strong) RCSelectGroupMemberViewModel *viewModel;

@end

@implementation RCSelectGroupMemberViewController

- (instancetype)initWithViewModel:(RCSelectGroupMemberViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self.viewModel bindResponder:self];
    }
    return self;
}

- (void)loadView {
    self.view = self.listView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.viewModel registerCellForTableView:self.listView.tableView];
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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.confirmButton];
    self.confirmButton.enabled = NO;
    
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

- (void)setupView {
    [self.listView configureSearchBar:[self.viewModel configureSearchBar]];
}

#pragma mark -- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)confirmButtonDidClick {
    [self.viewModel selectionDidDone];
}

- (void)itemSelectDidUpdate {
    if (self.viewModel.selectUserIds.count > 0) {
        self.confirmButton.enabled = YES;
    } else {
        self.confirmButton.enabled = NO;
    }
}

#pragma mark -- RCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.listView.tableView reloadData];
    self.listView.emptyLabel.hidden = !isEmpty;
}

- (void)updateItem:(NSIndexPath *)indexPath {
    [self itemSelectDidUpdate];
}

- (UIViewController *)currentViewController {
    return self;
}

#pragma mark -- UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self
                         tableView:tableView
                      didSelectRow:indexPath];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.memberList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return  [self.viewModel tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel.memberList[indexPath.row] tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark -- getter

- (RCSelectUserView *)listView {
    if (!_listView) {
        _listView = [RCSelectUserView new];
        _listView.tableView.delegate = self;
        _listView.tableView.dataSource = self;
        _listView.emptyLabel.text = RCLocalizedString(@"NotUserFound");
    }
    return _listView;
}

- (RCBaseButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[RCBaseButton alloc] init];
        [_confirmButton setTitle:RCLocalizedString(@"Confirm") forState:UIControlStateNormal];
        [_confirmButton setTitleColor:RCDynamicColor(@"primary_color",@"0x0099ff", @"0x007acc") forState:(UIControlStateNormal)];
        [_confirmButton setTitleColor:RCDynamicColor(@"disabled_color",@"0xa0a5ab", @"0xa0a5ab") forState:(UIControlStateDisabled)];
        [_confirmButton addTarget:self action:@selector(confirmButtonDidClick) forControlEvents:UIControlEventTouchUpInside];
        [_confirmButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        _confirmButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    }
    return _confirmButton;
}

@end
