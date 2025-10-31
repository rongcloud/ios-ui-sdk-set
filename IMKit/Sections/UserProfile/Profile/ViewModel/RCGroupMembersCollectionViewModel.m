//
//  RCGroupMembersCollectionViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupMembersCollectionViewModel.h"
#import "RCGroupMemberHeaderCell.h"
#import "RCSelectUserViewController.h"
#import "RCRemoveGroupMembersViewController.h"
#import "RCGroupManager.h"
#import "RCProfileViewController.h"
#import "RCUserProfileViewModel.h"
#import "RCKitCommonDefine.h"
#import "RCAlertView.h"
@interface RCGroupMembersCollectionViewModel ()

@property (nonatomic, weak) UIViewController *inViewController;

@property (nonatomic, strong) NSArray <RCGroupMemberInfo *> *members;

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, assign) BOOL allowAdd;

@property (nonatomic, assign) BOOL allowRemove;

@property (nonatomic, copy) NSArray <RCFriendInfo *> *friends;

@end

@implementation RCGroupMembersCollectionViewModel
@dynamic delegate;

+ (instancetype)viewModelWithGroupId:(NSString *)groupId
                             members:(NSArray <RCGroupMemberInfo *> *)members
                            allowAdd:(BOOL)allowAdd
                         allowRemove:(BOOL)allowRemove
                    inViewController:(UIViewController *)inViewController {
    RCGroupMembersCollectionViewModel *viewModel = [self.class new];
    viewModel.groupId = groupId;
    viewModel.members = members;
    viewModel.allowAdd = allowAdd;
    viewModel.allowRemove = allowRemove;
    viewModel.inViewController = inViewController;
    [viewModel fetchFriendInfos];
    return viewModel;
}

#pragma mark -- RCCollectionViewModelProtocol

- (NSInteger)numberOfItemsInSection:(NSInteger)section {
    NSInteger count = self.members.count;
    if (self.allowAdd) {
        count += 1;
    }
    if (self.allowRemove) {
        count += 1;
    }
    return count;
}

+ (void)registerCollectionViewCell:(UICollectionView *)collectionView {
    [collectionView registerClass:RCGroupMemberHeaderCell.class forCellWithReuseIdentifier:RCGroupMemberHeaderCellIdentifier];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RCGroupMemberHeaderCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:RCGroupMemberHeaderCellIdentifier forIndexPath:indexPath];
    if (self.members.count > indexPath.row) {
        RCGroupMemberInfo *member = self.members[indexPath.row];
        cell.nameLabel.hidden = NO;
        cell.portraitImageView.placeholderImage = RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg");
        cell.portraitImageView.imageURL = [NSURL URLWithString:member.portraitUri];
        NSString *remark = [self remarkWithUserId:member.userId];
        if (remark.length > 0) {
            cell.nameLabel.text = remark;
        } else if (member.nickname.length > 0) {
            cell.nameLabel.text = member.nickname;
        } else {
            cell.nameLabel.text = member.name;
        }
    } else if ([self isAddItem:indexPath.row]) {
        cell.nameLabel.hidden = YES;
        cell.portraitImageView.placeholderImage = RCResourceImage(@"group_member_add");
    } else if ([self isRemoveItem:indexPath.row]) {
        cell.nameLabel.hidden = YES;
        cell.portraitImageView.placeholderImage = RCResourceImage(@"group_member_remove");
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.members.count > indexPath.row) {
        [self showMemberDetailVC:self.members[indexPath.row]];
    } else if ([self isAddItem:indexPath.row]) {
        [self addGroupMember];
    } else if ([self isRemoveItem:indexPath.row]) {
        [self removeGroupMember];
    }
}

#pragma mark -- private

- (void)fetchFriendInfos {
    [RCGroupManager fetchFriendInfos:self.members complete:^(NSArray<RCFriendInfo *> * _Nullable friendInfos) {
        if (friendInfos.count <= 0) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.friends = friendInfos;
            if ([self.responder respondsToSelector:@selector(reloadCollectionViewData)]) {
                [self.responder reloadCollectionViewData];
            }
        });
    }];
}

- (NSString *)remarkWithUserId:(NSString *)userId {
    if (self.friends.count <= 0) {
        return nil;
    }
    return [RCGroupManager friendWithUserId:userId inFriendInfos:self.friends].remark;
}

- (void)showMemberDetailVC:(RCGroupMemberInfo *)member {
    if ([self.delegate respondsToSelector:@selector(groupMembersCollectionViewModel:viewController:didSelectMember:)]) {
        BOOL intercept = [self.delegate groupMembersCollectionViewModel:self viewController:self.inViewController didSelectMember:member];
        if (intercept) {
            return;
        }
    }
    RCProfileViewModel *viewModel = [RCUserProfileViewModel viewModelWithUserId:member.userId];
    if ([viewModel isKindOfClass:RCUserProfileViewModel.class]) {
        [((RCUserProfileViewModel *)viewModel) showGroupMemberInfo:self.groupId];
    }
    RCProfileViewController *viewController = [[RCProfileViewController alloc] initWithViewModel:viewModel];
    [self.inViewController.navigationController pushViewController:viewController animated:YES];
}

- (void)addGroupMember {
    if ([self.delegate respondsToSelector:@selector(groupMembersCollectionViewModel:didSelectAdd:)]) {
        BOOL intercept = [self.delegate groupMembersCollectionViewModel:self didSelectAdd: self.inViewController];
        if (intercept) {
            return;
        }
    }
    RCSelectUserViewModel *vm = [RCSelectUserViewModel viewModelWithType:RCSelectUserTypeInviteJoinGroup groupId:self.groupId];
    __weak typeof(self) weakSelf = self;
    vm.selectionDidCompelteBlock = ^(NSArray<NSString *> * _Nonnull selectUserIds, UIViewController * _Nonnull selectVC) {
        [weakSelf inviteJoinGroup:selectUserIds viewController:selectVC];
    };
    RCSelectUserViewController *vc = [[RCSelectUserViewController alloc] initWithViewModel:vm];
    [self.inViewController.navigationController pushViewController:vc animated:YES];
}

- (void)inviteJoinGroup:(NSArray *)selectUserIds viewController:(UIViewController *)viewController {
    [[RCCoreClient sharedCoreClient] inviteUsersToGroup:self.groupId userIds:selectUserIds success:^(RCErrorCode processCode) {
        if ([self.delegate respondsToSelector:@selector(groupMembersCollectionViewModel:didInviteUsers:processCode:viewController:)]) {
            BOOL intercept = [self.delegate groupMembersCollectionViewModel:self didInviteUsers:selectUserIds processCode:processCode viewController:viewController];
            if (intercept) {
                return;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [viewController.navigationController popViewControllerAnimated:YES];
            if (processCode == RC_GROUP_JOIN_GROUP_NEED_MANAGER_ACCEPT) {
                [RCAlertView showAlertController:nil message:RCLocalizedString(@"inviteJoinGroupNeedOwnerOrManagerAcceptTip") hiddenAfterDelay:2];
            } else if (processCode == RC_GROUP_NEED_INVITEE_ACCEPT) {
                [RCAlertView showAlertController:nil message:RCLocalizedString(@"inviteJoinGroupNeedInviteeAcceptTip") hiddenAfterDelay:2];
            } else {
                [RCAlertView showAlertController:nil message:RCLocalizedString(@"inviteJoinGroupSuccess") hiddenAfterDelay:2];
            }
        });
    } error:^(RCErrorCode errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"inviteJoinGroupError") hiddenAfterDelay:2];
        });
    }];
}

- (void)removeGroupMember {
    if ([self.delegate respondsToSelector:@selector(groupMembersCollectionViewModel:didSelectRemove:)]) {
        BOOL intercept = [self.delegate groupMembersCollectionViewModel:self didSelectRemove:self.inViewController];
        if (intercept) {
            return;
        }
    }
    RCRemoveGroupMembersViewModel *vm = [RCRemoveGroupMembersViewModel viewModelWithGroupId:self.groupId];
    RCRemoveGroupMembersViewController *vc = [[RCRemoveGroupMembersViewController alloc] initWithViewModel:vm];
    [self.inViewController.navigationController pushViewController:vc animated:YES];
}

- (BOOL)isAddItem:(NSInteger)index {
    if (self.allowAdd && index == self.members.count) {
        return YES;
    }
    return NO;
}

- (BOOL)isRemoveItem:(NSInteger)index {
    if (!self.allowRemove)  {
        return NO;
    }
    if (self.allowAdd) {
        if (index == self.members.count + 1) {
            return YES;
        }
    } else {
        if (index == self.members.count) {
            return YES;
        }
    }
    return NO;
}

@end
