//
//  RCSTTDetailView.h
//  RongIMKit
//
//  Created by RobinCui on 2025/5/27.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCSTTDetailView : RCBaseView
@property (nonatomic, assign) BOOL messageSent;
- (void)detailViewHighlight:(BOOL)highlight;
- (void)showText:(NSString *)text
            size:(CGSize)size
       animation:(BOOL)animation;
- (void)animateIfNeeded;
- (void)cleanAnimation;
@end

NS_ASSUME_NONNULL_END
