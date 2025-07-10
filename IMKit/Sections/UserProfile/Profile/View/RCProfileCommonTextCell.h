//
//  RCUserProfileTextCell.h
//  RongUserProfile
//
//  Created by zgh on 2024/8/16.
//

#import "RCProfileCommonCell.h"
UIKIT_EXTERN NSString * _Nullable const RCUProfileTextCellIdentifier;

NS_ASSUME_NONNULL_BEGIN

@interface RCProfileCommonTextCell : RCProfileCommonCell

@property (nonatomic, strong) UILabel *detailLabel;

@end

NS_ASSUME_NONNULL_END
