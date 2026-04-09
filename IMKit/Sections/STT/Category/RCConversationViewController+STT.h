//
//  RCConversationViewController+STT.h
//  RongIMKit
//
//  Created by RobinCui on 2025/5/30.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationViewController.h"
NS_ASSUME_NONNULL_BEGIN

@interface RCConversationViewController (STT)

/// 长按STT 时间
/// - Parameters:
///   - model: 消息模型
///   - view: 视图
- (void)stt_didLongTouchSTTInfo:(RCMessageModel *)model inView:(UIView *)view;

/// 长按STT 视图菜单
/// - Parameter model: 消息模型
- (NSArray<UIMenuItem *> *)stt_getLongTouchSTTInfoMenuList:(RCMessageModel *)model;

/// STT menu
/// - Parameter model: 消息模型
- (UIMenuItem *)stt_menuItemForModel:(RCMessageModel *)model;
@end

NS_ASSUME_NONNULL_END
