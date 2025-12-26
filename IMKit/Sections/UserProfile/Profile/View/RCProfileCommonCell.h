//
//  RCUProfileCommonCell.h
//  RongUserProfile
//
//  Created by zgh on 2024/8/19.
//

#import "RCPaddingTableViewCell.h"
#import "RCBaseImageView.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCProfileCommonCell : RCPaddingTableViewCell

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) RCBaseImageView *arrowView;

@property (nonatomic, strong) UIStackView *contentStackView;

@end

NS_ASSUME_NONNULL_END
