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
#import "RCSelectUserView.h"
#import "RCPaddingTableViewCell.h"

@interface RCSelectUserViewController ()<
UITableViewDelegate,
UITableViewDataSource,
RCListViewModelResponder
>

@property (nonatomic, strong) RCBaseButton *confirmButton;

@property (nonatomic, strong) RCSelectUserView *listView;

@property (nonatomic, strong) RCSelectUserViewModel *viewModel;

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
    [self.viewModel registerCellForTableView:self.listView.tableView];
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
    UIView *bar = [self.viewModel configureSearchBarForViewController:self];
    [self.listView configureSearchBar:bar];
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
    [self.listView.tableView reloadData];
    self.listView.emptyLabel.hidden = !isEmpty;
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
    UITableViewCell *cell =  [self.viewModel tableView:tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[RCPaddingTableViewCell class]]) {
        RCPaddingTableViewCell *paddingCell = (RCPaddingTableViewCell *)cell;
        [paddingCell updatePaddingContainer:RCUserManagementPadding trailing:-1];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return RCUserManagementCellHeight;
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

- (RCSelectUserView *)listView {
    if (!_listView) {
        _listView = [RCSelectUserView new];
        _listView.emptyLabel.text = [self.viewModel emptyTip];
        _listView.tableView.delegate = self;
        _listView.tableView.dataSource = self;
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
