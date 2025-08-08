//
//  RCAttributedLabel+EditedState.h
//  RongIMKit
//
//  Created by Assistant on 2024/01/XX.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCAttributedLabel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * RCAttributedLabel 已编辑状态扩展
 * 为 RCAttributedLabel 添加统一的已编辑状态显示支持
 */
@interface RCAttributedLabel (EditedState)

#pragma mark - 已编辑状态支持

/// 设置带已编辑状态的文本内容
/// @param text 原始文本内容
/// @param isEdited 是否已编辑状态
- (void)setTextWithEditedState:(NSString *)text isEdited:(BOOL)isEdited;

/// 手动应用已编辑文本样式（异步调用）
/// @param originalTextLength 原始文本长度，用于定位"已编辑"部分
- (void)applyEditedTextStyleWithOriginalTextLength:(NSUInteger)originalTextLength;

@end

#pragma mark - 工具方法

/**
 * 已编辑状态工具类
 * 提供已编辑状态相关的实用方法
 */
@interface RCEditedStateUtil : NSObject

/// 获取显示用的文本（包含已编辑标识）
/// @param originalText 原始文本
/// @param isEdited 是否已编辑
/// @return 显示用的文本
+ (NSString *)displayTextForOriginalText:(NSString *)originalText isEdited:(BOOL)isEdited;

/// 获取已编辑文本的颜色配置
/// @return 已编辑文本颜色
+ (UIColor *)editedTextColor;

/// 获取已编辑标识文本
/// @return 已编辑标识（"（已编辑）"）
+ (NSString *)editedSuffix;

/// 计算包含已编辑状态的文本尺寸
/// @param originalText 原始文本
/// @param isEdited 是否已编辑
/// @param font 字体
/// @param constrainedSize 约束尺寸
/// @return 文本尺寸
+ (CGSize)sizeForText:(NSString *)originalText 
             isEdited:(BOOL)isEdited 
                 font:(UIFont *)font 
      constrainedSize:(CGSize)constrainedSize;

@end

NS_ASSUME_NONNULL_END 