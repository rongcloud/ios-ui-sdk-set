//
//  RCResendManager.h
//  RongIMKit
//
//  Created by 孙浩 on 2020/6/1.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

NS_ASSUME_NONNULL_BEGIN

/**
重新发送消息管理类
*/
@interface RCResendManager : NSObject

/**
 重新发送消息管理类单例

 @return 单例
 */
+ (instancetype)sharedManager;

/**
 该消息是否需要重新发送

 @param messageId 消息 Id
*/
- (BOOL)needResend:(long)messageId;

/**
 将消息加入重新发送消息池

 @param messageId 消息 Id
 */
- (void)addResendMessageIfNeed:(long)messageId error:(RCErrorCode)code;

/**
 将消息从重新发送消息池删除
 
 @param messageId 消息 Id
 */
- (void)removeResendMessage:(long)messageId;

@end

NS_ASSUME_NONNULL_END
