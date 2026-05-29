//
//  RCProfileGenderCell.h
//  RongIMKit
//
//  Created by zgh on 2024/8/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCBaseTableViewCell.h"
#import "RCBaseImageView.h"

UIKIT_EXTERN NSString  * _Nonnull const RCProfileGenderCellIdentifier;

NS_ASSUME_NONNULL_BEGIN

@interface RCProfileGenderCell : RCBaseTableViewCell

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) RCBaseImageView *selectView;

@end

NS_ASSUME_NONNULL_END
