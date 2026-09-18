//
//  RCGroupMemberHeaderCell.h
//  RongIMKit
//
//  Created by zgh on 2024/8/23.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCBaseCollectionViewCell.h"
#import "RCloudImageView.h"

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSString  * _Nonnull const RCGroupMemberHeaderCellIdentifier;

@interface RCGroupMemberHeaderCell : RCBaseCollectionViewCell

@property (nonatomic, strong) RCloudImageView *portraitImageView;

@property (nonatomic, strong) UILabel *nameLabel;

@end

NS_ASSUME_NONNULL_END
