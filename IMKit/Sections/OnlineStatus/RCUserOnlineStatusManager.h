//
//  RCUserOnlineStatusManager.h
//  RongIMKit
//
//  Created by Lang on 11/4/25.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 代理定义

@class RCUserOnlineStatusManager;

/// 在线状态订阅管理代理
///
/// 用于在订阅超限时，由外部（如会话列表）提供需要显示在线状态的用户列表
@protocol RCUserOnlineStatusManagerDelegate <NSObject>

@required

/// 获取需要显示在线状态的用户ID列表
///
/// - Parameter manager: 在线状态管理器实例
/// - Returns: 需要显示在线状态的用户ID数组，按优先级排序（优先级高的在前）
///
/// - Note:
///   - 当订阅数量超限时，管理器会调用此方法获取需要显示在线状态的用户列表
///   - 返回的列表可以包含好友和非好友，管理器内部会自动过滤（好友不需要订阅）
///   - 过滤后的列表会被截取到最大订阅数量，超出部分将不会被订阅
///   - 返回 nil 或空数组表示没有用户需要显示在线状态，订阅流程将停止
- (NSArray<NSString *> * _Nullable)userIdsNeedOnlineStatus:(RCUserOnlineStatusManager *)manager;

@end

@interface RCUserOnlineStatusManager : NSObject

/// 代理对象
@property (nonatomic, weak, nullable) id<RCUserOnlineStatusManagerDelegate> delegate;

/// 获取单例实例
+ (instancetype)sharedManager;

/// 批量获取用户在线状态
///
/// - Note:
///   1. 从 Lib 获取最新状态
///   2. 更新本地缓存
///   3. 发送 RCKitUserOnlineStatusChangedNotification 通知（所有监听的页面会自动更新）
- (void)fetchOnlineStatus:(NSArray<NSString *> *)userIds;

/// 获取用户在线状态，可配置是否处理订阅超限
/// - Parameters:
///   - userId: 用户ID
///   - processSubscribeLimit: 是否处理订阅超限
/// - Note:
///   - 如果 processSubscribeLimit 为 YES，则当订阅超限时，会自动处理订阅超限
///   - 如果 processSubscribeLimit 为 NO，则当订阅超限时，不会自动处理订阅超限，需要外部自行处理
- (void)fetchOnlineStatus:(NSString *)userId processSubscribeLimit:(BOOL)processSubscribeLimit;

/// 获取好友的在线状态
///
/// - Parameter userIds: 用户ID数组（必须都是好友）
- (void)fetchFriendOnlineStatus:(NSArray<NSString *> *)userIds;


/// 从缓存获取用户在线状态（同步方法，立即返回）
///
/// - Parameter userId: 用户ID
/// - Returns: 在线状态对象，nil 表示缓存中没有该用户的状态
///
/// - Note:
///   -  用于快速显示 UI，不会发起网络请求
///   - 如果返回 nil，建议调用 fetchOnlineStatus: 获取最新状态
- (RCSubscribeUserOnlineStatus * _Nullable)getCachedOnlineStatus:(NSString *)userId;

/// 清除所有缓存，并重置内部状态
- (void)clearCache;

@end

NS_ASSUME_NONNULL_END
