//
//  RCPhotoPreviewCollectionViewController.h
//  RongExtensionKit
//
//  Created by RongCloud on 16/3/17.
//  Copyright © 2016 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCBaseCollectionViewController.h"
@class RCAssetModel;

@interface RCPhotoPreviewCollectionViewController : RCBaseCollectionViewController

@property (nonatomic, copy) void (^finishPreviewAndBackPhotosPicker)
    (NSMutableArray *selectArr, NSArray *assetPhotos, BOOL isFull);

@property (nonatomic, copy) void (^finishiPreviewAndSendImage)(NSArray *selectArr, BOOL isFull);

@property (nonatomic, assign) BOOL isFull;

+ (instancetype)imagePickerViewController;

- (void)previewPhotosWithSelectArr:(NSMutableArray *)selectedArr
                      allPhotosArr:(NSArray *)allPhotosArr
                      currentIndex:(NSInteger)currentIndex
                  accordToIsSelect:(BOOL)isSelected;
@end
