//
//  RCConversationUserInfoCache.m
//  RongIMKit
//
//  Created by 岑裕 on 16/1/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCConversationUserInfoCache.h"
#import "RCConversationInfo.h"
#import "RCThreadSafeMutableDictionary.h"
#import "RCUserInfoCacheManager.h"
#import "RCloudImageLoader.h"

static void *cacheRWQueueTag = &cacheRWQueueTag;

@interface RCConversationUserInfoCache ()

// key:GUID(conversationType;;;targetId), value:(NSMutableDictionary(key:userId, value:userInfo))
@property (nonatomic, strong) RCThreadSafeMutableDictionary *cache;
@property (nonatomic, strong) dispatch_queue_t conversationUserInfoCacheRWQueue;

@end

@implementation RCConversationUserInfoCache

+ (instancetype)sharedCache {
    static RCConversationUserInfoCache *defaultCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!defaultCache) {
            defaultCache = [[RCConversationUserInfoCache alloc] init];
            defaultCache.cache = [[RCThreadSafeMutableDictionary alloc] init];
        }
    });
    return defaultCache;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.conversationUserInfoCacheRWQueue =  dispatch_queue_create("cn.rongcloud.conversationUserInfoCacheRWQueue", NULL);
        dispatch_queue_set_specific(self.conversationUserInfoCacheRWQueue, cacheRWQueueTag, cacheRWQueueTag, NULL);
    }
    return self;
}

- (RCUserInfo *)getUserInfo:(NSString *)userId
           conversationType:(RCConversationType)conversationType
                   targetId:(NSString *)targetId {
    NSString *conversationGUID = [RCConversationInfo getConversationGUID:conversationType targetId:targetId];
    if (0 == conversationGUID.length || 0 == userId.length) {
        return nil;
    }
    
    __block RCUserInfo *cacheUserInfo = nil;
    
    // 同步读取
    [self performSyncRWQueueBlock:^{
        NSMutableDictionary *cacheUserInfoList = self.cache[conversationGUID];
        if (cacheUserInfoList) {
            cacheUserInfo = cacheUserInfoList[userId];
        }
    }];

    // 缓存中没有
    if (nil == cacheUserInfo) {
        //读取数据库
        RCUserInfo *dbUserInfo =
            [rcUserInfoReadDBHelper selectUserInfoFromDB:userId conversationType:conversationType targetId:targetId];
        if (dbUserInfo) {
            // 更新缓存，使用串行队列
            [self performAsyncRWQueueBlock:^{
                NSMutableDictionary *cacheUserInfoList = self.cache[conversationGUID];
                if (!cacheUserInfoList) {
                    cacheUserInfoList = [[NSMutableDictionary alloc] init];
                    [self.cache setObject:cacheUserInfoList forKey:conversationGUID];
                }
                [cacheUserInfoList setValue:dbUserInfo forKey:userId];
            }];
            cacheUserInfo = dbUserInfo;
        }
    }
    if (!cacheUserInfo) {
        return nil;
    }
    RCUserInfo *user = [[RCUserInfo alloc] initWithUserId:cacheUserInfo.userId name:cacheUserInfo.name portrait:cacheUserInfo.portraitUri];
    user.alias = cacheUserInfo.alias;
    user.extra = cacheUserInfo.extra;
    return user;
}

- (void)updateUserInfo:(RCUserInfo *)userInfo
             forUserId:(NSString *)userId
      conversationType:(RCConversationType)conversationType
              targetId:(NSString *)targetId {
    NSString *conversationGUID = [RCConversationInfo getConversationGUID:conversationType targetId:targetId];
    if (0 == conversationGUID.length || 0 == userId.length) {
        return;
    }
    
    __block RCUserInfo *cacheUserInfo = nil;
    
    // 同步读取
    [self performSyncRWQueueBlock:^{
        NSMutableDictionary *cacheUserInfoList = self.cache[conversationGUID];
        if (cacheUserInfoList) {
            cacheUserInfo = cacheUserInfoList[userId];
        }
    }];

    if (![userInfo isEqual:cacheUserInfo]) {
        // 更新缓存，使用串行队列
        [self performAsyncRWQueueBlock:^{
            NSMutableDictionary *cacheUserInfoList = self.cache[conversationGUID];
            if (!cacheUserInfoList) {
                cacheUserInfoList = [[NSMutableDictionary alloc] init];
                [self.cache setObject:cacheUserInfoList forKey:conversationGUID];
            }
            [cacheUserInfoList setValue:userInfo forKey:userId];
        }];
            
        dispatch_async(rcUserInfoDBQueue, ^{
            [rcUserInfoWriteDBHelper replaceUserInfoFromDB:userInfo
                                                 forUserId:userId
                                          conversationType:conversationType
                                                  targetId:targetId];
            RCLogI(@"updateUserInfo:forUserId:conversationType;targetId:;;;conversationType=%lu,targerId=%@,userId=%@,"
                   @"name=%@,portrait=%@",
                   (unsigned long)conversationType, targetId, userInfo.userId, userInfo.name, userInfo.portraitUri);
            [self.updateDelegate onConversationUserInfoUpdate:userInfo
                                                   inConversation:conversationType
                                                         targetId:targetId];
        });
    }
}

- (void)clearConversationUserInfoNetworkCacheOnly:(NSString *)userId
                                 conversationType:(RCConversationType)conversationType
                                         targetId:(NSString *)targetId {
    NSString *conversationGUID = [RCConversationInfo getConversationGUID:conversationType targetId:targetId];
    if (0 == conversationGUID.length || 0 == userId.length) {
        return;
    }
    
    __block RCUserInfo *cacheUserInfo = nil;
    
    // 同步读取
    [self performSyncRWQueueBlock:^{
        NSMutableDictionary *cacheUserInfoList = self.cache[conversationGUID];
        if (cacheUserInfoList) {
            cacheUserInfo = cacheUserInfoList[userId];
        }
    }];

    if (!cacheUserInfo) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(rcUserInfoDBQueue, ^{
            RCUserInfo *dbUserInfo = [rcUserInfoWriteDBHelper selectUserInfoFromDB:userId
                                                                  conversationType:conversationType
                                                                          targetId:targetId];
            [weakSelf deleteImageCache:dbUserInfo];
        });
    } else {
        [self deleteImageCache:cacheUserInfo];
    }
}

- (void)clearConversationUserInfo:(NSString *)userId
                 conversationType:(RCConversationType)conversationType
                         targetId:(NSString *)targetId {
    NSString *conversationGUID = [RCConversationInfo getConversationGUID:conversationType targetId:targetId];
    if (0 == conversationGUID.length || 0 == userId.length) {
        return;
    }
    
    __block RCUserInfo *cacheUserInfo = nil;
    __block NSMutableDictionary *cacheUserInfoList = nil;
    
    // 同步读取
    [self performSyncRWQueueBlock:^{
        cacheUserInfoList = self.cache[conversationGUID];
        if (cacheUserInfoList) {
            cacheUserInfo = cacheUserInfoList[userId];
        }
    }];

    if (!cacheUserInfo) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(rcUserInfoDBQueue, ^{
            RCUserInfo *dbUserInfo = [rcUserInfoWriteDBHelper selectUserInfoFromDB:userId
                                                                  conversationType:conversationType
                                                                          targetId:targetId];
            [weakSelf deleteImageCache:dbUserInfo];
        });
    } else {
        [self performAsyncRWQueueBlock:^{
            [cacheUserInfoList removeObjectForKey:userId];
            [self.cache setValue:cacheUserInfoList forKey:conversationGUID];
            [self deleteImageCache:cacheUserInfo];
        }];
    }
    dispatch_async(rcUserInfoDBQueue, ^{
        [rcUserInfoWriteDBHelper deleteConversationUserInfoFromDB:userId
                                                 conversationType:conversationType
                                                         targetId:targetId];
        RCLogI(@"clearConversationUserInfo:conversationType;targetId:;;;userId:%@,conversationType=%lu,targerId=%@",userId, (unsigned long)conversationType, targetId);
        RCUserInfo *userInfo = [[RCUserInfo alloc] init];
        userInfo.userId = userId;
        [self.updateDelegate onConversationUserInfoUpdate:userInfo
                                               inConversation:conversationType
                                                     targetId:targetId];
    });
}

- (void)clearAllConversationUserInfo {
    //    for (NSDictionary *cacheUserInfoList in [self.cache allValues]) {
    //        for (RCUserInfo *cacheUserInfo in [cacheUserInfoList allValues]) {
    //            [self deleteImageCache:cacheUserInfo];
    //        }
    //    }
    
    [self performAsyncRWQueueBlock:^{
        [self.cache removeAllObjects];
    }];

    //    __weak typeof(self) weakSelf = self;
    dispatch_async(rcUserInfoDBQueue, ^{
        //        NSArray *dbUserInfoList = [rcUserInfoWriteDBHelper selectAllConversationUserInfoFromDB];
        //        for (RCUserInfo *dbUserInfo in dbUserInfoList) {
        //            [weakSelf deleteImageCache:dbUserInfo];
        //        }
        [rcUserInfoWriteDBHelper deleteAllConversationUserInfoFromDB];
    });
}

#pragma mark - image cache
- (void)deleteImageCache:(RCUserInfo *)userInfo {
    //    if ([userInfo.portraitUri length] > 0) {
    //        [[RCloudImageLoader sharedImageLoader] clearCacheForURL:[NSURL URLWithString:userInfo.portraitUri]];
    //    }
}

- (void)performAsyncRWQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(cacheRWQueueTag)) {
        block();
    }
    else {
        dispatch_async(self.conversationUserInfoCacheRWQueue, block);
    }
}

- (void)performSyncRWQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(cacheRWQueueTag)) {
        block();
    }
    else {
        dispatch_sync(self.conversationUserInfoCacheRWQueue, block);
    }
}

@end
