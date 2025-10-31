//
//  RCSightFileBrowserViewController.m
//  RongIMKit
//
//  Created by zhaobingdong on 2017/5/12.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightFileBrowserViewController.h"
#import "RCIM.h"
#import "RCKitUtility.h"
#import "RCSightSlideViewController.h"
#import "RCKitCommonDefine.h"
#import "RCSemanticContext.h"
#import "RCBaseTableViewCell.h"
#import "RCBaseNavigationController.h"
#import "RCUserInfoCacheManager.h"

@interface RCSightFileBrowserViewController ()

@property (nonatomic, strong) RCMessage *messageModel;
@property (nonatomic, strong) NSMutableArray<RCMessage *> *messageModelArray;

@end

@implementation RCSightFileBrowserViewController
#pragma mark - Life Cycle
- (instancetype)initWithMessageModel:(RCMessage *)model {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.messageModel = model;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 0);
    [self getMessageFromModel:self.messageModel];
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = RCDynamicColor(@"disabled_color", @"0xD3D3D3", @"0xD3D3D3");
    [self.refreshControl addTarget:self action:@selector(refreshAction:) forControlEvents:UIControlEventValueChanged];
    self.tableView.tableFooterView = [UIView new];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = RCLocalizedString(@"ChatFiles");
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messageModelArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *const identifier = @"RCSightFileCell";
    RCBaseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[RCBaseTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    cell.textLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x000000", @"0xffffffe5");
    cell.detailTextLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xD3D3D3", @"0xa0a5ab");
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
    RCMessage *model = self.messageModelArray[indexPath.row];
    RCSightMessage *sightMessage = (RCSightMessage *)model.content;
    UIImage *image = RCDynamicImage(@"video_files_list_icon_img", @"sight_file_icon");
    cell.imageView.image = image;
    cell.textLabel.text = sightMessage.name;
    long long milliseconds = model.messageDirection == MessageDirection_SEND ? model.sentTime : model.receivedTime;

    long long timeSecond = milliseconds / 1000;
    NSString *timeString = [RCKitUtility convertMessageTime:timeSecond];
    NSString *sizeString = sightMessage.size > 1000000
                               ? [NSString stringWithFormat:@"%0.1fM", sightMessage.size / 1024.0f / 1024.0f]
                               : [NSString stringWithFormat:@"%0.1fKB", sightMessage.size / 1024.0f];
    RCUserInfo *userInfo;
    if (self.messageModel.conversationType == ConversationType_GROUP) {
        userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId inGroupId:model.targetId];
        RCUserInfo *tempUserInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId];
        if (userInfo) {
            userInfo.alias = tempUserInfo.alias.length > 0 ? tempUserInfo.alias : userInfo.alias;
        } else {
            userInfo = tempUserInfo;
        }
    } else {
        userInfo = [[RCIM sharedRCIM] getUserInfoCache:model.senderUserId];
    }
    NSString *displayName = [RCKitUtility getDisplayName:userInfo];
    NSString *userName = displayName.length > 20
                             ? [NSString stringWithFormat:@"%@...", [displayName substringToIndex:20]]
                             : displayName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ %@", userName, timeString, sizeString];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RCMessage *model = self.messageModelArray[indexPath.row];
    RCSightSlideViewController *ssv = [[RCSightSlideViewController alloc] init];
    ssv.messageModel = [RCMessageModel modelWithMessage:model];
    ssv.topRightBtnHidden = YES;
    RCBaseNavigationController *navc = [[RCBaseNavigationController alloc] initWithRootViewController:ssv];
    navc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navc animated:YES completion:nil];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat totalHeight = scrollView.contentOffset.y + scrollView.frame.size.height;
    if (totalHeight - scrollView.contentSize.height > 0) {
        NSArray<RCMessage *> *array =
            [self getOlderMessagesThanModel:self.messageModelArray.lastObject count:5 times:0];
        if (array.count > 0) {
            NSMutableArray *indexPathes = [[NSMutableArray alloc] init];
            for (NSUInteger i = self.messageModelArray.count; i < self.messageModelArray.count + array.count; i++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                [indexPathes addObject:indexPath];
            }
            [self.messageModelArray
                insertObjects:array
                    atIndexes:[NSIndexSet
                                  indexSetWithIndexesInRange:NSMakeRange(self.messageModelArray.count, array.count)]];
            [self.tableView insertRowsAtIndexPaths:[indexPathes copy] withRowAnimation:UITableViewRowAnimationMiddle];
        }
    }
}

#pragma mark - Target action

- (void)refreshAction:(UIRefreshControl *)refreshControl {
    [refreshControl endRefreshing];
    NSArray<RCMessage *> *array =
        [self getLaterMessagesThanModel:self.messageModelArray.firstObject count:5 times:0];
    if (array.count > 0) {
        NSMutableArray *indexPathes = [[NSMutableArray alloc] init];
        for (int i = 0; i < array.count; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [indexPathes addObject:indexPath];
        }
        [self.messageModelArray insertObjects:array
                                    atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, array.count)]];
        [self.tableView insertRowsAtIndexPaths:[indexPathes copy] withRowAnimation:UITableViewRowAnimationMiddle];
    }
}

#pragma mark - Private Methods

- (NSArray<RCMessage *> *)getLaterMessagesThanModel:(RCMessage *)model
                                                   count:(NSInteger)count
                                                   times:(int)times {
    NSArray<RCMessage *> *imageArrayBackward =
        [[RCCoreClient sharedCoreClient] getHistoryMessages:model.conversationType
                                                 targetId:model.targetId
                                               objectName:[RCSightMessage getObjectName]
                                            baseMessageId:model.messageId
                                                isForward:false
                                                    count:(int)count];
    NSArray *messages = [self filterDestructSightMessage:imageArrayBackward.reverseObjectEnumerator.allObjects];
    if (times < 2 && messages.count == 0 && imageArrayBackward.count == count) {
        messages = [self getLaterMessagesThanModel:imageArrayBackward.lastObject count:count times:times + 1];
    }
    return messages;
}

- (NSArray<RCMessage *> *)getOlderMessagesThanModel:(RCMessage *)model
                                                   count:(NSInteger)count
                                                   times:(int)times {
    NSArray<RCMessage *> *imageArrayForward =
        [[RCCoreClient sharedCoreClient] getHistoryMessages:model.conversationType
                                                 targetId:model.targetId
                                               objectName:[RCSightMessage getObjectName]
                                            baseMessageId:model.messageId
                                                isForward:true
                                                    count:(int)count];
    NSArray *messages = [self filterDestructSightMessage:imageArrayForward];
    if (times < 2 && imageArrayForward.count == count && messages.count == 0) {
        messages = [self getOlderMessagesThanModel:imageArrayForward.lastObject count:count times:times + 1];
    }
    return messages;
}

//过滤阅后即焚视频消息
- (NSArray *)filterDestructSightMessage:(NSArray *)array {
    NSMutableArray *backwardMessages = [NSMutableArray array];
    for (RCMessage *model in array) {
        if (!(model.content.destructDuration > 0)) {
            [backwardMessages addObject:model];
        }
    }
    return backwardMessages.copy;
}

- (void)getMessageFromModel:(RCMessage *)model {
    if (!model) {
        NSLog(@"Parameters are not allowed to be nil");
        return;
    }
    NSArray<RCMessage *> *frontMessagesArray = [self getLaterMessagesThanModel:model count:10 times:0];
    NSMutableArray *modelsArray = [[NSMutableArray alloc] init];
    [modelsArray addObjectsFromArray:frontMessagesArray];
    [modelsArray addObject:model];
    NSArray<RCMessage *> *backMessageArray = [self getOlderMessagesThanModel:model count:10 times:0];
    [modelsArray addObjectsFromArray:backMessageArray];
    self.messageModelArray = modelsArray;
}
@end
