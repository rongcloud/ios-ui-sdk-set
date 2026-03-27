//
//  RCSightProgressView.m
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/5/17.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightProgressView.h"

#define DEGREES_TO_RADIANS(x) (x) / 180.0 * M_PI
#define RADIANS_TO_DEGREES(x) (x) / M_PI * 180.0

@interface RCProgressViewBackgroundLayer : CALayer

@property (nonatomic, strong) UIColor *tintColor;

@end

@implementation RCProgressViewBackgroundLayer

- (id)init {
    self = [super init];
    if (self) {
        self.contentsScale = [UIScreen mainScreen].scale;
    }
    return self;
}

- (void)setTintColor:(UIColor *)tintColor {
    _tintColor = tintColor;

    [self display];
}

- (void)drawInContext:(CGContextRef)ctx {
    CGContextSetFillColorWithColor(ctx, _tintColor.CGColor);
    CGContextSetStrokeColorWithColor(ctx, _tintColor.CGColor);
    CGRect rect = CGRectMake((self.bounds.size.width - self.bounds.size.height) / 2, 0, self.bounds.size.height,
                             self.bounds.size.height);

    CGContextStrokeEllipseInRect(ctx, CGRectInset(rect, 1, 1));
}

@end

@interface RCSightProgressView ()

@property (nonatomic, strong) RCProgressViewBackgroundLayer *backgroundLayer;
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, assign) BOOL startAnimation;

@end

@implementation RCSightProgressView {
    UIColor *_progressTintColor;
}

- (RCProgressViewBackgroundLayer *)backgroundLayer {
    if (!_backgroundLayer) {
        _backgroundLayer = [[RCProgressViewBackgroundLayer alloc] init];
    }
    return _backgroundLayer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self commonInit];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.frame = CGRectMake(0, 0, 44, 44);
        [self commonInit];
    }

    return self;
}

- (void)commonInit {
    _progressTintColor = [UIColor blackColor];
    self.tintColor = [UIColor whiteColor];

    self.backgroundLayer.frame = self.bounds;
    self.backgroundLayer.tintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8];
    self.backgroundLayer.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.2].CGColor;
    self.backgroundLayer.cornerRadius = self.bounds.size.width / 2;
    [self.layer addSublayer:self.backgroundLayer];

    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.frame = self.bounds;
    shapeLayer.fillColor = nil;
    shapeLayer.strokeColor = [UIColor whiteColor].CGColor; // self.progressTintColor.CGColor;
    [self.layer addSublayer:shapeLayer];
    self.shapeLayer = shapeLayer;
}

#pragma mark - Accessors

- (void)setProgress:(float)progress animated:(BOOL)animated {
    if (progress>0 && _progress==0 && self.shapeLayer.strokeEnd == 1) {
        // 第一次加载进度, 按需重置 strokeEnd
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.shapeLayer.strokeEnd = 0;
        [CATransaction commit];
    }
    _progress = progress;

    if (progress > 0) {
        BOOL startingFromIndeterminateState = [self.shapeLayer animationForKey:@"indeterminateAnimation"] != nil;
        [self stopIndeterminateAnimation];

        self.shapeLayer.lineWidth = self.shapeLayer.bounds.size.height / 2 - 3;

        self.shapeLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.shapeLayer.bounds),
                                                                                 CGRectGetMidY(self.shapeLayer.bounds))
                                                              radius:self.shapeLayer.lineWidth / 2
                                                          startAngle:3 * M_PI_2
                                                            endAngle:3 * M_PI_2 + 2 * M_PI
                                                           clockwise:YES]
                                   .CGPath;
        self.shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
        if (animated) {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            animation.fromValue = (startingFromIndeterminateState) ? @0 : nil;
            animation.toValue = [NSNumber numberWithFloat:progress];
            animation.duration = 1;
            self.shapeLayer.strokeEnd = progress;

            [self.shapeLayer addAnimation:animation forKey:@"animation"];
        } else {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            self.shapeLayer.strokeEnd = progress;
            [CATransaction commit];
        }

    } else {

        if (self.startAnimation) {
            return;
        } else {
            self.shapeLayer.strokeEnd = 0;
            [self startIndeterminateAnimation];
        }
    }
}

- (void)setProgress:(float)progress {
    [self setProgress:progress animated:NO];

    if (progress >= 1) {
        _progress = 0;
        self.startAnimation = NO;
    }
}

- (void)setProgressTintColor:(UIColor *)progressTintColor {
    if ([self respondsToSelector:@selector(setTintColor:)]) {
        self.tintColor = progressTintColor;
    } else {
        _progressTintColor = progressTintColor;
        [self tintColorDidChange];
    }
}

- (UIColor *)progressTintColor {
    if ([self respondsToSelector:@selector(tintColor)]) {
        return self.tintColor;
    } else {
        return _progressTintColor;
    }
}

#pragma mark - UIControl overrides

- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {

    if (self.progress > 0) {
        [super sendAction:action to:target forEvent:event];
    }
}

#pragma mark - Other methods

- (void)tintColorDidChange {
    self.backgroundLayer.tintColor = self.progressTintColor;
    self.shapeLayer.strokeColor = self.progressTintColor.CGColor;
}

- (void)startIndeterminateAnimation {
    if (self.startAnimation) {
        return;
    }
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    self.backgroundLayer.hidden = YES;

    self.shapeLayer.lineWidth = 1;
    self.shapeLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.shapeLayer.bounds),
                                                                             CGRectGetMidY(self.shapeLayer.bounds))
                                                          radius:self.shapeLayer.bounds.size.height / 2
                                                      startAngle:DEGREES_TO_RADIANS(348)
                                                        endAngle:DEGREES_TO_RADIANS(12)
                                                       clockwise:NO]
                               .CGPath;
    self.shapeLayer.strokeEnd = 1;
    self.shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    [CATransaction commit];

    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    rotationAnimation.toValue = [NSNumber numberWithFloat:2 * M_PI];
    rotationAnimation.duration = 1.0;
    rotationAnimation.repeatCount = HUGE_VALF;

    [self.shapeLayer addAnimation:rotationAnimation forKey:@"indeterminateAnimation"];
    self.startAnimation = YES;
}

- (void)stopIndeterminateAnimation {
    [self.shapeLayer removeAnimationForKey:@"indeterminateAnimation"];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.backgroundLayer.hidden = NO;
    [CATransaction commit];

    self.startAnimation = NO;
}

- (void)reset {
    [self setProgress:0 animated:NO];
    self.startAnimation = NO;
    [self startIndeterminateAnimation];
}

@end
