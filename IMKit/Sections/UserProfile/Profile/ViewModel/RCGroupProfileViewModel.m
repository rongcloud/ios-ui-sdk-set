//
//  RCGroupProfileViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupProfileViewModel.h"
#import "RCProfileCommonCellViewModel.h"
#import "RCProfileCommonTextCell.h"
#import "RCProfileCommonImageCell.h"
#import "RCGroupProfileMembersCell.h"
#import "RCGroupProfileMembersCellViewModel.h"
#import "RCGroupMembersCollectionViewModel.h"
#import "RCNameEditViewController.h"
#import "RCGroupMemberListViewController.h"
#import "RCGroupManager.h"
#import "RCGroupNoticeViewController.h"
#import "RCProfileCommonSwitchCell.h"
#import "RCProfileSwitchCellViewModel.h"
#import "RCProfileViewModel+private.h"
#import "RCKitCommonDefine.h"
#import "RCAlertView.h"
#import "RCGroupFollowsViewController.h"
#import "RCGroupManagementViewController.h"
#import "RCInfoManagement.h"
#import "RCGroup+RCExtented.h"
@interface RCGroupProfileViewModel ()<RCGroupEventDelegate, RCConversationStatusChangeDelegate>

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, strong) RCGroupProfileMembersCellViewModel *membersViewModel;

@property (nonatomic, strong) RCGroupInfo *group;

@property (nonatomic, assign) BOOL showGroupFollowsCell;

@end

@implementation RCGroupProfileViewModel
+ (instancetype)viewModelWithGroupId:(NSString *)groupId {
    RCGroupProfileViewModel *viewModel = [[self.class alloc] init];
    viewModel.groupId = groupId;
    return viewModel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.displayMaxMemberCount = 30;
        [[RCCoreClient sharedCoreClient] addGroupEventDelegate:self];
        [[RCCoreClient sharedCoreClient] setRCConversationStatusChangeDelegate:self];
    }
    return self;
}

- (void)dealloc {
    [[RCCoreClient sharedCoreClient] removeGroupEventDelegate:self];
}

- (void)updateProfile {
    if (self.groupId.length == 0) {
        return;
    }
    
    [self fetchGroupInfo];
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[RCProfileCommonTextCell class]
      forCellReuseIdentifier:RCUProfileTextCellIdentifier];
    [tableView registerClass:[RCProfileCommonImageCell class]
      forCellReuseIdentifier:RCUProfileImageCellIdentifier];
    [tableView registerClass:[RCGroupProfileMembersCell class]
      forCellReuseIdentifier:RCGroupProfileMembersCellIdentifier];
    [tableView registerClass:[RCProfileCommonSwitchCell class]
      forCellReuseIdentifier:RCProfileCommonSwitchCellIdentifier];
}

- (void)viewController:(UIViewController *)viewController tableView:(UITableView *)tableView didSelectRow:(NSIndexPath *)indexPath {
    RCProfileCellViewModel *cellViewModel = self.profileList[indexPath.section][indexPath.row];
    
    if ([self.delegate respondsToSelector:@selector(profileViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate profileViewModel:self viewController:[self.responder currentViewController] tableView:tableView didSelectRow:indexPath cellViewModel:cellViewModel];
        if (intercept) {
            return;
        }
    }
    
    if (![cellViewModel isKindOfClass:RCProfileCommonCellViewModel.class]) {
        return;
    }
    RCProfileCommonCellViewModel *commonCellViewModel = (RCProfileCommonCellViewModel *)cellViewModel;
    if ([commonCellViewModel.title isEqualToString:RCLocalizedString(@"GroupNameTitle")]) {
        if (![self canEditProfile]) {
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"NoEditGroupPermission") hiddenAfterDelay:1];
            return;
        }
        RCNameEditViewModel *viewModel = [RCNameEditViewModel viewModelWithUserId:[RCCoreClient sharedCoreClient].currentUserInfo.userId groupId:self.groupId type:RCNameEditTypeGroupName];
        RCNameEditViewController *nameEditVC = [[RCNameEditViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:nameEditVC animated:YES];
    } else if ([commonCellViewModel.title isEqualToString:RCLocalizedString(@"GroupForMyName")]) {
        RCNameEditViewModel *viewModel = [RCNameEditViewModel viewModelWithUserId:[RCCoreClient sharedCoreClient].currentUserInfo.userId groupId:self.groupId type:RCNameEditTypeGroupMemberNickname];
        RCNameEditViewController *nameEditVC = [[RCNameEditViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:nameEditVC animated:YES];
    } else if ([commonCellViewModel.title hasPrefix:RCLocalizedString(@"GroupMembers")]) {
        RCGroupMemberListViewModel *viewModel = [RCGroupMemberListViewModel viewModelWithGroupId:self.groupId];
        RCGroupMemberListViewController *membersVC = [[RCGroupMemberListViewController alloc] initWithViewModel:viewModel];
        membersVC.title = commonCellViewModel.title;
        [viewController.navigationController pushViewController:membersVC animated:YES];
    } else if ([commonCellViewModel.title isEqualToString:RCLocalizedString(@"GroupNotice")]) {
        RCGroupNoticeViewModel *viewModel = [[RCGroupNoticeViewModel alloc] initWithGroup:self.group];
        RCGroupNoticeViewController *membersVC = [[RCGroupNoticeViewController alloc] initWithViewModel:viewModel];
        membersVC.title = commonCellViewModel.title;
        [viewController.navigationController pushViewController:membersVC animated:YES];
    } else if ([commonCellViewModel.title hasSuffix:RCLocalizedString(@"GroupFollowsCellTitle")]) {
        RCGroupFollowsViewModel *viewModel = [RCGroupFollowsViewModel viewModelWithGroupId:self.groupId];
        RCGroupFollowsViewController *vc = [[RCGroupFollowsViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:vc animated:YES];
    } else if ([commonCellViewModel.title isEqualToString:RCLocalizedString(@"GroupRemark")]) {
        RCNameEditViewModel *viewModel = [RCNameEditViewModel viewModelWithUserId:[RCCoreClient sharedCoreClient].currentUserInfo.userId groupId:self.groupId type:RCNameEditTypeGroupRemark];
        RCNameEditViewController *nameEditVC = [[RCNameEditViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:nameEditVC animated:YES];
    } else if ([commonCellViewModel.title isEqualToString:RCLocalizedString(@"GroupManagement")]) {
        RCGroupManagementViewModel *viewModel = [RCGroupManagementViewModel viewModelWithGroupId:self.groupId];
        RCGroupManagementViewController *vc = [[RCGroupManagementViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark -- RCConversationStatusChangeDelegate

- (void)conversationStatusDidChange:(NSArray<RCConversationStatusInfo *> *)conversationStatusInfos {
    [self updateProfile];
}

#pragma mark -- RCGroupEventDelegate
- (void)onGroupInfoChanged:(RCGroupMemberInfo *)operatorInfo groupInfo:(RCGroupInfo *)groupInfo updateKeys:(NSArray<RCGroupInfoKeys> *)updateKeys operationTime:(long long)operationTime {
    if ([groupInfo.groupId isEqualToString:self.groupId]) {
        [self updateProfile];
    }
}

- (void)onGroupOperation:(NSString *)groupId operatorInfo:(RCGroupMemberInfo *)operatorInfo groupInfo:(RCGroupInfo *)groupInfo operation:(RCGroupOperation)operation memberInfos:(NSArray<RCGroupMemberInfo *> *)memberInfos operationTime:(long long)operationTime {
    if ([groupId isEqualToString:self.groupId]) {
        [self updateProfile];
    }
}

#pragma mark -- private

- (void)fetchGroupInfo {
    [[RCCoreClient sharedCoreClient] getGroupsInfo:@[self.groupId] success:^(NSArray<RCGroupInfo *> * _Nonnull groupInfos) {
        self.group = groupInfos.firstObject;
        [self reloadDataSource:self.group];
        [self fetchMembers:self.group];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder updateTitle:[NSString stringWithFormat: RCLocalizedString(@"GroupProfileTitle%@"),@(self.group.membersCount)]];
        });
    } error:^(RCErrorCode errorCode) {
        
    }];
}

- (void)fetchMembers:(RCGroupInfo *)group {
    RCPagingQueryOption *option = [RCPagingQueryOption new];
    option.count = self.displayMaxMemberCount;
    option.order = YES;
    __weak typeof(self) weakSelf = self;
    [RCGroupManager getGroupMembers:self.groupId option:option role:RCGroupMemberRoleUndef complete:^(RCPagingQueryResult<RCGroupMemberInfo *> * _Nonnull result) {
        if (!result) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            RCGroupMembersCollectionViewModel *membersViewModel = [RCGroupMembersCollectionViewModel viewModelWithGroupId:weakSelf.groupId members:result.data allowAdd:[weakSelf showAdd:group] allowRemove:[weakSelf showRemove:group] inViewController:[weakSelf.responder currentViewController]];
            [weakSelf.membersViewModel configViewModel:membersViewModel];
            [weakSelf.responder reloadData:NO];
        });
    }];
}

- (void)reloadDataSource:(RCGroupInfo *)group {
    if (group.groupId.length == 0) {
        group.groupId = self.groupId;
    }
    
    RCProfileCommonCellViewModel *memberVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:[NSString stringWithFormat: RCLocalizedString(@"GroupMembersWithCount"), @(group.membersCount)] detail:nil];
    memberVM.hiddenSeparatorLine = YES;
    
    self.membersViewModel = [[RCGroupProfileMembersCellViewModel alloc] initWithItemCount:[self showItemCount:group]];
    
    RCProfileCommonCellViewModel *portraitVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeImage title:RCLocalizedString(@"GroupPortrait") detail:group.portraitUri];
    portraitVM.hiddenArrow = YES;
    portraitVM.conversationType = ConversationType_GROUP;
    RCProfileCommonCellViewModel *nameVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"GroupNameTitle") detail:group.groupName];
    RCProfileCommonCellViewModel *noticeVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"GroupNotice") detail:nil];
    RCProfileCommonCellViewModel *memberNameVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"GroupForMyName") detail:nil];
    [self showMyNameInGroup:memberNameVM];
    RCProfileCommonCellViewModel *groupRemarkVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"GroupRemark") detail:group.remark];
    
    RCProfileSwitchCellViewModel *disturbVM = [self disturbVM];
    RCProfileSwitchCellViewModel *topVM = [self topVM];
    
    NSMutableArray *switchVMList = [NSMutableArray array];
    [switchVMList addObject:disturbVM];
    if (self.showGroupFollowsCell) {
        RCProfileCommonCellViewModel *followsVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:[NSString stringWithFormat:@"    %@", RCLocalizedString(@"GroupFollowsCellTitle")] detail:nil];
        [switchVMList addObject:followsVM];
    }
    [switchVMList addObject:topVM];
    
    NSArray *list = @[
    @[memberVM, self.membersViewModel],
    @[portraitVM, nameVM, noticeVM, memberNameVM, groupRemarkVM],
    switchVMList
    ];
    
    if (group.role == RCGroupMemberRoleOwner || group.role == RCGroupMemberRoleManager) {
        RCProfileCommonCellViewModel *managementVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"GroupManagement") detail:nil];
        list = @[
        @[memberVM, self.membersViewModel],
        @[portraitVM, nameVM, noticeVM, memberNameVM, groupRemarkVM],
        @[managementVM],
        switchVMList
        ];
    }
    
    RCProfileFooterViewType type = RCProfileFooterViewTypeGroupMember;
    if ([group.ownerId isEqualToString:[RCCoreClient sharedCoreClient].currentUserInfo.userId]) {
       type = RCProfileFooterViewTypeGroupOwner;
    }
    
    [self configFooterViewModel:[[RCProfileFooterViewModel alloc] initWithResponder:[self.responder currentViewController] type:type targetId:self.groupId]];
        
    dispatch_async(dispatch_get_main_queue(), ^{
        self.profileList = list;
        [self.responder reloadData:NO];
    });
}

- (void)showMyNameInGroup:(RCProfileCommonCellViewModel *)memberNameVM {
    [[RCCoreClient sharedCoreClient] getGroupMembers:self.groupId userIds:@[[RCCoreClient sharedCoreClient].currentUserInfo.userId ? : @""] success:^(NSArray<RCGroupMemberInfo *> * _Nonnull groupMembers) {
        memberNameVM.detail = groupMembers.firstObject.nickname;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder reloadData:NO];
        });
    } error:^(RCErrorCode errorCode) {

    }];
}

- (RCProfileSwitchCellViewModel *)topVM {
    RCProfileSwitchCellViewModel *topVM = [RCProfileSwitchCellViewModel new];
    topVM.title = RCLocalizedString(@"SetTop");
    RCConversationIdentifier * con = [[RCConversationIdentifier alloc] initWithConversationIdentifier:ConversationType_GROUP targetId:self.groupId];
    [[RCCoreClient sharedCoreClient] getConversationTopStatus:con completion:^(BOOL ret) {
        dispatch_async(dispatch_get_main_queue(), ^{
            topVM.switchOn = ret;
            [self.responder reloadData:NO];
        });
    }];
    __weak typeof(self) weakSelf = self;
    topVM.switchValueChanged = ^(BOOL on) {
        [[RCCoreClient sharedCoreClient] setConversationToTop:ConversationType_GROUP targetId:weakSelf.groupId isTop:on completion:^(BOOL ret) {
            
        }];
    };
    return topVM;
}

- (RCProfileSwitchCellViewModel *)disturbVM {
    RCProfileSwitchCellViewModel *disturbVM = [RCProfileSwitchCellViewModel new];
    disturbVM.title = RCLocalizedString(@"SetNotDisturb");
    [[RCCoreClient sharedCoreClient] getConversationNotificationStatus:ConversationType_GROUP targetId:self.groupId success:^(RCConversationNotificationStatus nStatus) {
        dispatch_async(dispatch_get_main_queue(), ^{
            disturbVM.switchOn = !nStatus;
            [self showGroupFollows:disturbVM.switchOn];
            [self.responder reloadData:NO];
        });
    }  error:^(RCErrorCode status){
        
    }];
    __weak typeof(self) weakSelf = self;
    disturbVM.switchValueChanged = ^(BOOL on) {
        [[RCChannelClient sharedChannelManager] setConversationChannelNotificationLevel:ConversationType_GROUP targetId:weakSelf.groupId channelId:nil level:(on ? RCPushNotificationLevelBlocked : RCPushNotificationLevelAllMessage) success:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf showGroupFollows:on];
            });
        } error:^(RCErrorCode status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.responder reloadData:NO];
            });
        }];
    };
    return disturbVM;
}

- (void)showGroupFollows:(BOOL)show {
    if (self.showGroupFollowsCell != show) {
        self.showGroupFollowsCell = show;
        [self reloadDataSource:self.group];
    }
}

- (NSInteger)showItemCount:(RCGroupInfo *)group {
    NSInteger count = (group.membersCount <= self.displayMaxMemberCount ? group.membersCount : self.displayMaxMemberCount);
    if ([self showAdd:group]) {
        count += 1;
    }
    if ([self showRemove:group]) {
        count += 1;
    }
    return count;
}

- (BOOL)showAdd:(RCGroupInfo *)group {
    if (group.invitePermission == RCGroupOperationPermissionOwner && group.role == RCGroupMemberRoleOwner) {
        return YES;
    }
    
    if (group.invitePermission == RCGroupOperationPermissionOwnerOrManager && (group.role == RCGroupMemberRoleOwner || group.role ==  RCGroupMemberRoleManager)) {
        return YES;
    }
    
    if (group.invitePermission == RCGroupOperationPermissionEveryone) {
        return YES;
    }
    return NO;
}

- (BOOL)showRemove:(RCGroupInfo *)group {
    if (group.removeMemberPermission == RCGroupOperationPermissionOwner && group.role == RCGroupMemberRoleOwner) {
        return YES;
    }
    
    if (group.removeMemberPermission == RCGroupOperationPermissionOwnerOrManager && (group.role == RCGroupMemberRoleOwner || group.role ==  RCGroupMemberRoleManager)) {
        return YES;
    }
    
    if (group.removeMemberPermission == RCGroupOperationPermissionEveryone) {
        return YES;
    }
    return NO;
}


- (BOOL)canEditProfile {
    if (self.group.groupInfoEditPermission == RCGroupOperationPermissionOwner && self.group.role == RCGroupMemberRoleOwner) {
        return YES;
    }
    if (self.group.groupInfoEditPermission == RCGroupOperationPermissionOwnerOrManager && (self.group.role == RCGroupMemberRoleOwner || self.group.role == RCGroupMemberRoleManager)) {
        return YES;
    }
    if (self.group.groupInfoEditPermission == RCGroupOperationPermissionEveryone) {
        return YES;
    }
    return NO;
}

#pragma mark -- setter

- (void)setDisplayMaxMemberCount:(NSInteger)displayMaxMemberCount {
    //最小为 5 个，最大不超过 50 个。
    if (displayMaxMemberCount < 5 || displayMaxMemberCount > 50) {
        return;
    }
    _displayMaxMemberCount = displayMaxMemberCount;
}

@end
