//
//  RCGroupMemberCell.h
//  RongIMKit
//
//  Created by zgh on 2024/8/26.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCBaseTableViewCell.h"
#import "RCloudImageView.h"

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSString  * _Nonnull const RCGroupMemberCellIdentifier;

@interface RCGroupMemberCell : RCBaseTableViewCell

@property (nonatomic, strong) RCloudImageView *portraitImageView;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UILabel *roleLabel;

@property (nonatomic, strong) RCBaseImageView *arrowView;

- (void)hiddenArrow:(BOOL)hiddenArrow;

@end

NS_ASSUME_NONNULL_END
