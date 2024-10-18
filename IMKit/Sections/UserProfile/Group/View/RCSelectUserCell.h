//
//  RCSelectUserCell.h
//  RongIMKit
//
//  Created by zgh on 2024/8/26.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import <RongIMKit/RCBaseTableViewCell.h>
#import "RCloudImageView.h"
#import <RongIMKit/RCUserProfileDefine.h>
UIKIT_EXTERN NSString  * _Nonnull const RCSelectUserCellIdentifier;

NS_ASSUME_NONNULL_BEGIN

@interface RCSelectUserCell : RCBaseTableViewCell

@property (nonatomic, strong) RCBaseImageView *selectImageView;

@property (nonatomic, strong) RCloudImageView *portraitImageView;

@property (nonatomic, strong) UILabel *nameLabel;

- (void)updateSelectState:(RCSelectState)state;

@end

NS_ASSUME_NONNULL_END
