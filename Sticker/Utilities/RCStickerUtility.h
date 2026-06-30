//
//  RCStickerUtility.h
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/9.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#define RongStickerImage(name) [RCStickerUtility imageNamed:(name) ofBundle:@"RongSticker.bundle"]

#define RongStickerString(key) [RCStickerUtility localizedString:(key) table:@"RongSticker"]

#define RongStickerLog(s, ...)                                                                                         \
    NSLog(@"[RongSticker]: %s, line: %d, desc: %@", __func__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__]);

#define RCSticker_CODER_DECODER()                                                                                      \
                                                                                                                       \
    -(id)initWithCoder : (NSCoder *)coder {                                                                            \
        Class cls = [self class];                                                                                      \
        while (cls != [NSObject class]) {                                                                              \
            BOOL bIsSelfClass = (cls == [self class]);                                                                 \
            unsigned int iVarCount = 0;                                                                                \
            unsigned int propVarCount = 0;                                                                             \
            unsigned int sharedVarCount = 0;                                                                           \
            Ivar *ivarList = bIsSelfClass ? class_copyIvarList([cls class], &iVarCount) : NULL;                        \
            objc_property_t *propList = bIsSelfClass ? NULL : class_copyPropertyList(cls, &propVarCount);              \
            sharedVarCount = bIsSelfClass ? iVarCount : propVarCount;                                                  \
                                                                                                                       \
            for (int i = 0; i < sharedVarCount; i++) {                                                                 \
                const char *varName =                                                                                  \
                    bIsSelfClass ? ivar_getName(*(ivarList + i)) : property_getName(*(propList + i));                  \
                NSString *key = [NSString stringWithUTF8String:varName];                                               \
                id varValue = [coder decodeObjectForKey:key];                                                          \
                NSArray *filters = @[ @"superclass", @"description", @"debugDescription", @"hash" ];                   \
                if (varValue && [filters containsObject:key] == NO) {                                                  \
                    [self setValue:varValue forKey:key];                                                               \
                }                                                                                                      \
            }                                                                                                          \
            free(ivarList);                                                                                            \
            free(propList);                                                                                            \
            cls = class_getSuperclass(cls);                                                                            \
        }                                                                                                              \
        return self;                                                                                                   \
    }                                                                                                                  \
                                                                                                                       \
    -(void)encodeWithCoder : (NSCoder *)coder {                                                                        \
        Class cls = [self class];                                                                                      \
        while (cls != [NSObject class]) {                                                                              \
            BOOL bIsSelfClass = (cls == [self class]);                                                                 \
            unsigned int iVarCount = 0;                                                                                \
            unsigned int propVarCount = 0;                                                                             \
            unsigned int sharedVarCount = 0;                                                                           \
            Ivar *ivarList = bIsSelfClass ? class_copyIvarList([cls class], &iVarCount) : NULL;                        \
            objc_property_t *propList = bIsSelfClass ? NULL : class_copyPropertyList(cls, &propVarCount);              \
            sharedVarCount = bIsSelfClass ? iVarCount : propVarCount;                                                  \
                                                                                                                       \
            for (int i = 0; i < sharedVarCount; i++) {                                                                 \
                const char *varName =                                                                                  \
                    bIsSelfClass ? ivar_getName(*(ivarList + i)) : property_getName(*(propList + i));                  \
                NSString *key = [NSString stringWithUTF8String:varName];                                               \
                id varValue = [self valueForKey:key];                                                                  \
                NSArray *filters = @[ @"superclass", @"description", @"debugDescription", @"hash" ];                   \
                if (varValue && [filters containsObject:key] == NO) {                                                  \
                    [coder encodeObject:varValue forKey:key];                                                          \
                }                                                                                                      \
            }                                                                                                          \
            free(ivarList);                                                                                            \
            free(propList);                                                                                            \
            cls = class_getSuperclass(cls);                                                                            \
        }                                                                                                              \
    }

@interface RCStickerUtility : NSObject

+ (NSString *)sha1:(NSString *)input;

/*
 动态颜色设置

 @param lightColor  亮色
 @param darkColor  暗色
 @return 修正后的图片
*/
+ (UIColor *)generateDynamicColor:(UIColor *)lightColor darkColor:(UIColor *)darkColor;

/*
 根据 RongCoreClient 是否设置代理，统一构造 NSURLSessionConfiguration

 @return 代理设置好的 NSURLSessionConfiguration 实例
*/
+ (NSURLSessionConfiguration *)rcSessionConfiguration;

/*
 本地化

 @param key  key
 @param table  string 文件名
 @return 修正后的图片
*/
+ (NSString *)localizedString:(NSString *)key table:(NSString *)table;
/*
 加载图片

 @param name  图片名称
 @param bundleName  bundle 文件名
 @return 修正后的图片
*/
+ (UIImage *)imageNamed:(NSString *)name ofBundle:(NSString *)bundleName;

@end
