//
//  RCloudPretreatImage.m
//  RongIMKit
//
//  Created by 杨雨东 on 2018/9/20.
//  Copyright © 2018 RongCloud. All rights reserved.
//

#import "RCloudMediaManager.h"
#import "RCKitCommonDefine.h"

#define kDestImageSizeMB 200.0f      // 预定目标图片最大大小
#define kSourceImageTileSizeMB 40.0f // 原图片分块大小
#define bytesPerMB 1048576.0f
#define bytesPerPixel 4.0f
#define pixelsPerMB (bytesPerMB / bytesPerPixel) // 262144 pixels, for 4 bytes per pixel.
#define destTotalPixels kDestImageSizeMB *pixelsPerMB
#define tileTotalPixels kSourceImageTileSizeMB *pixelsPerMB
#define destSeemOverlap 2.0f // the numbers of pixels to overlap the seems where tiles meet.

@implementation RCloudMediaManager {
    dispatch_queue_t _imageProcessQueue;
}
+ (RCloudMediaManager *)sharedManager {
    static RCloudMediaManager *_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc] init];
    });
    return _manager;
}

// 大图缩小：防止渲染的图片所占物理内存过大导致系统回收
- (void)downsizeImage:(UIImage *)sourceImage
      completionBlock:(nonnull RCDownsizeImageBlock)completionBlock
        progressBlock:(nonnull RCDownsizeImageBlock)progressBlock {
    if (!sourceImage) {
        if(completionBlock){
            completionBlock(nil, YES);
        }
        return;
    }

    CGSize sourceResolution;
    sourceResolution.width = CGImageGetWidth(sourceImage.CGImage);
    sourceResolution.height = CGImageGetHeight(sourceImage.CGImage);

    CGFloat sourceTotalPixels = sourceResolution.width * sourceResolution.height;
    CGFloat sourceTotalMB = sourceTotalPixels / pixelsPerMB; // 图片所占物理内存
    if (sourceTotalMB < kDestImageSizeMB) {
        completionBlock(sourceImage, YES);
        return;
    }

    if (!_imageProcessQueue) {
        _imageProcessQueue = dispatch_queue_create("rc_image_process_queue", DISPATCH_QUEUE_CONCURRENT);
    }
    dispatch_async(_imageProcessQueue, ^{
        CGFloat imageScale = destTotalPixels / sourceTotalPixels;
        CGSize destResolution;

        destResolution.width = (int)(sourceResolution.width * imageScale);
        destResolution.height = (int)(sourceResolution.height * imageScale);

        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        int bytesPerRow = bytesPerPixel * destResolution.width;
        void *destBitmapData = malloc(bytesPerRow * destResolution.height);
        if (destBitmapData == NULL) {
            DebugLog(@"failed to allocate space for the output image!");
            CGColorSpaceRelease(colorSpace);
            completionBlock(nil, YES);
            return;
        };

        CGContextRef _destContext = CGBitmapContextCreate(destBitmapData, destResolution.width, destResolution.height,
                                                          8, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
        if (_destContext == NULL) {
            free(destBitmapData);
            CGColorSpaceRelease(colorSpace);
            completionBlock(nil, YES);
            return;
        }
        CGColorSpaceRelease(colorSpace);

        CGRect sourceTile;
        CGRect destTile;

        sourceTile.size.width = sourceResolution.width;
        sourceTile.size.height = (int)(tileTotalPixels / sourceTile.size.width);
        sourceTile.origin.x = 0.0f;

        destTile.size.width = destResolution.width;
        destTile.size.height = sourceTile.size.height * imageScale;
        destTile.origin.x = 0.0f;

        CGFloat sourceSeemOverlap = (int)((destSeemOverlap / destResolution.height) * sourceResolution.height);

        CGImageRef sourceTileImageRef;

        int iterations = (int)(sourceResolution.height / sourceTile.size.height);

        int remainder = (int)sourceResolution.height % (int)sourceTile.size.height;
        if (remainder)
            iterations++;

        float sourceTileHeightMinusOverlap = sourceTile.size.height;
        sourceTile.size.height += sourceSeemOverlap;
        destTile.size.height += destSeemOverlap;

        for (NSInteger y = 0; y < iterations; ++y) {
            DebugLog(@"iteration %ld of %d", (long)y + 1, iterations);
            sourceTile.origin.y = y * sourceTileHeightMinusOverlap + sourceSeemOverlap;
            destTile.origin.y =
                (destResolution.height) - ((y + 1) * sourceTileHeightMinusOverlap * imageScale + destSeemOverlap);

            sourceTileImageRef = CGImageCreateWithImageInRect(sourceImage.CGImage, sourceTile);

            if (y == iterations - 1 && remainder) {
                float dify = destTile.size.height;
                destTile.size.height = CGImageGetHeight(sourceTileImageRef) * imageScale;
                dify -= destTile.size.height;
                destTile.origin.y += dify;
            }
            CGContextDrawImage(_destContext, destTile, sourceTileImageRef);
            CGImageRelease(sourceTileImageRef);
            if (y < (iterations - 1) && progressBlock) {
                CGImageRef destImageRef = CGBitmapContextCreateImage(_destContext);
                if (destImageRef == NULL) {
                    DebugLog(@"destImageRef is null.");
                    CGContextRelease(_destContext);
                    free(destBitmapData);
                    return;
                }
                UIImage *progressImage = [UIImage imageWithCGImage:destImageRef];
                progressBlock(progressImage, NO);
                CGImageRelease(destImageRef);
            }
        }
        CGImageRef destImageRef = CGBitmapContextCreateImage(_destContext);
        if (destImageRef == NULL) {
            DebugLog(@"destImageRef is null.");
            CGContextRelease(_destContext);
            free(destBitmapData);
            return;
        }
        UIImage *progressImage = [UIImage imageWithCGImage:destImageRef];
        if (completionBlock) {
            completionBlock(progressImage, NO);
        }
        CGContextRelease(_destContext);
        CGImageRelease(destImageRef);
        free(destBitmapData);
    });
}
- (UIImage *)downsizeImage:(UIImage *)sourceImage {
    CGSize sourceResolution;
    sourceResolution.width = CGImageGetWidth(sourceImage.CGImage);
    sourceResolution.height = CGImageGetHeight(sourceImage.CGImage);

    CGFloat sourceTotalPixels = sourceResolution.width * sourceResolution.height;
    CGFloat sourceTotalMB = sourceTotalPixels / pixelsPerMB;
    if (sourceTotalMB < kDestImageSizeMB) {
        return sourceImage;
    }

    CGFloat imageScale = destTotalPixels / sourceTotalPixels;
    CGSize destResolution;

    destResolution.width = (int)(sourceResolution.width * imageScale);
    destResolution.height = (int)(sourceResolution.height * imageScale);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int bytesPerRow = bytesPerPixel * destResolution.width;
    void *destBitmapData = malloc(bytesPerRow * destResolution.height);
    if (destBitmapData == NULL) {
        DebugLog(@"failed to allocate space for the output image!");
        CGColorSpaceRelease(colorSpace);
        return [UIImage new];
    };

    CGContextRef _destContext = CGBitmapContextCreate(destBitmapData, destResolution.width, destResolution.height, 8,
                                                      bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    if (_destContext == NULL) {
        free(destBitmapData);
        CGColorSpaceRelease(colorSpace);
        return [UIImage new];
    }
    CGColorSpaceRelease(colorSpace);

    CGRect sourceTile;
    CGRect destTile;

    sourceTile.size.width = sourceResolution.width;
    sourceTile.size.height = (int)(tileTotalPixels / sourceTile.size.width);
    sourceTile.origin.x = 0.0f;

    destTile.size.width = destResolution.width;
    destTile.size.height = sourceTile.size.height * imageScale;
    destTile.origin.x = 0.0f;

    CGFloat sourceSeemOverlap = (int)((destSeemOverlap / destResolution.height) * sourceResolution.height);

    CGImageRef sourceTileImageRef;

    int iterations = (int)(sourceResolution.height / sourceTile.size.height);

    int remainder = (int)sourceResolution.height % (int)sourceTile.size.height;
    if (remainder)
        iterations++;

    float sourceTileHeightMinusOverlap = sourceTile.size.height;
    sourceTile.size.height += sourceSeemOverlap;
    destTile.size.height += destSeemOverlap;

    for (NSInteger y = 0; y < iterations; ++y) {
        DebugLog(@"iteration %ld of %d", (long)y + 1, iterations);
        sourceTile.origin.y = y * sourceTileHeightMinusOverlap + sourceSeemOverlap;
        destTile.origin.y =
            (destResolution.height) - ((y + 1) * sourceTileHeightMinusOverlap * imageScale + destSeemOverlap);

        sourceTileImageRef = CGImageCreateWithImageInRect(sourceImage.CGImage, sourceTile);

        if (y == iterations - 1 && remainder) {
            float dify = destTile.size.height;
            destTile.size.height = CGImageGetHeight(sourceTileImageRef) * imageScale;
            dify -= destTile.size.height;
            destTile.origin.y += dify;
        }
        CGContextDrawImage(_destContext, destTile, sourceTileImageRef);
        CGImageRelease(sourceTileImageRef);
    }
    CGImageRef destImageRef = CGBitmapContextCreateImage(_destContext);
    if (destImageRef == NULL) {
        CGContextRelease(_destContext);
        free(destBitmapData);
        return [UIImage new];
    }
    UIImage *progressImage = [UIImage imageWithCGImage:destImageRef];

    CGContextRelease(_destContext);
    CGImageRelease(destImageRef);
    free(destBitmapData);

    return progressImage;
}
@end
