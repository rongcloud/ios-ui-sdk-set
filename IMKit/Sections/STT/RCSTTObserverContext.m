//
//  RCSTTObserverContext.m
//  RongIMKit
//
//  Created by RobinCui on 2025/6/11.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCSTTObserverContext.h"
#import "RCIMThreadLock.h"

@interface RCSTTObserverContext()<RCSpeechToTextDelegate>
@property (nonatomic, strong) NSMapTable *observers;
@property (nonatomic, strong) RCIMThreadLock *lock;
@end

@implementation RCSTTObserverContext

+ (instancetype)sharedInstance {
   static id instance = nil;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
       instance = [[self alloc] init];
   });
   return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.observers =  [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
                                                valueOptions:NSMapTableWeakMemory];
        self.lock = [[RCIMThreadLock alloc] init];
        [[RCCoreClient sharedCoreClient] addSpeechToTextDelegate:self];
    }
    return self;
}

- (void)registerObserver:(id<RCSpeechToTextDelegate>)observer forMessage:(NSString *)messageUid {
    if (messageUid) {
        [self.lock performWriteLockBlock:^{
            [self.observers setObject:observer forKey:messageUid];
        }];
    }
   
}


/// 移除观察者
/// - Parameter messageUid: 语音消息ID
- (void)removeObserverForMessage:(NSString *)messageUid {
    if (messageUid) {
        [self.lock performWriteLockBlock:^{
            [self.observers removeObjectForKey:messageUid];
        }];
    }
}

#pragma mark - RCSpeechToTextDelegate
- (void)speechToTextDidComplete:(RCSpeechToTextInfo *)info
                     messageUId:(nonnull NSString *)messageUId
                           code:(RCErrorCode)code {
    __block id<RCSpeechToTextDelegate> observer = nil;
    if (!messageUId) {
        return;
    }
    [self.lock performReadLockBlock:^{
            observer = [self.observers objectForKey:messageUId];
    }];
    if ([observer respondsToSelector:@selector(speechToTextDidComplete:messageUId:code:)]) {
        [observer speechToTextDidComplete:info messageUId:messageUId code:code];
    }
}

#pragma mark - Public
+ (void)registerObserver:(id<RCSpeechToTextDelegate>)observer forMessage:(NSString *)messageUid {
    RCSTTObserverContext *instance = [RCSTTObserverContext sharedInstance];
    [instance registerObserver:observer forMessage:messageUid];
}

/// 移除观察者
/// - Parameter messageUid: 语音消息ID
+ (void)removeObserverForMessage:(NSString *)messageUid {
    RCSTTObserverContext *instance = [RCSTTObserverContext sharedInstance];
    [instance removeObserverForMessage:messageUid];
}

@end
