//
//  RCIMKitThemeContext.h
//  RongIMKit
//
//  Created by RobinCui on 2025/9/17.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCIMKitTheme.h"
NS_ASSUME_NONNULL_BEGIN

@interface RCIMKitInnerThemes : NSObject

/// 获取颜色
/// - Parameters:
///   - colorKey: 欢快主题颜色 key 值
///   - lightHex: 传统主题浅色模式 colorHex
///   - darkHex:  传统主题深色模式 colorHex
- (UIColor *)dynamicColor:(NSString *)colorKey
               lightColor:(NSString *)lightHex
                darkColor:(NSString *)darkHex;

/// 获取默认颜色
/// - Parameters:
///   - colorKey: 欢快主题颜色 key 值
///   - lightHex: 传统主题浅色模式 colorHex
- (UIColor *)defaultColor:(NSString *)colorKey
               lightColor:(NSString *)lightHex;

/// 获取图片
/// - Parameters:
///   - imageKey: 欢快主题图片 key 值
///   - defaultImageName: 传统主题浅色模式图片名称
- (UIImage *)dynamicImage:(NSString *)imageKey
         defaultImageName:(NSString *)defaultImageName;

/// 获取默认图片
/// - Parameters:
///   - imageKey: 欢快主题图片 key 值 或者 传统主题浅色模式图片名称
///   - defaultImageName: 传统主题浅色模式图片名称
- (UIImage *)defaultImage:(NSString *)imageKey
         defaultImageName:(NSString *)defaultImageName;
@end

/// 传统皮肤
@interface RCIMKitTraditionThemes : RCIMKitInnerThemes

@end


/// 欢快皮肤
@interface RCIMKitLivelyThemes : RCIMKitInnerThemes

@end
NS_ASSUME_NONNULL_END
