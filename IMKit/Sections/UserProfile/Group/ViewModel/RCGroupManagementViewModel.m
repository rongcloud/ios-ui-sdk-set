//
//  RCGroupManagementViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/11/25.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupManagementViewModel.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCProfileSwitchCellViewModel.h"
#import "RCProfileCommonCellViewModel.h"
#import "RCProfileCommonSwitchCell.h"
#import "RCGroupManager.h"
#import "RCKitCommonDefine.h"
#import "RCSelectGroupMemberViewController.h"
#import "RCAlertView.h"
#import "RCActionSheetView.h"
#import "RCGroupManagerListController.h"
#import "RCGroupTransferViewController.h"
#import "RCIM.h"
@interface RCGroupManagementViewModel ()<RCGroupEventDelegate>
@property (nonatomic, copy) NSString *groupId;
@property (nonatomic, strong) NSArray<NSArray <RCBaseCellViewModel *>*> *dataSources;
@property (nonatomic, weak) id<RCListViewModelResponder> responder;
@end

@implementation RCGroupManagementViewModel
@dynamic delegate;
+ (instancetype)viewModelWithGroupId:(NSString *)groupId {
    RCGroupManagementViewModel *viewModel = [RCGroupManagementViewModel new];
    viewModel.groupId = groupId;
    [[RCCoreClient sharedCoreClient] addGroupEventDelegate:viewModel];
    return viewModel;
}

- (void)dealloc {
    [[RCCoreClient sharedCoreClient] removeGroupEventDelegate:self];
}

- (void)fetchDataSources {
    if (self.groupId.length == 0) {
        return;
    }
    [[RCCoreClient sharedCoreClient] getGroupsInfo:@[self.groupId] success:^(NSArray<RCGroupInfo *> * _Nonnull groupInfos) {
        if (groupInfos.firstObject && (groupInfos.firstObject.role == RCGroupMemberRoleOwner || groupInfos.firstObject.role == RCGroupMemberRoleManager)) {
            [self reloadDataSources:groupInfos.firstObject];
        }
    } error:^(RCErrorCode errorCode) {
        
    }];
}

- (void)bindResponder:(id<RCListViewModelResponder>)responder {
    self.responder = responder;
}

#pragma mark -- RCGroupEventDelegate

- (void)onGroupInfoChanged:(RCGroupMemberInfo *)operatorInfo groupInfo:(RCGroupInfo *)groupInfo updateKeys:(NSArray<RCGroupInfoKeys> *)updateKeys operationTime:(long long)operationTime {
    if ([groupInfo.groupId isEqualToString:self.groupId]) {
        [self fetchDataSources];
    }
}

- (void)onGroupOperation:(NSString *)groupId operatorInfo:(RCGroupMemberInfo *)operatorInfo groupInfo:(RCGroupInfo *)groupInfo operation:(RCGroupOperation)operation memberInfos:(NSArray<RCGroupMemberInfo *> *)memberInfos operationTime:(long long)operationTime {
    if ([groupId isEqualToString:self.groupId]) {
        [self fetchDataSources];
    }
}

#pragma mark -- RCListViewModelProtocol

- (void)registerCellForTableView:(UITableView *)tableView {
    [RCProfileCommonCellViewModel registerCellForTableView:tableView];
    [tableView registerClass:RCProfileCommonSwitchCell.class forCellReuseIdentifier:RCProfileCommonSwitchCellIdentifier];
}

- (void)viewController:(UIViewController*)viewController
             tableView:(UITableView *)tableView
          didSelectRow:(NSIndexPath *)indexPath {
    RCBaseCellViewModel *cellViewModel = self.dataSources[indexPath.section][indexPath.row];
    if ([self.delegate respondsToSelector:@selector(groupManagement:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate groupManagement:self viewController:[self.responder currentViewController] tableView:tableView didSelectRow:indexPath cellViewModel:cellViewModel];
        if (intercept) {
            return;
        }
    }
    if (![cellViewModel isKindOfClass:RCProfileCommonCellViewModel.class]) {
        return;
    }
    RCProfileCommonCellViewModel *commonCellVM = (RCProfileCommonCellViewModel *)cellViewModel;
    if ([commonCellVM.title isEqualToString:RCLocalizedString(@"GroupManagerTitle")]) {
        RCGroupManagerListViewModel *viewModel = [RCGroupManagerListViewModel viewModelWithGroupId:self.groupId];
        RCGroupManagerListController *vc = [[RCGroupManagerListController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:vc animated:YES];
    } else if ([commonCellVM.title isEqualToString:RCLocalizedString(@"SetGroupInfoEditPer")]) {
        [self setGroupInfoPermission];
    } else if ([commonCellVM.title isEqualToString:RCLocalizedString(@"SetAddGroupMemberPer")]) {
        [self setAddGroupMemberPermission];
    } else if ([commonCellVM.title isEqualToString:RCLocalizedString(@"SetRemoveGroupMemberPer")]) {
        [self setRemoveGroupMemberPermission];
    } else if ([commonCellVM.title isEqualToString:RCLocalizedString(@"SetGroupMemberInfoEditPer")]) {
        [self setGroupMemberInfoPermission];
    } else if ([commonCellVM.title isEqualToString:RCLocalizedString(@"GroupTransfer")]) {
        RCGroupTransferViewModel *viewModel = [RCGroupTransferViewModel viewModelWithGroupId:self.groupId];
        RCGroupTransferViewController *vc = [[RCGroupTransferViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:vc animated:YES];
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

- (void)reloadDataSources:(RCGroupInfo *)group {
    NSMutableArray *list = [NSMutableArray array];
    RCProfileCommonCellViewModel *managerVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"GroupManagerTitle") detail:nil];
    [list addObject:@[managerVM]];
    if (group.role == RCGroupMemberRoleOwner) {
        RCProfileCommonCellViewModel *groupInfoEditPerVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"SetGroupInfoEditPer") detail:[self groupOperationPerStr:group.groupInfoEditPermission]];
        RCProfileCommonCellViewModel *addGroupMemberPerVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"SetAddGroupMemberPer") detail:[self groupOperationPerStr:group.invitePermission]];
        RCProfileCommonCellViewModel *removeGroupMemberPerVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"SetRemoveGroupMemberPer") detail:[self groupOperationPerStr:group.removeMemberPermission]];
        RCProfileCommonCellViewModel *memberInfoEditPerVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"SetGroupMemberInfoEditPer") detail:[self getMemberInfoPerStr:group.memberInfoEditPermission]];
        [list addObject:@[groupInfoEditPerVM, addGroupMemberPerVM, removeGroupMemberPerVM, memberInfoEditPerVM]];
        
        RCProfileSwitchCellViewModel *inviteVM = [RCProfileSwitchCellViewModel new];
        inviteVM.title = RCLocalizedString(@"InviteGroupComfirm");
        inviteVM.switchOn = group.joinPermission == RCGroupJoinPermissionFree ? NO : YES;
        __weak typeof(self) weakSelf = self;
        [inviteVM setSwitchValueChanged:^(BOOL on) {
            [weakSelf updateGroupJoinPermission:on];
        }];
        [list addObject:@[inviteVM]];

        
        RCProfileCommonCellViewModel *groupTransferVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"GroupTransfer") detail:nil];
        [list addObject:@[groupTransferVM]];
    }

    if ([self.delegate respondsToSelector:@selector(groupManagement:willLoadItemsInDataSource:)]) {
        list = [self.delegate groupManagement:self willLoadItemsInDataSource:list].mutableCopy;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dataSources = list;
        [self.responder reloadData:self.dataSources.count == 0];
    });
}

- (void)updateGroupJoinPermission:(BOOL)open {
    RCGroupInfo *group = [RCGroupInfo new];
    group.groupId = self.groupId;
    group.joinPermission = open ? RCGroupJoinPermissionOwnerOrManagerVerify : RCGroupJoinPermissionFree;
    [self updateGroupInfo:group reloadWithFailed:YES];
}

- (NSString *)groupOperationPerStr:(RCGroupOperationPermission)permisson {
    NSArray *permissonStrs = @[RCLocalizedString(@"OnlyGroupOwnerOperation"), RCLocalizedString(@"GroupOwnerOrManagerOperation"), RCLocalizedString(@"AllGroupMemberOperation")];
    return permissonStrs[permisson];
}

- (NSString *)getMemberInfoPerStr:(RCGroupMemberInfoEditPermission)permisson {
    NSArray *permissonStrs = @[RCLocalizedString(@"GroupOwnerOrManagerOperation"),
          RCLocalizedString(@"OnlyGroupOwnerOperation")];
    return permissonStrs[permisson];
}

- (void)setGroupInfoPermission {
    [RCActionSheetView showActionSheetView:nil cellArray:@[RCLocalizedString(@"OnlyGroupOwnerOperation"), RCLocalizedString(@"GroupOwnerOrManagerOperation"), RCLocalizedString(@"AllGroupMemberOperation")] cancelTitle:RCLocalizedString(@"Cancel") selectedBlock:^(NSInteger index) {
        RCGroupInfo *group = [RCGroupInfo new];
        group.groupId = self.groupId;
        group.groupInfoEditPermission = index;
        [self updateGroupInfo:group reloadWithFailed:NO];
    } cancelBlock:^{
        
    }];
}

- (void)setAddGroupMemberPermission {
    [RCActionSheetView showActionSheetView:nil cellArray:@[RCLocalizedString(@"OnlyGroupOwnerOperation"), RCLocalizedString(@"GroupOwnerOrManagerOperation"), RCLocalizedString(@"AllGroupMemberOperation")] cancelTitle:RCLocalizedString(@"Cancel") selectedBlock:^(NSInteger index) {
        RCGroupInfo *group = [RCGroupInfo new];
        group.groupId = self.groupId;
        group.invitePermission = index;
        [self updateGroupInfo:group reloadWithFailed:NO];
    } cancelBlock:^{
        
    }];
}

- (void)setRemoveGroupMemberPermission {
    [RCActionSheetView showActionSheetView:nil cellArray:@[RCLocalizedString(@"OnlyGroupOwnerOperation"), RCLocalizedString(@"GroupOwnerOrManagerOperation"), RCLocalizedString(@"AllGroupMemberOperation")] cancelTitle:RCLocalizedString(@"Cancel") selectedBlock:^(NSInteger index) {
        RCGroupInfo *group = [RCGroupInfo new];
        group.groupId = self.groupId;
        group.removeMemberPermission = index;
        [self updateGroupInfo:group reloadWithFailed:NO];
    } cancelBlock:^{
        
    }];
}

- (void)setGroupMemberInfoPermission {
    [RCActionSheetView showActionSheetView:nil cellArray:@[RCLocalizedString(@"OnlyGroupOwnerOperation"), RCLocalizedString(@"GroupOwnerOrManagerOperation")] cancelTitle:RCLocalizedString(@"Cancel") selectedBlock:^(NSInteger index) {
        RCGroupInfo *group = [RCGroupInfo new];
        group.groupId = self.groupId;
        group.memberInfoEditPermission = (index == 0 ? RCGroupMemberInfoEditPermissionOwnerOrSelf : RCGroupMemberInfoEditPermissionOwnerOrManagerOrSelf);
        [self updateGroupInfo:group reloadWithFailed:NO];
    } cancelBlock:^{
        
    }];
}

- (void)updateGroupInfo:(RCGroupInfo *)group reloadWithFailed:(BOOL)reloadWithFailed{
    UIViewController *viewController = nil;
    if ([self.responder respondsToSelector:@selector(currentViewController)]) {
        viewController = [self.responder currentViewController];
    }
    [self loadingWithTip:RCLocalizedString(@"Saving")];
    [[RCIM sharedRCIM] updateGroupInfo:group
                          successBlock:^{
        [self stopLoading];
        [self fetchDataSources];
        dispatch_async(dispatch_get_main_queue(), ^{
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"SetSuccess") hiddenAfterDelay:1];
        });
    } errorBlock:^(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys) {
        [self stopLoading];
        if (reloadWithFailed) {
            [self fetchDataSources];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *tips = RCLocalizedString(@"SetFailed");
            if (errorCode == RC_SERVICE_INFORMATION_AUDIT_FAILED) {
                tips = RCLocalizedString(@"Content_Contains_Sensitive");
            }
            [RCAlertView showAlertController:nil message:tips hiddenAfterDelay:1];
        });
    }];
}
@end
