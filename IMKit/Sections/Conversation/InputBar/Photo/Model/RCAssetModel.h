//
//  RCAssetModel.h
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/16.
//  Copyright © 2016年 张改红. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <UIKit/UIKit.h>

@interface RCAssetModel : NSObject

@property (nonatomic, strong) id asset;
/**
 *   缩略图
 */
@property (nonatomic, strong) UIImage *thumbnailImage;

/**
 *   预览图
 */
@property (nonatomic, strong) UIImage *previewImage;

/**
 *   原图Data
 */
@property (nonatomic, strong) NSData *originImageData;

/**
 *   原图大小
 */
@property (nonatomic, assign) CGFloat imageSize;

/**
 *   Orientation
 */
@property (nonatomic, assign) ALAssetOrientation imageOrientation;

@property (nonatomic, assign) BOOL isSelect;

@property (nonatomic, assign) NSInteger index;

/**
 assert 的类型
 */
@property (nonatomic, assign, readonly) PHAssetMediaType mediaType;

@property (nonatomic, strong) AVAsset *avAsset;

/**
 asset的时长，单位是秒
 */
@property (nonatomic, assign) NSTimeInterval duration;

@property (nonatomic, copy, readonly) NSString *durationText;

+ (RCAssetModel *)modelWithAsset:(id)asset;
@end
