//
//  RCStickerCollectionViewCell.h
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/14.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCStickerSingle.h"
#import "RongStickerAdaptiveHeader.h"

@interface RCStickerCollectionViewCell : RCBaseCollectionViewCell
/**
 表情背板视图
 */
@property (nonatomic, strong) UIView *stickerBackgroundView;
- (void)configWithModel:(RCStickerSingle *)model packageId:(NSString *)packageId;

@end
