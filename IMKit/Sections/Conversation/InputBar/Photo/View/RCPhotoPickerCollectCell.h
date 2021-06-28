//
//  RCPhotoPickerCollectCell.h
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/17.
//  Copyright © 2016年 张改红. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RCAssetModel;

@protocol RCPhotoPickerCollectCellDelegate <NSObject>

/**
 *  按钮点击后的回调
 *  返回按钮的状态是否会被更改
 */
- (BOOL)canChangeSelectedState:(RCAssetModel *)asset;

/**
 *  从 iCloud 下载失败回调：默认读相册数据，失败则读 iCloud，如果 iCloud 还失败，会触发该回调
 *  和下面的 didChangeSelectedState 互斥
 */
- (void)downloadFailFromiCloud;

/**
 *  当按钮selected状态改变后,回调
 */
- (void)didChangeSelectedState:(BOOL)selected model:(RCAssetModel *)asset;

- (void)didTapPickerCollectCell:(RCAssetModel *)model;

@end

@interface RCPhotoPickerCollectCell : UICollectionViewCell


@property (nonatomic, copy) NSString *representedAssetIdentifier;

- (void)configPickerCellWithItem:(RCAssetModel *)model delegate:(id<RCPhotoPickerCollectCellDelegate>)delegate;

@end
