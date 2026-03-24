//
//  RCInputKeyboardManager.h
//  RongIMKit
//
//  Created by RongCloud Code on 2025/07/23.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RCInputKeyboardManager;

/// 输入键盘管理器代理协议
/// 用于通知键盘状态变化，实现UI与键盘逻辑的解耦
@protocol RCInputKeyboardManagerDelegate <NSObject>

@required

/// 键盘即将显示
/// - Parameter manager 键盘管理器实例
/// - Parameter height 键盘高度
/// - Parameter frame 键盘frame
/// - Parameter duration 动画持续时间
/// - Parameter curve 动画曲线
- (void)keyboardManager:(RCInputKeyboardManager *)manager 
     willShowWithHeight:(CGFloat)height 
                  frame:(CGRect)frame
      animationDuration:(NSTimeInterval)duration 
         animationCurve:(UIViewAnimationCurve)curve;

/// 键盘即将隐藏
/// - Parameter manager 键盘管理器实例
- (void)keyboardManagerWillHide:(RCInputKeyboardManager *)manager;

@optional

/// 询问是否应该处理键盘事件
/// - Parameter manager 键盘管理器实例
/// - Returns YES-处理键盘事件，NO-忽略键盘事件
- (BOOL)keyboardManagerShouldHandleKeyboardEvent:(RCInputKeyboardManager *)manager;

@end

/// 输入键盘管理器
///
/// 职责：
/// 1. 监听系统键盘通知
/// 2. 解析键盘参数（高度、frame、动画信息）
/// 3. 提供键盘相关的计算工具方法
/// 4. 通过代理模式通知键盘状态变化
@interface RCInputKeyboardManager : NSObject

#pragma mark - 基本属性

/// 代理对象，用于通知键盘状态变化
@property (nonatomic, weak, nullable) id<RCInputKeyboardManagerDelegate> delegate;

/// 当前键盘高度（只读）
@property (nonatomic, assign, readonly) CGFloat currentKeyboardHeight;

/// 当前键盘frame（只读）
@property (nonatomic, assign, readonly) CGRect currentKeyboardFrame;

/// 键盘是否可见（只读）
@property (nonatomic, assign, readonly) BOOL isKeyboardVisible;

#pragma mark - 生命周期管理

/// 开始监听键盘通知
/// 应在需要监听键盘的时候调用
///
- (void)startMonitoring;

/// 停止监听键盘通知
/// 应在不再需要监听键盘的时候调用，通常在dealloc中
- (void)stopMonitoring;

#pragma mark - 工具方法（纯函数）

/// 获取屏幕底部Y坐标（考虑安全区域和热点）
/// - Returns 屏幕底部Y坐标
+ (CGFloat)screenBottomY;

/// 检查是否连接了热点
/// - Returns 是否连接热点
+ (BOOL)isHotspotConnected;

/// 计算输入栏在当前键盘状态下的Y坐标
/// - Parameter inputBarHeight 输入栏高度
/// - Returns 输入栏应该在的Y坐标
- (CGFloat)calculateInputBarYWithInputBarHeight:(CGFloat)inputBarHeight;

@end

NS_ASSUME_NONNULL_END 
