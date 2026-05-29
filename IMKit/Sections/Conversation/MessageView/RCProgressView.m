//
//  RCProgressView.m
//  RongIMKit
//
//  Created by 张改红 on 2020/9/9.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCProgressView.h"
#import "RCKitCommonDefine.h"
@implementation RCProgressView
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setProgress:(CGFloat)progress{
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat xCenter = rect.size.width * 0.5;
    CGFloat yCenter = rect.size.height * 0.5;
    CGFloat radius = MIN(rect.size.width, rect.size.height) * 0.5 ;
    
    UIColor *maskColor = [HEXCOLOR(0x000000) colorWithAlphaComponent:0.4];
    //背景遮罩
    [maskColor set];
    CGFloat lineW = MAX(rect.size.width, rect.size.height) * 0.5;
    CGContextSetLineWidth(context, lineW);
    CGContextAddArc(context, xCenter, yCenter, radius + lineW * 0.5 + 5, 0, M_PI * 2, 1);
    CGContextStrokePath(context);
    
    //进程圆
    CGContextSetLineWidth(context, 1);
    CGContextMoveToPoint(context, xCenter, yCenter);
    CGContextAddLineToPoint(context, xCenter, 0);
    CGFloat endAngle = - M_PI * 0.5 + _progress * M_PI * 2 + 0.001;
    CGContextAddArc(context, xCenter, yCenter, radius, - M_PI * 0.5, endAngle, 1);
    CGContextFillPath(context);
}
@end
