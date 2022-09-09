//
//  RCTranslation+Internal.h
//  RongIMKit
//
//  Created by RobinCui on 2022/3/1.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#ifndef RCTranslation_Internal_h
#define RCTranslation_Internal_h

@interface RCTranslation : NSObject
/// 消息ID
@property (nonatomic, assign) NSInteger messageId;
/// 源语言
@property (nonatomic, copy) NSString *srcLanguage;
/// 目标语言
@property (nonatomic, copy) NSString *targetLanguage;
/// 原始文本
@property (nonatomic, copy) NSString *text;
/// 翻译文本
@property (nonatomic, copy) NSString *translationString;

@end

#endif /* RCTranslation_Internal_h */
