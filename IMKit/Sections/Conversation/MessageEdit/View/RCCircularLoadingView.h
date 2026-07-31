//
//  RCCircularLoadingView.h
//  RongIMKit
//
//  Created by Lang on 2025/7/28.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 圆形旋转Loading视图
 * 基于CAShapeLayer纯代码绘制的3/4圆弧loading效果，支持连续旋转动画
 * 默认配置：2.0线宽，蓝色#007AFF，从3点钟方向开始到12点钟方向结束的270度圆弧
 */
@interface RCCircularLoadingView : UIView

/**
 * loading圆环的线宽，默认为 2.0
 */
@property (nonatomic, assign) CGFloat lineWidth;

/**
 * loading 圆环的颜色，默认为蓝色 #007AFF
 */
@property (nonatomic, strong) UIColor *strokeColor;

/**
 * 旋转动画的持续时间，默认为1.0秒
 */
@property (nonatomic, assign) CGFloat animationDuration;

/**
 * 圆环的起始角度弧度，默认为0（从3点钟方向开始）
 */
@property (nonatomic, assign) CGFloat startAngle;

/**
 * 圆环的结束角度弧度，默认为-π/2（到12点钟方向结束，形成3/4圆弧）
 */
@property (nonatomic, assign) CGFloat endAngle;

/**
 * 指定frame初始化loading视图
 * @param frame 视图框架，loading圆环会根据frame大小自动居中绘制
 */
- (instancetype)initWithFrame:(CGRect)frame;

/**
 * 开始旋转动画
 * 启动连续的360度顺时针旋转动画，直到调用stopAnimating停止
 */
- (void)startAnimating;

/**
 * 停止旋转动画
 * 立即停止旋转动画并移除动画效果
 */
- (void)stopAnimating;

/**
 * 判断loading是否正在执行旋转动画
 * @return YES表示正在动画中，NO表示已停止动画
 */
- (BOOL)isAnimating;

@end

NS_ASSUME_NONNULL_END 
