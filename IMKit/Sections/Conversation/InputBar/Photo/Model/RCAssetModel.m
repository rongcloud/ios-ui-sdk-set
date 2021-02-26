//
//  RCAssetModel.m
//  RongExtensionKit
//
//  Created by 张改红 on 16/3/16.
//  Copyright © 2016年 张改红. All rights reserved.
//

#import "RCAssetModel.h"
#import "RCAssetHelper.h"
#import "RCKitCommonDefine.h"

#define WIDTH ([UIScreen mainScreen].bounds.size.width - 20) / 4
#define SIZE CGSizeMake(WIDTH, WIDTH)

@interface RCAssetModel ()
@property (nonatomic, assign) int32_t imageRequestID;
@property (nonatomic, copy) NSString *durationText;

@end
@implementation RCAssetModel
+ (RCAssetModel *)modelWithAsset:(id)asset {
    RCAssetModel *model = [[RCAssetModel alloc] init];
    model.asset = asset;
    return model;
}

- (UIImage *)thumbnailImage {
    if (_thumbnailImage) {
        return _thumbnailImage;
    }
    [[RCAssetHelper shareAssetHelper] getThumbnailWithAsset:self.asset
                                                       size:CGSizeMake((WIDTH * SCREEN_SCALE), (WIDTH * SCREEN_SCALE))
                                                     result:^(UIImage *thumbnailImage) {
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             _thumbnailImage = thumbnailImage;
                                                         });
                                                     }];
    return _thumbnailImage;
}

- (UIImage *)previewImage {
    if (_previewImage) {
        return _previewImage;
    }

    [[RCAssetHelper shareAssetHelper] getPreviewWithAsset:self.asset
                                                   result:^(UIImage *photo, NSDictionary *info) {
                                                       // 排除取消，错误，低清图三种情况，即获取到高清图
                                                       BOOL downloadFinined =
                                                           ![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                                           ![info objectForKey:PHImageErrorKey] &&
                                                           ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                                                       if (downloadFinined) {
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               _previewImage = photo;

                                                           });
                                                       }
                                                   }];
    return _previewImage;
}

- (NSData *)originImageData {
    if (!_originImageData) {
        self.imageRequestID = [self fetchOriginData];
    }
    return _originImageData;
}

- (CGFloat)imageSize {
    if (!_imageSize) {
        [[RCAssetHelper shareAssetHelper] getAssetDataSizeWithAsset:self.asset
                                                             result:^(CGFloat size) {
                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                     _imageSize = size;
                                                                 });
                                                             }];
    }
    return _imageSize;
}

- (ALAssetOrientation)imageOrientation {
    if (_imageOrientation) {
        return _imageOrientation;
    }
    _imageOrientation = [[self.asset valueForProperty:@"ALAssetPropertyOrientation"] integerValue];
    return _imageOrientation;
}

- (void)setValue:(id)value forKey:(NSString *)key {
}

- (PHImageRequestID)fetchOriginData {
    //获取大图前如果已经存在获取的请求，先取消之前的请求再重新启动请求（重新请求也是在上次请求的基础上请求，类似断点续传）
    if (self.imageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
        self.imageRequestID = 0;
    }
    __weak typeof(self) weakSelf = self;
    if (self.mediaType == PHAssetMediaTypeVideo && NSClassFromString(@"RCSightCapturer")) {
        return [[RCAssetHelper shareAssetHelper]
            getOriginVideoWithAsset:self.asset
                             result:^(AVAsset *avAsset, NSDictionary *info, NSString *imageIdentifier) {
                                 if (![[[RCAssetHelper shareAssetHelper] getAssetIdentifier:self.asset] isEqualToString:imageIdentifier]) {
                                     return;
                                 }
                                 BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                                         ![info objectForKey:PHImageErrorKey] &&
                                                         ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                                 if (downloadFinined) {
                                     weakSelf.avAsset = avAsset;
                                 }
                             }
                    progressHandler:nil];
    } else {
        return [[RCAssetHelper shareAssetHelper]
            getOriginImageDataWithAsset:self
                                 result:^(NSData *imageData, NSDictionary *info, RCAssetModel *assetModel) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         BOOL downloadFinined =
                                             (![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                              ![info objectForKey:PHImageErrorKey] &&
                                              ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                                         if (downloadFinined) {
                                             weakSelf.originImageData = imageData;
                                         }
                                     });
                                 }
                        progressHandler:nil];
    }
}

- (void)setIsSelect:(BOOL)isSelect {
    _isSelect = isSelect;
    if (isSelect) {
        //选中后，提前获取下大图
        self.imageRequestID = [self fetchOriginData];
    } else {
        //取消选中，取消大图的获取
        if (self.imageRequestID) {
            [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
            self.imageRequestID = 0;
        }
    }
}

- (PHAssetMediaType)mediaType {
    return ((PHAsset *)self.asset).mediaType;
}

- (NSTimeInterval)duration {
    if (0 == _duration && self.avAsset) {
        _duration = CMTimeGetSeconds(self.avAsset.duration);
    }
    return _duration;
}

- (NSString *)durationText {
    if (!_durationText && self.duration != 0) {
        NSTimeInterval duration = round(self.duration);
        NSTimeInterval fmiutes = duration / 60;
        NSUInteger minutes = fmiutes;
        NSUInteger seconds = round(duration - minutes * 60);
        if (seconds == 60) {
            minutes += 1;
            seconds = 0;
        }
        if (minutes != 0 || seconds != 0) {
            _durationText = [NSString stringWithFormat:@"%02lu:%02lu", (unsigned long)minutes, (unsigned long)seconds];
        }
    }
    return _durationText;
}

@end
