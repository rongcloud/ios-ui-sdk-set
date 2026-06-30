//
//  RCMessageReactionManager.m
//  RongIMKit
//
//  Created by RC on 2026/6/2.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageReactionManager.h"

static NSString *const RCMessageReactionDefaultStorageKey = @"RCKitMessageReactionFrequentlyUsed";
static NSInteger const RCMessageReactionMaxFrequentlyUsedCount = 20;

@interface RCMessageReactionManager ()

@property (nonatomic, copy) NSString *storageKey;

@end

@implementation RCMessageReactionManager

+ (instancetype)sharedManager {
    static RCMessageReactionManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[RCMessageReactionManager alloc] initWithStorageKey:RCMessageReactionDefaultStorageKey];
    });
    return manager;
}

- (instancetype)init {
    return [self initWithStorageKey:RCMessageReactionDefaultStorageKey];
}

- (instancetype)initWithStorageKey:(NSString *)storageKey {
    self = [super init];
    if (self) {
        _storageKey = storageKey.length > 0 ? [storageKey copy] : RCMessageReactionDefaultStorageKey;
    }
    return self;
}

- (void)recordReactionUsage:(NSString *)reactionId {
    if (reactionId.length == 0) {
        return;
    }
    @synchronized (self) {
        NSMutableDictionary<NSString *, RCMessageReactionUsageInfo *> *usageMap = [self mutableUsageMap];
        RCMessageReactionUsageInfo *info = usageMap[reactionId];
        if (!info) {
            info = [[RCMessageReactionUsageInfo alloc] init];
            info.reactionId = reactionId;
        }
        info.useCount += 1;
        info.lastUsedTime = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
        usageMap[reactionId] = info;
        [self saveUsageItems:usageMap.allValues];
    }
}

- (NSArray<RCMessageReactionUsageInfo *> *)getFrequentlyUsedReactionsWithCount:(NSInteger)count {
    if (count <= 0) {
        return @[];
    }
    NSInteger limit = MIN(count, RCMessageReactionMaxFrequentlyUsedCount);
    @synchronized (self) {
        NSArray<RCMessageReactionUsageInfo *> *sortedItems = [[self usageItems] sortedArrayUsingComparator:^NSComparisonResult(RCMessageReactionUsageInfo *first, RCMessageReactionUsageInfo *second) {
            if (first.useCount > second.useCount) {
                return NSOrderedAscending;
            }
            if (first.useCount < second.useCount) {
                return NSOrderedDescending;
            }
            if (first.lastUsedTime > second.lastUsedTime) {
                return NSOrderedAscending;
            }
            if (first.lastUsedTime < second.lastUsedTime) {
                return NSOrderedDescending;
            }
            return [first.reactionId compare:second.reactionId];
        }];
        if (sortedItems.count <= limit) {
            return sortedItems;
        }
        return [sortedItems subarrayWithRange:NSMakeRange(0, limit)];
    }
}

- (void)clearReactionUsageForTesting {
    @synchronized (self) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.storageKey];
    }
}

- (NSMutableDictionary<NSString *, RCMessageReactionUsageInfo *> *)mutableUsageMap {
    NSMutableDictionary<NSString *, RCMessageReactionUsageInfo *> *usageMap = [NSMutableDictionary dictionary];
    for (RCMessageReactionUsageInfo *item in [self usageItems]) {
        if (item.reactionId.length > 0) {
            usageMap[item.reactionId] = [item copy];
        }
    }
    return usageMap;
}

- (NSArray<RCMessageReactionUsageInfo *> *)usageItems {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:self.storageKey];
    if (![data isKindOfClass:NSData.class]) {
        return @[];
    }
    NSArray<RCMessageReactionUsageInfo *> *items = nil;
    if (@available(iOS 11.0, *)) {
        NSError *error = nil;
        NSSet *classes = [NSSet setWithObjects:NSArray.class, RCMessageReactionUsageInfo.class, NSString.class,
                          NSNumber.class, nil];
        items = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];
        if (error) {
            return @[];
        }
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        items = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#pragma clang diagnostic pop
    }
    if (![items isKindOfClass:NSArray.class]) {
        return @[];
    }
    NSMutableArray<RCMessageReactionUsageInfo *> *validItems = [NSMutableArray array];
    for (id item in items) {
        if ([item isKindOfClass:RCMessageReactionUsageInfo.class]) {
            [validItems addObject:item];
        }
    }
    return validItems.copy;
}

- (void)saveUsageItems:(NSArray<RCMessageReactionUsageInfo *> *)items {
    NSArray<RCMessageReactionUsageInfo *> *sortedItems = [[items sortedArrayUsingComparator:^NSComparisonResult(RCMessageReactionUsageInfo *first, RCMessageReactionUsageInfo *second) {
        if (first.useCount > second.useCount) {
            return NSOrderedAscending;
        }
        if (first.useCount < second.useCount) {
            return NSOrderedDescending;
        }
        if (first.lastUsedTime > second.lastUsedTime) {
            return NSOrderedAscending;
        }
        if (first.lastUsedTime < second.lastUsedTime) {
            return NSOrderedDescending;
        }
        return [first.reactionId compare:second.reactionId];
    }] copy];
    if (sortedItems.count > RCMessageReactionMaxFrequentlyUsedCount) {
        sortedItems = [sortedItems subarrayWithRange:NSMakeRange(0, RCMessageReactionMaxFrequentlyUsedCount)];
    }
    NSData *data = nil;
    if (@available(iOS 11.0, *)) {
        NSError *error = nil;
        data = [NSKeyedArchiver archivedDataWithRootObject:sortedItems requiringSecureCoding:YES error:&error];
        if (error) {
            return;
        }
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        data = [NSKeyedArchiver archivedDataWithRootObject:sortedItems];
#pragma clang diagnostic pop
    }
    if (data) {
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:self.storageKey];
    }
}

@end
