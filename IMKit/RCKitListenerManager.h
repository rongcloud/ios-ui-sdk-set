//
//  RCKitListenerManager.h
//  RongCloudOpenSource
//
//  Created by 张改红 on 2021/12/30.
//

#import "RCIM.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCKitListenerManager : NSObject
/**
 单例

 @return 单例对象
 */
+ (instancetype)sharedManager;

#pragma mark - 连接状态监听

/*!
 添加 IMKit 连接状态监听

 @param delegate 代理
 */
- (void)addConnectionStatusChangeDelegate:(id<RCIMConnectionStatusDelegate>)delegate;

/*!
 移除 IMKit 连接状态监听

 @param delegate 代理
 */
- (void)removeConnectionStatusChangeDelegate:(id<RCIMConnectionStatusDelegate>)delegate;

/*!
 获取 IMKit 所有连接状态监听
 
 @return 所有 IMKit 连接状态的监听
 */
- (NSArray <id<RCIMConnectionStatusDelegate>> *)allConnectionStatusChangeDelegates;

#pragma mark - 接收消息监听
/*!
 添加 IMKit 接收消息监听

 @param delegate 代理
 */
- (void)addReceiveMessageDelegate:(id<RCIMReceiveMessageDelegate>)delegate;

/*!
 移除 IMKit 接收消息监听

 @param delegate 代理
 */
- (void)removeReceiveMessageDelegate:(id<RCIMReceiveMessageDelegate>)delegate;

/*!
 获取 IMKit 接收消息监听
 
 @return 所有 IMKit 接收消息监听
 */
- (NSArray <id<RCIMReceiveMessageDelegate>> *)allReceiveMessageDelegates;
@end

NS_ASSUME_NONNULL_END
