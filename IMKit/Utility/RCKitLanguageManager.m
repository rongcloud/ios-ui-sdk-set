//
//  RCKitLanguageManager.m
//  RongIMKit
//
//  Created by Lang on 12/24/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCKitLanguageManager.h"
#import "RCKitConfig.h"
#import "RCKitUtility.h"

@interface RCKitLanguageManager ()

/// 缓存的 lproj 候选列表
@property (nonatomic, copy) NSArray<NSString *> *cachedLprojCandidates;

/// 缓存的 Bundle（key = table 名称）
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSBundle *> *cachedBundles;

/// 同步队列（保证线程安全）
@property (nonatomic, strong) dispatch_queue_t syncQueue;

/// 当前生效的语言标识（用于检测变化）
/// 存储实际使用的语言标识：用户指定 > 系统语言
/// 注意：如果用户未指定语言，这里存储的是系统语言，而不是空字符串
@property (nonatomic, copy) NSString *lastPreferredLanguage;

@end

@implementation RCKitLanguageManager

#pragma mark - Lifecycle

+ (instancetype)sharedManager {
    static RCKitLanguageManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _syncQueue = dispatch_queue_create("cn.rongcloud.imkit.languageManager", DISPATCH_QUEUE_SERIAL);
        _cachedBundles = [NSMutableDictionary dictionary];
        
        // 初始化语言上下文（同步初始化，避免竞态）
        // 存储实际使用的语言标识（用户指定 > 系统语言），而不是 preferredLanguage
        _lastPreferredLanguage = [self p_languageIdentifier];
        _cachedLprojCandidates = [self p_generateLprojCandidates];
        
        // 注意：不需要监听系统语言变化通知
        // iOS 系统语言变化通常需要重启应用或设备，应用重启时会重新初始化并读取最新系统语言
    }
    return self;
}

#pragma mark - Public Methods

- (NSString *)localizedStringForKey:(NSString *)key table:(NSString *)table {
    if (!key || !table) {
        return key ?: @"";
    }
    
    __block NSBundle *bundle = nil;
    
    // 读取缓存的 Bundle（线程安全）
    dispatch_sync(self.syncQueue, ^{
        bundle = self.cachedBundles[table];
        
        // 首次访问该 table，查找并缓存
        if (!bundle) {
            bundle = [self p_findBundleForTable:table];
            if (bundle) {
                self.cachedBundles[table] = bundle;
            }
        }
    });
    
    // 从 Bundle 获取本地化字符串
    if (bundle) {
        NSString *localizedString = [bundle localizedStringForKey:key value:nil table:table];
        if (localizedString && ![localizedString isEqualToString:key]) {
            return localizedString;
        }
    }
    
    // 兜底：返回 key
    return key;
}

- (void)reloadLanguageContext {
    dispatch_async(self.syncQueue, ^{
        // 获取当前实际使用的语言标识（用户指定 > 系统语言）
        NSString *currentLanguageId = [self p_languageIdentifier];
        
        // 检查实际使用的语言标识是否真的变了
        // 注意：如果用户未指定语言，需要比较系统语言，而不是 preferredLanguage
        if ([currentLanguageId isEqualToString:self.lastPreferredLanguage]) {
            return; // 未变化，跳过
        }
        
        self.lastPreferredLanguage = currentLanguageId;
        
        // 重新生成候选列表
        self.cachedLprojCandidates = [self p_generateLprojCandidates];
        
        // 清空 Bundle 缓存（因为语言切换后，Bundle 路径可能变化）
        [self.cachedBundles removeAllObjects];
    });
}

#pragma mark - Private Methods

/// 生成完整的 lproj 候选列表
- (NSArray<NSString *> *)p_generateLprojCandidates {
    NSString *languageId = [self p_languageIdentifier];
    if (!languageId) {
        return @[@"en"];
    }
    
    NSMutableOrderedSet *candidates = [NSMutableOrderedSet orderedSet];
    
    // 为语言生成降级链
    NSArray *chain = [self p_fallbackChainForLanguage:languageId];
    NSArray *withChineseFallback = [self p_chineseFallbackForChain:chain];
    [candidates addObjectsFromArray:withChineseFallback];
    
    // 追加通用兜底
    [candidates addObject:@"en"];
    
    return [candidates array];
}

/// 获取语言标识（用户指定 > 系统偏好第一个）
- (NSString *)p_languageIdentifier {
    NSString *preferred = [RCKitConfig defaultConfig].ui.preferredLanguage;
    
    // 用户指定了语言
    if (preferred.length > 0) {
        return [self p_normalizeLanguageIdentifier:preferred];
    }
    
    // 回退到系统偏好语言（只取第一个）
    NSArray *systemLanguages = [NSLocale preferredLanguages];
    if (systemLanguages.count > 0) {
        return [self p_normalizeLanguageIdentifier:systemLanguages.firstObject];
    }
    
    return nil;
}

/// 规范化语言标识（下划线 → 连字符）
- (NSString *)p_normalizeLanguageIdentifier:(NSString *)identifier {
    return [identifier stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
}

/// 构建语言降级链（zh-Hans-CN → zh-Hans → zh）
- (NSArray<NSString *> *)p_fallbackChainForLanguage:(NSString *)langId {
    NSMutableArray *chain = [NSMutableArray arrayWithObject:langId];
    NSArray *components = [langId componentsSeparatedByString:@"-"];
    
    if (components.count > 1) {
        for (NSInteger i = components.count - 1; i > 0; i--) {
            NSString *parent = [[components subarrayWithRange:NSMakeRange(0, i)] componentsJoinedByString:@"-"];
            [chain addObject:parent];
        }
    }
    
    return chain;
}

/// 中文特殊降级处理：繁体中文无资源时降级到简体中文
- (NSArray<NSString *> *)p_chineseFallbackForChain:(NSArray<NSString *> *)chain {
    // 如果链中包含繁体中文，且没有简体中文，则在繁体后添加简体作为降级
    if ([chain containsObject:@"zh-Hant"] && ![chain containsObject:@"zh-Hans"]) {
        NSMutableArray *result = [chain mutableCopy];
        NSUInteger hantIndex = [result indexOfObject:@"zh-Hant"];
        [result insertObject:@"zh-Hans" atIndex:hantIndex + 1];
        return result;
    }
    
    return chain;
}

/// 查找第一个存在的 bundle（包含 table.strings）
- (NSBundle *)p_findBundleForTable:(NSString *)table {
    NSArray *bundles = @[
        [NSBundle mainBundle],
        [NSBundle bundleForClass:[RCKitUtility class]],
        [NSBundle bundleForClass:NSClassFromString(@"RCCall")]
    ];
    
    NSString *tablePath = [NSString stringWithFormat:@"%@.strings", table];
    NSArray<NSString *> *candidates = self.cachedLprojCandidates;
    
    // 防御性检查：如果候选列表为空，使用默认降级策略
    if (candidates.count == 0) {
        candidates = @[@"en"];
    }
    
    for (NSString *lprojName in candidates) {
        for (NSBundle *searchBundle in bundles) {
            NSString *lprojPath = [searchBundle pathForResource:lprojName ofType:@"lproj"];
            if (lprojPath) {
                NSString *fullPath = [lprojPath stringByAppendingPathComponent:tablePath];
                if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
                    return [NSBundle bundleWithPath:lprojPath];
                }
            }
        }
    }
    
    return nil;
}

@end

