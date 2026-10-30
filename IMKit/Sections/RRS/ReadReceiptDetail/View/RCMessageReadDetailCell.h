//
//  RCMessageReadDetailCell.h
//  RongIMKit
//
//  Created by Lang on 10/15/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCBaseTableViewCell.h"
#import "RCMessageReadDetailCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCMessageReadDetailCell : RCBaseTableViewCell

+ (NSString *)reuseIdentifier;

/// 绑定 ViewModel
/// - Parameters viewModel: Cell ViewModel
- (void)bindViewModel:(RCMessageReadDetailCellViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
