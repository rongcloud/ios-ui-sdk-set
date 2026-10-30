//
//  RCMenuView.h
//  PopMenu
//
//  Created by RobinCui on 2025/10/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RCMenuItem;

/**
 * RCMenuView 是承载 RCMenuItemView 的容器类
 * 使用 UIStackView 实现多行布局，每行最多5个菜单项
 */
@interface RCMenuView : UIView

/// 菜单项数组
@property (nonatomic, strong, readonly) NSArray<RCMenuItem *> *menuItems;

/// 每行最多显示的菜单项数量，默认为5
@property (nonatomic, assign) NSInteger maxItemsPerRow;

/// 菜单项之间的间距，默认为0
@property (nonatomic, assign) CGFloat itemSpacing;

/// 行之间的间距，默认为0
@property (nonatomic, assign) CGFloat rowSpacing;

/**
 * 使用菜单项数组配置视图
 * @param menuItems 菜单项数组
 * @param actionHandler 菜单项点击回调，参数为被点击的菜单项和索引
 */
- (void)configureWithMenuItems:(NSArray<RCMenuItem *> *)menuItems
                 actionHandler:(void (^)(RCMenuItem *menuItem, NSInteger index))actionHandler;

@end

NS_ASSUME_NONNULL_END

