//
//  RCLocalNotification.h
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

@interface RCLocalNotification : NSObject

/**
 *  单例设计
 *
 *  @return 实例
 */
+ (RCLocalNotification *)defaultCenter;

/// 兼容 iOS10 的本地通知（iOS10 以上，本地通知可分组和覆盖）
- (void)postLocalNotificationWithMessage:(RCMessage *)message userInfo:(NSDictionary *)userInfo;

/// 加密会话使用
- (void)postLocalNotification:(NSString *)formatMessage userInfo:(NSDictionary *)userInfo;

/// 本方法需要在主线程调用
- (void)recallLocalNotification:(NSString *)messageUId;

@end
