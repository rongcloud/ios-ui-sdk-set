//
//  RCBatchSubmitManager.h
//  RongIMKit
//
//  Created by AI Assistant on 2025/10/13.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 批量提交结果回调
 
 @param code 提交结果错误码：0 代表成功，其他代表失败
 @param refillData 是否需要回填数据，某些失败场景需要回填重试
 */
typedef void(^RCBatchSubmitResultCallback)(NSInteger code, BOOL refillData);

/**
 批量提交回调
 
 @param items 要提交的数据列表
 @param resultCallback 提交结果回调，执行完业务逻辑后必须调用
 */
typedef void(^RCBatchSubmitCallback)(NSArray *items, RCBatchSubmitResultCallback resultCallback);

/**
 批量提交管理器
 用于将高频调用的操作进行批量处理，减少网络请求次数
 
 功能特性：
 1. 防抖动：在指定延迟时间内的多次调用会被合并成一次提交
 2. 状态机管理：使用清晰的状态转换避免竞态条件
 3. 线程安全：使用统一的状态锁确保多线程安全
 4. 顺序保证：使用 NSMutableOrderedSet 保持任务的插入顺序
 5. 去重保证：自动去除重复任务（基于 isEqual: 和 hash）
 6. 批量限制：单次最多提交 100 条数据
 7. 失败重试：支持失败数据回填到队列头部优先处理
 8. 连接状态感知：根据连接状态自动暂停/恢复任务处理
 
 状态机：
 IDLE ⇄ ACTIVE
 
 状态说明：
 - IDLE: 空闲状态，没有待处理数据，没有安排任务
 - ACTIVE: 活跃状态，有待处理数据或正在处理中
 
 连接状态感知：
 - 断网时：新任务只添加到队列，不启动提交
 - 连接恢复：自动启动队列中的待处理任务
 
 @note 添加的数据类型需要正确实现 isEqual: 和 hash 方法以支持去重
 */
@interface RCBatchSubmitManager : NSObject

/**
 设置批量提交回调
 
 @param callback 批量提交回调
 */
- (void)setupSubmitCallback:(RCBatchSubmitCallback)callback;

/**
 添加数据到批量处理队列
 
 @param item 要添加的数据（会自动去重）
 @note 数据类型需要正确实现 isEqual: 和 hash 方法
 */
- (void)addSubmitTask:(id)item;

/**
 停止接收连接状态通知，但保留内部状态，让剩余任务继续执行完成
 
 @note 调用此方法后，BatchSubmitManager 将不再响应连接状态变化，
       但已添加的任务会继续执行直到完成或失败
 */
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END

