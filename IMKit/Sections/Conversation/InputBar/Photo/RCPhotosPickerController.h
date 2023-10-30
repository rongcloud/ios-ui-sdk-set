//
//  RCPhotosPickerController.h
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/18.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCAssetHelper.h"
#import "RCBaseCollectionViewController.h"
@class RCAssetModel;
@interface RCPhotosPickerController : RCBaseCollectionViewController
@property (nonatomic, strong) NSMutableArray<RCAssetModel *> *assetArray;
@property (nonatomic, assign) long count;
@property (nonatomic, strong) id currentAsset;
@property (nonatomic, copy) void (^sendPhotosBlock)(NSArray *photos, BOOL isFull);

+ (instancetype)imagePickerViewController;
@end
