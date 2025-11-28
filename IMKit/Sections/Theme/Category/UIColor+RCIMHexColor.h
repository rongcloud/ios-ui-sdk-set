//
//  UIColor+RCIMHexColor.h
//  RongIMKit
//
//  Created by RobinCui on 2025/9/17.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (RCIMHexColor)
+ (UIColor *)rcim_colorWithHex:(NSString *)hex;

+ (UIColor *)rcim_colorWithHex:(NSString *)hex alpha:(CGFloat)alpha;

@end

NS_ASSUME_NONNULL_END
