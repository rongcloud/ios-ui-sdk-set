//
//  RCRobotEvaluationView.h
//  RongIMKit
//
//  Created by litao on 16/2/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCCustomIOSAlertView.h"
#import <UIKit/UIKit.h>

@class RCRobotEvaluationView;

@protocol RCRobotEvaluationViewDelegate <NSObject>

- (void)robotEvaluateViewCancel:(RCRobotEvaluationView *)view;
- (void)robotEvaluateView:(RCRobotEvaluationView *)view didEvaluateValue:(BOOL)isResolved;

@end

@interface RCRobotEvaluationView : RCCustomIOSAlertView
- (instancetype)initWithDelegate:(id<RCRobotEvaluationViewDelegate>)delegate;
@property (nonatomic) BOOL quitAfterEvaluation;
@property (nonatomic, copy) NSString *knownledgeId;
@end
