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
 *   缩略图，只有选中的时候进行赋值，保证内存里面最多 9 个该类有缩略图
 */
@property (nonatomic, strong) UIImage *thumbnailImage;

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

// 如果 self 为视频类型且 avAsset 为 nil，说明视频数据无法从本地或者 icloud 拿到
@property (nonatomic, strong) AVAsset *avAsset;

/**
 asset的时长，单位是秒
 */
@property (nonatomic, assign) NSTimeInterval duration;

@property (nonatomic, copy, readonly) NSString *durationText;

/// 加载缩略图时尝试获取大图，本地没有大图且从 iCloud 下载大图失败时为 YES
@property (nonatomic, assign) BOOL isDownloadFailFromiCloud;

//如果是视频类型，并且 avAsset 为无效数据则返回 YES，其余返回 NO
- (BOOL)isVideoAssetInvalid;

//为了解决相册大量图片性能问题，默认不保存缩略图，但是图片视频被选中后就需要保存了`
- (void)fetchThumbnailImage;

+ (RCAssetModel *)modelWithAsset:(id)asset;
@end
