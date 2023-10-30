//
//  RCAdminEvaluationView.h
//  RongIMKit
//
//  Created by litao on 16/2/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCCustomIOSAlertView.h"
#import <UIKit/UIKit.h>

@class RCAdminEvaluationView;

@protocol RCAdminEvaluationViewDelegate <NSObject>

- (void)adminEvaluateViewCancel:(RCAdminEvaluationView *)view;

- (void)adminEvaluateView:(RCAdminEvaluationView *)view didEvaluateValue:(int)starValues;

@end

@interface RCAdminEvaluationView : RCCustomIOSAlertView
@property (nonatomic, assign) BOOL quitAfterEvaluation;
@property (nonatomic, copy) NSString *dialogId;

- (instancetype)initWithDelegate:(id<RCAdminEvaluationViewDelegate>)delegate;

@end
