//
//  RCMessageEditUtil.h
//  RongIMKit
//
//  Created by Lang on 2025/8/10.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCMessageEditUtil : NSObject

/// 获取显示用的文本（包含已编辑标识）
/// - Parameter originalText 原始文本
/// - Parameter isEdited 是否已编辑
/// - Returns 显示用的文本
+ (NSString *)displayTextForOriginalText:(NSString *)originalText isEdited:(BOOL)isEdited;

/// 获取已编辑文本的颜色配置
/// - Returns 已编辑文本颜色
+ (UIColor *)editedTextColor;

/// 获取已编辑标识文本
/// - Returns 已编辑标识（"（已编辑）"）
+ (NSString *)editedSuffix;

/// 计算包含已编辑状态的文本尺寸
/// - Parameter originalText 原始文本
/// - Parameter isEdited 是否已编辑
/// - Parameter font 字体
/// - Parameter constrainedSize 约束尺寸
/// - Returns 文本尺寸
+ (CGSize)sizeForText:(NSString *)originalText
             isEdited:(BOOL)isEdited
                 font:(UIFont *)font
      constrainedSize:(CGSize)constrainedSize;

/// 编辑时间是否过期
/// 编辑时间可在融云控制台进行设置
/// - Parameter sentTime 消息发送时间
+ (BOOL)isEditTimeValid:(long long)sentTime;

@end

NS_ASSUME_NONNULL_END
