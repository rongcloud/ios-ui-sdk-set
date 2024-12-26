//
//  RCGroupNotificationStatusCell.h
//  RongIMKit
//
//  Created by RobinCui on 2024/11/26.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupNotificationCell.h"

NS_ASSUME_NONNULL_BEGIN
UIKIT_EXTERN NSString  * const RCGroupNotificationStatusCellIdentifier;
@interface RCGroupNotificationStatusCell : RCGroupNotificationCell
@property (nonatomic, strong) UILabel *labStatus;
@end

NS_ASSUME_NONNULL_END
