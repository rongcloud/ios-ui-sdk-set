//
//  RCOldMessageNotificationMessage.h
//  RongIMKit
//
//  Created by 杜立召 on 15/8/24.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>

#define RCOldMessageNotificationMessageTypeIdentifier @"RC:OldMsgNtf"

/// 展示历史消息文字
@interface RCOldMessageNotificationMessage : RCMessageContent <RCMessageCoding, RCMessagePersistentCompatible>

/**
 *  init
 *
 *  - Returns: return instance
 */
- (instancetype)init;
@end
