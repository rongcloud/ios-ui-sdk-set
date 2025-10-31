//
//  RCMenuViewController.h
//  PopMenu
//
//  Created by RobinCui on 2025/10/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RCMenuItem;

/**
 * RCMenuViewController 负责控制 RCMenuView 的显示和隐藏
 * 行为类似 UIMenuController，带有三角形指示器
 */
@interface RCMenuController : NSObject

/// 单例
+ (instancetype)sharedMenuController;

/// 菜单是否可见
@property (nonatomic, assign, readonly, getter=isMenuVisible) BOOL menuVisible;

/**
 * 从指定视图显示菜单
 * @param targetView 触发菜单的目标视图
 * @param menuItems 菜单项数组
 * @param actionHandler 菜单项点击回调
 */
- (void)showMenuFromView:(UIView *)targetView
               menuItems:(NSArray<UIMenuItem *> *)menuItems
           actionHandler:(void (^)(RCMenuItem *menuItem, NSInteger index))actionHandler;

/**
 * 从指定视图和矩形区域显示菜单
 * @param targetRect 目标矩形区域（在targetView坐标系中）
 * @param targetView 触发菜单的目标视图
 * @param menuItems 菜单项数组
 * @param actionHandler 菜单项点击回调
 */
- (void)showMenuFromRect:(CGRect)targetRect
                  inView:(UIView *)targetView
               menuItems:(NSArray<RCMenuItem *> *)menuItems
           actionHandler:(void (^)(RCMenuItem *menuItem, NSInteger index))actionHandler;

/**
 * 隐藏菜单
 * @param animated 是否动画
 */
- (void)hideMenuAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END

