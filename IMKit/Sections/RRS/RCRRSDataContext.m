//
//  RCRRSDataContext.m
//  RongIMKit
//
//  Created by RobinCui on 2025/6/13.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCRRSDataContext.h"
#import "RCIMThreadLock.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCConversationModel+RRS.h"

@interface RCRRSDataContext()
@property (nonatomic, strong) RCIMThreadLock *lock;
@property (nonatomic, strong) NSMutableDictionary *cacheInfo;
@end

@implementation RCRRSDataContext

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
        self.lock = [[RCIMThreadLock alloc] init];
        self.cacheInfo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)keyByIdentifier:(RCConversationIdentifier *)identifier {
    NSString *key = nil;
    if (identifier.targetId) {
        NSString *channelID = identifier.channelId ? identifier.channelId : @"null";
        key = [NSString stringWithFormat:@"%@-%lu-%@", identifier.targetId, (unsigned long)identifier.type, channelID];
    }
    return key;
}

+ (void)refreshCacheWithReceiptInfo:(NSArray<RCReadReceiptInfoV5 *> *)infoList {
    RCRRSDataContext *instance = [RCRRSDataContext sharedInstance];
    [instance refreshCacheWithReceiptInfo:infoList];
}

- (void)refreshCacheWithReceiptInfo:(NSArray<RCReadReceiptInfoV5 *> *)infoList {
    [self.lock performWriteLockBlock:^{
        for (RCReadReceiptInfoV5 *info in infoList) {
            NSString *key = [self keyByIdentifier:info.identifier];
            if (key && info.readCount>0) {
                self.cacheInfo[key] = info.messageUId;
            }
        }
    }];
}

+ (void)refreshCacheWithResponse:(NSArray<RCReadReceiptResponseV5 *> *)infoList {
    RCRRSDataContext *instance = [RCRRSDataContext sharedInstance];
    [instance refreshCacheWithResponse:infoList];
}

- (void)refreshCacheWithResponse:(NSArray<RCReadReceiptResponseV5 *> *)infoList {
    NSMutableArray *array = [NSMutableArray array];
    for (RCReadReceiptResponseV5 *info in infoList) {
        if (info.identifier.type == ConversationType_PRIVATE) {// 只处理单聊
            [array addObject:info];
        }
    }
    [self.lock performWriteLockBlock:^{
        for (RCReadReceiptResponseV5 *info in array) {
            NSString *key = [self keyByIdentifier:info.identifier];
            if (key && info.readCount>0) {
                self.cacheInfo[key] = info.messageUId;
            }
        }
    }];
}

+ (void)refreshConversationsCachedIfNeeded:(NSArray <RCConversationModel *>*)conversations {
    RCRRSDataContext *instance = [RCRRSDataContext sharedInstance];
    [instance refreshConversationsCachedIfNeeded:conversations];
}

- (void)refreshConversationsCachedIfNeeded:(NSArray <RCConversationModel *>*)conversations {
    __block NSSet *setMessageUIDs = nil;
    [self.lock performReadLockBlock:^{
        NSArray *array = [self.cacheInfo allValues];
        setMessageUIDs = [NSSet setWithArray:array];
    }];
    for (RCConversationModel *model in conversations) {
        if ([model rrs_couldFetchConversationReadReceipt]) {
            if ([setMessageUIDs containsObject:model.latestMessageUId]) {
                model.readReceiptCount = 1;
                model.sentStatus = SentStatus_READ;
            }
        }
    }
}
@end
