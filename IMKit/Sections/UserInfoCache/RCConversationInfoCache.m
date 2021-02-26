//
//  RCConversationInfoCache.m
//  RongIMKit
//
//  Created by 岑裕 on 16/1/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCConversationInfoCache.h"
#import "RCThreadSafeMutableDictionary.h"
#import "RCUserInfoCacheManager.h"
#import "RCloudImageLoader.h"

@interface RCConversationInfoCache ()

// key:GUID(conversationType;;;targetId), value:coversationInfo
@property (nonatomic, strong) RCThreadSafeMutableDictionary *cache;

@end

@implementation RCConversationInfoCache

+ (instancetype)sharedCache {
    static RCConversationInfoCache *defaultCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!defaultCache) {
            defaultCache = [[RCConversationInfoCache alloc] init];
            defaultCache.cache = [[RCThreadSafeMutableDictionary alloc] init];
        }
    });
    return defaultCache;
}

- (RCConversationInfo *)getConversationInfo:(RCConversationType)conversationType targetId:(NSString *)targetId {
    NSString *conversationGUID = [RCConversationInfo getConversationGUID:conversationType targetId:targetId];
    if (!conversationGUID) {
        return nil;
    }
    RCConversationInfo *cacheConversationInfo = self.cache[conversationGUID];

    if (!cacheConversationInfo) {
        //线程同步读取
        RCConversationInfo *dbConversationInfo =
            [rcUserInfoReadDBHelper selectConversationInfoFromDB:conversationType targetId:targetId];
        if (dbConversationInfo) {
            [self.cache setValue:dbConversationInfo forKey:conversationGUID];
        }
        cacheConversationInfo = dbConversationInfo;
    }

    return cacheConversationInfo;
}

- (void)updateConversationInfo:(RCConversationInfo *)conversationInfo
              conversationType:(RCConversationType)conversationType
                      targetId:(NSString *)targetId {
    NSString *conversationGUID = [RCConversationInfo getConversationGUID:conversationType targetId:targetId];
    if (!conversationGUID) {
        return;
    }
    RCConversationInfo *cacheConversationInfo = self.cache[conversationGUID];

    if (![cacheConversationInfo isEqual:conversationInfo]) {
        [self.cache setValue:conversationInfo forKey:conversationGUID];

        __weak typeof(self) weakSelf = self;
        dispatch_async(rcUserInfoDBQueue, ^{
            [rcUserInfoWriteDBHelper replaceConversationInfoFromDB:conversationInfo
                                                  conversationType:conversationType
                                                          targetId:targetId];
            RCLogI(@"updateConversationInfo:conversationType:targetId:;;;conversationType=%lu,targerId=%@,name=%@,"
                   @"portrait=%@",
                   (unsigned long)conversationType, targetId, conversationInfo.name, conversationInfo.portraitUri);
            [weakSelf.updateDelegate onConversationInfoUpdate:conversationInfo];
        });
    }
}

- (void)clearConversationInfoNetworkCacheOnly:(RCConversationType)conversationType targetId:(NSString *)targetId {
    NSString *conversationGUID = [RCConversationInfo getConversationGUID:conversationType targetId:targetId];
    RCConversationInfo *cacheConversationInfo = self.cache[conversationGUID];

    if (!cacheConversationInfo) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(rcUserInfoDBQueue, ^{
            RCConversationInfo *dbConversationInfo =
                [rcUserInfoWriteDBHelper selectConversationInfoFromDB:conversationType targetId:targetId];
            [weakSelf deleteImageCache:dbConversationInfo];
        });
    } else {
        [self deleteImageCache:cacheConversationInfo];
    }
}

- (void)clearConversationInfo:(RCConversationType)conversationType targetId:(NSString *)targetId {
    NSString *conversationGUID = [RCConversationInfo getConversationGUID:conversationType targetId:targetId];
    if (!conversationGUID) {
        return;
    }
    RCConversationInfo *cacheConversationInfo = self.cache[conversationGUID];

    if (!cacheConversationInfo) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(rcUserInfoDBQueue, ^{
            RCConversationInfo *dbConversationInfo =
                [rcUserInfoWriteDBHelper selectConversationInfoFromDB:conversationType targetId:targetId];
            [weakSelf deleteImageCache:dbConversationInfo];
            [rcUserInfoWriteDBHelper deleteConversationInfoFromDB:conversationType targetId:targetId];
        });
    } else {
        [self deleteImageCache:cacheConversationInfo];
        [self.cache removeObjectForKey:conversationGUID];
    }
}

- (void)clearAllConversationInfo {
    //    for (RCConversationInfo *cacheConversationInfo in [self.cache allValues]) {
    //        [self deleteImageCache:cacheConversationInfo];
    //    }
    [self.cache removeAllObjects];

    //    __weak typeof(self) weakSelf = self;
    dispatch_async(rcUserInfoDBQueue, ^{
        //        NSArray *dbConversationInfoList = [rcUserInfoWriteDBHelper selectAllConversationInfoFromDB];
        //        for (RCConversationInfo *dbConversationInfo in dbConversationInfoList) {
        //            [weakSelf deleteImageCache:dbConversationInfo];
        //        }
        [rcUserInfoWriteDBHelper deleteAllConversationInfoFromDB];
    });
}

#pragma mark - image cache
- (void)deleteImageCache:(RCConversationInfo *)conversationInfo {
    //    if ([conversationInfo.portraitUri length] > 0) {
    //        [[RCloudImageLoader sharedImageLoader] clearCacheForURL:[NSURL
    //        URLWithString:conversationInfo.portraitUri]];
    //    }
}

@end
