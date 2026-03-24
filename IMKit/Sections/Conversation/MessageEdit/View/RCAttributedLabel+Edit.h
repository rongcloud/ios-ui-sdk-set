//
//  RCAttributedLabel+Edit.h
//  RongIMKit
//
//  Created by RongCloud on 2025/07/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCAttributedLabel.h"
#import "RCMessageEditUtil.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * RCAttributedLabel 已编辑状态扩展
 * 为 RCAttributedLabel 添加统一的已编辑状态显示支持
 */
@interface RCAttributedLabel (Edit)

#pragma mark - 已编辑状态支持

/// 设置带已编辑状态的文本内容
/// @param text 原始文本内容
/// @param isEdited 是否已编辑状态
- (void)edit_setTextWithEditedState:(NSString *)text isEdited:(BOOL)isEdited;

@end

NS_ASSUME_NONNULL_END 
