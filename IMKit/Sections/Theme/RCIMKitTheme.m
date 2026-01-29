//
//  RCIMKitTheme.m
//  RongIMKit
//
//  Created by RobinCui on 2025/9/17.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCIMKitTheme.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "UIColor+RCIMHexColor.h"

// 主题配置文件常量
static NSString * const kThemePlistFileName = @"theme.plist";
static NSString * const kThemeResourcesDirectoryName = @"resources";

// 主题配置字典 Key
static NSString * const kThemeNameKey = @"name";
static NSString * const kThemeColorsKey = @"colors";
static NSString * const kThemeImagesKey = @"images";

@interface RCIMKitTheme()

@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSString *> *colors;
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSString *> *images;
@property (nonatomic, copy, readwrite) NSString *resourcePath;
@property (nonatomic, copy, readwrite) NSString *plistPath;

@end

@implementation RCIMKitTheme

#pragma mark - Lifecycle

- (instancetype)initWithThemePath:(NSString *)path {
    if (self = [super init]) {
        [self loadDataWithPath:path];
    }
    return self;
}

#pragma mark - Private Methods

/// 从指定路径加载主题数据
/// - Parameter path: 主题文件夹路径
- (void)loadDataWithPath:(NSString *)path {
    // 验证路径有效性
    if (!path || path.length == 0) {
        RCLogE(@"[RCIMKitTheme] theme path is invalid");
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        RCLogE(@"[RCIMKitTheme] theme path does not exist: %@", path);
        return;
    }
    
    // 验证 plist 配置文件
    NSString *plistPath = [path stringByAppendingPathComponent:kThemePlistFileName];
    if (![fileManager fileExistsAtPath:plistPath]) {
        RCLogE(@"[RCIMKitTheme] theme plist file is not found: %@", plistPath);
        return;
    }
    
    // 验证资源文件夹
    NSString *resourcePath = [path stringByAppendingPathComponent:kThemeResourcesDirectoryName];
    if (![fileManager fileExistsAtPath:resourcePath]) {
        RCLogE(@"[RCIMKitTheme] theme resources directory is not found: %@", resourcePath);
        return;
    }
    
    // 加载并验证 plist 配置
    NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    if (![themeDict isKindOfClass:[NSDictionary class]]) {
        RCLogE(@"[RCIMKitTheme] theme plist file format is invalid: %@", plistPath);
        return;
    }
    
    // 解析主题配置
    [self parseThemeConfiguration:themeDict];
    
    // 保存路径信息
    self.resourcePath = resourcePath;
    self.plistPath = plistPath;
}

/// 解析主题配置字典
/// - Parameter themeDict: 主题配置字典
- (void)parseThemeConfiguration:(NSDictionary *)themeDict {
    // 解析主题名称
    id nameValue = themeDict[kThemeNameKey];
    if ([nameValue isKindOfClass:[NSString class]]) {
        self.name = nameValue;
    }
    
    // 解析颜色配置
    id colorsValue = themeDict[kThemeColorsKey];
    if ([colorsValue isKindOfClass:[NSDictionary class]]) {
        self.colors = colorsValue;
    }
    
    // 解析图片配置
    id imagesValue = themeDict[kThemeImagesKey];
    if ([imagesValue isKindOfClass:[NSDictionary class]]) {
        self.images = imagesValue;
    }
}

#pragma mark - Public Methods

/// 获取动态颜色
/// - Parameters:
///   - colorKey: 颜色 key 值
///   - hex: 默认颜色 Hex
/// - Returns: 颜色对象,如果无法获取则返回 nil
- (UIColor *)dynamicColor:(NSString *)colorKey
             defaultColor:(NSString *)hex {
    // 参数验证
    if (![self isValidStringKey:colorKey]) {
        return nil;
    }
    
    // 优先从主题配置中获取颜色
    UIColor *color = [self colorFromThemeWithKey:colorKey];
    
    // 如果主题中没有配置,使用默认颜色
    if (!color && hex) {
        color = [UIColor rcim_colorWithHex:hex];
    }
    
    return color;
}

/// 获取动态图片
/// - Parameters:
///   - imageKey: 图片 key 值
///   - defaultImage: 默认图片
/// - Returns: 图片对象,如果无法获取则返回默认图片
- (UIImage *)dynamicImage:(NSString *)imageKey
             defaultImage:(UIImage *)defaultImage {
    // 参数验证
    if (![self isValidStringKey:imageKey]) {
        return defaultImage;
    }
    
    // 优先从主题配置中获取图片
    UIImage *image = [self imageFromThemeWithKey:imageKey];
    
    // 如果主题中没有配置,使用默认图片
    return image ?: defaultImage;
}

#pragma mark - Helper Methods

/// 验证字符串 key 是否有效
/// - Parameter key: 待验证的 key
/// - Returns: 是否有效
- (BOOL)isValidStringKey:(NSString *)key {
    return [key isKindOfClass:[NSString class]] && key.length > 0;
}

/// 从主题配置中获取颜色
/// - Parameter colorKey: 颜色 key
/// - Returns: 颜色对象,如果不存在则返回 nil
- (UIColor *)colorFromThemeWithKey:(NSString *)colorKey {
    NSString *colorHex = self.colors[colorKey];
    if ([colorHex isKindOfClass:[NSString class]] && colorHex.length > 0) {
        return [UIColor rcim_colorWithHex:colorHex];
    }
    return nil;
}

/// 从主题配置中获取图片
/// - Parameter imageKey: 图片 key
/// - Returns: 图片对象,如果不存在则返回 nil
- (UIImage *)imageFromThemeWithKey:(NSString *)imageKey {
    NSString *imageName = self.images[imageKey];
    if (![imageName isKindOfClass:[NSString class]] || imageName.length == 0) {
        return nil;
    }
    
    // 构建完整的图片路径
    NSString *imagePath = [self.resourcePath stringByAppendingPathComponent:imageName];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    
    if (!image) {
        RCLogW(@"[RCIMKitTheme] Failed to load image at path: %@", imagePath);
    }
    
    return image;
}

@end
