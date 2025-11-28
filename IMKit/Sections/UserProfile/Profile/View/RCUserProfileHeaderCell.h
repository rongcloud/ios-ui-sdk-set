//
//  RCUUserProfileHeaderCell.h
//  RongUserProfile
//
//  Created by zgh on 2024/8/19.
//

#import "RCBaseTableViewCell.h"
#import "RCloudImageView.h"
#import "RCOnlineStatusView.h"

UIKIT_EXTERN NSString  * _Nullable const RCUUserProfileHeaderCellIdentifier;

NS_ASSUME_NONNULL_BEGIN

@interface RCUserProfileHeaderCell : RCBaseTableViewCell

@property (nonatomic, strong) RCloudImageView *portraitImageView;

/// 在线状态图标
/// 默认隐藏
@property (nonatomic, strong) RCOnlineStatusView *onlineStatusView;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UILabel *remarkLabel;

- (void)hiddenNameLabel:(BOOL)hidden;

- (void)hiddenOnlineStatusView:(BOOL)hidden;

- (void)updateOnlineStatus:(BOOL)isOnline;

@end

NS_ASSUME_NONNULL_END
