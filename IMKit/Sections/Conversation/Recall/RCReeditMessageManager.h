//
//  RCReeditMessageManager.h
//  RongIMKit
//
//  Created by 孙浩 on 2019/12/26.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 更新撤回消息状态的 Notification
FOUNDATION_EXPORT NSString *const RCKitNeedUpdateRecallStatusNotification;

@interface RCReeditMessageManager : NSObject

+ (instancetype)defaultManager;

/// 添加发送时间距离当前时间的时间
- (void)addReeditDuration:(long long)duration messageId:(long)messageId;

/// 重置撤回再编辑的时间并释放 timer
- (void)resetAndInvalidateTimer;

@end

NS_ASSUME_NONNULL_END
