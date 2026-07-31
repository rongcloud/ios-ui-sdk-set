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
#import "RCRRSUtil.h"

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
                self.cacheInfo[key] = info;
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
        for (RCReadReceiptResponseV5 *response in array) {
            NSString *key = [self keyByIdentifier:response.identifier];
            if (key && response.readCount > 0) {
                RCReadReceiptInfoV5 *info = [RCRRSUtil infoFromResponse:response];
                if (info) {
                    self.cacheInfo[key] = info;
                }
            }
        }
    }];
}

+ (void)refreshConversationsCachedIfNeeded:(NSArray <RCConversationModel *>*)conversations {
    RCRRSDataContext *instance = [RCRRSDataContext sharedInstance];
    [instance refreshConversationsCachedIfNeeded:conversations];
}

- (void)refreshConversationsCachedIfNeeded:(NSArray <RCConversationModel *>*)conversations {
    if (conversations.count == 0) {
        return;
    }
    
    // 复制一份缓存快照，避免长时间持有读锁
    __block NSDictionary *cacheSnapshot = nil;
    [self.lock performReadLockBlock:^{
        cacheSnapshot = [self.cacheInfo copy];
    }];
    
    // 遍历会话列表，直接用 key 查询缓存
    for (RCConversationModel *model in conversations) {
        if (![model rrs_couldFetchConversationReadReceipt]) {
            continue;
        }
        // 构建缓存 key
        RCConversationIdentifier *identifier = [[RCConversationIdentifier alloc] initWithConversationIdentifier:model.conversationType targetId:model.targetId];
        NSString *key = [self keyByIdentifier:identifier];
        // 从缓存中查询
        id cachedValue = cacheSnapshot[key];
        if (!cachedValue) {
            continue;
        }
        
        if ([cachedValue isKindOfClass:[RCReadReceiptInfoV5 class]]) {
            RCReadReceiptInfoV5 *info = (RCReadReceiptInfoV5 *)cachedValue;
            // 验证 messageUId 匹配且有已读数
            if ([info.messageUId isEqualToString:model.latestMessageUId]
                && info.readCount > 0) {
                model.readReceiptInfoV5 = info;
            }
        }
    }
}
@end
