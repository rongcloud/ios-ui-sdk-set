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

/// RCConversationViewController 的编辑功能扩展
/// 包含消息编辑相关的所有方法
@interface RCConversationViewController (Edit)

- (void)edit_viewWillAppear:(BOOL)animated;

- (void)edit_viewDidAppear:(BOOL)animated;

- (void)edit_viewWillDisappear:(BOOL)animated;

/// 当前是否处在编辑模式中
- (BOOL)edit_isMessageEditing;

#pragma mark - 编辑控件管理

/// 创建编辑控件
- (void)edit_createEditBarControl;

/// 关闭编辑输入面板
- (void)edit_hideEditBottomPanels;

#pragma mark - 编辑逻辑

- (BOOL)edit_updateConversationMessageCollectionView;

/// 点击撤回消息的重新编辑
/// - Returns 是否拦截原有事件
- (BOOL)edit_didTapReedit:(RCMessageModel *)model;

/// 点击长按菜单中的引用消息
/// - Returns 是否拦截原有事件
- (BOOL)edit_onReferenceMessageCell:(id)sender;

/// 开始编辑消息（菜单响应）
/// - Parameter sender 菜单项
- (void)edit_onEditMessage:(id)sender;

/// 编辑模式下添加 @ 用户（长按头像触发）
/// - Parameter userId 用户ID
/// - Returns 是否成功处理（YES=编辑模式处理了，NO=需要普通模式处理）
- (BOOL)edit_addMentionedUserToCurrentInput:(RCUserInfo *)userInfo;

/// 刷新输入框引用消息的显示（包含普通输入框和编辑输入框）
/// 该方法会判断消息 UId 列表中是否包含正在引用的消息，如有则会更新，否则不会更新。
/// 当 status 为撤回和删除时，传入对应的消息即可。
/// 当 status 为已编辑状态时，messageModels 传入有变更的消息列表，内部会判断是否包含输入框正在显示的引用消息
/// - Parameter messageModels 发生变更的消息列表。
/// - Parameter status                 引用消息的状态 （已编辑、撤回、删除）
- (void)edit_refreshReferenceViewContentIfNeeded:(NSArray<RCMessageModel *> *)messageModels
                                          status:(RCReferenceMessageStatus)status;

/// 刷新编辑输入框的引用消息显示
/// 该方法会判断消息 UId 列表中是否包含正在引用的消息，如有则会更新，否则不会更新。
/// 当 status 为撤回和删除时，传入对应的消息即可。
/// 当 status 为已编辑状态时，messageModels 传入有变更的消息列表，内部会判断是否包含输入框正在显示的引用消息
/// - Parameter messageModels 发生变更的消息列表。
/// - Parameter status                 引用消息的状态 （已编辑、撤回、删除）
- (void)edit_refreshEditInputReferenceViewIfNeeded:(NSArray<RCMessageModel *> *)messageModels
                                            status:(RCReferenceMessageStatus)status;

#pragma mark - 编辑状态保存和恢复

/// 保存当前编辑状态（如果需要的话）
- (void)edit_saveCurrentEditStateIfNeeded;

/// 显示编辑消息
- (void)edit_showEditingMessage:(RCEditedMessageDraft *)draft;

/// 清理保存的编辑状态
- (void)edit_clearSavedEditState;

#pragma mark - 编辑 Delegate 具体实现方法

/// 处理编辑确认
/// - Parameter editInputBarControl 编辑控件
/// - Parameter text 编辑后的文本
- (void)edit_editInputBarControl:(RCEditInputBarControl *)editInputBarControl didConfirmWithText:(NSString *)text;

/// 处理编辑取消
/// - Parameter editInputBarControl 编辑控件
- (void)edit_editInputBarControlDidCancel:(RCEditInputBarControl *)editInputBarControl;

/// 处理编辑控件frame变化
/// - Parameter editInputBarControl 编辑控件
/// - Parameter frame 新的frame
- (void)edit_editInputBarControl:(RCEditInputBarControl *)editInputBarControl shouldChangeFrame:(CGRect)frame;

/// 处理用户选择界面展示
/// - Parameter editInputBarControl 编辑控件
/// - Parameter selectedBlock 选择完成回调
/// - Parameter cancelBlock 取消回调
- (void)edit_editInputBarControl:(RCEditInputBarControl *)editInputBarControl
                showUserSelector:(void (^)(RCUserInfo *selectedUser))selectedBlock
                          cancel:(void (^)(void))cancelBlock;

/// 处理获取用户信息
/// - Parameter editInputBarControl 编辑控件
/// - Parameter userId 用户ID
/// - Returns 用户信息
- (nullable RCUserInfo *)edit_editInputBarControl:(RCEditInputBarControl *)editInputBarControl
                                      getUserInfo:(NSString *)userId;

/// 处理请求全屏编辑
/// - Parameter editInputBarControl 编辑控件
- (void)edit_editInputBarControlRequestFullScreenEdit:(RCEditInputBarControl *)editInputBarControl;

/// 全屏编辑点击取消
- (void)edit_fullScreenEditViewCancel:(RCFullScreenEditView *)fullScreenEditView;

/// 全屏编辑点击缩放的按钮
- (void)edit_fullScreenEditViewCollapse:(RCFullScreenEditView *)fullScreenEditView;

/// 全屏编辑选择 @ 联系人
- (void)edit_fullScreenEditView:(RCFullScreenEditView *)fullScreenEditView
               showUserSelector:(void (^)(RCUserInfo *selectedUser))selectedBlock
                         cancel:(void (^)(void))cancelBlock;
/// 全屏编辑点击确认按钮
- (void)edit_fullScreenEditView:(RCFullScreenEditView *)fullScreenEditView didConfirmWithText:(NSString *)text;

/// 编辑失败时，重试按钮的点击事件
- (void)edit_didTapEditRetryButton:(RCMessageModel *)model;

@end

NS_ASSUME_NONNULL_END 
