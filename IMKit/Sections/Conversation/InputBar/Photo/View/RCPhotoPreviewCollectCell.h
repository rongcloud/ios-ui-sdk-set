//
//  RCPhotoPreviewCollectCell.h
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/17.
//  Copyright © 2016年 张改红. All rights reserved.
//

#import "RCBaseCollectionViewCell.h"
@class RCAssetModel;
@interface RCPhotoPreviewCollectCell : RCBaseCollectionViewCell

@property (nonatomic, strong) void (^singleTap)(void);

- (void)configPreviewCellWithItem:(RCAssetModel *)model;

- (void)resetSubviews;
@end
