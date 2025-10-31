//
//  RCCircularLoadingView.m
//  RongIMKit
//
//  Created by Lang on 2025/7/28.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCCircularLoadingView.h"
#import "RCKitCommonDefine.h"
static NSString * const kRotationAnimationKey = @"circularLoadingRotationAnimation";

@interface RCCircularLoadingView ()

/**
 * 用于绘制loading圆环的图层
 */
@property (nonatomic, strong) CAShapeLayer *circleLayer;

/**
 * 标记当前是否正在动画
 */
@property (nonatomic, assign) BOOL animating;

@end

@implementation RCCircularLoadingView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaultValues];
        [self setupLayer];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectMake(0, 0, 40, 40)];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupDefaultValues];
    [self setupLayer];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateCirclePath];
}

#pragma mark - Setup Methods

/**
 * 设置默认属性值
 */
- (void)setupDefaultValues {
    _lineWidth = 2.0;
    UIColor *color = RCDynamicColor(@"primary_color", @"0x007aff", @"0x007aff");
    if (!color) {
        color = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
    }
    _strokeColor = color;// 匹配UI图的蓝色
    _animationDuration = 1.0;
    _startAngle = 0;                    // 从3点钟方向开始(0度)
    _endAngle = -M_PI_2;                // 到12点钟方向结束(-90度)
    _animating = NO;
}

/**
 * 设置圆环图层
 */
- (void)setupLayer {
    self.circleLayer = [CAShapeLayer layer];
    self.circleLayer.fillColor = [UIColor clearColor].CGColor;
    self.circleLayer.strokeColor = self.strokeColor.CGColor;
    self.circleLayer.lineWidth = self.lineWidth;
    self.circleLayer.lineCap = kCALineCapRound;
    self.circleLayer.lineJoin = kCALineJoinRound;
    
    [self.layer addSublayer:self.circleLayer];
    
    // 初始时更新路径
    [self updateCirclePath];
}

/**
 * 更新圆环路径
 */
- (void)updateCirclePath {
    CGRect bounds = self.bounds;
    CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    CGFloat radius = MIN(bounds.size.width, bounds.size.height) / 2 - self.lineWidth / 2;
    
    // 确保半径为正值
    if (radius <= 0) {
        radius = 1;
    }
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center
                                                        radius:radius
                                                    startAngle:self.startAngle
                                                      endAngle:self.endAngle
                                                     clockwise:YES];
    
    self.circleLayer.path = path.CGPath;
    self.circleLayer.frame = bounds;
}

#pragma mark - Public Methods

- (void)startAnimating {
    if (self.animating) {
        return;
    }
    
    self.animating = YES;
    self.hidden = NO;
    
    // 创建旋转动画
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = @(0);
    rotationAnimation.toValue = @(M_PI * 2);
    rotationAnimation.duration = self.animationDuration;
    rotationAnimation.repeatCount = HUGE_VALF;
    rotationAnimation.removedOnCompletion = NO;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    [self.circleLayer addAnimation:rotationAnimation forKey:kRotationAnimationKey];
}

- (void)stopAnimating {
    if (!self.animating) {
        return;
    }
    
    self.animating = NO;
    [self.circleLayer removeAnimationForKey:kRotationAnimationKey];
}

- (BOOL)isAnimating {
    return self.animating;
}

#pragma mark - Setter Methods

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    self.circleLayer.lineWidth = lineWidth;
    [self updateCirclePath];
}

- (void)setStrokeColor:(UIColor *)strokeColor {
    _strokeColor = strokeColor;
    self.circleLayer.strokeColor = strokeColor.CGColor;
}

- (void)setStartAngle:(CGFloat)startAngle {
    _startAngle = startAngle;
    [self updateCirclePath];
}

- (void)setEndAngle:(CGFloat)endAngle {
    _endAngle = endAngle;
    [self updateCirclePath];
}

#pragma mark - Cleanup

- (void)dealloc {
    [self stopAnimating];
}

@end 
