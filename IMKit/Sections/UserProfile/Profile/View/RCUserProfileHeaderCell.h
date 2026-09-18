//
//  RCUUserProfileHeaderCell.h
//  RongUserProfile
//
//  Created by zgh on 2024/8/19.
//

#import "RCBaseTableViewCell.h"
#import "RCloudImageView.h"

UIKIT_EXTERN NSString  * _Nullable const RCUUserProfileHeaderCellIdentifier;

NS_ASSUME_NONNULL_BEGIN

@interface RCUserProfileHeaderCell : RCBaseTableViewCell

@property (nonatomic, strong) RCloudImageView *portraitImageView;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UILabel *remarkLabel;

- (void)hiddenNameLabel:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
