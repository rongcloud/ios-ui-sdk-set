//
//  RCMessageNotificationHelper.h
//  RongIMKit
//
//  Created by RobinCui on 2022/4/18.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCMessageNotificationHelper : NSObject

/// 验证消息是否可以通知
/// - Parameter message: 消息
/// - Parameter completion: 回调
+ (void)checkNotifyAbilityWith:(RCMessage *)message
                    completion:(void (^)(BOOL show))completion;
@end

NS_ASSUME_NONNULL_END
