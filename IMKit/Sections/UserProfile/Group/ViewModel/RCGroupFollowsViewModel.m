//
//  RCGroupFollowsViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/11/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupFollowsViewModel.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCGroupFollowCellViewModel.h"
#import "RCProfileCommonCellViewModel.h"
#import "RCGroupManager.h"
#import "RCKitCommonDefine.h"
#import "RCSelectGroupMemberViewController.h"
#import "RCAlertView.h"
@interface RCGroupFollowsViewModel ()<RCGroupFollowCellViewModelDelegate, RCGroupEventDelegate>
@property (nonatomic, copy) NSString *groupId;
@property (nonatomic, strong) NSMutableArray <RCBaseCellViewModel *>*mutableFollowList;
@property (nonatomic, strong) NSMutableArray *followUserIds;
@property (nonatomic, weak) id<RCListViewModelResponder> responder;
@end

@implementation RCGroupFollowsViewModel
+ (instancetype)viewModelWithGroupId:(NSString *)groupId {
    RCGroupFollowsViewModel *viewModel = [RCGroupFollowsViewModel new];
    viewModel.groupId = groupId;
    [[RCCoreClient sharedCoreClient] addGroupEventDelegate:viewModel];
    return viewModel;
}

- (void)dealloc {
    [[RCCoreClient sharedCoreClient] removeGroupEventDelegate:self];
}

- (void)fetchGroupFollows {
    [[RCCoreClient sharedCoreClient] getGroupFollows:self.groupId success:^(NSArray<RCFollowInfo *> * _Nonnull followInfos) {
        self.followUserIds = nil;
        if (followInfos.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self resetMutableFollowList];
                [self.responder reloadData:YES];
            });
            return;
        }
        NSMutableArray *userIds = [NSMutableArray array];
        for (RCFollowInfo *info in followInfos) {
            if (info.userId) {
                [userIds addObject:info.userId];
            }
        }
        self.followUserIds = userIds;
        [self getDetailInfo:^(NSArray<RCGroupFollowCellViewModel *> *cellVMs) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self resetMutableFollowList];
                [self.mutableFollowList addObjectsFromArray:cellVMs];
                [self.responder reloadData:self.mutableFollowList.count == 1];
            });
        }];
    } error:^(RCErrorCode errorCode) {
        
    }];
}

- (void)bindResponder:(id<RCListViewModelResponder>)responder {
    self.responder = responder;
}

#pragma mark -- RCGroupEventDelegate

- (void)onGroupFollowsChangedSync:(NSString *)groupId
                    operationType:(RCGroupOperationType)operationType
                          userIds:(NSArray<NSString *> *)userIds
                    operationTime:(long long)operationTime {
    if ([groupId isEqualToString:self.groupId]) {
        [self fetchGroupFollows];
    }
}


#pragma mark -- RCGroupFollowCellViewModelDelegate

- (void)actionButtonDidClick:(RCGroupFollowCellViewModel *)cellViewModel {
    NSString *name;
    if (cellViewModel.remark.length > 0) {
        name = cellViewModel.remark;
    } else if (cellViewModel.memberInfo.nickname.length > 0) {
        name = cellViewModel.memberInfo.nickname;
    } else {
        name = cellViewModel.memberInfo.name;
    }
    NSString *message = [NSString stringWithFormat:RCLocalizedString(@"RemoveGroupFollowsAlert"),name];
    [RCAlertView showAlertController:nil message:message actionTitles:nil cancelTitle:RCLocalizedString(@"Cancel") confirmTitle:RCLocalizedString(@"Confirm") preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:^{
        [[RCCoreClient sharedCoreClient] removeGroupFollows:self.groupId userIds:@[cellViewModel.memberInfo.userId ? : @""] success:^{
            [self fetchGroupFollows];
            dispatch_async(dispatch_get_main_queue(), ^{
                [RCAlertView showAlertController:nil message:RCLocalizedString(@"RemoveSuccess") hiddenAfterDelay:1];
            });
        } error:^(RCErrorCode errorCode) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [RCAlertView showAlertController:nil message:RCLocalizedString(@"RemoveFailed") hiddenAfterDelay:1];
            });
        }];
    } inViewController:[self.responder currentViewController]];
}

#pragma mark -- RCListViewModelProtocol

- (void)registerCellForTableView:(UITableView *)tableView {
    [RCProfileCommonCellViewModel registerCellForTableView:tableView];
    [RCGroupFollowCellViewModel registerCellForTableView:tableView];
}

- (void)viewController:(UIViewController*)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        [self pushSelectVC:viewController];
    }
}

- (NSInteger)numberOfSections {
    return 1;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    return self.mutableFollowList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.mutableFollowList[indexPath.row] tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.mutableFollowList[indexPath.row] tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark -- private
- (void)getDetailInfo:(void (^)(NSArray <RCGroupFollowCellViewModel *> *cellVMs))complete {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *mutableCellVMs = [NSMutableArray array];
        for (int i = 0; i < self.followUserIds.count; i+=100) {
            NSArray *tempUserIds = [self.followUserIds subarrayWithRange:NSMakeRange(i, MIN(100, self.followUserIds.count - i))];
            [mutableCellVMs addObjectsFromArray:[self getFollowsCellViewModels:tempUserIds]];
        }
        complete(mutableCellVMs);
    });
}

- (NSArray <RCGroupFollowCellViewModel *> *)getFollowsCellViewModels:(NSArray *)userIds {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0); // 创建信号量
    __block NSMutableArray *list = [NSMutableArray array];
    // 异步获取群组成员
    [[RCCoreClient sharedCoreClient] getGroupMembers:self.groupId userIds:userIds success:^(NSArray<RCGroupMemberInfo *> * _Nonnull members) {
        // 异步获取朋友信息
        [[RCCoreClient sharedCoreClient] getFriendsInfo:userIds success:^(NSArray<RCFriendInfo *> * _Nonnull friendInfos) {
            [list addObjectsFromArray:[self processMembers:members withFriendInfos:friendInfos]];
            dispatch_semaphore_signal(semaphore); // 释放信号量
        } error:^(RCErrorCode errorCode) {
            // 如果获取朋友信息失败，仍然处理成员
            [list addObjectsFromArray:[self processMembers:members withFriendInfos:nil]];
            dispatch_semaphore_signal(semaphore); // 释放信号量
        }];
        
    } error:^(RCErrorCode errorCode) {
        // 如果获取群组成员失败，直接释放信号量
        dispatch_semaphore_signal(semaphore); // 释放信号量
    }];
    
    // 等待信号量
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return list;
}

- (NSArray <RCGroupFollowCellViewModel *> *)processMembers:(NSArray<RCGroupMemberInfo *> *)members withFriendInfos:(NSArray<RCFriendInfo *> *)friendInfos{
    NSMutableArray *list = [NSMutableArray array];
    for (RCGroupMemberInfo *member in members) {
        RCGroupFollowCellViewModel *cellVM = [[RCGroupFollowCellViewModel alloc] initWithMember:member];
        cellVM.delegate = self;
        if (friendInfos.count > 0) {
            cellVM.remark = [RCGroupManager friendWithUserId:member.userId inFriendInfos:friendInfos].remark;
        }
        [list addObject:cellVM];
    }
    return list;
}

- (void)resetMutableFollowList {
    self.mutableFollowList = [NSMutableArray array];
    RCProfileCommonCellViewModel *addVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"AddFollowsMember") detail:nil];
    [self.mutableFollowList addObject:addVM];
}

- (void)pushSelectVC:(UIViewController *)viewController {
    RCSelectGroupMemberViewModel *viewModel = [RCSelectGroupMemberViewModel viewModelWithGroupId:self.groupId existingUserIds:self.followUserIds];
    viewModel.hideUserIds = @[[RCCoreClient sharedCoreClient].currentUserInfo.userId];
    viewModel.maxSelectCount = 100;
    __weak typeof(self) weakSelf = self;
    [viewModel setSelectionDidCompelteBlock:^(NSArray<NSString *> * _Nonnull selectUserIds, UIViewController * _Nonnull selectVC) {
        [[RCCoreClient sharedCoreClient] addGroupFollows:weakSelf.groupId userIds:selectUserIds success:^{
            [weakSelf fetchGroupFollows];
            dispatch_async(dispatch_get_main_queue(), ^{
                [selectVC.navigationController popViewControllerAnimated:YES];
                [RCAlertView showAlertController:nil message:RCLocalizedString(@"AddSuccess") hiddenAfterDelay:1];
            });
        } error:^(RCErrorCode errorCode) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [RCAlertView showAlertController:nil message:RCLocalizedString(@"AddFailed") hiddenAfterDelay:1];
            });
        }];
    }];
    RCSelectGroupMemberViewController *vc = [[RCSelectGroupMemberViewController alloc] initWithViewModel:viewModel];
    vc.title = RCLocalizedString(@"SelectGroupMemberVCTitle");
    [viewController.navigationController pushViewController:vc animated:YES];
}
@end
