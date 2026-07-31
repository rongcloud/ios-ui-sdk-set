//
//  RCProfileViewModel+private.h
//  RongIMKit
//
//  Created by zgh on 2024/9/4.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCProfileViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCProfileViewModel ()

@property (nonatomic, strong) NSArray <NSArray <RCProfileCellViewModel*> *> *profileList;

- (void)configFooterViewModel:(RCProfileFooterViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
