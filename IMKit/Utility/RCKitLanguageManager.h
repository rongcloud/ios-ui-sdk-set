//
//  RCKitLanguageManager.h
//  RongIMKit
//
//  Created by Lang on 12/24/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 语言管理器
 
/// 负责语言资源的查找和缓存，提升多语言字符串获取性能。
@interface RCKitLanguageManager : NSObject

/// 获取单例实例
+ (instancetype)sharedManager;

/// 获取本地化字符串
/// @param key 字符串 key
/// @param table 字符串表名（如 "RongCloudKit"）
/// @return 本地化后的字符串，找不到则返回 key
- (NSString *)localizedStringForKey:(NSString *)key table:(NSString *)table;

/// 重新加载语言上下文（语言切换时调用）
///
/// **注意：**
/// 当修改 `[RCKitConfig defaultConfig].ui.preferredLanguage` 时，会自动触发此方法，
/// 通常无需手动调用。
- (void)reloadLanguageContext;

@end

NS_ASSUME_NONNULL_END

