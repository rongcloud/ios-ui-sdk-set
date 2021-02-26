//
//  RCPhotoPickerCollectCell.h
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/17.
//  Copyright © 2016年 张改红. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RCAssetModel;
@interface RCPhotoPickerCollectCell : UICollectionViewCell
/**
 *  按钮点击后的回调
 *  返回按钮的状态是否会被更改
 */
@property (nonatomic, copy) BOOL (^willChangeSelectedStateBlock)(RCAssetModel *asset);

/**
 *  当按钮selected状态改变后,回调
 */
@property (nonatomic, copy) void (^didChangeSelectedStateBlock)(BOOL selected, RCAssetModel *asset);


@property (nonatomic, copy) NSString *representedAssetIdentifier;

- (void)configPickerCellWithItem:(RCAssetModel *)model;

@end
