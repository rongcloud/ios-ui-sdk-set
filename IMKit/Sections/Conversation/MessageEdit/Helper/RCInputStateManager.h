//
//  RCInputStateManager.h
//  RongIMKit
//
//  Created by RongCloud on 2025/07/23.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RongIMLibCore/RongIMLibCore.h>

NS_ASSUME_NONNULL_BEGIN

@class RCInputStateManager;

#pragma mark - 代理协议

@protocol RCInputStateManagerDelegate <NSObject>

@required
/// 显示用户选择界面
/// - Parameter manager 管理器实例
/// - Parameter selectedBlock 选择完成回调
/// - Parameter cancelBlock 取消回调
- (void)inputStateManager:(RCInputStateManager *)manager
         showUserSelector:(void (^)(RCUserInfo *selectedUser))selectedBlock
                   cancel:(void (^)(void))cancelBlock;

/// 获取用户信息（用于 @ 信息恢复）
/// - Parameter manager 状态管理器实例
/// - Parameter userId 用户ID
/// - Returns 用户信息对象
- (nullable RCUserInfo *)inputStateManager:(RCInputStateManager *)manager getUserInfoForUserId:(NSString *)userId;

@optional
/// @ 信息发生变化的通知
/// - Parameter manager 管理器实例
- (void)inputStateManagerDidUpdateMentions:(RCInputStateManager *)manager;

@end

#pragma mark - 主要接口

/// RCInputStateManager - 完整的输入状态管理器
///
/// 主要职责：
/// 1. 管理输入状态的保存和恢复（stateData）
/// 2. 处理文本变化和光标管理（handleTextChange）
/// 3. 提供@功能支持（insertMentionedUser）
/// 4. 管理引用消息信息（referenceInfo）
/// 5. 协调输入相关的UI交互
@interface RCInputStateManager : NSObject

/// 代理对象（用于获取用户信息）
@property (nonatomic, weak, nullable) id<RCInputStateManagerDelegate> delegate;

#pragma mark - 初始化

/// 初始化输入状态管理器
/// - Parameter textView 关联的文本输入框
/// - Parameter delegate 代理对象
- (instancetype)initWithTextView:(UITextView *)textView
                        delegate:(id<RCInputStateManagerDelegate>)delegate;

#pragma mark - 基础功能

/// 是否启用 @功能
@property (nonatomic, assign) BOOL isMentionedEnabled;

/// 处理文本变化（在UITextView的shouldChangeTextInRange中调用）
/// - Parameter text 要替换的文本
/// - Parameter range 替换范围
/// - Returns 是否使用默认的文本变化处理
- (BOOL)handleTextChange:(NSString *)text inRange:(NSRange)range;

/// 手动插入 @用户
/// - Parameter userInfo 用户信息
- (void)insertMentionedUser:(RCUserInfo *)userInfo;

/// 插入 @用户（支持symbolRequest参数）
/// - Parameter userInfo 用户信息
/// - Parameter symbolRequest 是否需要插入 @ 符号（YES=插入@符号+用户名，NO=只插入用户名，假设@符号已存在）
- (void)insertMentionedUser:(RCUserInfo *)userInfo symbolRequest:(BOOL)symbolRequest;

/// 获取当前的 @信息（用于发送消息）
@property (nonatomic, strong, readonly, nullable) RCMentionedInfo *mentionedInfo;

/// 清除所有 @信息
- (void)clearAllMentions;

#pragma mark - 引用消息状态管理

/// 设置引用消息信息
/// - Parameter senderName 引用消息发送者姓名
/// - Parameter content 引用消息内容
- (void)setReferenceInfo:(nullable NSString *)senderName
                 content:(nullable NSString *)content;

/// 清除引用消息信息
- (void)clearReferenceInfo;

/// 是否有引用消息信息
@property (nonatomic, assign, readonly) BOOL hasReferenceInfo;

/// 引用消息相关属性（只读）
@property (nonatomic, copy, readonly, nullable) NSString *referencedSenderName;
@property (nonatomic, copy, readonly, nullable) NSString *referencedContent;

#pragma mark - 完整状态管理

/// 获取完整的输入状态数据（包含文本、@ 信息、引用信息）
@property (nonatomic, copy, readonly) NSDictionary *stateData;

/// 检查是否有任何内容（文本、@ 信息、引用信息）
@property (nonatomic, assign, readonly) BOOL hasContent;

/// 从状态数据恢复完整状态
- (BOOL)restoreFromStateData:(NSDictionary *)stateData;

/// 从原始消息恢复 @ 信息
/// - Parameter mentionedInfo 原始消息中的@信息
- (void)restoreFromOriginalMessage:(RCMentionedInfo *)mentionedInfo;

/// 清除所有状态
- (void)clearAllStates;

@end

NS_ASSUME_NONNULL_END 
