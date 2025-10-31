//
//  RCSelectUserViewController.m
//  RongIMKit
//
//  Created by zgh on 2024/8/26.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCSelectUserViewController.h"
#import "RCBaseButton.h"
#import "RCBaseTableView.h"
#import "RCKitCommonDefine.h"

@interface RCSelectUserViewController ()<
UITableViewDelegate,
UITableViewDataSource,
RCListViewModelResponder
>

@property (nonatomic, strong) RCBaseButton *confirmButton;

@property (nonatomic, strong) RCBaseTableView *listView;

@property (nonatomic, strong) RCSelectUserViewModel *viewModel;

@property (nonatomic, strong) UILabel *emptyLabel;

@end

@implementation RCSelectUserViewController

- (instancetype)initWithViewModel:(RCSelectUserViewModel *)viewModel{
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self.viewModel bindResponder:self];
        self.title = RCLocalizedString(@"SelectContact");
    }
    return self;
}

- (void)loadView {
    self.view = self.listView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.viewModel registerCellForTableView:self.listView];
    [self setNavigationBarItems];
    [self setupView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.viewModel fetchData];
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
    self.listView.tableHeaderView = [self.viewModel configureSearchBarForViewController:self];
    [self.listView addSubview:self.emptyLabel];
}

#pragma mark -- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)confirmButtonDidClick {
    [self.viewModel selectionDidDone];
}

#pragma mark -- RCListViewModelResponder

- (void)reloadData:(BOOL)isEmpty {
    [self.listView reloadData];
    self.emptyLabel.hidden = !isEmpty;
    if (!self.emptyLabel.hidden) {
        self.emptyLabel.text = [self.viewModel emptyTip];
        [self.emptyLabel sizeToFit];
        self.emptyLabel.center = CGPointMake(self.view.center.x, 150);
    }
}

- (void)updateItem:(NSIndexPath *)indexPath {
    if (self.viewModel.selectUserIds.count > 0) {
        self.confirmButton.enabled = YES;
    } else {
        self.confirmButton.enabled = NO;
    }
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
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self.viewModel sectionIndexTitles];
}

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

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [self.viewModel tableView:tableView viewForHeaderInSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self.viewModel heightForHeaderInSection:section];
}

//如果没有该方法，tableView会默认显示footerView，其高度与headerView等高
//另外如果return 0或者0.0f是没有效果的
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark -- getter

- (RCBaseTableView *)listView {
    if (!_listView) {
        _listView = [RCBaseTableView new];
        _listView.separatorColor = RCDYCOLOR(0xE3E5E6, 0x272727);
        _listView.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x111111);
        _listView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        _listView.delegate = self;
        _listView.dataSource = self;
        if (@available(iOS 15.0, *)) {
            _listView.sectionHeaderTopPadding = 0;
        }
        if ([_listView respondsToSelector:@selector(setSeparatorInset:)]) {
            _listView.separatorInset = UIEdgeInsetsMake(0, 64, 0, 0);
        }
        if ([_listView respondsToSelector:@selector(setLayoutMargins:)]) {
            _listView.layoutMargins = UIEdgeInsetsMake(0, 64, 0, 0);
        }
    }
    return _listView;
}

- (RCBaseButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[RCBaseButton alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
        [_confirmButton setTitle:RCLocalizedString(@"Confirm") forState:UIControlStateNormal];
        [_confirmButton setTitleColor:RCDYCOLOR(0x0099ff, 0x007acc) forState:(UIControlStateNormal)];
        [_confirmButton setTitleColor:HEXCOLOR(0xa0a5ab) forState:(UIControlStateDisabled)];
        [_confirmButton addTarget:self action:@selector(confirmButtonDidClick) forControlEvents:UIControlEventTouchUpInside];
        [_confirmButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
        _confirmButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    }
    return _confirmButton;
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
