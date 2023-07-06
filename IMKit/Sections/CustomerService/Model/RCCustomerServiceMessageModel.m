//
//  RCCustomerServiceMessageModel.m
//  RongIMKit
//
//  Created by litao on 16/3/30.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCCustomerServiceMessageModel.h"

@interface RCCustomerServiceMessageModel ()
@property (nonatomic, copy) NSString *evaluateId;
@property (nonatomic) BOOL ignoreEvaluate;
@end

@implementation RCCustomerServiceMessageModel
- (instancetype)initWithMessage:(RCMessage *)rcMessage {
    self = [super initWithMessage:rcMessage];
    if (self) {
        self.ignoreEvaluate = NO;
        self.evaluateId = nil;
    }

    return self;
}

- (BOOL)isNeedEvaluateArea {
    if (self.conversationType == ConversationType_CUSTOMERSERVICE && !self.ignoreEvaluate &&
        self.messageDirection == MessageDirection_RECEIVE) {
        if ([self.content isKindOfClass:[RCTextMessage class]]) {
            RCTextMessage *txtMsg = (RCTextMessage *)self.content;
            if (txtMsg.extra) {
                NSData *data = [txtMsg.extra dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                if (dict) {
                    BOOL isNeedEva = [[dict objectForKey:@"robotEva"] boolValue];
                    if (isNeedEva) {
                        self.evaluateId = [dict objectForKey:@"sid"];
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}

- (void)disableEvaluate {
    self.ignoreEvaluate = YES;
}
@end
