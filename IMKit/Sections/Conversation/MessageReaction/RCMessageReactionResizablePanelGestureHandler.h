//
//  RCMessageReactionResizablePanelGestureHandler.h
//  RongIMKit
//
//  Created by RC on 2026/6/24.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^RCMessageReactionResizablePanelShouldResizeBlock)(CGFloat translationY);
typedef void (^RCMessageReactionResizablePanelApplyStateBlock)(CGFloat panelHeight, CGFloat panelTranslationY);
typedef void (^RCMessageReactionResizablePanelLayoutBlock)(void);
typedef void (^RCMessageReactionResizablePanelDismissBlock)(void);

@interface RCMessageReactionResizablePanelGestureHandler : NSObject

@property (nonatomic, assign) CGFloat heightEpsilon;
@property (nonatomic, assign) CGFloat dismissDistance;
@property (nonatomic, assign) CGFloat dismissVelocity;
@property (nonatomic, assign) CGFloat expandVelocity;
@property (nonatomic, copy, nullable) RCMessageReactionResizablePanelShouldResizeBlock shouldResizeBlock;
@property (nonatomic, copy, nullable) RCMessageReactionResizablePanelApplyStateBlock applyStateBlock;
@property (nonatomic, copy, nullable) RCMessageReactionResizablePanelLayoutBlock layoutBlock;
@property (nonatomic, copy, nullable) RCMessageReactionResizablePanelDismissBlock dismissBlock;

- (instancetype)initWithHeightEpsilon:(CGFloat)heightEpsilon
                       dismissDistance:(CGFloat)dismissDistance
                       dismissVelocity:(CGFloat)dismissVelocity;

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
                  inView:(UIView *)view
      currentPanelHeight:(CGFloat)currentPanelHeight
        minimumPanelHeight:(CGFloat)minimumPanelHeight
        maximumPanelHeight:(CGFloat)maximumPanelHeight;

@end

NS_ASSUME_NONNULL_END
