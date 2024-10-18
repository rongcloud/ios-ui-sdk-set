//
//  RCAdapterCenter.m
//  RongIMKit
//
//  Created by zgh on 2024/9/3.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCViewModelAdapterCenter.h"
#import "RCIMThreadLock.h"
#import "RCBaseViewModel.h"
@interface RCViewModelAdapterCenter()

@property (nonatomic, strong) NSMapTable *delegates;
@property (nonatomic, strong) RCIMThreadLock *lock;

@end

@implementation RCViewModelAdapterCenter
 
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
        self.delegates =  [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
                                                valueOptions:NSMapTableWeakMemory];
        self.lock = [[RCIMThreadLock alloc] init];
    }
    return self;
}

#pragma mark - Private


- (BOOL)registerDelegate:(id)delegate forViewModelClass:(Class)cls {
    if (![cls isSubclassOfClass:[RCBaseViewModel class]]) {
        return NO;
    }
    NSString *identifier = NSStringFromClass(cls);
    if (identifier) {
        [self.lock performWriteLockBlock:^{
            [self.delegates setObject:delegate forKey:identifier];
        }];
        return YES;
    }
    return NO;
}

- (id)delegateForViewModelClass:(Class)cls {
    if (![cls isSubclassOfClass:[RCBaseViewModel class]]) {
        return nil;
    }
    NSString *identifier = NSStringFromClass(cls);
    if (identifier) {
       __block id delegate = nil;
        [self.lock  performReadLockBlock:^{
            delegate = [self.delegates objectForKey:identifier];
        }];
        return delegate;
    }
    return nil;
}

#pragma mark - Public

+ (BOOL)registerDelegate:(id)delegate forViewModelClass:(Class)cls {
    RCViewModelAdapterCenter *instance = [RCViewModelAdapterCenter sharedInstance];
    return [instance registerDelegate:delegate forViewModelClass:cls];
}


+ (id)delegateForViewModelClass:(Class)cls {
    RCViewModelAdapterCenter *instance = [RCViewModelAdapterCenter sharedInstance];
    return [instance delegateForViewModelClass:cls];
}

+ (BOOL)removeDelegateForViewModelClass:(Class)cls {
    return [self registerDelegate:nil forViewModelClass:cls];
}
@end
