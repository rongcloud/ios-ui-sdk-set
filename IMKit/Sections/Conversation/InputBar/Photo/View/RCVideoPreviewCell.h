//
//  RCVideoPreviewCell.h
//  RongExtensionKit
//
//  Created by zhaobingdong on 2018/7/5.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RCVideoPreviewCellDelegate <NSObject>

- (void)sendPlayActionInCell:(UICollectionViewCell *)cell;

@end

@class RCAssetModel;
@class PHAsset;
@interface RCVideoPreviewCell : UICollectionViewCell

@property (nonatomic, weak) id<RCVideoPreviewCellDelegate> delegate;

- (void)configPreviewCellWithItem:(RCAssetModel *)model;

- (void)play:(PHAsset *)asset;

- (void)stop;

@end
