//
//  RCMessageReactionResizablePanelGestureHandler.m
//  RongIMKit
//
//  Created by RC on 2026/6/24.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageReactionResizablePanelGestureHandler.h"

@interface RCMessageReactionResizablePanelGestureHandler ()

@property (nonatomic, assign) CGFloat panStartHeight;
@property (nonatomic, assign) CGFloat resizeStartTranslationY;
@property (nonatomic, assign) CGFloat panelTranslationY;
@property (nonatomic, assign) BOOL shouldResizeForCurrentPan;

@end

@implementation RCMessageReactionResizablePanelGestureHandler

- (instancetype)init {
    return [self initWithHeightEpsilon:0 dismissDistance:0 dismissVelocity:0];
}

- (instancetype)initWithHeightEpsilon:(CGFloat)heightEpsilon
                       dismissDistance:(CGFloat)dismissDistance
                       dismissVelocity:(CGFloat)dismissVelocity {
    self = [super init];
    if (self) {
        _heightEpsilon = heightEpsilon;
        _dismissDistance = dismissDistance;
        _dismissVelocity = dismissVelocity;
        _expandVelocity = -500.0;
    }
    return self;
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
                  inView:(UIView *)view
      currentPanelHeight:(CGFloat)currentPanelHeight
      minimumPanelHeight:(CGFloat)minimumPanelHeight
      maximumPanelHeight:(CGFloat)maximumPanelHeight {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.panStartHeight = currentPanelHeight;
        self.resizeStartTranslationY = 0;
        self.panelTranslationY = 0;
        self.shouldResizeForCurrentPan = NO;
    }

    CGFloat translationY = [gestureRecognizer translationInView:view].y;
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged && !self.shouldResizeForCurrentPan) {
        self.shouldResizeForCurrentPan = self.shouldResizeBlock ? self.shouldResizeBlock(translationY) : NO;
        if (self.shouldResizeForCurrentPan) {
            self.panStartHeight = currentPanelHeight;
            self.resizeStartTranslationY = translationY;
            self.panelTranslationY = 0;
        }
    }
    if (!self.shouldResizeForCurrentPan) {
        return;
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateFailed) {
        [self resetState];
        return;
    }

    CGFloat panelTranslationY = translationY - self.resizeStartTranslationY;
    CGFloat targetHeight = MIN(MAX(self.panStartHeight - panelTranslationY, minimumPanelHeight), maximumPanelHeight);
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        self.panelTranslationY = MAX(panelTranslationY - (self.panStartHeight - minimumPanelHeight), 0);
        [self applyPanelHeight:targetHeight panelTranslationY:self.panelTranslationY];
        [self layoutPanel];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
               gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
        CGFloat velocityY = [gestureRecognizer velocityInView:view].y;
        CGFloat resizedDistance = self.panStartHeight - targetHeight + self.panelTranslationY;
        if (gestureRecognizer.state == UIGestureRecognizerStateEnded &&
            resizedDistance > self.heightEpsilon &&
            [self shouldDismissWithTranslationY:self.panelTranslationY velocityY:velocityY]) {
            [self resetState];
            if (self.dismissBlock) {
                self.dismissBlock();
            }
            return;
        }

        CGFloat midpoint = (minimumPanelHeight + maximumPanelHeight) / 2.0;
        CGFloat settledHeight = (targetHeight >= midpoint || velocityY < self.expandVelocity) ? maximumPanelHeight : minimumPanelHeight;
        [self applyPanelHeight:settledHeight panelTranslationY:0];
        [UIView animateWithDuration:0.2 animations:^{
            [self layoutPanel];
        }];
        [self resetState];
    }
}

- (BOOL)shouldDismissWithTranslationY:(CGFloat)translationY velocityY:(CGFloat)velocityY {
    return translationY >= self.dismissDistance || velocityY >= self.dismissVelocity;
}

- (void)applyPanelHeight:(CGFloat)panelHeight panelTranslationY:(CGFloat)panelTranslationY {
    if (self.applyStateBlock) {
        self.applyStateBlock(panelHeight, panelTranslationY);
    }
}

- (void)layoutPanel {
    if (self.layoutBlock) {
        self.layoutBlock();
    }
}

- (void)resetState {
    self.resizeStartTranslationY = 0;
    self.panelTranslationY = 0;
    self.shouldResizeForCurrentPan = NO;
}

@end
