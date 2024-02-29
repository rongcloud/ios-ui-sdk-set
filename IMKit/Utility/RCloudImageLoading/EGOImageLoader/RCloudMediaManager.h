//
//  RCloudPretreatImage.h
//  RongIMKit
//
//  Created by 杨雨东 on 2018/9/20.
//  Copyright © 2018 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^RCDownsizeImageBlock)(UIImage *_Nullable image, BOOL doNothing);

NS_ASSUME_NONNULL_BEGIN

@interface RCloudMediaManager : NSObject
+ (RCloudMediaManager *)sharedManager;

@property (nonatomic, copy) RCDownsizeImageBlock progressBlock;

- (void)downsizeImage:(UIImage *)image
      completionBlock:(RCDownsizeImageBlock)imageBlock
        progressBlock:(RCDownsizeImageBlock)progressBlock;

/**
 降低图片分辨率，同步方法

 @param image 原始图片
 @return 压缩过的图片
 */
- (UIImage *)downsizeImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
