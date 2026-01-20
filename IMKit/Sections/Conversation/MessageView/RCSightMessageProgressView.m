//
//  RCSightMessageProgressView.m
//  RongIMKit
//
//  Created by zhaobingdong on 2017/5/18.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightMessageProgressView.h"

#define DEGREES_TO_RADIANS(x) (x) / 180.0 * M_PI
#define RADIANS_TO_DEGREES(x) (x) / M_PI * 180.0

@interface RCMessageProgressViewBackgroundLayer : CALayer

@property (nonatomic, strong) UIColor *tintColor;

@end

@implementation RCMessageProgressViewBackgroundLayer

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

typedef NS_ENUM(NSUInteger, RCEAnimationStatus) {
    AnimationIdleStatus,
    AnimationStartStatus,
    AnimationStopStatus,
};

@interface RCSightMessageProgressView ()

@property (nonatomic, strong) RCMessageProgressViewBackgroundLayer *backgroundLayer;
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, assign) RCEAnimationStatus animationstatus;

@end

@implementation RCSightMessageProgressView {
    UIColor *_progressTintColor;
}

#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self setup];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.frame = CGRectMake(0, 0, 44, 44);
        [self setup];
    }

    return self;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window) {
        if (self.animationstatus == AnimationStopStatus && self.progress <= 0) {
            [self startIndeterminateAnimation];
        }
    } else {
        if (self.animationstatus == AnimationStartStatus) {
            [self stopIndeterminateAnimation];
        }
    }
}

#pragma mark - UIControl overrides

- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {

    if (self.progress > 0) {
        [super sendAction:action to:target forEvent:event];
    }
}

#pragma mark - Public Methods
- (void)setProgress:(float)progress animated:(BOOL)animated {
    _progress = progress;

    if (progress > 0) {
        BOOL startingFromIndeterminateState = [self.shapeLayer animationForKey:@"indeterminateAnimation"] != nil;

        if (self.animationstatus == AnimationStartStatus) {
            [self stopIndeterminateAnimation];
        }

        self.shapeLayer.lineWidth = self.shapeLayer.bounds.size.height / 2 - 3;

        self.shapeLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.shapeLayer.bounds),
                                                                                 CGRectGetMidY(self.shapeLayer.bounds))
                                                              radius:self.shapeLayer.lineWidth / 2
                                                          startAngle:3 * M_PI_2
                                                            endAngle:3 * M_PI_2 + 2 * M_PI
                                                           clockwise:YES]
                                   .CGPath;

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

        if (self.animationstatus == AnimationStartStatus) {
            return;
        } else {
            self.shapeLayer.strokeEnd = 0;
            [self startIndeterminateAnimation];
        }
    }
}

- (void)startIndeterminateAnimation {
    if (self.animationstatus == AnimationStartStatus) {
        return;
    }
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    self.backgroundLayer.hidden = YES;

    self.shapeLayer.lineWidth = 1;
    self.shapeLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.shapeLayer.bounds),
                                                                             CGRectGetMidY(self.shapeLayer.bounds))
                                                          radius:self.shapeLayer.bounds.size.height / 2 - 1
                                                      startAngle:DEGREES_TO_RADIANS(348)
                                                        endAngle:DEGREES_TO_RADIANS(12)
                                                       clockwise:NO]
                               .CGPath;
    self.shapeLayer.strokeEnd = 1;

    [CATransaction commit];

    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    rotationAnimation.toValue = [NSNumber numberWithFloat:2 * M_PI];
    rotationAnimation.duration = 1.0;
    rotationAnimation.repeatCount = HUGE_VALF;

    [self.shapeLayer addAnimation:rotationAnimation forKey:@"indeterminateAnimation"];
    self.animationstatus = AnimationStartStatus;
}

- (void)stopIndeterminateAnimation {
    if (self.animationstatus == AnimationStopStatus || self.animationstatus == AnimationIdleStatus) {
        return;
    }
    [self.shapeLayer removeAnimationForKey:@"indeterminateAnimation"];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.backgroundLayer.hidden = NO;
    [CATransaction commit];

    self.animationstatus = AnimationStopStatus;
}

- (void)resetStatus {
    [self setProgress:0 animated:NO];
    self.animationstatus = AnimationIdleStatus;
    [self startIndeterminateAnimation];
}

#pragma mark - Private Methods

- (void)setup {
    _progressTintColor = [UIColor blackColor];

    self.backgroundLayer.frame = self.bounds;
    self.backgroundLayer.tintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8];
    ;
    self.backgroundLayer.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.2].CGColor;
    self.backgroundLayer.cornerRadius = self.bounds.size.width / 2;
    [self.layer addSublayer:self.backgroundLayer];

    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.frame = self.bounds;
    shapeLayer.fillColor = nil;
    shapeLayer.strokeColor = [UIColor whiteColor].CGColor; // self.progressTintColor.CGColor;

    [self.layer addSublayer:shapeLayer];
    self.shapeLayer = shapeLayer;
    self.animationstatus = AnimationIdleStatus;
}

- (void)tintColorDidChange {
    self.backgroundLayer.tintColor = self.progressTintColor;
    self.shapeLayer.strokeColor = self.progressTintColor.CGColor;
}

#pragma mark - Getters and Setters
- (RCMessageProgressViewBackgroundLayer *)backgroundLayer {
    if (!_backgroundLayer) {
        _backgroundLayer = [[RCMessageProgressViewBackgroundLayer alloc] init];
    }
    return _backgroundLayer;
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

- (void)setProgress:(float)progress {
    [self setProgress:progress animated:NO];

    if (progress >= 1) {
        _progress = 0;
        self.animationstatus = AnimationStopStatus;
    }
}
@end
