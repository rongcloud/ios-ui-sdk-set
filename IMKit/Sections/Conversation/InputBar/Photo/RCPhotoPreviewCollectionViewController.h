//
//  RCPhotoPreviewCollectionViewController.h
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/17.
//  Copyright © 2016年 张改红. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCBaseCollectionViewController.h"
@class RCAssetModel;

@interface RCPhotoPreviewCollectionViewController : RCBaseCollectionViewController

@property (nonatomic, copy) void (^finishPreviewAndBackPhotosPicker)
    (NSMutableArray *selectArr, NSArray *assetPhotos, BOOL isFull);

@property (nonatomic, copy) void (^finishiPreviewAndSendImage)(NSArray *selectArr, BOOL isFull);

@property (nonatomic, copy) void (^onClickEditPhotoBlock)(UIViewController *rootCtrl, RCAssetModel *asset);

@property (nonatomic, assign) BOOL isFull;

/**
 是否开启了图片编辑功能
 */
@property (nonatomic, assign) BOOL photoEditEnable;

+ (instancetype)imagePickerViewController;

- (void)previewPhotosWithSelectArr:(NSMutableArray *)selectedArr
                      allPhotosArr:(NSArray *)allPhotosArr
                      currentIndex:(NSInteger)currentIndex
                  accordToIsSelect:(BOOL)isSelected;
@end
