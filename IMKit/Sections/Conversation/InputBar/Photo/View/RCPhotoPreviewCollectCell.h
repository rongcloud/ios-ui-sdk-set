//
//  RCPhotoPreviewCollectCell.h
//  RongExtensionKit
//
//  Created by RongCloud on 16/3/17.
//  Copyright © 2016 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RCAssetModel;
@interface RCPhotoPreviewCollectCell : UICollectionViewCell

@property (nonatomic, strong) void (^singleTap)(void);

- (void)configPreviewCellWithItem:(RCAssetModel *)model;

- (void)resetSubviews;
@end
