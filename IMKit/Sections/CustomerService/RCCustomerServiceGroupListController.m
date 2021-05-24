//
//  RCCustomerServiceGroupListController.m
//  RongIMKit
//
//  Created by 张改红 on 16/7/19.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCCustomerServiceGroupListController.h"
#import "RCCustomerServiceGroupCell.h"
#import "RCKitCommonDefine.h"
#import <RongIMLib/RongIMLib.h>
#import "RCKitUtility.h"
#import "RCKitConfig.h"
#import <RongCustomerService/RongCustomerService.h>
#define CellIdentifier @"customerGroupCell"

@interface RCCustomerServiceGroupListController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) UIButton *isSureButton;
@end

@implementation RCCustomerServiceGroupListController

#pragma mark – Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.groupList = [NSArray array];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.currentIndex = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"请选择咨询内容";
    
    [self setTableView];
    [self setLeftBarButtonItems];
    [self setRightBarButtonItems];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.groupList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCCustomerServiceGroupCell *cell =
        [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[RCCustomerServiceGroupCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:CellIdentifier];
    }
    RCCustomerServiceGroupItem *item = self.groupList[indexPath.row];
    cell.groupName.text = item.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RCCustomerServiceGroupCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selected = YES;
    _isSureButton.enabled = YES;
    self.currentIndex = indexPath.row;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    RCCustomerServiceGroupCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selected = NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

#pragma mark – Private Methods

- (void)dismissController {
    self.selectGroupBlock(nil);
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissByselectedGroup {
    RCCustomerServiceGroupItem *group = self.groupList[self.currentIndex];
    self.selectGroupBlock(group.groupId);
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


- (void)setTableView{
    [self.tableView registerClass:[RCCustomerServiceGroupCell class] forCellReuseIdentifier:CellIdentifier];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = RCDYCOLOR(0xf0f0f6, 0x000000);
    self.tableView.separatorColor = RCDYCOLOR(0xE3E5E6, 0x272727);
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 45, 0, 0)];
    }
}

- (void)setLeftBarButtonItems{
    UIButton *leftbtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    leftbtn.frame = CGRectMake(3, 0, 60, 44);
    leftbtn.titleLabel.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
    leftbtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [leftbtn setTitle:RCLocalizedString(@"Cancel") forState:UIControlStateNormal];
    [leftbtn addTarget:self action:@selector(dismissController) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *btn_left = [[UIBarButtonItem alloc] initWithCustomView:leftbtn];
    UIBarButtonItem *negativeSpacer =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    negativeSpacer.width = -7;
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, btn_left, nil];
}

- (void)setRightBarButtonItems{
    _isSureButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _isSureButton.frame = CGRectMake(0, 0, 40, 44);
    _isSureButton.titleLabel.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
    _isSureButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [_isSureButton setTitle:RCLocalizedString(@"OK") forState:UIControlStateNormal];
    [_isSureButton addTarget:self
                      action:@selector(dismissByselectedGroup)
            forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *btn_right = [[UIBarButtonItem alloc] initWithCustomView:_isSureButton];
    UIBarButtonItem *rightNegativeSpacer =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    rightNegativeSpacer.width = -5;
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:rightNegativeSpacer, btn_right, nil];
    _isSureButton.enabled = NO;
}

@end
