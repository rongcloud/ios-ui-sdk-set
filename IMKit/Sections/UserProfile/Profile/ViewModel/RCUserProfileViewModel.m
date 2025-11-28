//
//  RCUserProfileViewModel.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/19.
//

#import <RongIMLibCore/RongIMLibCore.h>

#import "RCUserProfileViewModel.h"
#import "RCUserProfileHeaderCellViewModel.h"
#import "RCProfileCommonCellViewModel.h"
#import "RCProfileCommonTextCell.h"
#import "RCUserProfileHeaderCell.h"
#import "RCKitCommonDefine.h"
#import "RCNameEditViewController.h"
#import "RCProfileFooterViewModel.h"
#import "RCProfileViewModel+private.h"
#import "RCMyProfileViewModel.h"
#import "RCUserOnlineStatusManager.h"
#import "RCUserOnlineStatusUtil.h"
#import "RCIM.h"

#define RCUUserProfileViewFooterChatTop 100
#define RCUUserProfileViewFooterLeadingOrTrailing 25
#define RCUUserProfileViewFooterBtnheight 40
#define RCUUserProfileViewFooterAddFriendBtnTop 15

@interface RCUserProfileViewModel ()

@property (nonatomic, copy) NSString *userId;

@property (nonatomic, assign) BOOL isFriend;

@property (nonatomic, copy) NSString *groupId;

@property (nonatomic, strong) RCGroupInfo *group;

@property (nonatomic, strong) RCGroupMemberInfo *member;

@end

@implementation RCUserProfileViewModel
+ (RCProfileViewModel *)viewModelWithUserId:(NSString *)userId {
    if ([userId isEqualToString:[RCCoreClient sharedCoreClient].currentUserInfo.userId]) {
        return [RCMyProfileViewModel new];
    }
    RCUserProfileViewModel *viewModel = [[self.class alloc] init];
    viewModel.userId = userId;
    return viewModel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.verifyFriend = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserOnlineStatusChanged:) name:RCKitUserOnlineStatusChangedNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[RCProfileCommonTextCell class]
      forCellReuseIdentifier:RCUProfileTextCellIdentifier];
    [tableView registerClass:[RCUserProfileHeaderCell class]
      forCellReuseIdentifier:RCUUserProfileHeaderCellIdentifier];
}

- (void)showGroupMemberInfo:(NSString *)groupId {
    if (groupId.length == 0 || self.userId.length == 0) {
        return;
    }
    if ([self.userId isEqualToString:[RCCoreClient sharedCoreClient].currentUserInfo.userId]) {
        return;
    }
    self.groupId = groupId;
}

#pragma mark -- RCListViewModelProtocol

- (void)viewController:(UIViewController *)viewController tableView:(UITableView *)tableView didSelectRow:(NSIndexPath *)indexPath {
    RCProfileCellViewModel *cellViewModel = self.profileList[indexPath.section][indexPath.row];
    
    if ([self.delegate respondsToSelector:@selector(profileViewModel:viewController:tableView:didSelectRow:cellViewModel:)]) {
        BOOL intercept = [self.delegate profileViewModel:self viewController:viewController tableView:tableView didSelectRow:indexPath cellViewModel:cellViewModel];
        if (intercept) {
            return;
        }
    }
    
    if (![cellViewModel isKindOfClass:RCProfileCommonCellViewModel.class]) {
        return;
    }
    RCProfileCommonCellViewModel *commonCellViewModel = (RCProfileCommonCellViewModel *)cellViewModel;
    if ([commonCellViewModel.title isEqualToString:RCLocalizedString(@"SetRemark")]) {
        RCNameEditViewModel *viewModel = [RCNameEditViewModel viewModelWithUserId:self.userId groupId:nil type:RCNameEditTypeRemark];
        RCNameEditViewController *nameEditVC = [[RCNameEditViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:nameEditVC animated:YES];
    } else if ([commonCellViewModel.title isEqualToString:RCLocalizedString(@"GroupMemberNickname")] && [self canEditGroupMemberNickname]) {
        RCNameEditViewModel *viewModel = [RCNameEditViewModel viewModelWithUserId:self.userId groupId:self.group.groupId type:RCNameEditTypeGroupMemberNickname];
        viewModel.title = RCLocalizedString(@"GroupMemberNickname");
        RCNameEditViewController *nameEditVC = [[RCNameEditViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:nameEditVC animated:YES];
    }
}

- (void)updateProfile {
    if (self.userId.length == 0) {
        return;
    }
    [self updateGroupMemberInfo];
    if (self.verifyFriend) {
        [[RCCoreClient sharedCoreClient] checkFriends:@[self.userId] directionType:(RCDirectionTypeBoth) success:^(NSArray<RCFriendRelationInfo *> * _Nonnull friendRelations) {
            RCFriendRelationInfo *relationInfo = friendRelations.firstObject;
            if (relationInfo.relationType == RCFriendRelationTypeInMyFriendList || relationInfo.relationType == RCFriendRelationTypeBothWay) {
                self.isFriend = YES;
                [self getFriendInfo];
            } else {
                [self getUserProfile];
            }
        } error:^(RCErrorCode errorCode) {
            [self getUserProfile];
        }];
    } else {
        [self getUserProfile];
    }
}

- (void)getUserProfile {
    [[RCCoreClient sharedCoreClient] getUserProfiles:@[self.userId ? : @""] success:^(NSArray<RCUserProfile *> * _Nonnull userProfiles) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadFooterViewModel];
            self.profileList = [self reloadDataSource:userProfiles.firstObject];
            [self.responder reloadData:NO];
        });
    } error:^(RCErrorCode errorCode) {
        RCLogE(@"get User Profiles error");
    }];
}

- (void)getFriendInfo {
    [[RCCoreClient sharedCoreClient] getFriendsInfo:@[self.userId ? : @""] success:^(NSArray<RCFriendInfo *> * _Nonnull friendInfos) {
        RCFriendInfo *friend = friendInfos.firstObject;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadFooterViewModel];
            self.profileList = [self reloadFriendDataSource:friend];
            [self.responder reloadData:NO];
        });
    } error:^(RCErrorCode errorCode) {
        
    }];
}

- (void)loadFooterViewModel {
    RCProfileFooterViewType type = RCProfileFooterViewTypeChat;
    if (self.verifyFriend && !self.isFriend) {
       type = RCProfileFooterViewTypeAddFriend;
    }
    RCProfileFooterViewModel *footerViewModel = [[RCProfileFooterViewModel alloc] initWithResponder:[self.responder currentViewController] type:type targetId:self.userId];
    footerViewModel.verifyFriend = self.verifyFriend;
    [self configFooterViewModel:footerViewModel];
}

- (void)onUserOnlineStatusChanged:(NSNotification *)notification {
    NSArray<NSString *> *changedUserIds = notification.userInfo[RCKitUserOnlineStatusChangedUserIdsKey];
    for (NSString *userId in changedUserIds) {
        if ([userId isEqualToString:self.userId]) {
            RCProfileCellViewModel *headerVM = self.profileList[0][0];
            if ([headerVM isKindOfClass:RCUserProfileHeaderCellViewModel.class]) {
                RCUserProfileHeaderCellViewModel *headerCellVM = (RCUserProfileHeaderCellViewModel *)headerVM;
                RCSubscribeUserOnlineStatus *onlineStatus = [RCUserOnlineStatusManager.sharedManager getCachedOnlineStatus:userId];
                headerCellVM.isOnline = onlineStatus.isOnline;
                [self.responder reloadData:NO];
            }
        }
    }
}

#pragma mark - private

- (NSArray<NSArray<RCProfileCellViewModel *> *> *)reloadFriendDataSource:(RCFriendInfo *)friendInfo {
    
    NSMutableArray *profileList = [NSMutableArray array];
    
    RCUserProfileHeaderCellViewModel *headerVM = [[RCUserProfileHeaderCellViewModel alloc] initWithPortrait:friendInfo.portraitUri name:friendInfo.name remark:friendInfo.remark];
    // 在线状态
    [self setupViewModelOnlineStatus:headerVM];
    
    RCProfileCommonCellViewModel *setRemarkVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"SetRemark") detail:nil];
    
    [profileList addObject:@[headerVM]];
    [profileList addObject:@[setRemarkVM]];

    if (self.member) {
        RCProfileCommonCellViewModel *memberNicknameVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"GroupMemberNickname") detail:self.member.nickname];
        memberNicknameVM.hiddenArrow = ![self canEditGroupMemberNickname];
        [profileList addObject:@[memberNicknameVM]];
    }
    return profileList;
}

- (NSArray<NSArray<RCProfileCellViewModel *> *> *)reloadDataSource:(RCUserProfile *)userProfile {
    if (!userProfile) {
        userProfile = [[RCUserProfile alloc] init];
        userProfile.userId = self.userId;
    }
    NSMutableArray *profileList = [NSMutableArray array];
    
    RCUserProfileHeaderCellViewModel *headerVM = [[RCUserProfileHeaderCellViewModel alloc] initWithPortrait:userProfile.portraitUri name:userProfile.name remark:userProfile.email];
   
    [self setupViewModelOnlineStatus:headerVM];
    
    [profileList addObject:@[headerVM]];
    if (self.verifyFriend && self.isFriend) {
        RCProfileCommonCellViewModel *setRemarkVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"SetRemark") detail:nil];
        [profileList addObject:@[setRemarkVM]];
    }
    
    if (self.member) {
        RCProfileCommonCellViewModel *memberNicknameVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"GroupMemberNickname") detail:self.member.nickname];
        memberNicknameVM.hiddenArrow = ![self canEditGroupMemberNickname];
        [profileList addObject:@[memberNicknameVM]];
    }
    return profileList;
}

- (void)updateGroupMemberInfo {
    if (self.groupId.length == 0) {
        return;
    }
    [[RCCoreClient sharedCoreClient] getGroupsInfo:@[self.groupId] success:^(NSArray<RCGroupInfo *> * _Nonnull groupInfos) {
        self.group = groupInfos.firstObject;
        [[RCCoreClient sharedCoreClient] getGroupMembers:self.groupId userIds:@[self.userId] success:^(NSArray<RCGroupMemberInfo *> * _Nonnull groupMembers) {
            self.member = groupMembers.firstObject;
        } error:^(RCErrorCode errorCode) {
            
        }];
    } error:^(RCErrorCode errorCode) {
        
    }];
}

- (BOOL)canEditGroupMemberNickname {
    if ([self.member.userId isEqualToString:[RCCoreClient sharedCoreClient].currentUserInfo.userId]) {
        return YES;
    }
    if (self.group.memberInfoEditPermission == RCGroupMemberInfoEditPermissionOwnerOrManagerOrSelf && (self.group.role == RCGroupMemberRoleOwner || self.group.role == RCGroupMemberRoleManager)) {
        return YES;
    }
    if (self.group.memberInfoEditPermission == RCGroupMemberInfoEditPermissionOwnerOrSelf &&
        (self.group.role == RCGroupMemberRoleOwner)) {
        return YES;
    }
    return NO;
}

- (void)setupViewModelOnlineStatus:(RCUserProfileHeaderCellViewModel *)headerVM {
    if (![RCUserOnlineStatusUtil shouldDisplayOnlineStatus]) {
        headerVM.displayOnlineStatus = NO;
        return;
    }
    RCSubscribeUserOnlineStatus *onlineStatus = [self getUserOnlineStatus:self.userId];
    headerVM.isOnline = onlineStatus.isOnline;
    headerVM.displayOnlineStatus = YES;
}

- (RCSubscribeUserOnlineStatus *)getUserOnlineStatus:(NSString *)userId {
    if (userId.length == 0) {
        return nil;
    }
    RCSubscribeUserOnlineStatus *onlineStatus = [RCUserOnlineStatusManager.sharedManager getCachedOnlineStatus:userId];
    if (!onlineStatus) {
        if (self.isFriend && self.verifyFriend) {
            [RCUserOnlineStatusManager.sharedManager fetchFriendOnlineStatus:@[userId]];
        } else {
            [RCUserOnlineStatusManager.sharedManager fetchOnlineStatus:userId processSubscribeLimit:NO];
        }
    }
    return onlineStatus;
}

@end
