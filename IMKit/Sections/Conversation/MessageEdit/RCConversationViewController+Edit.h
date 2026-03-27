//
//  RCConversationViewController+Edit.h
//  RongIMKit
//
//  Created by RongCloud on 2025/1/16.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationViewController.h"
#import <RongIMLibCore/RongIMLibCore.h>

@class RCEditInputBarControl;

NS_ASSUME_NONNULL_BEGIN

/**
 * RCConversationViewController 的编辑功能扩展
 * 包含消息编辑相关的所有方法
 */
@interface RCConversationViewController (Edit)

- (void)edit_viewWillAppear:(BOOL)animated;

/// 当前是否处在编辑模式中
- (BOOL)edit_isMessageEditing;

#pragma mark - 编辑控件管理

/**
 * 创建编辑控件
 */
- (void)edit_createEditBarControl;

/**
 * 关闭编辑输入面板
 */
- (void)edit_dismissEditBottomPanels;

#pragma mark - 编辑逻辑

- (BOOL)edit_updateConversationMessageCollectionView;

/// 点击撤回消息的重新编辑
/// /// - Returns 是否拦截原有事件
- (BOOL)edit_didTapReedit:(RCMessageModel *)model;

/// 点击长按菜单中的引用消息
/// - Returns 是否拦截原有事件
- (BOOL)edit_onReferenceMessageCell:(id)sender;

/**
 * 开始编辑消息（菜单响应）
 * @param sender 菜单项
 */
- (void)edit_onEditMessage:(id)sender;

/**
 * 编辑模式下添加@用户（长按头像触发）
 * @param userId 用户ID
 * @return 是否成功处理（YES=编辑模式处理了，NO=需要普通模式处理）
 */
- (BOOL)edit_addMentionedUserToCurrentInput:(RCUserInfo *)userInfo;

#pragma mark - 编辑状态保存和恢复

/**
 * 保存当前编辑状态（如果需要的话）
 */
- (void)edit_saveCurrentEditStateIfNeeded;

/**
 * 加载编辑消息（优先恢复保存状态）
 */
- (void)edit_loadEditingMessageIfNeeded;

/**
 * 清理保存的编辑状态
 */
- (void)edit_clearSavedEditState;

#pragma mark - 编辑 Delegate 具体实现方法

/**
 * 处理编辑确认
 * @param editInputBarControl 编辑控件
 * @param text 编辑后的文本
 */
- (void)edit_editInputBarControl:(RCEditInputBarControl *)editInputBarControl didConfirmWithText:(NSString *)text;

/**
 * 处理编辑取消
 * @param editInputBarControl 编辑控件
 */
- (void)edit_editInputBarControlDidCancel:(RCEditInputBarControl *)editInputBarControl;

/**
 * 处理编辑控件frame变化
 * @param editInputBarControl 编辑控件
 * @param frame 新的frame
 */
- (void)edit_editInputBarControl:(RCEditInputBarControl *)editInputBarControl shouldChangeFrame:(CGRect)frame;

/**
 * 处理用户选择界面展示
 * @param editInputBarControl 编辑控件
 * @param selectedBlock 选择完成回调
 * @param cancelBlock 取消回调
 */
- (void)edit_editInputBarControl:(RCEditInputBarControl *)editInputBarControl
                showUserSelector:(void (^)(RCUserInfo *selectedUser))selectedBlock
                          cancel:(void (^)(void))cancelBlock;

/**
 * 处理@信息更新
 * @param editInputBarControl 编辑控件
 * @param mentionedInfo @信息
 */
- (void)edit_editInputBarControl:(RCEditInputBarControl *)editInputBarControl didUpdateMentionedInfo:(nullable RCMentionedInfo *)mentionedInfo;

/**
 * 处理获取用户信息
 * @param editInputBarControl 编辑控件
 * @param userId 用户ID
 * @return 用户信息
 */
- (nullable RCUserInfo *)edit_editInputBarControl:(RCEditInputBarControl *)editInputBarControl getUserInfo:(NSString *)userId;

/**
 * 处理请求全屏编辑
 * @param editInputBarControl 编辑控件
 */
- (void)edit_editInputBarControlRequestFullScreenEdit:(RCEditInputBarControl *)editInputBarControl;

- (void)edit_fullScreenEditViewCancel:(RCFullScreenEditView *)fullScreenEditView;

- (void)edit_fullScreenEditViewCollapse:(RCFullScreenEditView *)fullScreenEditView;

- (void)edit_fullScreenEditView:(RCFullScreenEditView *)fullScreenEditView
               showUserSelector:(void (^)(RCUserInfo *selectedUser))selectedBlock
                         cancel:(void (^)(void))cancelBlock;

- (void)edit_fullScreenEditView:(RCFullScreenEditView *)fullScreenEditView didConfirmWithText:(NSString *)text;

/// 编辑失败时，重试按钮的点击事件
- (void)edit_didTapEditRetryButton:(RCMessageModel *)model;

@end

NS_ASSUME_NONNULL_END 
