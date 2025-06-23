//
//  RCGroupManagersViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/11/25.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupManagerListViewModel.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCGroupFollowCellViewModel.h"
#import "RCProfileCommonCellViewModel.h"
#import "RCGroupManager.h"
#import "RCKitCommonDefine.h"
#import "RCSelectGroupMemberViewController.h"
#import "RCAlertView.h"
@interface RCGroupManagerListViewModel ()<RCGroupFollowCellViewModelDelegate, RCGroupEventDelegate>
@property (nonatomic, copy) NSString *groupId;
@property (nonatomic, strong) NSArray <NSArray <RCBaseCellViewModel *>*> *dataSources;
@property (nonatomic, strong) NSArray *managerIdList;
@property (nonatomic, weak) id<RCListViewModelResponder> responder;
@end

@implementation RCGroupManagerListViewModel
@dynamic delegate;
+ (instancetype)viewModelWithGroupId:(NSString *)groupId {
    RCGroupManagerListViewModel *viewModel = [RCGroupManagerListViewModel new];
    viewModel.groupId = groupId;
    [[RCCoreClient sharedCoreClient] addGroupEventDelegate:viewModel];
    return viewModel;
}

- (void)dealloc {
    [[RCCoreClient sharedCoreClient] removeGroupEventDelegate:self];
}

- (void)fetchGroupManagers {
    RCPagingQueryOption *option = [RCPagingQueryOption new];
    option.count = 100;
    option.order = YES;
    [[RCCoreClient sharedCoreClient] getGroupMembersByRole:self.groupId role:(RCGroupMemberRoleManager) option:option success:^(RCPagingQueryResult<RCGroupMemberInfo *> * _Nonnull result) {
        [self reloadGroupMemberData:result.data];
    } error:^(RCErrorCode errorCode) {
        
    }];
}

- (void)bindResponder:(id<RCListViewModelResponder>)responder {
    self.responder = responder;
}

#pragma mark -- RCGroupEventDelegate

- (void)onGroupOperation:(NSString *)groupId operatorInfo:(RCGroupMemberInfo *)operatorInfo groupInfo:(RCGroupInfo *)groupInfo operation:(RCGroupOperation)operation memberInfos:(NSArray<RCGroupMemberInfo *> *)memberInfos operationTime:(long long)operationTime {
    if ([groupId isEqualToString:self.groupId]) {
        [self fetchGroupManagers];
    }
}


#pragma mark -- RCGroupFollowCellViewModelDelegate

- (void)actionButtonDidClick:(RCGroupFollowCellViewModel *)cellViewModel {
    if ([self.delegate respondsToSelector:@selector(groupManagersWillRemove:removeUserIds:viewController:)]) {
        BOOL intercept = [self.delegate groupManagersWillRemove:self.groupId removeUserIds:@[cellViewModel.memberInfo.userId] viewController:[self.responder currentViewController]];
        if (intercept) {
            return;
        }
    }
    NSString *name;
    if (cellViewModel.remark.length > 0) {
        name = cellViewModel.remark;
    } else if (cellViewModel.memberInfo.nickname.length > 0) {
        name = cellViewModel.memberInfo.nickname;
    } else {
        name = cellViewModel.memberInfo.name;
    }
    NSString *message = [NSString stringWithFormat:RCLocalizedString(@"RemoveGroupManagersAlert"),name];
    [RCAlertView showAlertController:nil message:message actionTitles:nil cancelTitle:RCLocalizedString(@"Cancel") confirmTitle:RCLocalizedString(@"Confirm") preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:^{
        [[RCCoreClient sharedCoreClient] removeGroupManagers:self.groupId userIds:@[cellViewModel.memberInfo.userId ? : @""] success:^{
            [self fetchGroupManagers];
            if ([self.delegate respondsToSelector:@selector(groupManagersDidRemove:removeUserIds:viewController:)]) {
                BOOL intercept = [self.delegate groupManagersDidRemove:self.groupId removeUserIds:@[cellViewModel.memberInfo.userId] viewController:[self.responder currentViewController]];
                if (intercept) {
                    return;
                }
            }
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
    RCBaseCellViewModel *cellViewModel = self.dataSources[indexPath.section][indexPath.row];
    if ([self.delegate respondsToSelector:@selector(groupManagers:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate groupManagers:self viewController:[self.responder currentViewController] tableView:tableView didSelectRow:indexPath cellViewModel:cellViewModel];
        if (intercept) {
            return;
        }
    }
    if (![cellViewModel isKindOfClass:RCProfileCommonCellViewModel.class]) {
        return;
    }
    RCProfileCommonCellViewModel *commonCellVM = (RCProfileCommonCellViewModel *)cellViewModel;
    if ([commonCellVM.title isEqualToString:RCLocalizedString(@"AddGroupManagers")]) {
        [self pushSelectVC:viewController];
    }
}

- (NSInteger)numberOfSections {
    return self.dataSources.count;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    return self.dataSources[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dataSources[indexPath.section][indexPath.row] tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dataSources[indexPath.section][indexPath.row] tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark -- private
- (void)reloadGroupMemberData:(NSArray *)members {
    if (members.count == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataSources = nil;
            [self.responder reloadData:YES];
        });
    }
    NSMutableArray *idList = [NSMutableArray new];
    for (RCGroupMemberInfo *member in members) {
        if (member.userId) {
            [idList addObject:member.userId];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.managerIdList = idList.copy;
    });
    [[RCCoreClient sharedCoreClient] getFriendsInfo:idList success:^(NSArray<RCFriendInfo *> * _Nonnull friendInfos) {
        [self reloadDataSources:members friends:friendInfos];
    } error:^(RCErrorCode errorCode) {
        [self reloadDataSources:members friends:nil];
    }];
}
   
- (void)reloadDataSources:(NSArray *)members friends:(NSArray *)friends {
    [[RCCoreClient sharedCoreClient] getGroupsInfo:@[self.groupId] success:^(NSArray<RCGroupInfo *> * _Nonnull groupInfos) {
        NSMutableArray *managerslist = [NSMutableArray array];
        for (RCGroupMemberInfo *member in members) {
            RCGroupFollowCellViewModel *cellVM = [[RCGroupFollowCellViewModel alloc] initWithMember:member];
            cellVM.delegate = self;
            cellVM.hiddenButton = (groupInfos.firstObject.role == RCGroupMemberRoleOwner ? NO : YES);
            if (friends.count > 0) {
                cellVM.remark = [RCGroupManager friendWithUserId:member.userId inFriendInfos:friends].remark;
            }
            [managerslist addObject:cellVM];
        }
        NSMutableArray *addList = [NSMutableArray array];
        if (groupInfos.firstObject.role == RCGroupMemberRoleOwner) {
            RCProfileCommonCellViewModel *addVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"AddGroupManagers") detail:nil];
            [addList addObject:addVM];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (addList.count > 0) {
                self.dataSources = @[addList, managerslist];
            } else {
                self.dataSources = @[managerslist];
            }
            [self.responder reloadData:managerslist.count == 0];
        });
    } error:^(RCErrorCode errorCode) {
        
    }];
    
}

- (void)pushSelectVC:(UIViewController *)viewController {
    RCSelectGroupMemberViewModel *viewModel = [RCSelectGroupMemberViewModel viewModelWithGroupId:self.groupId existingUserIds:self.managerIdList];
    viewModel.hideUserIds = @[[RCCoreClient sharedCoreClient].currentUserInfo.userId];
    NSInteger maxManagerLimit = 10;
    viewModel.maxSelectCount = 10 - self.managerIdList.count;
    viewModel.tip = [NSString stringWithFormat:RCLocalizedString(@"GroupMemberSelectMaxTip"), @(maxManagerLimit)];
    __weak typeof(self) weakSelf = self;
    [viewModel setSelectionDidCompelteBlock:^(NSArray<NSString *> * _Nonnull selectUserIds, UIViewController * _Nonnull selectVC) {
        [[RCCoreClient sharedCoreClient] addGroupManagers:weakSelf.groupId userIds:selectUserIds success:^{
            [self fetchGroupManagers];
            if ([self.delegate respondsToSelector:@selector(groupManagersDidAdd:addUserIds:viewController:)]) {
                BOOL intercept = [self.delegate groupManagersDidAdd:self.groupId addUserIds:selectUserIds viewController:[self.responder currentViewController]];
                if (intercept) {
                    return;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [selectVC.navigationController popViewControllerAnimated:YES];
                [RCAlertView showAlertController:nil message:RCLocalizedString(@"AddSuccess") hiddenAfterDelay:1];
            });
        } error:^(RCErrorCode errorCode) {
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"AddFailed") hiddenAfterDelay:1];
        }];
    }];
    RCSelectGroupMemberViewController *vc = [[RCSelectGroupMemberViewController alloc] initWithViewModel:viewModel];
    vc.title = RCLocalizedString(@"SelectGroupMemberVCTitle");
    [viewController.navigationController pushViewController:vc animated:YES];
}

- (void)getNamesString:(NSArray *)userIds complete:(void(^)(NSString *names))complete {
    [[RCCoreClient sharedCoreClient] getGroupMembers:self.groupId userIds:userIds success:^(NSArray<RCGroupMemberInfo *> * _Nonnull groupMembers) {
        [[RCCoreClient sharedCoreClient] getFriendsInfo:userIds success:^(NSArray<RCFriendInfo *> * _Nonnull friendInfos) {
            NSMutableArray *names = [NSMutableArray array];
            for (RCGroupMemberInfo *member in groupMembers) {
                NSString *name = [RCGroupManager friendWithUserId:member.userId inFriendInfos:friendInfos].remark;
                if (name.length > 0) {
                    [names addObject:name];
                    continue;
                }
                if (member.nickname.length > 0) {
                    name = member.nickname;
                } else if (member.name.length > 0) {
                    name = member.name;
                } else {
                    name = member.userId;
                }
                [names addObject:name];
            }
            NSString *separator = @"、"; // 指定的分隔符
            NSString *namesStr = [names componentsJoinedByString:separator];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complete) {
                    complete(namesStr);
                }
            });
        } error:^(RCErrorCode errorCode) {
            
        }];
    } error:^(RCErrorCode errorCode) {
        
    }];
}
@end
