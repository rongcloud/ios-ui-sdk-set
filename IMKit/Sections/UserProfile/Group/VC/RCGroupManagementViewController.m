//
//  RCGroupManagementViewController.h
//  RongIMKit
//
//  Created by zgh on 2024/11/25.
//  Copyright © 2024 RongCloud. All rights reserved.
//
#import "RCGroupManagementViewController.h"
#import "RCBaseTableView.h"
#import "RCKitCommonDefine.h"

@interface RCGroupManagementViewController ()<
UITableViewDelegate,
UITableViewDataSource,
RCListViewModelResponder
>

@property (nonatomic, strong) RCBaseTableView *tableView;

@property (nonatomic, strong) RCGroupManagementViewModel *viewModel;

@end

@implementation RCGroupManagementViewController

- (instancetype)initWithViewModel:(RCGroupManagementViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self.viewModel bindResponder:self];
        self.title = RCLocalizedString(@"GroupManagement");
    }
    return self;
}

- (void)loadView {
    self.view = self.tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.viewModel registerCellForTableView:self.tableView];
    [self setNavigationBarItems];
    [self.viewModel fetchDataSources];
}

#pragma mark -- private

- (void)setNavigationBarItems {
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}


#pragma mark -- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -- RCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.tableView reloadData];
}

- (UIViewController *)currentViewController {
    return self;
}

#pragma mark -- UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.viewModel numberOfSections];
}

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

- (RCBaseTableView *)tableView {
    if (!_tableView) {
        _tableView = [[RCBaseTableView alloc] initWithFrame:CGRectZero style:(UITableViewStyleGrouped)];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorColor = RCDYCOLOR(0xE3E5E6, 0x272727);
        _tableView.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x111111);
        _tableView.tableFooterView = [UIView new];
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 15)];
        _tableView.sectionHeaderHeight = 0;
        if (@available(iOS 15.0, *)) {
            _tableView.sectionHeaderTopPadding = 15;
        }
        if ([_tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            _tableView.separatorInset = UIEdgeInsetsMake(0, 12, 0, 0);
        }
        if ([_tableView respondsToSelector:@selector(setLayoutMargins:)]) {
            _tableView.layoutMargins = UIEdgeInsetsMake(0, 12, 0, 0);
        }
    }
    return _tableView;
}
@end
