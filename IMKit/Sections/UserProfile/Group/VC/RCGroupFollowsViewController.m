//
//  RCGroupFollowsViewController.m
//  RongIMKit
//
//  Created by zgh on 2024/11/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupFollowsViewController.h"
#import "RCBaseTableView.h"
#import "RCKitCommonDefine.h"

@interface RCGroupFollowsViewController ()<
UITableViewDelegate,
UITableViewDataSource,
RCListViewModelResponder
>

@property (nonatomic, strong) RCBaseTableView *tableView;

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
    self.view = self.tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.viewModel registerCellForTableView:self.tableView];
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
    [self.tableView addSubview:self.emptyLabel];
}

#pragma mark -- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -- RCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.tableView reloadData];
    self.emptyLabel.hidden = !isEmpty;
    if (!self.emptyLabel.hidden) {
        self.emptyLabel.text = RCLocalizedString(@"NoGroupFollows");
        [self.emptyLabel sizeToFit];
        self.emptyLabel.center = CGPointMake(self.view.center.x, 150);
    }
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

- (RCBaseTableView *)tableView {
    if (!_tableView) {
        _tableView = [RCBaseTableView new];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorColor = RCDYCOLOR(0xE3E5E6, 0x272727);
        _tableView.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x111111);
        _tableView.tableFooterView = [UIView new];
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 15)];
        _tableView.sectionHeaderHeight = 0;
        if (@available(iOS 15.0, *)) {
            _tableView.sectionHeaderTopPadding = 15;
        }
        if ([_tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            _tableView.separatorInset = UIEdgeInsetsMake(0, 64, 0, 0);
        }
        if ([_tableView respondsToSelector:@selector(setLayoutMargins:)]) {
            _tableView.layoutMargins = UIEdgeInsetsMake(0, 64, 0, 0);
        }
    }
    return _tableView;
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
