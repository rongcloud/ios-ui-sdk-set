//
//  RCDotLoadingView.m
//  RongIMKit
//
//  Created by RobinCui on 2025/5/27.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCDotLoadingView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"

@interface RCDotLoadingView ()

@property (nonatomic, strong) NSArray<CALayer *> *dotLayers;
@property (nonatomic, strong) NSArray<NSNumber *> *opacities;

@end

@implementation RCDotLoadingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDots];
    }
    return self;
}

- (void)setupDots {
    self.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0x1c1c1e");
    // 创建三个圆点图层
    NSMutableArray *layers = [NSMutableArray array];
    NSArray *opacities = @[@0.3, @0.6, @1.0];
    self.opacities = opacities;
    
    CGFloat dotDiameter = 5.0;
    CGFloat spacing = 5.0; // 圆点间距固定为5px
    
    // 计算总宽度：3个圆点 + 2个间距
    CGFloat totalWidth = (3 * dotDiameter) + (2 * spacing);
    
    // 计算起始x坐标，使整体居中
    CGFloat startX = (self.bounds.size.width - totalWidth) / 2.0;
    
    for (int i = 0; i < 3; i++) {
        CALayer *dotLayer = [CALayer layer];
        // 计算每个圆点的x坐标：起始位置 + (圆点直径 + 间距) * 索引
        CGFloat x = startX + (i * (dotDiameter + spacing));
        // 垂直居中
        CGFloat y = (self.bounds.size.height - dotDiameter) / 2.0;
        
        dotLayer.frame = CGRectMake(x, y, dotDiameter, dotDiameter);
        dotLayer.cornerRadius = dotDiameter / 2.0;
        UIColor *dotColor = RCDynamicColor(@"text_secondary_color", @"0x111f2c", @"0xAAAAAA");
        dotLayer.backgroundColor = dotColor.CGColor;
        dotLayer.opacity = [opacities[i] floatValue];
        [self.layer addSublayer:dotLayer];
        [layers addObject:dotLayer];
    }
    
    self.dotLayers = layers;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 重新计算圆点位置
    CGFloat dotDiameter = 5.0;
    CGFloat spacing = 5.0;
    CGFloat totalWidth = (3 * dotDiameter) + (2 * spacing);
    CGFloat startX = (self.bounds.size.width - totalWidth) / 2.0;
    
    for (int i = 0; i < self.dotLayers.count; i++) {
        CALayer *dotLayer = self.dotLayers[i];
        CGFloat x = startX + (i * (dotDiameter + spacing));
        CGFloat y = (self.bounds.size.height - dotDiameter) / 2.0;
        dotLayer.frame = CGRectMake(x, y, dotDiameter, dotDiameter);
    }
}

- (void)startAnimating {
    // 为每个圆点创建关键帧动画
    for (int i = 0; i < self.dotLayers.count; i++) {
        CALayer *dotLayer = self.dotLayers[i];
        
        // 创建关键帧动画
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
        
        // 设置关键帧值
        NSMutableArray *values = [NSMutableArray array];
        NSMutableArray *keyTimes = [NSMutableArray array];
        
        // 根据点的索引设置不同的透明度变化序列
        switch (i) {
            case 0: // 第一个点: 0.3 -> 0.6 -> 1 -> 0.6
                [values addObject:@0.3];  // 0%
                [values addObject:@0.6];  // 33%
                [values addObject:@1.0];  // 66%
                [values addObject:@0.6];  // 100%
                [values addObject:@0.3];  // 0%

                break;
                
            case 1: // 第二个点: 0.6 -> 1 -> 0.6 -> 0.3
                [values addObject:@0.6];  // 0%
                [values addObject:@1.0];  // 33%
                [values addObject:@0.6];  // 66%
                [values addObject:@0.3];  // 100%
                [values addObject:@0.6];  // 0%

                break;
                
            case 2: // 第三个点: 1 -> 0.6 -> 0.3 -> 0.6
                [values addObject:@1.0];  // 0%
                [values addObject:@0.6];  // 33%
                [values addObject:@0.3];  // 66%
                [values addObject:@0.6];  // 100%
                [values addObject:@1.0];  // 0%

                break;
        }
        
        // 设置关键帧时间点
        [keyTimes addObject:@0.0];
        [keyTimes addObject:@0.2];
        [keyTimes addObject:@0.3];
        [keyTimes addObject:@0.6];
        [keyTimes addObject:@1.0];
        
        animation.values = values;
        animation.keyTimes = keyTimes;
        
        // 设置动画属性
        animation.duration = 1.05;
        animation.repeatCount = HUGE_VALF;
        animation.autoreverses = YES; // 添加自动回放
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        // 添加动画
        [dotLayer addAnimation:animation forKey:@"opacityAnimation"];
    }
}

- (void)stopAnimating {
    // 移除所有圆点的动画
    for (CALayer *dotLayer in self.dotLayers) {
        [dotLayer removeAnimationForKey:@"opacityAnimation"];
    }
    
    // 重置圆点透明度
    for (int i = 0; i < self.dotLayers.count; i++) {
        self.dotLayers[i].opacity = [self.opacities[i] floatValue];
    }
}

- (void)dealloc {
    [self stopAnimating];
}

@end
