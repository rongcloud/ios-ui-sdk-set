//
//  RCUGenderSelectViewController.m
//  RongIMKit
//
//  Created by zgh on 2024/8/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGenderSelectViewController.h"
#import "RCProfileGenderViewModel.h"
#import "RCBaseTableView.h"
#import "RCBaseButton.h"
#import "RCKitCommonDefine.h"

#define RCUGenderSelectViewControllerConfirmWidth 100
#define RCUGenderSelectViewControllerConfirmHeight 40

@interface RCGenderSelectViewController ()<
UITableViewDelegate,
UITableViewDataSource
>

@property (nonatomic, strong) RCProfileGenderViewModel *viewModel;

@property (nonatomic, strong) RCBaseTableView *genderView;

@property (nonatomic, strong) RCBaseButton *confirmButton;

@end

@implementation RCGenderSelectViewController

- (instancetype)initWithViewModel:(id)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
    }
    return self;
}

- (void)loadView {
    self.view = self.genderView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = RCLocalizedString(@"GenderEdit");
    [self.viewModel registerCellForTableView:self.genderView];
    [self setNavigationBarItems];
}

- (void)setNavigationBarItems {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.confirmButton];
    
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:@"" target:self action:@selector(leftBarButtonItemPressed)];
}

#pragma mark -- action

- (void)leftBarButtonItemPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)confirmButtonDidClick {
    [self.viewModel updateUserProfileGender:self];
}

#pragma mark -- UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCProfileGenderCellViewModel *cellViewModel = self.viewModel.dataSource[indexPath.row];
    return [cellViewModel tableView:tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark -- UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel viewController:self tableView:tableView didSelectRow:indexPath];

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel.dataSource[indexPath.row] tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark -- getter

- (RCBaseTableView *)genderView {
    if (!_genderView) {
        _genderView = [[RCBaseTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _genderView.separatorColor = RCDYCOLOR(0xE3E5E6, 0x272727);
        _genderView.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x111111);
        _genderView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 15)];
        _genderView.sectionHeaderHeight = 0;
        if (@available(iOS 15.0, *)) {
            _genderView.sectionHeaderTopPadding = 15;
        }
        _genderView.delegate = self;
        _genderView.dataSource = self;
        if ([_genderView respondsToSelector:@selector(setSeparatorInset:)]) {
            _genderView.separatorInset = UIEdgeInsetsMake(0, 12, 0, 0);
        }
        if ([self respondsToSelector:@selector(setLayoutMargins:)]) {
            _genderView.layoutMargins = UIEdgeInsetsMake(0, 12, 0, 0);
        }
    }
    return _genderView;
}

- (RCBaseButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[RCBaseButton alloc] initWithFrame:CGRectMake(0, 0, RCUGenderSelectViewControllerConfirmWidth, RCUGenderSelectViewControllerConfirmHeight)];
        [_confirmButton setTitle:RCLocalizedString(@"Confirm") forState:UIControlStateNormal];
        [_confirmButton setTitleColor:RCDYCOLOR(0x0099ff, 0x007acc) forState:(UIControlStateNormal)];
        [_confirmButton addTarget:self action:@selector(confirmButtonDidClick) forControlEvents:UIControlEventTouchUpInside];
        [_confirmButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
        _confirmButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    }
    return _confirmButton;
}

@end
