//
//  RCCSAlertView.h
//  RongIMKit
//
//  Created by litao on 16/2/23.
//  Copyright © 2016 RongCloud. All rights reserved.
//

#import "RCCustomIOSAlertView.h"

@class RCCSAlertView;
@protocol RCCSAlertViewDelegate <NSObject>
- (void)willCSAlertViewDismiss:(RCCSAlertView *)view;
@end

@interface RCCSAlertView : RCCustomIOSAlertView
- (instancetype)initWithTitle:(NSString *)title
                      warning:(NSString *)warning
                     delegate:(id<RCCSAlertViewDelegate>)delegate;
@end
