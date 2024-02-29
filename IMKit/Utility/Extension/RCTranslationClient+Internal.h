//
//  RCTranslationClient+Internal.h
//  RongIMKit
//
//  Created by RobinCui on 2022/2/24.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#ifndef RCTranslationClient_Internal_h
#define RCTranslationClient_Internal_h

#import "RCTranslation+Internal.h"

@interface RCTranslationClient : NSObject

/// 翻译SDK单例
+ (instancetype)sharedInstance;

/// 添加翻译代理
/// @param delegate 代理
- (void)addTranslationDelegate:(id)delegate;

/// 移除翻译代理
/// @param delegate 代理
- (void)removeTranslationDelegate:(id)delegate;

/// 翻译
/// @param messageId 消息ID
/// @param text 文本
/// @param srcLanguage 源语言类型
/// @param targetLanguage 目标语言类型

- (void)translate:(NSInteger)messageId
             text:(NSString *)text
      srcLanguage:(NSString *)srcLanguage
   targetLanguage:(NSString *)targetLanguage;

/// 是否支持翻译
- (BOOL)isTextTranslationSupported;

@end

#endif /* RCTranslationClient_Internal_h */
