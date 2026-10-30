//
//  RCConversationTitleView.h
//  RongIMKit
//
//  Created by Lang on 11/7/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCOnlineStatusView;

NS_ASSUME_NONNULL_BEGIN

/**
 * 会话导航栏标题视图
 * 
 * @discussion
 *   - 支持显示在线状态指示器
 *   - 支持显示标题文本
 *   - 使用 UIStackView 进行布局
 */
@interface RCConversationTitleView : UIView

/// 在线状态视图
@property (nonatomic, strong, readonly) RCOnlineStatusView *onlineStatusView;

/// 标题标签
@property (nonatomic, strong, readonly) UILabel *titleLabel;

/**
 * 设置标题文本
 * 
 * @param title 标题文本
 */
- (void)setTitle:(NSString *)title;

/**
 * 更新在线状态
 *
 * @param isOnline YES：在线，NO：离线
 */
- (void)updateOnlineStatus:(BOOL)isOnline;

@end

NS_ASSUME_NONNULL_END


