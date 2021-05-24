//
//  RCCustomerServiceMessageModel.h
//  RongIMKit
//
//  Created by litao on 16/3/30.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCMessageModel.h"
#import <RongIMLib/RongIMLib.h>

@interface RCCustomerServiceMessageModel : RCMessageModel
@property (nonatomic, readonly, getter=isNeedEvaluateArea) BOOL needEvaluateArea;
@property (nonatomic, copy, readonly) NSString *evaluateId;
@property (nonatomic) BOOL alreadyEvaluated;

- (instancetype)initWithMessage:(RCMessage *)rcMessage;
- (void)disableEvaluate;
@end
