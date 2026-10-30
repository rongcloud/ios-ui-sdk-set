//
//  RCMessageCell+Edit.h
//  RongIMKit
//
//  Created by Lang on 2025/07/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCMessageCell.h"
#import "RCCircularLoadingView.h"

NS_ASSUME_NONNULL_BEGIN

/// RCMessageCell 编辑状态扩展
/// 专门处理消息编辑相关的状态显示和管理
@interface RCMessageCell (Edit)

#pragma mark - 编辑状态管理

- (void)edit_showEditStatusIfNeeded;

/// 更新编辑状态显示
/// - Parameter editStatus 编辑状态
- (void)edit_updateEditStatus:(RCMessageModifyStatus)editStatus;

/// 隐藏编辑状态
- (void)edit_hideEditStatus;

/// 编辑状态栏的高度
+ (CGFloat)edit_editStatusBarHeightWithModel:(RCMessageModel *)model;

@end

NS_ASSUME_NONNULL_END 
