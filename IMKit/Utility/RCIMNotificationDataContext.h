//
//  RCIMNotificationDataContext.h
//  RongIMLibCore
//
//  Created by RobinCui on 2022/4/18.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>
//# define RCDLog(format, ...) NSLog((@"[X]-> " "[函数名:%s]" "[行号:%d]" format), __FUNCTION__, __LINE__, ##__VA_ARGS__);

NS_ASSUME_NONNULL_BEGIN
#ifdef DEBUG
# define RCDLog(format, ...) NSLog((@"[X]-> "  "[行号:%d]" format), __LINE__, ##__VA_ARGS__);
#else
# define RCDLog(...)
#endif

@interface RCIMNotificationDataContext : NSObject

///按照会话列表构建level
/// - Parameter conversations: 会话列表
+ (void)updateNotificationLevelWith:(NSArray<RCConversation *> *)conversations;

/// 获取level
/// - Parameter type: 会话类型
/// - Parameter targetId: 会话ID
/// - Parameter channelId: 频道ID
/// - Parameter completion: 成功回调
/// - Parameter errorBlock: 失败回调
+ (void)queryNotificationLevelWith:(RCConversationType)type
                      targetId:(NSString *__nullable)targetId
                     channelId:(NSString *__nullable )channelId
                        completion:(void (^)(RCPushNotificationLevel level))completion;

/// 销毁上下文
+ (void)destroy;

+ (void)clean;
@end

NS_ASSUME_NONNULL_END
