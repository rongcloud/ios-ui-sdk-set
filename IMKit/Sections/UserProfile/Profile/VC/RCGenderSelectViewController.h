//
//  RCUGenderSelectViewController.h
//  RongIMKit
//
//  Created by zgh on 2024/8/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import <RongIMKit/RongIMKit.h>
#import "RCProfileGenderViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCGenderSelectViewController : RCBaseViewController

- (instancetype)initWithViewModel:(RCProfileGenderViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
