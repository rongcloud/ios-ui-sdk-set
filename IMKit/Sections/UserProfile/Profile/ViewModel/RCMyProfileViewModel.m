//
//  RCUCurrentUserProfileViewModel.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/16.
//

#import "RCMyProfileViewModel.h"
#import "RCProfileCommonCellViewModel.h"
#import "RCProfileCommonTextCell.h"
#import "RCProfileCommonImageCell.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCKitCommonDefine.h"
#import "RCNameEditViewController.h"
#import "RCGenderSelectViewController.h"
#import "RCProfileViewModel+private.h"
@interface RCMyProfileViewModel ()

@property (nonatomic, strong) RCUserProfile *userProfile;

@end

@implementation RCMyProfileViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:[RCProfileCommonTextCell class]
      forCellReuseIdentifier:RCUProfileTextCellIdentifier];
    [tableView registerClass:[RCProfileCommonImageCell class]
      forCellReuseIdentifier:RCUProfileImageCellIdentifier];
}

- (void)updateProfile {
    [[RCCoreClient sharedCoreClient] getMyUserProfile:^(RCUserProfile * _Nonnull userProfile) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.profileList = [self reloadDataSource:userProfile];
            [self.responder reloadData:NO];
        });
    } error:^(RCErrorCode errorCode) {
        RCLogE(@"get my User Profiles error");
    }];
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
    if ([commonCellViewModel.title isEqualToString:RCLocalizedString(@"Nickname")]) {
        RCNameEditViewModel *viewModel = [RCNameEditViewModel viewModelWithUserId:[RCCoreClient sharedCoreClient].currentUserInfo.userId groupId:nil type:RCNameEditTypeName];
        RCNameEditViewController *nameEditVC = [[RCNameEditViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:nameEditVC animated:YES];
    } else if([commonCellViewModel.title isEqualToString:RCLocalizedString(@"Gender")]) {
        RCProfileGenderViewModel *viewModel = [[RCProfileGenderViewModel alloc] init];
        viewModel.profle = self.userProfile;
        RCGenderSelectViewController *genderVC = [[RCGenderSelectViewController alloc] initWithViewModel:viewModel];
        [viewController.navigationController pushViewController:genderVC animated:YES];
    }
}

#pragma mark -- private

- (NSArray<NSArray<RCProfileCellViewModel *> *> *)reloadDataSource:(RCUserProfile *)userProfile {
    self.userProfile = userProfile;
    RCProfileCommonCellViewModel *portraitViewModel = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeImage title:RCLocalizedString(@"Portrait") detail:self.userProfile.portraitUri];
    portraitViewModel.hiddenArrow = YES;
    
    RCProfileCommonCellViewModel *nameViewModel = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"Nickname") detail:self.userProfile.name];
    
    RCProfileCommonCellViewModel *uniqueIdViewModel = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"ApplicationNumber") detail:self.userProfile.uniqueId];
    uniqueIdViewModel.hiddenArrow = YES;
    
    RCProfileCommonCellViewModel *genderViewModel = [[RCProfileCommonCellViewModel alloc] initWithCellType:RCUProfileCellTypeText title:RCLocalizedString(@"Gender") detail:[self getGenderString:self.userProfile.gender]];
    NSArray *array = @[
        @[portraitViewModel, nameViewModel, uniqueIdViewModel, genderViewModel]
    ];
    return array;
}

- (NSString *)getGenderString:(RCUserGender)gender {
    switch (gender) {
        case RCUserGenderMale:
            return RCLocalizedString(@"Male");
        case RCUserGenderFemale:
            return RCLocalizedString(@"Female");
        default:
            break;
    }
    return RCLocalizedString(@"Unknown");
}

@end
