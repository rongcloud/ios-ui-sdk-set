//
//  RCIMThreadLock.h
//  RongIMKit
//
//  Created by RobinCui on 2022/8/5.
//  Copyright © 2022 RongCloud. All rights reserved.
//

/*
 //  本类封装了读写锁, 注意使用场合（任务耗时短的场合）
 1、同一时间，只能有1个线程进行写的操作
 2、同一时间，允许有多个线程进行读的操作
 3、同一时间，不允许既有写的操作，又有读的操作
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCIMThreadLock : NSObject

// 创建实例（注意：每次都生成新的实例）
+ (instancetype)createRWLock;

// 读加锁，同一时间，允许多线程读
- (void)performReadLockBlock:(dispatch_block_t)block;

// 写加锁，同一时间，只允许一个线程写
- (void)performWriteLockBlock:(dispatch_block_t)block;

@end


NS_ASSUME_NONNULL_END
