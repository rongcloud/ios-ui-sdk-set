//
//  RCLoadingTipView.h
//  RongIMKit
//
//  Created by RobinCui on 2025/2/24.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCLoadingTipView : UIView

+ (RCLoadingTipView *)loadingWithTip:(NSString *)tip
                          parentView:(UIView *)parentView;
+ (RCLoadingTipView *)loadingWithTip:(NSString *)tip;
- (void)startLoading;
- (void)stopLoading;
@end

NS_ASSUME_NONNULL_END
