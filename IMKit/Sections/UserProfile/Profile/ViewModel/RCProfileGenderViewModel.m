//
//  RCProfileGenderViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCProfileGenderViewModel.h"
#import "RCProfileGenderCell.h"
#import "RCAlertView.h"
#import "RCKitCommonDefine.h"
#import "RCIM.h"
@implementation RCProfileGenderViewModel
@dynamic delegate;

#pragma mark -- RCListViewModelProtocol
- (void)registerCellForTableView:(UITableView *)tableView {
    [tableView registerClass:RCProfileGenderCell.class forCellReuseIdentifier:RCProfileGenderCellIdentifier];
}

- (void)viewController:(UIViewController *)viewController tableView:(UITableView *)tableView didSelectRow:(NSIndexPath *)indexPath {
    [self itemDidSelectedAtIndexPath:indexPath];
}

- (NSArray<RCProfileGenderCellViewModel *> *)dataSource {
    if (!_dataSource) {
        RCProfileGenderCellViewModel *maleVM = [RCProfileGenderCellViewModel cellViewModel:RCUserGenderMale];
        maleVM.isSelect = (self.profle.gender == RCUserGenderMale);
        
        RCProfileGenderCellViewModel *femaleVM = [RCProfileGenderCellViewModel cellViewModel:RCUserGenderFemale];
        femaleVM.isSelect = (self.profle.gender == RCUserGenderFemale);
        
        _dataSource = @[maleVM, femaleVM];
    }
    return _dataSource;
}

- (void)updateUserProfileGender:(UIViewController *)viewController {
    RCUserGender gender = RCUserGenderUnknown;
    for (int i = 0; i<self.dataSource.count; i++) {
        RCProfileGenderCellViewModel *cellViewModel = self.dataSource[i];
        if (cellViewModel.isSelect) {
            gender = cellViewModel.gender;
            break;
        }
    }
    self.profle.gender = gender;
    [self loadingWithTip:RCLocalizedString(@"Saving")];

    [[RCIM sharedRCIM] updateMyUserProfile:self.profle successBlock:^{
        [self stopLoading];
        dispatch_async(dispatch_get_main_queue(), ^{
            [viewController.navigationController popViewControllerAnimated:YES];
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"SetSuccess") hiddenAfterDelay:1];
        });
    } errorBlock:^(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys) {
        [self stopLoading];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *tips = RCLocalizedString(@"SetFailed");
            if (errorCode == RC_SERVICE_INFORMATION_AUDIT_FAILED) {
                tips = RCLocalizedString(@"Content_Contains_Sensitive");
            }
            [RCAlertView showAlertController:nil message:tips hiddenAfterDelay:1];
        });
    }];
}

- (void)itemDidSelectedAtIndexPath:(NSIndexPath *)indexPath {
    for (int i = 0; i<self.dataSource.count; i++) {
        RCProfileGenderCellViewModel *cellViewModel = self.dataSource[i];
        if (i == indexPath.row) {
            cellViewModel.isSelect = YES;
        } else {
            cellViewModel.isSelect = NO;
        }
        [cellViewModel reloadData];
    }
}
@end
