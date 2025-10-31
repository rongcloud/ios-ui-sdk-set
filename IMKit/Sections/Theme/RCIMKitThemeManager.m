//
//  RCIMKitThemeManager.m
//  RongIMKit
//
//  Created by RobinCui on 2025/9/17.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCIMKitThemeManager.h"
#import "RCIMKitInnerThemes.h"
#import "RCIMThreadLock.h"
#import "RCKitUtility.h"

@interface RCIMKitThemeManager() {
    RCIMKitInnerThemesType _innerThemesType;
    RCIMKitTheme *_currentTheme;
}
@property (nonatomic, assign) RCIMKitInnerThemesType innerThemesType;
@property (nonatomic, strong) RCIMKitTraditionThemes *traditionThemes;
@property (nonatomic, strong) RCIMKitLivelyThemes *livelyThemes;
@property (nonatomic, strong) RCIMKitTheme *currentTheme;
@property (nonatomic, strong) NSHashTable *delegates;
@property (nonatomic, strong) RCIMThreadLock *lock;

/// 验证内置主题类型是否有效
/// - Parameter type: 主题类型
/// - Returns: 是否有效
- (BOOL)isValidInnerThemesType:(RCIMKitInnerThemesType)type;

/// 获取当前内置主题实例
/// - Returns: 内置主题实例
- (RCIMKitInnerThemes *)currentInnerThemes;

/// 通知所有代理主题已变更
- (void)noticeThemeChanged;

@end

@implementation RCIMKitThemeManager

#pragma mark - Lifecycle

+ (instancetype)sharedInstance {
    static RCIMKitThemeManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _delegates = [NSHashTable weakObjectsHashTable];
        _lock = [RCIMThreadLock new];
        _innerThemesType = RCIMKitInnerThemesTypeTradition; // 默认使用传统主题
    }
    return self;
}

#pragma mark - Public Class Methods

+ (RCIMKitInnerThemesType)currentInnerThemesType {
    return [[RCIMKitThemeManager sharedInstance] innerThemesType];
}

+ (BOOL)changeInnerTheme:(RCIMKitInnerThemesType)type {
    return [self changeCustomTheme:nil baseOnTheme:type];
}

+ (void)addThemeDelegate:(id<RCIMKitThemeDelegate>)delegate {
    [[RCIMKitThemeManager sharedInstance] addThemeDelegate:delegate];
}

+ (void)removeThemeDelegate:(id<RCIMKitThemeDelegate>)delegate {
    [[RCIMKitThemeManager sharedInstance] removeThemeDelegate:delegate];
}

+ (BOOL)changeCustomTheme:(RCIMKitTheme *)theme
         baseOnTheme:(RCIMKitInnerThemesType)innerThemesType {
    return [[RCIMKitThemeManager sharedInstance] changeCustomTheme:theme
                                                  baseOnTheme:innerThemesType];
}

+ (UIColor *)dynamicColor:(NSString *)colorKey
               lightColor:(NSString *)lightHex
                darkColor:(NSString *)darkHex {
    return [[RCIMKitThemeManager sharedInstance] dynamicColor:colorKey
                                                   lightColor:lightHex
                                                    darkColor:darkHex];
}

+ (UIImage *)dynamicImage:(NSString *)imageKey
         defaultImageName:(NSString *)defaultImageName {
    return [[RCIMKitThemeManager sharedInstance] dynamicImage:imageKey
                                             defaultImageName:defaultImageName];
}

+ (UIColor *)dynamicColor:(NSString *)colorKey
              resourceKey:(NSString *)resourceKey
            originalColor:(NSString *)colorHex {
    return [[RCIMKitThemeManager sharedInstance] dynamicColor:colorKey
                                                  resourceKey:resourceKey
                                                originalColor:colorHex];
}

#pragma mark - Delegate Management

/// 添加主题变更代理
/// - Parameter delegate: 代理
- (void)addThemeDelegate:(id<RCIMKitThemeDelegate>)delegate {
    if (!delegate) {
        return;
    }
    
    [self.lock performWriteLockBlock:^{
        if (![self.delegates containsObject:delegate]) {
            [self.delegates addObject:delegate];
        }
    }];
}

/// 移除主题变更代理
/// - Parameter delegate: 代理
- (void)removeThemeDelegate:(id<RCIMKitThemeDelegate>)delegate {
    if (!delegate) {
        return;
    }
    
    [self.lock performWriteLockBlock:^{
        if ([self.delegates containsObject:delegate]) {
            [self.delegates removeObject:delegate];
        }
    }];
}

#pragma mark - Theme Configuration

/// 配置自定义主题
/// - Parameters:
///   - theme: 自定义主题
///   - innerThemesType: 该主题依赖的内置主题类别
/// - Returns: 配置是否成功
- (BOOL)changeCustomTheme:(RCIMKitTheme *)theme
         baseOnTheme:(RCIMKitInnerThemesType)innerThemesType {
    // 参数验证
    if (![self isValidInnerThemesType:innerThemesType]) {
        return NO;
    }
    
    BOOL isSameInnerTheme = (innerThemesType == self.innerThemesType);
    BOOL isSameCustomTheme = (theme == self.currentTheme);
    
    if (isSameInnerTheme) {
        // 基础主题相同,只更新自定义主题
        self.currentTheme = theme;
    } else {
        if (isSameCustomTheme) {
            // 自定义主题相同,只更新基础主题
            self.innerThemesType = innerThemesType;
        } else {
            // 基础主题和自定义主题都不同,先设置基础主题(不触发通知),再设置自定义主题(触发通知)
            _innerThemesType = innerThemesType;
            self.currentTheme = theme;
        }
    }
    return YES;
}

#pragma mark - Dynamic Resource Access

/// 获取动态颜色(支持浅色/深色模式)
/// - Parameters:
///   - colorKey: 欢快主题颜色 key 值
///   - lightHex: 传统主题浅色模式 colorHex
///   - darkHex: 传统主题深色模式 colorHex
/// - Returns: 颜色对象
- (UIColor *)dynamicColor:(NSString *)colorKey
               lightColor:(NSString *)lightHex
                darkColor:(NSString *)darkHex {
    UIColor *color = nil;
    RCIMKitTheme *theme = self.currentTheme;
    RCIMKitInnerThemes *innerThemes = [self currentInnerThemes];

    if (theme) {
        // 优先使用自定义主题
        color = [theme dynamicColor:colorKey defaultColor:lightHex];
        if (!color) {
            // 使用内置主题浅色模式补充
            color = [innerThemes defaultColor:colorKey lightColor:lightHex];
        }
    } else {
        // 使用内置主题
        color = [innerThemes dynamicColor:colorKey
                               lightColor:lightHex
                                darkColor:darkHex];
    }
    
    return color ?: [UIColor clearColor];
}

/// 获取动态颜色(支持资源文件配置)
/// - Parameters:
///   - colorKey: 欢快主题颜色 key 值
///   - resourceKey: RCColor.plist 的 key 字符串
///   - colorHex: 原始颜色 colorHex
/// - Returns: 颜色对象
- (UIColor *)dynamicColor:(NSString *)colorKey
              resourceKey:(NSString *)resourceKey
            originalColor:(NSString *)colorHex {
    UIColor *color = nil;
    RCIMKitTheme *theme = self.currentTheme;
    RCIMKitInnerThemes *innerThemes = [self currentInnerThemes];

    if (theme) {
        // 优先使用自定义主题
        color = [theme dynamicColor:colorKey defaultColor:colorHex];
        if (!color) {
            // 使用内置主题
            if ([innerThemes isKindOfClass:[RCIMKitTraditionThemes class]]) {
                // 传统主题使用资源文件配置
                color = [RCKitUtility color:resourceKey originalColor:colorHex];
            } else {
                // 欢快主题使用浅色模式颜色
                color = [innerThemes defaultColor:colorKey lightColor:colorHex];
            }
        }
    } else {
        // 使用内置主题
        if ([innerThemes isKindOfClass:[RCIMKitTraditionThemes class]]) {
            // 传统主题使用资源文件配置
            color = [RCKitUtility color:resourceKey originalColor:colorHex];
        } else {
            // 欢快主题使用动态颜色
            color = [innerThemes dynamicColor:colorKey
                                   lightColor:colorHex
                                    darkColor:colorHex];
        }
    }
    return color ?: [UIColor clearColor];
}

/// 获取动态图片
/// - Parameters:
///   - imageKey: 欢快主题图片 key 值
///   - defaultImageName: 传统主题浅色模式图片名称
/// - Returns: 图片对象
- (UIImage *)dynamicImage:(NSString *)imageKey
         defaultImageName:(NSString *)defaultImageName {
    RCIMKitTheme *theme = self.currentTheme;
    RCIMKitInnerThemes *innerThemes = [self currentInnerThemes];
    UIImage *image = nil;
    if (theme) {
        UIImage *defaultImage =  [innerThemes defaultImage:imageKey defaultImageName:defaultImageName];
        image = [theme dynamicImage:imageKey defaultImage:defaultImage];
        
    } else {
        // 使用内置主题
        image = [innerThemes dynamicImage:imageKey
                        defaultImageName:defaultImageName];
    }
    
    return image;
    
}

#pragma mark - Private Methods

/// 验证内置主题类型是否有效
/// - Parameter type: 主题类型
/// - Returns: 是否有效
- (BOOL)isValidInnerThemesType:(RCIMKitInnerThemesType)type {
    return (type == RCIMKitInnerThemesTypeTradition || 
            type == RCIMKitInnerThemesTypeLively);
}

/// 获取当前内置主题实例
/// - Returns: 内置主题实例
- (RCIMKitInnerThemes *)currentInnerThemes {
    if (self.innerThemesType == RCIMKitInnerThemesTypeTradition) {
        return self.traditionThemes;
    }
    return self.livelyThemes;
}

/// 通知所有代理主题已变更
- (void)noticeThemeChanged {
    __block NSArray *delegates = nil;
    [self.lock performReadLockBlock:^{
        delegates = [self.delegates allObjects];
    }];
    
    for (id<RCIMKitThemeDelegate> delegate in delegates) {
        if ([delegate respondsToSelector:@selector(themeDidChanged:baseOnTheme:)]) {
            [delegate themeDidChanged:self.currentTheme
                     baseOnTheme:self.innerThemesType];
        }
    }
}

#pragma mark - Setters

- (void)setInnerThemesType:(RCIMKitInnerThemesType)innerThemesType {
    if (innerThemesType != _innerThemesType) {
        _innerThemesType = innerThemesType;
        [self noticeThemeChanged];
    }
}

- (void)setCurrentTheme:(RCIMKitTheme *)currentTheme {
    if (currentTheme != _currentTheme) {
        _currentTheme = currentTheme;
        [self noticeThemeChanged];
    }
}

#pragma mark - Lazy Loading

- (RCIMKitTraditionThemes *)traditionThemes {
    if (!_traditionThemes) {
        _traditionThemes = [RCIMKitTraditionThemes new];
    }
    return _traditionThemes;
}

- (RCIMKitLivelyThemes *)livelyThemes {
    if (!_livelyThemes) {
        _livelyThemes = [RCIMKitLivelyThemes new];
    }
    return _livelyThemes;
}

@end
