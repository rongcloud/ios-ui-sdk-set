//
//  RCSightPreviewView.m
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/4/24.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightPreviewView.h"

#define FOCUS_BOX_BOUNDS CGRectMake(0.0f, 0.0f, 100.0f, 100.0f)

@interface RCSightPreviewView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIVisualEffectView *overlayView;
@property (strong, nonatomic) UIView *focusBox;
@property (strong, nonatomic) UITapGestureRecognizer *singleTapRecognizer;

@end

@implementation RCSightPreviewView

#pragma mark - Api
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        [self setup];
    }
    return self;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

#pragma mark - helper
- (void)setup {
    [self addSubview:self.overlayView];
    [self strechToSuperview:self.overlayView];

    [self addSubview:self.focusBox];
    [self addGestureRecognizer:self.singleTapRecognizer];
}

- (void)strechToSuperview:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *formats = @[ @"H:|[view]|", @"V:|[view]|" ];
    for (NSString *each in formats) {
        NSArray *constraints =
            [NSLayoutConstraint constraintsWithVisualFormat:each options:0 metrics:nil views:@{
                @"view" : view
            }];
        [view.superview addConstraints:constraints];
    }
}

#pragma mark - properties
- (UIVisualEffectView *)overlayView {
    if (!_overlayView) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _overlayView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    }
    return _overlayView;
}

- (UIView *)focusBox {
    if (!_focusBox) {
        _focusBox = [[UIView alloc] initWithFrame:FOCUS_BOX_BOUNDS];
        _focusBox.backgroundColor = [UIColor clearColor];
        _focusBox.layer.borderColor = [UIColor redColor].CGColor;
        _focusBox.layer.borderWidth = 1.0f;
        _focusBox.hidden = YES;
    }
    return _focusBox;
}

- (UITapGestureRecognizer *)singleTapRecognizer {
    if (!_singleTapRecognizer) {
        _singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        _singleTapRecognizer.delegate = self;
    }
    return _singleTapRecognizer;
}

#pragma mark - override
+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

#pragma mark - Gesture Action
- (void)handleSingleTap:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self];
    if (!self.focusBox.hidden) {
        return;
    }
    [self.delegate tappedToFocusAtPoint:[self.previewLayer captureDevicePointOfInterestForPoint:point]];
}

- (void)showFocusBoxAnimationAtPoint:(CGPoint)point {
    self.focusBox.center = point;
    self.focusBox.hidden = NO;
    void (^focusBoxAnimationBlock)(void) = ^{
        [UIView animateWithDuration:0.25
            delay:0
            options:UIViewAnimationOptionCurveEaseInOut
            animations:^{
                self.focusBox.layer.transform = CATransform3DMakeScale(0.7, 0.7, 1.0);
            }
            completion:^(BOOL finished) {
                double delayInSeconds = 0.5f;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                    self.focusBox.hidden = YES;
                    self.focusBox.layer.transform = CATransform3DMakeScale(1.0, 1.0f, 1.0);
                });
            }];
    };
    if (self.overlayView.alpha != 0) {
        [UIView animateWithDuration:0.5
            animations:^{
                self.overlayView.alpha = 0;
            }
            completion:^(BOOL finished) {
                focusBoxAnimationBlock();
            }];
    } else {
        focusBoxAnimationBlock();
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGRect rect = CGRectMake(0, 0, screenSize.width, 44);
    if (CGRectContainsPoint(rect, point)) {
        return NO;
    }
    return YES;
}

@end
