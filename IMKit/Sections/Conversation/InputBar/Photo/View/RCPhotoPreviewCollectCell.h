//
//  RCPhotoPreviewCollectCell.h
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/17.
//  Copyright © 2016年 张改红. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RCAssetModel;
@interface RCPhotoPreviewCollectCell : UICollectionViewCell

@property (nonatomic, strong) void (^singleTap)(void);

- (void)configPreviewCellWithItem:(RCAssetModel *)model;

- (void)resetSubviews;
@end
