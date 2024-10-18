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

#define RCUUserProfileViewFooterChatTop 100
#define RCUUserProfileViewFooterLeadingOrTrailing 25
#define RCUUserProfileViewFooterBtnheight 40
#define RCUUserProfileViewFooterAddFriendBtnTop 15

@interface RCUserProfileViewModel ()

@property (nonatomic, copy) NSString *userId;

@property (nonatomic, assign) BOOL isFriend;

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
    }
    return self;
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[RCProfileCommonTextCell class]
      forCellReuseIdentifier:RCUProfileTextCellIdentifier];
    [tableView registerClass:[RCUserProfileHeaderCell class]
      forCellReuseIdentifier:RCUUserProfileHeaderCellIdentifier];
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
    }
}

- (void)updateProfile {
    if (self.userId.length == 0) {
        return;
    }
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

#pragma mark - private

- (NSArray<NSArray<RCProfileCellViewModel *> *> *)reloadFriendDataSource:(RCFriendInfo *)friendInfo {
    RCUserProfileHeaderCellViewModel *headerVM = [[RCUserProfileHeaderCellViewModel alloc] initWithPortrait:friendInfo.portraitUri name:friendInfo.name remark:friendInfo.remark];
    
    RCProfileCommonCellViewModel *setRemarkVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"SetRemark") detail:nil];
    NSArray *array = @[
        @[headerVM],
        @[setRemarkVM]
    ];
    return array;
}

- (NSArray<NSArray<RCProfileCellViewModel *> *> *)reloadDataSource:(RCUserProfile *)userProfile {
    if (!userProfile) {
        userProfile = [[RCUserProfile alloc] init];
        userProfile.userId = self.userId;
    }
    NSMutableArray *otherList = [NSMutableArray array];
    
    RCUserProfileHeaderCellViewModel *headerVM = [[RCUserProfileHeaderCellViewModel alloc] initWithPortrait:userProfile.portraitUri name:userProfile.name remark:userProfile.email];
    
    if (self.verifyFriend && self.isFriend) {
        RCProfileCommonCellViewModel *setRemarkVM = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"SetRemark") detail:nil];
        [otherList addObject:setRemarkVM];
        return @[
            @[headerVM],
            otherList];
    }
    return @[
        @[headerVM]];
    
}

@end
