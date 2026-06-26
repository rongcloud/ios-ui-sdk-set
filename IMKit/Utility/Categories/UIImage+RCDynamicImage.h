//
//  UIImage+RCDynamicImage.h
//  RongExtensionKit
//
//  Created by 张改红 on 2019/11/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (RCDynamicImage)

@property (nonatomic, copy) NSString *rc_imageLocalPath;

+ (UIImage *)rc_imageWithLocalPath:(NSString *)path;

- (BOOL)rc_needReloadImage;
@end

NS_ASSUME_NONNULL_END
