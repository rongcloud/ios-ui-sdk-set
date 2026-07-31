//
//  RCProfileGenderCellViewModel.h
//  RongIMKit
//
//  Created by zgh on 2024/8/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import <RongIMLibCore/RongIMLibCore.h>
#import "RCBaseCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCProfileGenderCellViewModel : RCBaseCellViewModel

@property (nonatomic, assign) RCUserGender gender;

@property (nonatomic, assign) BOOL isSelect;

+ (instancetype)cellViewModel:(RCUserGender)gender;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
