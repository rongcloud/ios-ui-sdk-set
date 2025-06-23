//
//  RCMessageSendingContext.h
//  RongIMKit
//
//  Created by RobinCui on 2025/6/18.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCMessageModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface RCMessageSendingContext : NSObject

// 添加发送中的消息
- (void)addSendingMessage:(RCMessageModel *)message;
// 更新消息发送成功状态
- (BOOL)updateMessageSendSuccess:(RCMessage *)message;

@end

NS_ASSUME_NONNULL_END
