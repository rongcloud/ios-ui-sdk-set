//
//  RCSelectConversationViewController.m
//  RongCallKit
//
//  Created by 岑裕 on 16/3/12.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCSelectConversationViewController.h"
#import "RCKitUtility.h"
#import "RCSelectConversationCell.h"
#import "RCKitCommonDefine.h"
#import "RCIM.h"
#import "RCKitConfig.h"

typedef void (^CompleteBlock)(NSArray *conversationList);

@interface RCSelectConversationViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray *selectedConversationArray;

@property (nonatomic, strong) UITableView *conversationTableView;

@property (nonatomic, strong) UIBarButtonItem *rightBarButtonItem;

@property (nonatomic, strong) NSArray *listingConversationArray;

@property (nonatomic, strong) CompleteBlock completeBlock;

@end

@implementation RCSelectConversationViewController
#pragma mark - Life Cycle
- (instancetype)initSelectConversationViewControllerCompleted:
    (void (^)(NSArray<RCConversation *> *conversationList))completedBlock {
    if (self = [super init]) {
        self.completeBlock = completedBlock;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavi];
    self.view.backgroundColor = RCDYCOLOR(0xf0f0f6, 0x000000);
    [self.view addSubview:self.conversationTableView];
    self.selectedConversationArray = [[NSMutableArray alloc] init];
    self.listingConversationArray =
        [[RCIMClient sharedRCIMClient] getConversationList:@[ @(ConversationType_PRIVATE), @(ConversationType_GROUP) ]];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.listingConversationArray) {
        return 0;
    } else {
        return self.listingConversationArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.listingConversationArray.count <= indexPath.row) {
        return nil;
    }

    static NSString *reusableID = @"RCSelectConversationCell";
    RCSelectConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableID];
    if (!cell) {
        cell = [[RCSelectConversationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reusableID];
    }

    RCConversation *conversation = self.listingConversationArray[indexPath.row];
    BOOL ifSelected = [self.selectedConversationArray containsObject:conversation];
    [cell setConversation:conversation ifSelected:ifSelected];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.listingConversationArray.count) {
        return;
    }
    NSString *userId = self.listingConversationArray[indexPath.row];
    if ([self.selectedConversationArray containsObject:userId]) {
        [self.selectedConversationArray removeObject:userId];
    } else if (userId) {
        [self.selectedConversationArray addObject:userId];
    }
    [self updateRightButton];
    [UIView performWithoutAnimation:^{
        [self.conversationTableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
    }];
}


#pragma mark - Target Action

- (void)onLeftButtonClick:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)onRightButtonClick:(id)sender {
    if (!self.selectedConversationArray) {
        return;
    }
    if (self.completeBlock) {
        self.completeBlock(self.selectedConversationArray);
    }
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark - Private Methods
- (void)setupNavi {
    self.title = RCLocalizedString(@"SelectContact");
    UIBarButtonItem *leftBarItem =
        [[UIBarButtonItem alloc] initWithTitle:RCLocalizedString(@"Cancel")
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(onLeftButtonClick:)];
    leftBarItem.tintColor = RCKitConfigCenter.ui.globalNavigationBarTintColor;
    self.navigationItem.leftBarButtonItem = leftBarItem;

    self.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:RCLocalizedString(@"OK")
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(onRightButtonClick:)];
    self.rightBarButtonItem.tintColor = RCKitConfigCenter.ui.globalNavigationBarTintColor;
    self.navigationItem.rightBarButtonItem = self.rightBarButtonItem;

    [self updateRightButton];
}

- (void)updateRightButton {
    [self.rightBarButtonItem setEnabled:self.selectedConversationArray.count > 0];
}

#pragma mark - Getters and Setters

- (UITableView *)conversationTableView {
    if (!_conversationTableView) {
        CGFloat homeBarHeight = [RCKitUtility getWindowSafeAreaInsets].bottom;
        CGRect frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height-homeBarHeight);
        _conversationTableView = [[UITableView alloc] initWithFrame:frame  style:UITableViewStyleGrouped];
        _conversationTableView.estimatedRowHeight = 0;
        _conversationTableView.estimatedSectionHeaderHeight = 0;
        _conversationTableView.estimatedSectionFooterHeight = 0;
        _conversationTableView.dataSource = self;
        _conversationTableView.delegate = self;
        _conversationTableView.backgroundColor = [UIColor clearColor];
        _conversationTableView.tableFooterView = [[UIView alloc] init];
    }
    return _conversationTableView;
}

@end
