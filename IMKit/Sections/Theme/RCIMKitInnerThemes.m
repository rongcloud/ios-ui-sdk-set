//
//  RCIMKitThemeContext.m
//  RongIMKit
//
//  Created by RobinCui on 2025/9/17.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCIMKitInnerThemes.h"
#import "UIColor+RCIMHexColor.h"
#import "RCKitCommonDefine.h"

// 主题名称常量
NSString *const RCIMKitThemeNameLight = @"light";
NSString *const RCIMKitThemeNameDark = @"dark";

// 欢快主题资源包名称
static NSString * const kLivelyThemeBundleName = @"RongCloudLively";

#pragma mark - RCIMKitInnerThemes

@interface RCIMKitInnerThemes()
@end

@implementation RCIMKitInnerThemes

- (UIColor *)dynamicColor:(NSString *)colorKey
               lightColor:(NSString *)lightHex
                darkColor:(NSString *)darkHex {
    // 基类默认实现,子类应该重写此方法
    return [UIColor clearColor];
}

- (UIImage *)dynamicImage:(NSString *)imageKey
         defaultImageName:(NSString *)defaultImageName {
    // 基类默认实现,子类应该重写此方法
    return nil;
}

- (UIColor *)defaultColor:(NSString *)colorKey
               lightColor:(NSString *)lightHex {
    // 基类默认实现,子类应该重写此方法
    return [UIColor clearColor];
}

- (UIImage *)defaultImage:(NSString *)imageKey defaultImageName:(NSString *)defaultImageName {
    // 基类默认实现,子类应该重写此方法
    return nil;
}

@end

#pragma mark - RCIMKitTraditionThemes

@implementation RCIMKitTraditionThemes

/// 获取动态颜色(支持浅色/深色模式)
/// - Parameters:
///   - colorKey: 颜色 key 值(传统主题不使用此参数)
///   - lightHex: 浅色模式颜色 Hex
///   - darkHex: 深色模式颜色 Hex
/// - Returns: 动态颜色对象
- (UIColor *)dynamicColor:(NSString *)colorKey
               lightColor:(NSString *)lightHex
                darkColor:(NSString *)darkHex {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor *_Nonnull(UITraitCollection *_Nonnull traitCollection) {
            switch (traitCollection.userInterfaceStyle) {
                case UIUserInterfaceStyleDark:
                    return [UIColor rcim_colorWithHex:darkHex];
                    
                case UIUserInterfaceStyleLight:
                case UIUserInterfaceStyleUnspecified:
                default:
                    return [UIColor rcim_colorWithHex:lightHex];
            }
        }];
    } else {
        // iOS 13 以下不支持深色模式,返回浅色
        return [UIColor rcim_colorWithHex:lightHex];
    }
}

/// 获取默认颜色(浅色模式)
/// - Parameters:
///   - colorKey: 颜色 key 值(传统主题不使用此参数)
///   - lightHex: 浅色模式颜色 Hex
/// - Returns: 颜色对象
- (UIColor *)defaultColor:(NSString *)colorKey 
               lightColor:(NSString *)lightHex {
    return [UIColor rcim_colorWithHex:lightHex];
}

/// 获取动态图片
/// - Parameters:
///   - imageKey: 图片 key 值(传统主题不使用此参数)
///   - defaultImageName: 图片名称
/// - Returns: 图片对象
- (UIImage *)dynamicImage:(NSString *)imageKey
         defaultImageName:(NSString *)defaultImageName {
    if (![self isValidString:defaultImageName]) {
        return nil;
    }
    return RCResourceImage(defaultImageName);
}

/// 获取默认图片
/// - Parameter imageKey: 图片名称
/// - Returns: 图片对象
- (UIImage *)defaultImage:(NSString *)imageKey defaultImageName:(NSString *)defaultImageName{
    if (![self isValidString:defaultImageName]) {
        return nil;
    }
    return RCResourceImage(defaultImageName);
}

#pragma mark - Helper Methods

/// 验证字符串是否有效
/// - Parameter string: 待验证的字符串
/// - Returns: 是否有效
- (BOOL)isValidString:(NSString *)string {
    return [string isKindOfClass:[NSString class]] && string.length > 0;
}

@end

#pragma mark - RCIMKitLivelyThemes

@interface RCIMKitLivelyThemes()

/// 浅色主题
@property (nonatomic, strong) RCIMKitTheme *lightTheme;

/// 深色主题
@property (nonatomic, strong) RCIMKitTheme *darkTheme;

@end

@implementation RCIMKitLivelyThemes

#pragma mark - Public Methods

/// 获取动态颜色(支持浅色/深色模式)
/// - Parameters:
///   - colorKey: 欢快主题颜色 key 值
///   - lightHex: 浅色模式默认颜色 Hex
///   - darkHex: 深色模式默认颜色 Hex
/// - Returns: 动态颜色对象
- (UIColor *)dynamicColor:(NSString *)colorKey
               lightColor:(NSString *)lightHex
                darkColor:(NSString *)darkHex {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor *_Nonnull(UITraitCollection *_Nonnull traitCollection) {
            switch (traitCollection.userInterfaceStyle) {
                case UIUserInterfaceStyleDark:
                    return [self.darkTheme dynamicColor:colorKey defaultColor:darkHex];
                    
                case UIUserInterfaceStyleLight:
                case UIUserInterfaceStyleUnspecified:
                default:
                    return [self.lightTheme dynamicColor:colorKey defaultColor:lightHex];
            }
        }];
    } else {
        // iOS 13 以下不支持深色模式,返回浅色主题颜色
        return [self.lightTheme dynamicColor:colorKey defaultColor:lightHex];
    }
}

/// 获取动态图片(支持浅色/深色模式)
/// - Parameters:
///   - imageKey: 欢快主题图片 key 值
///   - defaultImageName: 默认图片名称(未使用)
/// - Returns: 动态图片对象
- (UIImage *)dynamicImage:(NSString *)imageKey
         defaultImageName:(NSString *)defaultImageName {
    UIImage *lightImage = [self.lightTheme dynamicImage:imageKey defaultImage:nil];
    UIImage *darkImage = [self.darkTheme dynamicImage:imageKey defaultImage:nil];
    return [self combinedImageWithLight:lightImage dark:darkImage];
}

/// 获取默认图片(浅色模式)
/// - Parameter imageKey: 欢快主题图片 key 值
/// - Returns: 图片对象
- (UIImage *)defaultImage:(NSString *)imageKey defaultImageName:(NSString *)defaultImageName{
    return [self.lightTheme dynamicImage:imageKey defaultImage:nil];
}

#pragma mark - Private Methods

/// 组合浅色和深色图片为动态图片
/// - Parameters:
///   - lightImage: 浅色模式图片
///   - darkImage: 深色模式图片
/// - Returns: 动态图片对象
- (UIImage *)combinedImageWithLight:(UIImage *)lightImage 
                               dark:(UIImage *)darkImage {
    if (@available(iOS 13.0, *)) {
        if (!lightImage) {
            return darkImage;
        }
        if (!darkImage) {
            return lightImage;
        }
        
        // 获取屏幕缩放比例
        CGFloat scale = [UIScreen mainScreen].scale;
        UITraitCollection *scaleTraitCollection = [UITraitCollection traitCollectionWithDisplayScale:scale];
        
        // 创建浅色模式的 trait collection
        UITraitCollection *lightTraitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
        
        // 创建深色模式的 trait collection(包含缩放比例)
        UITraitCollection *darkUnscaledTraitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
        UITraitCollection *darkScaledTraitCollection = [UITraitCollection traitCollectionWithTraitsFromCollections:@[scaleTraitCollection, darkUnscaledTraitCollection]];
        
        // 为浅色图片配置 trait collection
        UIImage *configuredLightImage = [lightImage imageWithConfiguration:[lightImage.configuration configurationWithTraitCollection:lightTraitCollection]];
        
        // 为深色图片配置 trait collection
        UIImage *configuredDarkImage = [darkImage imageWithConfiguration:[darkImage.configuration configurationWithTraitCollection:darkScaledTraitCollection]];
        
        // 注册深色图片到图片资源集
        [configuredLightImage.imageAsset registerImage:configuredDarkImage withTraitCollection:darkScaledTraitCollection];
        
        return configuredLightImage;
    } else {
        // iOS 13 以下不支持深色模式,返回浅色图片
        return lightImage;
    }
}

/// 获取主题文件路径
/// - Parameter themeName: 主题名称
/// - Returns: 主题文件夹路径
- (NSString *)pathForTheme:(NSString *)themeName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *bundlePath = [bundle pathForResource:kLivelyThemeBundleName ofType:@"bundle"];
    NSString *themePath = [bundlePath stringByAppendingPathComponent:themeName];
    return themePath;
}

#pragma mark - Lazy Loading

- (RCIMKitTheme *)lightTheme {
    if (!_lightTheme) {
        NSString *path = [self pathForTheme:RCIMKitThemeNameLight];
        _lightTheme = [[RCIMKitTheme alloc] initWithThemePath:path];
    }
    return _lightTheme;
}

- (RCIMKitTheme *)darkTheme {
    if (!_darkTheme) {
        NSString *path = [self pathForTheme:RCIMKitThemeNameDark];
        _darkTheme = [[RCIMKitTheme alloc] initWithThemePath:path];
    }
    return _darkTheme;
}

@end
