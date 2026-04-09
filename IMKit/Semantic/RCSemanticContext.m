//
//  RCSemanticContext.m
//  RongIMKit
//
//  Created by RobinCui on 2022/9/6.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCSemanticContext.h"
#import <UIKit/UIKit.h>
#import "RCKitUtility.h"
@implementation RCSemanticContext

+ (BOOL)isRTL {
    return [RCKitUtility isRTL];
}

+ (void)configureAttributeForNavigationController:(UINavigationController *)navi {
    if (@available(iOS 9.0, *)) {
        if ([self isRTL]) {
            navi.navigationBar.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;;
            navi.view.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        } else {
            navi.navigationBar.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;;
            navi.view.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
    }
}

+ (UIImage *)imageflippedForRTL:(UIImage *)image {
    if (!image || ![self isRTL]) {
        return image;
    }
    
    // iOS 13+ 尝试保留动态图片特性
    if (@available(iOS 13.0, *)) {
        UIImage *dynamicFlippedImage = [self p_flippedDynamicImage:image];
        if (dynamicFlippedImage) {
            return dynamicFlippedImage;
        }
    }
    
    // 默认处理：直接翻转
    return [self p_flippedImage:image];
}

#pragma mark - Private

/// 翻转单个图片
+ (UIImage *)p_flippedImage:(UIImage *)image {
    if (!image.CGImage) {
        return image;
    }
    return [UIImage imageWithCGImage:image.CGImage
                               scale:image.scale
                         orientation:UIImageOrientationUpMirrored];
}

/// 翻转动态图片（保留深色/浅色模式支持）
+ (UIImage *)p_flippedDynamicImage:(UIImage *)image API_AVAILABLE(ios(13.0)) {
    UIImageAsset *imageAsset = image.imageAsset;
    if (!imageAsset) {
        return nil;
    }
    
    UITraitCollection *lightTrait = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    UITraitCollection *darkTrait = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
    
    UIImage *lightImage = [imageAsset imageWithTraitCollection:lightTrait];
    UIImage *darkImage = [imageAsset imageWithTraitCollection:darkTrait];
    
    // 非动态图片（浅色和深色相同）
    if (!lightImage || !darkImage || lightImage.CGImage == darkImage.CGImage) {
        return nil;
    }
    
    // 分别翻转
    UIImage *flippedLight = [self p_flippedImage:lightImage];
    UIImage *flippedDark = [self p_flippedImage:darkImage];
    
    // 组合为动态图片
    return [self p_combineDynamicImageWithLight:flippedLight dark:flippedDark];
}

/// 组合浅色和深色图片为动态图片
+ (UIImage *)p_combineDynamicImageWithLight:(UIImage *)lightImage 
                                       dark:(UIImage *)darkImage API_AVAILABLE(ios(13.0)) {
    CGFloat scale = [UIScreen mainScreen].scale;
    UITraitCollection *scaleTrait = [UITraitCollection traitCollectionWithDisplayScale:scale];
    UITraitCollection *lightTrait = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    UITraitCollection *darkTrait = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
    UITraitCollection *darkScaledTrait = [UITraitCollection traitCollectionWithTraitsFromCollections:@[scaleTrait, darkTrait]];
    
    UIImage *configuredLight = [lightImage imageWithConfiguration:[lightImage.configuration configurationWithTraitCollection:lightTrait]];
    UIImage *configuredDark = [darkImage imageWithConfiguration:[darkImage.configuration configurationWithTraitCollection:darkScaledTrait]];
    
    [configuredLight.imageAsset registerImage:configuredDark withTraitCollection:darkScaledTrait];
    
    return configuredLight;
}

+ (CGRect)modifyFrameForRTL:(CGRect)frame toX:(CGFloat)x {
    if (@available(iOS 9.0, *)) {
        if ([self isRTL]) {
            CGRect rect = CGRectMake(x,
                                     frame.origin.y,
                                     frame.size.width,
                                     frame.size.height);
            return rect;
        }
    }
    return frame;
}

+ (void)swapFrameForRTL:(UIView *)firstView withView:(UIView *)secondView {
    
    if (@available(iOS 9.0, *)) {
        if ([self isRTL]) {
            CGRect rect = firstView.frame;
            
            firstView.frame =  CGRectMake(secondView.frame.origin.x,
                                          firstView.frame.origin.y,
                                          firstView.frame.size.width,
                                          firstView.frame.size.height);
            secondView.frame =  CGRectMake(rect.origin.x,
                                          secondView.frame.origin.y,
                                          secondView.frame.size.width,
                                          secondView.frame.size.height);
        }
    }
}
@end
