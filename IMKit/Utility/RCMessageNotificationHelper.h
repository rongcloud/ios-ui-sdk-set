//
//  RCMessageNotificationHelper.h
//  RongIMKit
//
//  Created by RobinCui on 2022/4/18.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCMessageNotificationHelper : NSObject

/// 验证消息是否可以通知
/// @param message 消息
/// @param completion 回调
+ (void)checkNotifyAbilityWith:(RCMessage *)message
                    completion:(void (^)(BOOL show))completion;
@end

NS_ASSUME_NONNULL_END
