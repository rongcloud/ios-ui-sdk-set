//
//  RCSTTDetailView.m
//  RongIMKit
//
//  Created by RobinCui on 2025/5/27.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCSTTDetailView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCSTTLabel.h"
#import "RCMessageModel+STT.h"

@interface RCSTTDetailView()
@property (nonatomic, strong) UILabel *labContent;
@property (nonatomic, strong) CAShapeLayer *textMaskLayer;
@property (nonatomic, assign) BOOL animating;
@end

@implementation RCSTTDetailView

- (void)setupView {
    [super setupView];
    [self addSubview:self.labContent];
    self.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                    darkColor:HEXCOLOR(0x1c1c1e)];
    self.layer.cornerRadius = 8;
    [self.layer masksToBounds];
    self.layer.mask = self.textMaskLayer;
    
    RCSTTLog("🔍[MASK_DEBUG] setupView - textMaskLayer added to layer");
}


- (void)detailViewHighlight:(BOOL)highlight {
    if (highlight) {
        self.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xEAEAEA)
                                                        darkColor:HEXCOLOR(0x343438)];
    } else {
        self.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                        darkColor:HEXCOLOR(0x1c1c1e)];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    RCSTTLog(@"🔍[MASK_DEBUG] detailView layoutSubviews bounds:(%f, %f) (%f, %f)", 
             self.bounds.origin.x, self.bounds.origin.y, 
             self.bounds.size.width, self.bounds.size.height);
    RCSTTLog(@"🔍[MASK_DEBUG] layoutSubviews textMaskLayer frame:(%f, %f) (%f, %f)",
             self.textMaskLayer.frame.origin.x,
             self.textMaskLayer.frame.origin.y,
             self.textMaskLayer.frame.size.width,
             self.textMaskLayer.frame.size.height);
}

- (void)showText:(NSString *)text
            size:(CGSize)size
       animation:(BOOL)animation {
    RCSTTLog("showText: %@ size:%f - %f, animation: %d", text, size.width, size.height, animation);

    if (animation) {
        self.animating = YES;
        [self maskLayerInitial];
    } else {
        if (!CGRectEqualToRect(self.textMaskLayer.frame, self.bounds)) {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            self.textMaskLayer.frame = self.bounds;
            [CATransaction commit];
        }
        self.animating = NO;
    }
    RCSTTLog("🔍[MASK_DEBUG] showtext before maskLayer frame:(%f, %f) (%f, %f)",self.textMaskLayer.frame.origin.x,
             self.textMaskLayer.frame.origin.y,
             self.textMaskLayer.frame.size.width,
             self.textMaskLayer.frame.size.height
             );
    self.labContent.text = text;
    self.labContent.frame = CGRectMake(0, 0, size.width, size.height);
}

- (void)animateIfNeeded {
    if (!self.animating || self.hidden) {
        return;
    }
    RCSTTLog(@"🔍[MASK_DEBUG] detailView animationIfNeeded: %d", self.animating);
    self.animating = NO;
    
    // 清理之前的动画
    [self.textMaskLayer removeAllAnimations];
    
    // 强制同步 presentationLayer 到当前 modelLayer 状态
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [CATransaction setAnimationDuration:0.0];
    
    // 重新设置frame确保presentationLayer同步
    CGRect currentFrame = self.textMaskLayer.frame;
    self.textMaskLayer.frame = CGRectZero;
    self.textMaskLayer.frame = currentFrame;
    
    [CATransaction commit];
    
    // 强制刷新显示
    [self.textMaskLayer setNeedsDisplay];
    [self.textMaskLayer displayIfNeeded];
    
    RCSTTLog("🔍[MASK_DEBUG] animateIfNeeded start frame:(%f, %f) (%f, %f)",
             self.textMaskLayer.frame.origin.x,
             self.textMaskLayer.frame.origin.y,
             self.textMaskLayer.frame.size.width,
             self.textMaskLayer.frame.size.height);
    
    // 检查 presentationLayer 状态
    CALayer *presentationLayer = self.textMaskLayer.presentationLayer;
    if (presentationLayer) {
        RCSTTLog("🔍[MASK_DEBUG] presentationLayer after sync:(%f, %f) (%f, %f)",
                 presentationLayer.frame.origin.x,
                 presentationLayer.frame.origin.y,
                 presentationLayer.frame.size.width,
                 presentationLayer.frame.size.height);
    }
    
    RCSTTLog("🔍[MASK_DEBUG] animateIfNeeded target bounds:(%f, %f) (%f, %f)",
             self.bounds.origin.x,
             self.bounds.origin.y,
             self.bounds.size.width,
             self.bounds.size.height);
    
    // 延迟启动动画，确保状态同步完成
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 创建显式动画
        CABasicAnimation *frameAnimation = [CABasicAnimation animationWithKeyPath:@"frame"];
        frameAnimation.fromValue = [NSValue valueWithCGRect:currentFrame];
        frameAnimation.toValue = [NSValue valueWithCGRect:self.bounds];
        frameAnimation.duration = 0.35;
        frameAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        frameAnimation.fillMode = kCAFillModeForwards;
        frameAnimation.removedOnCompletion = NO;
        
        // 添加动画
        [self.textMaskLayer addAnimation:frameAnimation forKey:@"frameAnimation"];
        
        // 设置最终值
        self.textMaskLayer.frame = self.bounds;
        
        RCSTTLog("🔍[MASK_DEBUG] animation started from (%f, %f) to (%f, %f)",
                 currentFrame.origin.x, currentFrame.origin.y,
                 self.bounds.origin.x, self.bounds.origin.y);
    });
}

- (void)cleanAnimation {
    [self.textMaskLayer removeAllAnimations];
}

- (void)maskLayerInitial {
    RCSTTLog("🔍[MASK_DEBUG] maskLayerInitial bounds: (%f, %f) (%f, %f), messageSent: %d", 
             self.bounds.origin.x, self.bounds.origin.y, 
             self.bounds.size.width, self.bounds.size.height, self.messageSent);
    
    // 清理之前的动画状态
    [self.textMaskLayer removeAllAnimations];
    
    // 强制同步 presentationLayer 状态
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [CATransaction commit];
    
    // 确保bounds已经正确设置
    if (CGRectEqualToRect(self.bounds, CGRectZero)) {
        RCSTTLog("🔍[MASK_DEBUG] maskLayerInitial: bounds is zero, delaying execution");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self maskLayerInitial];
        });
        return;
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (self.messageSent) {
        self.textMaskLayer.frame = CGRectMake(CGRectGetMaxX(self.bounds),
                                              -CGRectGetMaxY(self.bounds),
                                              CGRectGetWidth(self.bounds),
                                              CGRectGetHeight(self.bounds));
        RCSTTLog("🔍[MASK_DEBUG] maskLayerInitial: set right position (%f, %f)", CGRectGetMaxX(self.bounds), -CGRectGetMaxY(self.bounds));
    }else {
        self.textMaskLayer.frame = CGRectMake(-CGRectGetMaxX(self.bounds),
                                              -CGRectGetMaxY(self.bounds),
                                              CGRectGetWidth(self.bounds),
                                              CGRectGetHeight(self.bounds));
        RCSTTLog("🔍[MASK_DEBUG] maskLayerInitial: set left position (%f, %f)", -CGRectGetMaxX(self.bounds), -CGRectGetMaxY(self.bounds));
    }
    [CATransaction commit];
    [self.textMaskLayer setNeedsDisplay];
    [self.textMaskLayer layoutIfNeeded];
    
    // 强制重设frame确保presentationLayer同步
    CGRect currentFrame = self.textMaskLayer.frame;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.textMaskLayer.frame = CGRectZero;
    self.textMaskLayer.frame = currentFrame;
    [CATransaction commit];
    
    // 立即检查设置是否生效
    RCSTTLog("🔍[MASK_DEBUG] maskLayerInitial immediately after commit, frame:(%f, %f) (%f, %f)",
             self.textMaskLayer.frame.origin.x,
             self.textMaskLayer.frame.origin.y,
             self.textMaskLayer.frame.size.width,
             self.textMaskLayer.frame.size.height);
    
    // 延迟检查 layer 位置是否被修改
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CALayer *presentationLayer = self.textMaskLayer.presentationLayer;
        RCSTTLog("🔍[MASK_DEBUG] maskLayerInitial check after 0.01s, modelLayer frame:(%f, %f) (%f, %f)",
                 self.textMaskLayer.frame.origin.x,
                 self.textMaskLayer.frame.origin.y,
                 self.textMaskLayer.frame.size.width,
                 self.textMaskLayer.frame.size.height);
        
        if (presentationLayer) {
            RCSTTLog("🔍[MASK_DEBUG] maskLayerInitial check after 0.01s, presentationLayer frame:(%f, %f) (%f, %f)",
                     presentationLayer.frame.origin.x,
                     presentationLayer.frame.origin.y,
                     presentationLayer.frame.size.width,
                     presentationLayer.frame.size.height);
        }
    });
}

- (UILabel *)labContent {
    if (!_labContent) {
        RCSTTLabel *lab  = [RCSTTLabel new];
        lab.textColor = RCDYCOLOR(0x11f2c, 0x9f9f9f);
        lab.font = [UIFont systemFontOfSize:16];
        lab.numberOfLines = 0;
        lab.adjustsFontSizeToFitWidth = NO;
        _labContent = lab;
    }
    return _labContent;
}

- (CAShapeLayer *)textMaskLayer {
    if (!_textMaskLayer) {
        _textMaskLayer = [CAShapeLayer layer];
        _textMaskLayer.fillColor = [UIColor blackColor].CGColor;
        _textMaskLayer.fillRule = kCAFillRuleEvenOdd;
        _textMaskLayer.frame = CGRectZero;
        _textMaskLayer.backgroundColor = [UIColor redColor].CGColor;
        
        RCSTTLog("🔍[MASK_DEBUG] textMaskLayer created");
    }
    return _textMaskLayer;
}

- (void)dealloc
{
    
}
@end
