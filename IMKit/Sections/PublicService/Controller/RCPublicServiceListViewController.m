//
//  RCPublicServiceListViewController.m
//  RongIMKit
//
//  Created by litao on 15/4/20.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCPublicServiceListViewController.h"
#import "RCConversationViewController.h"
#import "RCKitUtility.h"
#import "RCPublicServiceListViewCell.h"
#import "RCKitCommonDefine.h"
#import <RongPublicService/RongPublicService.h>
@interface RCPublicServiceListViewController ()
//#字符索引对应的user object
@property (nonatomic, strong) NSMutableArray *tempOtherArr;
@property (nonatomic, strong) NSMutableArray *friends;
@property (nonatomic, strong) NSArray *keys;
@property (nonatomic, assign) BOOL hideSectionHeader;

@end

@implementation RCPublicServiceListViewController
#pragma mark – Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = RCLocalizedString(@"PublicService");

    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = RCDYCOLOR(0xf0f0f6, 0x000000);
    self.tableView.separatorColor = RCDYCOLOR(0xE3E5E6, 0x272727);
    [self setTitle:RCLocalizedString(@"PublicService")];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self getAllData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark – Private Methods
/**
 *  initial data
 */
- (void)getAllData {
    NSArray *result = [[RCPublicServiceClient sharedPublicServiceClient] getPublicServiceList];
    _friends = [NSMutableArray arrayWithArray:result];

    //如果
    if (_friends.count < 10) {
        self.hideSectionHeader = YES;
    }

    _keys = @[
        @"A",
        @"B",
        @"C",
        @"D",
        @"E",
        @"F",
        @"G",
        @"H",
        @"I",
        @"J",
        @"K",
        @"L",
        @"M",
        @"N",
        @"O",
        @"P",
        @"Q",
        @"R",
        @"S",
        @"T",
        @"U",
        @"V",
        @"W",
        @"X",
        @"Y",
        @"Z",
        @"#"
    ];
    _allFriends = [NSMutableDictionary new];
    _allKeys = [NSMutableArray new];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        _allFriends = [weakSelf sortedArrayWithPinYinDic:_friends];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    });
}

//拼音排序
- (NSMutableDictionary *)sortedArrayWithPinYinDic:(NSArray *)friends {
    if (!friends)
        return nil;

    NSMutableDictionary *returnDic = [NSMutableDictionary new];
    _tempOtherArr = [NSMutableArray new];
    BOOL isReturn = NO;

    for (NSString *key in _keys) {

        if ([_tempOtherArr count]) {
            isReturn = YES;
        }

        NSMutableArray *tempArr = [NSMutableArray new];
        for (RCPublicServiceProfile *user in friends) {

            NSString *pyResult = [RCKitUtility getPinYinUpperFirstLetters:user.name];
            if (!pyResult || [pyResult length] < 1)
                continue;
            NSString *firstLetter = [pyResult substringToIndex:1];
            if ([firstLetter isEqualToString:key]) {
                [tempArr addObject:user];
            }

            if (isReturn)
                continue;
            char c = [pyResult characterAtIndex:0];
            if (isalpha(c) == 0) {
                [_tempOtherArr addObject:user];
            }
        }
        if ([tempArr count])
            [returnDic setObject:tempArr forKey:key];
    }
    if ([_tempOtherArr count])
        [returnDic setObject:_tempOtherArr forKey:@"#"];

    _allKeys = [[returnDic allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {

        return [obj1 compare:obj2 options:NSNumericSearch];
    }];

    return returnDic;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reusableCellWithIdentifier = @"RCPublicServiceListViewCell";
    RCPublicServiceListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableCellWithIdentifier];
    if (!cell) {
        cell = [[RCPublicServiceListViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                  reuseIdentifier:reusableCellWithIdentifier];
    }

    NSString *key = [_allKeys objectAtIndex:indexPath.section];
    NSArray *arrayForKey = [_allFriends objectForKey:key];

    RCPublicServiceProfile *user = arrayForKey[indexPath.row];
    if (user) {
        [cell setName:user.name];
        [cell setDescription:user.introduction];
        [cell.headerImageView setImageURL:[NSURL URLWithString:user.portraitUrl]];
    }

    return cell;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *key = [_allKeys objectAtIndex:section];

    NSArray *arr = [_allFriends objectForKey:key];

    return [arr count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return [_allKeys count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72.f;
}

// pinyin index
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {

    if (self.hideSectionHeader) {
        return nil;
    }
    return _allKeys;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.hideSectionHeader) {
        return nil;
    }

    NSString *key = [_allKeys objectAtIndex:section];
    return key;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *key = [_allKeys objectAtIndex:indexPath.section];
    NSArray *arrayForKey = [_allFriends objectForKey:key];

    RCPublicServiceProfile *user = arrayForKey[indexPath.row];
    if (user) {
        RCConversationViewController *_conversationVC = [[RCConversationViewController alloc] init];
        _conversationVC.conversationType = (RCConversationType)user.publicServiceType;
        _conversationVC.targetId = user.publicServiceId;
        _conversationVC.title = user.name;
        [self.navigationController pushViewController:_conversationVC animated:YES];
    }
}

@end
