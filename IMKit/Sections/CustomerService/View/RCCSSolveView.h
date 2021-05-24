//
//  RCCSSolveView.h
//  RongSelfBuiltCustomerDemo
//
//  Created by 张改红 on 2016/12/5.
//  Copyright © 2016年 rongcloud. All rights reserved.
//

#import <RongIMLib/RongIMLib.h>
#import <UIKit/UIKit.h>
@interface RCCSSolveView : UIView
@property (nonatomic, copy) void (^isSolveBlock)(RCCSResolveStatus solveStatus);
@end
