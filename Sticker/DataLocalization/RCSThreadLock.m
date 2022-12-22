//
//  RCSThreadLock.m
//  RongIMLibCore
//
//  Created by chinaspx on 2022/7/26.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCSThreadLock.h"
// 导入头文件
#import <pthread.h>

@interface RCSThreadLock()
@property (nonatomic, assign) pthread_rwlock_t rwlock;
@end

@implementation RCSThreadLock

+ (instancetype)createRWLock {
    return [[RCSThreadLock alloc] init];
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
