//
//  RCUProfileCommonCell.h
//  RongUserProfile
//
//  Created by zgh on 2024/8/19.
//

#import "RCBaseTableViewCell.h"
#import "RCBaseImageView.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCProfileCommonCell : RCBaseTableViewCell

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) RCBaseImageView *arrowView;

@end

NS_ASSUME_NONNULL_END
