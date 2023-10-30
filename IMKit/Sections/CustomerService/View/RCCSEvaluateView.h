//
//  RCCSEvaluateView.h
//  RongSelfBuiltCustomerDemo
//
//  Created by 张改红 on 2016/12/5.
//  Copyright © 2016年 rongcloud. All rights reserved.
//
#import <UIKit/UIKit.h>
@interface RCCSEvaluateView : UIView

@property (nonatomic, copy) void (^evaluateResult)(int source, int solveStatus, NSString *suggest);

- (instancetype)initWithFrame:(CGRect)frame showSolveView:(BOOL)isShowSolveView;
- (void)show;
- (void)hide;

@end
