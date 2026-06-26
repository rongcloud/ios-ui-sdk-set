//
//  RCKitListenerManager.m
//  RongCloudOpenSource
//
//  Created by 张改红 on 2021/12/30.
//

#import "RCKitListenerManager.h"

@interface RCKitListenerManager ()

@property (nonatomic, strong) NSHashTable<id<RCIMReceiveMessageDelegate>> *receiveMessageDelegates;
@property (nonatomic, strong) NSHashTable<id<RCIMConnectionStatusDelegate>> *connectionStatusDelegates;

@end
@implementation RCKitListenerManager
+ (instancetype)sharedManager {
    static RCKitListenerManager *shareManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareManager = [[RCKitListenerManager alloc] init];
        shareManager.connectionStatusDelegates = [NSHashTable weakObjectsHashTable];
        shareManager.receiveMessageDelegates = [NSHashTable weakObjectsHashTable];
    });
    return shareManager;
}

- (void)addConnectionStatusChangeDelegate:(id<RCIMConnectionStatusDelegate>)delegate {
    @synchronized (self) {
        if (delegate) {
            [self.connectionStatusDelegates addObject:delegate];
        }
    }
}

- (void)removeConnectionStatusChangeDelegate:(id<RCIMConnectionStatusDelegate>)delegate {
    @synchronized (self) {
        if (delegate) {
            [self.connectionStatusDelegates removeObject:delegate];
        }
    }
}

- (NSArray<id<RCIMConnectionStatusDelegate>> *)allConnectionStatusChangeDelegates {
    @synchronized (self) {
        return self.connectionStatusDelegates.allObjects;
    }
}

- (void)addReceiveMessageDelegate:(id<RCIMReceiveMessageDelegate>)delegate{
    @synchronized (self) {
        if (delegate) {
            [self.receiveMessageDelegates addObject:delegate];
        }
    }
}

- (void)removeReceiveMessageDelegate:(id<RCIMReceiveMessageDelegate>)delegate{
    @synchronized (self) {
        if (delegate) {
            [self.receiveMessageDelegates removeObject:delegate];
        }
    }
}

- (NSArray<id<RCIMReceiveMessageDelegate>> *)allReceiveMessageDelegates{
    @synchronized (self) {
        return self.receiveMessageDelegates.allObjects;
    }
}
@end
