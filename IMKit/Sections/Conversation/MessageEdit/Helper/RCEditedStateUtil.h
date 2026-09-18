//
//  RCEditedStateUtil.h
//  RongIMKit
//
//  Created by Lang on 2025/8/10.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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
