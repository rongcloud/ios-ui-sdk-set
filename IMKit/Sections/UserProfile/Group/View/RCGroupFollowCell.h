//
//  RCGroupFollowCell.h
//  RongIMKit
//
//  Created by zgh on 2024/11/21.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCBaseTableViewCell.h"
#import "RCButton.h"
#import "RCloudImageView.h"
NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSString  * _Nonnull const RCGroupFollowCellIdentifier;

@interface RCGroupFollowCell : RCBaseTableViewCell

@property (nonatomic, strong) RCloudImageView *portraitImageView;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) RCButton *actionButton;

@property (nonatomic, copy) void(^actionBlock)(void);
@end

NS_ASSUME_NONNULL_END
