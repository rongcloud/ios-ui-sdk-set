//
//  RCSightActionButton.m
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/4/25.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightActionButton.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RongSightAdaptiveHeader.h"

@interface RCSightActionButton ()

@property (nonatomic, strong) CAShapeLayer *ringLayer;

@property (nonatomic, strong) CAShapeLayer *progressLayer;

@property (nonatomic, strong) CAShapeLayer *centerLayer;

@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, assign) BOOL isTimeOut;

@property (nonatomic, assign) BOOL isPress;

@property (nonatomic, assign) BOOL isCancel;

@property (nonatomic, assign) CGRect ringFrame;

@property (nonatomic, assign) CGFloat progress;

@property (nonatomic, assign) CGFloat tempInterval;

@property (nonatomic, weak) UILongPressGestureRecognizer *longPressGesture;

@end

@implementation RCSightActionButton

- (void)quit {
    [self.displayLink invalidate];
}

#pragma mark - Properties
- (CAShapeLayer *)ringLayer {
    if (!_ringLayer) {
        _ringLayer = [[CAShapeLayer alloc] init];
        _ringLayer.frame = self.bounds;
        _ringLayer.fillColor = [UIColor lightGrayColor].CGColor;
    }
    return _ringLayer;
}

- (CAShapeLayer *)progressLayer {
    if (!_progressLayer) {
        _progressLayer = [[CAShapeLayer alloc] init];
        _progressLayer.fillColor = [UIColor clearColor].CGColor;
        _progressLayer.strokeColor =
            [UIColor colorWithRed:79 / 255.0f green:145 / 255.0f blue:236.0 / 255.0f alpha:1].CGColor;
        _progressLayer.lineWidth = 5;
        _progressLayer.lineCap = kCALineCapRound;
    }
    return _progressLayer;
}

- (CAShapeLayer *)centerLayer {
    if (!_centerLayer) {
        _centerLayer = [[CAShapeLayer alloc] init];
        _centerLayer.frame = self.bounds;
        _centerLayer.fillColor = [UIColor whiteColor].CGColor;
    }
    return _centerLayer;
}

- (CADisplayLink *)displayLink {
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(linkRun)];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        _displayLink.paused = true;
    }
    return _displayLink;
}

#pragma mark - init
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self.layer addSublayer:self.ringLayer];
        [self.layer addSublayer:self.centerLayer];
        self.ringFrame = CGRectZero;
        self.backgroundColor = [UIColor clearColor];
        NSUInteger canRecordMaxDurationTemp = [self sightRecordMaxDuration];
        if (canRecordMaxDurationTemp > [[RCCoreClient sharedCoreClient] getVideoDurationLimit]) {
            //这个值不能超过 [[RCCoreClient sharedCoreClient] getVideoDurationLimit]。
            canRecordMaxDurationTemp = [[RCCoreClient sharedCoreClient] getVideoDurationLimit];
        }
        self.canRecordMaxDuration = canRecordMaxDurationTemp;
        UILongPressGestureRecognizer *longPress =
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
        [self addGestureRecognizer:longPress];
        self.longPressGesture = longPress;

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)setSupportLongPress:(BOOL)supportLongPress {
    _supportLongPress = supportLongPress;
    self.longPressGesture.enabled = supportLongPress;
}

#pragma mark - Link Selector
- (void)linkRun {
    const CGFloat interval = 60.0f * self.canRecordMaxDuration;
    self.tempInterval += 1 / interval;
    self.progress = self.tempInterval;
    if (self.tempInterval > 1) {
        [self stop];
        self.isTimeOut = true;
        [self actionTrigger:RCSightActionStateEnd];
    }

    [self setNeedsDisplay];
}

#pragma mark - Gesture Selector
- (void)longPressGesture:(UILongPressGestureRecognizer *)gesture {
    switch (gesture.state) {
    case UIGestureRecognizerStateBegan: {
        self.displayLink.paused = NO;
        self.isPress = YES;
        self.isTimeOut = NO;
        [self.layer addSublayer:self.progressLayer];
        [self actionTrigger:RCSightActionStateBegin];
    } break;
    case UIGestureRecognizerStateChanged: {
        CGPoint point = [gesture locationInView:self];
        if (CGRectContainsPoint(self.ringFrame, point)) {
            self.isCancel = NO;
            [self actionTrigger:RCSightActionStateMoving];
        } else {
            self.isCancel = YES;
            [self actionTrigger:RCSightActionStateWillCancel];
        }
    } break;
    case UIGestureRecognizerStateEnded: {
        [self stop];
        if (self.isCancel) {
            [self actionTrigger:RCSightActionStateDidCancel];
        } else if (!self.isTimeOut) {
            [self actionTrigger:RCSightActionStateEnd];
        }

    } break;

    default: {
        [self stop];
        self.isCancel = YES;
        [self actionTrigger:RCSightActionStateDidCancel];
    } break;
    }
    [self setNeedsDisplay];
}

- (void)tapGesture {
    [self actionTrigger:RCSightActionStateClick];
}

#pragma mark - override

- (void)drawRect:(CGRect)rect {
    const CGFloat width = self.bounds.size.width;

    CGFloat mainWith = width / 2;

    CGRect mainFrame = CGRectMake(mainWith / 2.0f, mainWith / 2.0f, mainWith, mainWith);

    CGRect ringFrame = CGRectInset(mainFrame, -0.3 * mainWith / 2.0f, -0.3 * mainWith / 2.0f);
    self.ringFrame = ringFrame;
    if (self.isPress) {
        ringFrame = CGRectInset(mainFrame, -mainWith / 2.0f, -mainWith / 2.0f);
    }

    UIBezierPath *ringPath = [UIBezierPath bezierPathWithRoundedRect:ringFrame cornerRadius:ringFrame.size.width / 2];
    self.ringLayer.path = ringPath.CGPath;

    if (self.isPress) {
        mainWith *= 0.8;
        mainFrame = CGRectMake((width - mainWith) / 2, (width - mainWith) / 2, mainWith, mainWith);
    }

    UIBezierPath *mainPath = [UIBezierPath bezierPathWithRoundedRect:mainFrame cornerRadius:mainWith / 2];
    self.centerLayer.path = mainPath.CGPath;

    if (self.isPress) {
        CGRect progressFrame = CGRectInset(ringFrame, 2.0, 2.0);
        UIBezierPath *progressPath =
            [UIBezierPath bezierPathWithRoundedRect:progressFrame cornerRadius:progressFrame.size.width / 2];
        self.progressLayer.path = progressPath.CGPath;
        self.progressLayer.strokeEnd = self.progress;
    }
}

#pragma mark - helpers

- (void)stop {
    self.isPress = false;
    self.tempInterval = 0.0;
    self.progress = 0;

    self.progressLayer.strokeEnd = 0;
    [self.progressLayer removeFromSuperlayer];
    self.displayLink.paused = YES;
    [self setNeedsDisplay];
}

- (void)actionTrigger:(RCSightActionState)state {
    if (self.action) {
        self.action(state);
    }
}

- (NSUInteger)sightRecordMaxDuration {
    NSUInteger duration = NSUIntegerMax;
    if ([RCIM sharedRCIM]) {
        if ([[RCIM sharedRCIM] performSelector:@selector(sightRecordMaxDuration)]) {
            duration = [RCIM sharedRCIM].sightRecordMaxDuration;
        }
    }
    return duration;
}

@end
