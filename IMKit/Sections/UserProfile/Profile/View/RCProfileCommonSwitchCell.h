//
//  RCProfileCommonSwitchCell.h
//  RongIMKit
//
//  Created by zgh on 2024/9/2.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCProfileCommonCell.h"

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSString * _Nullable const RCProfileCommonSwitchCellIdentifier;

@protocol RCProfileCommonSwitchCellDelegate <NSObject>

- (void)switchValueChanged:(UISwitch *)switchView;

@end

@interface RCProfileCommonSwitchCell : RCProfileCommonCell

@property (nonatomic, weak) id<RCProfileCommonSwitchCellDelegate> delegate;

@property (nonatomic, strong) UISwitch *switchView;

@end

NS_ASSUME_NONNULL_END
