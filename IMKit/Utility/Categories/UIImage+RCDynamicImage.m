//
//  UIImage+RCDynamicImage.m
//  RongExtensionKit
//
//  Created by 张改红 on 2019/11/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "UIImage+RCDynamicImage.h"
#include <objc/runtime.h>
#import "RCExtensionService.h"
#import "RCKitConfig.h"
static const NSString *RCImageLocalPathKey = @"RCImageLocalPathKey";

@implementation UIImage (RCDynamicImage)
+ (UIImage *)rc_imageWithLocalPath:(NSString *)path {
    NSString *imagePath = [self getCurrentPathForTraitCollection:path];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    image.rc_imageLocalPath = imagePath;
    return image;
}

- (BOOL)rc_needReloadImage {
    if (!RCKitConfigCenter.ui.enableDarkMode) {
        return NO;
    }
    if (self.rc_imageLocalPath.length <= 0) {
        return NO;
    }
    if ([[self class] isDarkMode]) {
        if (![self.rc_imageLocalPath containsString:@"_dark"]) {
            NSString *currentPath = self.rc_imageLocalPath;
            currentPath = [currentPath stringByReplacingOccurrencesOfString:@".png" withString:@"_dark.png"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:currentPath] ||
                [[NSFileManager defaultManager]
                    fileExistsAtPath:[currentPath stringByReplacingOccurrencesOfString:@".png"
                                                                            withString:@"@2x.png"]] ||
                [[NSFileManager defaultManager]
                    fileExistsAtPath:[currentPath stringByReplacingOccurrencesOfString:@".png"
                                                                            withString:@"@3x.png"]]) {
                return YES;
            }
            return NO;
        }
    } else {
        if ([self.rc_imageLocalPath containsString:@"_dark"]) {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)getCurrentPathForTraitCollection:(NSString *)path {
    if (!RCKitConfigCenter.ui.enableDarkMode) {
        return path;
    }
    NSString *currentPath = path;
    if ([self isDarkMode]) {
        if (![path containsString:@"_dark"]) {
            currentPath = [path stringByReplacingOccurrencesOfString:@".png" withString:@"_dark.png"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:currentPath] ||
                [[NSFileManager defaultManager]
                    fileExistsAtPath:[currentPath stringByReplacingOccurrencesOfString:@".png"
                                                                            withString:@"@2x.png"]] ||
                [[NSFileManager defaultManager]
                    fileExistsAtPath:[currentPath stringByReplacingOccurrencesOfString:@".png"
                                                                            withString:@"@3x.png"]]) {
                return currentPath;
            } else {
                currentPath = path;
            }
        }
    } else {
        if ([path containsString:@"_dark"]) {
            currentPath = [path stringByReplacingOccurrencesOfString:@"_dark" withString:@""];
        }
    }
    return currentPath;
}

//判断是否是暗黑模式
+ (BOOL)isDarkMode {
    if (@available(iOS 13.0, *)) {
        NSNumber *currentUserInterfaceStyle =
        [[NSUserDefaults standardUserDefaults] objectForKey:@"RCCurrentUserInterfaceStyle"];
        if (!currentUserInterfaceStyle) {
            currentUserInterfaceStyle = @(UITraitCollection.currentTraitCollection.userInterfaceStyle);
        }
        if (currentUserInterfaceStyle.integerValue == UIUserInterfaceStyleDark) {
            return YES;
        }
    }
    return NO;
}

- (void)setRc_imageLocalPath:(NSString *)rc_imageLocalPath {
    objc_setAssociatedObject(self, &RCImageLocalPathKey, rc_imageLocalPath, OBJC_ASSOCIATION_RETAIN);
}

- (NSString *)rc_imageLocalPath {
    return objc_getAssociatedObject(self, &RCImageLocalPathKey);
}
@end
