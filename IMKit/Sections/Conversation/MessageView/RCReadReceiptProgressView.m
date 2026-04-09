//
//  RCReadReceiptProgressView.m
//  RongIMKit
//
//  Created by Lang on 2025/09/30.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCReadReceiptProgressView.h"

@implementation RCReadReceiptProgressView

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaultValues];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDefaultValues];
    }
    return self;
}

- (void)setupDefaultValues {
    self.backgroundColor = [UIColor clearColor];
    _progress = 0.0;
    // 默认颜色：#16D258 绿色
    UIColor *defaultColor = [UIColor colorWithRed:22.0/255.0 green:210.0/255.0 blue:88.0/255.0 alpha:1.0];
    _borderColor = defaultColor;
    _fillColor = defaultColor;
    _innerPadding = 1.5;  // 填充区域与边框之间有2px间距
    _borderWidth = 1.5;  // 边框宽度
}

#pragma mark - Property Setters

- (void)setProgress:(CGFloat)progress {
    // 限制进度范围在 0.0 ~ 1.0
    _progress = MAX(0.0, MIN(1.0, progress));
    [self setNeedsDisplay];
}

- (void)setBorderColor:(UIColor *)borderColor {
    if (borderColor) {
        _borderColor = borderColor;
    } else {
        // 默认绿色 #16D258
        _borderColor = [UIColor colorWithRed:22.0/255.0 green:210.0/255.0 blue:88.0/255.0 alpha:1.0];
    }
    [self setNeedsDisplay];
}

- (void)setFillColor:(UIColor *)fillColor {
    if (fillColor) {
        _fillColor = fillColor;
    } else {
        // 默认绿色 #16D258
        _fillColor = [UIColor colorWithRed:22.0/255.0 green:210.0/255.0 blue:88.0/255.0 alpha:1.0];
    }
    [self setNeedsDisplay];
}

- (void)setInnerPadding:(CGFloat)innerPadding {
    _innerPadding = MAX(0.0, innerPadding);
    [self setNeedsDisplay];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = MAX(0.0, borderWidth);
    [self setNeedsDisplay];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return;
    }
    
    CGFloat centerX = rect.size.width * 0.5;
    CGFloat centerY = rect.size.height * 0.5;
    CGFloat minSize = MIN(rect.size.width, rect.size.height);
    
    // 计算外圆半径（考虑边框宽度）
    CGFloat outerRadius = (minSize * 0.5) - (self.borderWidth * 0.5);
    
    // 绘制圆形边框
    [self drawBorderWithContext:context centerX:centerX centerY:centerY radius:outerRadius];
    
    // 绘制填充进度（如果进度大于0）
    if (self.progress > 0.0) {
        CGFloat fillRadius = outerRadius - (self.borderWidth * 0.5) - self.innerPadding;
        [self drawProgressWithContext:context centerX:centerX centerY:centerY radius:fillRadius];
    }
}

/// 绘制圆形边框
- (void)drawBorderWithContext:(CGContextRef)context centerX:(CGFloat)centerX centerY:(CGFloat)centerY radius:(CGFloat)radius {
    CGContextSaveGState(context);
    
    // 设置边框样式
    CGContextSetLineWidth(context, self.borderWidth);
    CGContextSetStrokeColorWithColor(context, self.borderColor.CGColor);
    
    // 绘制圆形边框
    CGContextAddArc(context, centerX, centerY, radius, 0, M_PI * 2, 0);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

/// 绘制进度填充（从12点钟方向顺时针）
- (void)drawProgressWithContext:(CGContextRef)context centerX:(CGFloat)centerX centerY:(CGFloat)centerY radius:(CGFloat)radius {
    CGContextSaveGState(context);
    
    // 设置填充颜色
    CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
    
    // 计算起始角度（12点钟方向为 -π/2）
    CGFloat startAngle = -M_PI_2;
    // 计算结束角度（顺时针旋转，progress * 2π）
    CGFloat endAngle = startAngle + (self.progress * M_PI * 2);
    
    // 创建路径：从圆心开始，画扇形
    CGContextMoveToPoint(context, centerX, centerY);
    CGContextAddArc(context, centerX, centerY, radius, startAngle, endAngle, 0);
    CGContextClosePath(context);
    
    // 填充路径
    CGContextFillPath(context);
    
    CGContextRestoreGState(context);
}

@end
