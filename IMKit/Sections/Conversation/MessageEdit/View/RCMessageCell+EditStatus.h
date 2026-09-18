//
//  RCMessageCell+EditStatus.h
//  RongIMKit
//
//  Created by Lang on 2025/07/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCMessageCell.h"
#import "RCCircularLoadingView.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * RCMessageCell 编辑状态扩展
 * 专门处理消息编辑相关的状态显示和管理
 */
@interface RCMessageCell (EditStatus)

#pragma mark - 编辑状态管理

- (void)edit_showEditStatusIfNeeded;

/// 更新编辑状态显示
/// @param editStatus 编辑状态
- (void)edit_updateEditStatus:(RCMessageModifyStatus)editStatus;

/// 显示编辑状态（便捷方法）
/// @param editStatus 编辑状态
- (void)edit_showEditStatus:(RCMessageModifyStatus)editStatus;

/// 隐藏编辑状态
- (void)edit_hideEditStatus;

/// 编辑状态栏的高度
+ (CGFloat)edit_editStatusBarHeightWithModel:(RCMessageModel *)model;

@end

NS_ASSUME_NONNULL_END 
