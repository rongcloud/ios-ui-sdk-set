//
//  RCUserProfileImageCell.h
//  RongUserProfile
//
//  Created by zgh on 2024/8/16.
//

#import "RCProfileCommonCell.h"
#import "RCloudImageView.h"
UIKIT_EXTERN NSString * _Nullable const RCUProfileImageCellIdentifier;

NS_ASSUME_NONNULL_BEGIN

@interface RCProfileCommonImageCell : RCProfileCommonCell

@property (nonatomic, strong) RCloudImageView *portraitImageView;

- (void)hiddenArrow:(BOOL)hiddenArrow;

@end

NS_ASSUME_NONNULL_END
