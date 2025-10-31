//
//  RCProfileGenderViewModel.h
//  RongIMKit
//
//  Created by zgh on 2024/8/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCBaseViewModel.h"
#import "RCProfileGenderCellViewModel.h"
#import "RCListViewModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCProfileGenderViewModel : RCBaseViewModel<RCListViewModelProtocol>

@property (nonatomic, strong) RCUserProfile *profle;

@property (nonatomic, strong) NSArray <RCProfileGenderCellViewModel *> *dataSource;

- (void)updateUserProfileGender:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
