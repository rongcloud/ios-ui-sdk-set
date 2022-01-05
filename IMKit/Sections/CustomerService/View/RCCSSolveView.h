//
//  RCCSSolveView.h
//  RongSelfBuiltCustomerDemo
//
//  Created by RongCloud on 2016/12/5.
//  Copyright © 2016 rongcloud. All rights reserved.
//

#import <RongIMLib/RongIMLib.h>
#import <UIKit/UIKit.h>
@interface RCCSSolveView : UIView
@property (nonatomic, copy) void (^isSolveBlock)(RCCSResolveStatus solveStatus);
@end
