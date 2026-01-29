//
//  RCSightFileBrowserCell.h
//  RongIMKit
//
//  Created by RobinCui on 2025/12/16.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCPaddingTableViewCell.h"

extern NSString  * const RCSightFileBrowserCellIdentifier;
NS_ASSUME_NONNULL_BEGIN

@interface RCSightFileBrowserCell : RCPaddingTableViewCell
@property (nonatomic, strong) UIImageView *imageIcon;
@property (nonatomic, strong) UILabel *labelTitle;
@property (nonatomic, strong) UILabel *labelTime;
@property (nonatomic, strong) UILabel *labelSubtitle;
@property (nonatomic, strong) UIStackView *rightStackView;
@property (nonatomic, strong) UIStackView *topStackView;
@property (nonatomic, strong) UIStackView *contentStackView;

@end

NS_ASSUME_NONNULL_END
