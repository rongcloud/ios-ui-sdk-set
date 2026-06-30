//
//  RCMenuItemView.h
//  PopMenu
//
//  Created by RobinCui on 2025/10/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RCMenuItem;

/**
 * RCMenuItemView 是单个菜单项的视图实现类
 * 包含图标和文字，支持点击事件
 */
@interface RCMenuItemView : UIView

/// 图标视图
@property (nonatomic, strong, readonly) UIImageView *iconImageView;

/// 标题标签
@property (nonatomic, strong, readonly) UILabel *titleLabel;

/// 点击回调
@property (nonatomic, copy, nullable) void (^actionHandler)(void);

/**
 * 使用 RCMenuItem 配置视图
 * @param menuItem 菜单项数据模型
 */
- (void)configureWithMenuItem:(RCMenuItem *)menuItem;

@end

NS_ASSUME_NONNULL_END

