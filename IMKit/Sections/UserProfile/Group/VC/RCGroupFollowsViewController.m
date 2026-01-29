//
//  RCGroupFollowsViewController.m
//  RongIMKit
//
//  Created by zgh on 2024/11/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupFollowsViewController.h"
#import "RCSelectUserView.h"
#import "RCKitCommonDefine.h"

@interface RCGroupFollowsViewController ()<
UITableViewDelegate,
UITableViewDataSource,
RCListViewModelResponder
>

@property (nonatomic, strong) RCSelectUserView *selectUserView;

@property (nonatomic, strong) RCGroupFollowsViewModel *viewModel;

@property (nonatomic, strong) UILabel *emptyLabel;

@end

@implementation RCGroupFollowsViewController

- (instancetype)initWithViewModel:(RCGroupFollowsViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self.viewModel bindResponder:self];
        self.title = RCLocalizedString(@"GroupFollowsVCTitle");
    }
    return self;
}

- (void)loadView {
    self.view = self.selectUserView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.viewModel registerCellForTableView:self.selectUserView.tableView];
    [self setNavigationBarItems];
    [self setupView];
    [self.viewModel fetchGroupFollows];
}

#pragma mark -- private

- (void)setNavigationBarItems {
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

- (void)setupView {
}

#pragma mark -- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -- RCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.selectUserView.tableView reloadData];
    self.selectUserView.emptyLabel.hidden = !isEmpty;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self tableView:tableView didSelectRow:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark -- getter

- (RCSelectUserView *)selectUserView {
    if (!_selectUserView) {
        _selectUserView = [RCSelectUserView new];
        _selectUserView.tableView.delegate = self;
        _selectUserView.tableView.dataSource = self;
        _selectUserView.emptyLabel.text = RCLocalizedString(@"NoGroupFollows");
    }
    return _selectUserView;
}

@end
