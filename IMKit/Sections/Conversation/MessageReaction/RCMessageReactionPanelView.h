//
//  RCMessageReactionPanelView.h
//  RongIMKit
//
//  Created by RC on 2026/6/2.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RCMessageReactionPanelView;

@protocol RCMessageReactionPanelViewDelegate <NSObject>

- (void)messageReactionPanelView:(RCMessageReactionPanelView *)panelView didSelectReactionId:(NSString *)reactionId;

@end

@interface RCMessageReactionPanelView : UIView

@property (nonatomic, weak, nullable) id<RCMessageReactionPanelViewDelegate> delegate;
@property (nonatomic, assign) CGFloat topLimitInset;

- (instancetype)initWithRecentReactionIds:(NSArray<NSString *> *)recentReactionIds;
- (void)showInView:(UIView *)view;
- (void)dismiss;
- (void)dismissAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
