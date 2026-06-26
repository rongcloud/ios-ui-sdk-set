//
//  RCIMThreadLock.m
//  RongIMKit
//
//  Created by RobinCui on 2022/8/5.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCIMThreadLock.h"
// 导入头文件
#import <pthread.h>

@interface RCIMThreadLock()
@property (nonatomic, assign) pthread_rwlock_t rwlock;
@end

@implementation RCIMThreadLock

+ (instancetype)createRWLock {
    return [[RCIMThreadLock alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_rwlock_init(&_rwlock, NULL);
    }
    return self;
}

- (void)performReadLockBlock:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    pthread_rwlock_rdlock(&_rwlock);
    block();
    pthread_rwlock_unlock(&_rwlock);
}

- (void)performWriteLockBlock:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    pthread_rwlock_wrlock(&_rwlock);
    block();
    pthread_rwlock_unlock(&_rwlock);
}

- (void)dealloc {
    pthread_rwlock_destroy(&_rwlock);
}
@end
