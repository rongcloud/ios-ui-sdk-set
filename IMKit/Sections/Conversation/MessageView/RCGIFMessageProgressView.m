//
//  RCGIFMessageProgressView.m
//  RongIMKit
//
//  Created by liyan on 2019/7/19.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCGIFMessageProgressView.h"
#import "RCKitUtility.h"

@interface RCGIFMessageProgressView ()

@property (nonatomic, assign) CGFloat currentProgress;

@end

@implementation RCGIFMessageProgressView

- (void)drawRect:(CGRect)rect {
    CGPoint origin = CGPointMake(18, 18);
    CGFloat radius = 18.0f;
    CGFloat startAngle = -M_PI_2;
    CGFloat endAngle = startAngle + self.currentProgress * M_PI * 2;
    UIBezierPath *sectorPath = [UIBezierPath bezierPathWithArcCenter:origin
                                                              radius:radius
                                                          startAngle:startAngle
                                                            endAngle:endAngle
                                                           clockwise:YES];
    [sectorPath addLineToPoint:origin];
    [[UIColor whiteColor] set];
    [sectorPath fill];
}

#pragma mark - Public Methods

- (void)setProgress:(CGFloat)progress {
    if (!progress) {
        return;
    }
    self.currentProgress = progress * 0.01;
    [self setNeedsDisplay];
}

#pragma mark - Getters and Setters

- (CGFloat)currentProgress {
    if (!_currentProgress) {
        _currentProgress = 0;
    }
    return _currentProgress;
}

@end
