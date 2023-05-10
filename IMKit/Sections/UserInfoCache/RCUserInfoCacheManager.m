//
//  RCUserInfoCacheManager.m
//  RongIMKit
//
//  Created by 岑裕 on 16/1/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCUserInfoCacheManager.h"

NSString *const RCKitDispatchUserInfoUpdateNotification = @"RCKitDispatchUserInfoUpdateNotification";
NSString *const RCKitDispatchGroupUserInfoUpdateNotification = @"RCKitDispatchGroupUserInfoUpdateNotification";
NSString *const RCKitDispatchGroupInfoUpdateNotification = @"RCKitDispatchGroupInfoUpdateNotification";
NSString *const RCKitDispatchPublicServiceInfoNotification = @"RCKitDispatchPublicServiceInfoNotification";

@interface RCUserInfoCacheManager () <RCUserInfoUpdateDelegate, RCConversationUserInfoUpdateDelegate,
                                      RCConversationInfoUpdateDelegate>

@property (nonatomic, strong) dispatch_queue_t requestQueue;

@end

@implementation RCUserInfoCacheManager

+ (instancetype)sharedManager {
    static RCUserInfoCacheManager *defaultManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!defaultManager) {
            defaultManager = [[RCUserInfoCacheManager alloc] init];
            defaultManager.groupUserInfoEnabled = NO;
            defaultManager.requestQueue = dispatch_queue_create("cn.rongcloud.userInfoRequsetQueue", NULL);
            defaultManager.dbQueue = dispatch_queue_create("cn.rongcloud.userInfoDBQueue", NULL);
            [RCUserInfoCache sharedCache].updateDelegate = defaultManager;
            [RCConversationUserInfoCache sharedCache].updateDelegate = defaultManager;
            [RCConversationInfoCache sharedCache].updateDelegate = defaultManager;
        }
    });
    return defaultManager;
}

#pragma mark - DB Path
- (void)moveFile:(NSString *)fileName fromPath:(NSString *)fromPath toPath:(NSString *)toPath {
    if (![[NSFileManager defaultManager] fileExistsAtPath:toPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:toPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    NSString *srcPath = [fromPath stringByAppendingPathComponent:fileName];
    NSString *dstPath = [toPath stringByAppendingPathComponent:fileName];
    [[NSFileManager defaultManager] moveItemAtPath:srcPath toPath:dstPath error:nil];
}

/**
 苹果审核时，要求打开itunes sharing功能的app在Document目录下不能放置用户处理不了的文件
 2.8.9之前的版本数据库保存在Document目录
 从2.8.9之前的版本升级的时候需要把数据库从Document目录移动到Library/Application Support目录
 */
- (void)moveDBfile {
    NSString *const rongCloudString = @"RongCloud";
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]
        stringByAppendingPathComponent:self.appKey];
    NSString *libraryPath =
        [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0]
            stringByAppendingPathComponent:rongCloudString] stringByAppendingPathComponent:self.appKey];

    if ([[NSFileManager defaultManager] fileExistsAtPath:documentPath]) {
        NSArray<NSString *> *subPaths =
            [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentPath error:nil];
        NSString *const usrInfoCacheString = @"IMKitUserInfoCache";
        [subPaths enumerateObjectsUsingBlock:^(NSString *_Nonnull userPath, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([userPath hasPrefix:@"."]) {
                return;
            }
            NSString *dstUsrPath = [libraryPath stringByAppendingPathComponent:userPath];
            NSString *cachePath = [documentPath
                stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", userPath, usrInfoCacheString]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
                [self moveFile:usrInfoCacheString
                      fromPath:[cachePath stringByDeletingLastPathComponent]
                        toPath:dstUsrPath];
            }
        }];
    }
}

- (void)setCurrentUserId:(NSString *)currentUserId {
    if ([RCIM sharedRCIM].enablePersistentUserInfoCache && ![currentUserId isEqualToString:_currentUserId]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.dbQueue, ^{
            [self moveDBfile];
            NSString *libraryPath =
                NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
            libraryPath = [[[libraryPath stringByAppendingPathComponent:@"RongCloud"]
                stringByAppendingPathComponent:weakSelf.appKey] stringByAppendingPathComponent:currentUserId];
            if (![[NSFileManager defaultManager] fileExistsAtPath:libraryPath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:libraryPath
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:nil];
            }
            NSString *libraryStoragePath = [libraryPath stringByAppendingPathComponent:@"IMKitUserInfoCache"];
            if (weakSelf.writeDBHelper) {
                [weakSelf.writeDBHelper closeDBIfNeed];
                weakSelf.writeDBHelper = nil;
            }
            weakSelf.writeDBHelper = [[RCUserInfoCacheDBHelper alloc] initWithPath:libraryStoragePath];

            if (weakSelf.readDBHelper) {
                [weakSelf.readDBHelper closeDBIfNeed];
                weakSelf.readDBHelper = nil;
            }
            weakSelf.readDBHelper = [[RCUserInfoCacheDBHelper alloc] initWithPath:libraryStoragePath];
        });
    }

    _currentUserId = [currentUserId copy];
}

- (void)dealloc {
    [self.writeDBHelper closeDBIfNeed];
    self.writeDBHelper = nil;
    [self.readDBHelper closeDBIfNeed];
    self.readDBHelper = nil;
}

#pragma mark - UserInfo
- (RCUserInfo *)getUserInfo:(NSString *)userId {
    if (userId) {
        RCUserInfo *cacheUserInfo = [[RCUserInfoCache sharedCache] getUserInfo:userId];
        if (!cacheUserInfo) {
            if (![RCIM sharedRCIM].userInfoDataSource) {
                NSLog(@"...................用户信息提供者为空请检查是否设置 [RCIM sharedRCIM].userInfoDataSource "
                      @",并且保证设置的对象没有被释放 [RCIM sharedRCIM].userInfoDataSource 是 weak "
                      @"属性...................");
                return nil;
            }
            if ([RCIM sharedRCIM].userInfoDataSource &&
                [[RCIM sharedRCIM]
                        .userInfoDataSource respondsToSelector:@selector(getUserInfoWithUserId:completion:)]) {
                __weak typeof(self) weakSelf = self;
                dispatch_async(self.requestQueue, ^{
                    [[RCIM sharedRCIM]
                            .userInfoDataSource
                        getUserInfoWithUserId:userId
                                   completion:^(RCUserInfo *userInfo) {
                                       if (userInfo == nil || userInfo.name.length == 0) {
                                           RCLogE(@"getUserInfo:error;;;getUserInfoDataSource:userId=%@", userId);
                                       }
                                       [weakSelf updateUserInfo:userInfo forUserId:userId];
                                   }];
                });
            }
        }
        return cacheUserInfo;
    } else {
        RCLogE(@"getUserInfo:error;;;useId is nil");
        return nil;
    }
}

- (void)getUserInfo:(NSString *)userId complete:(void (^)(RCUserInfo *userInfo))completeBlock {
    if (userId) {
        RCUserInfo *cacheUserInfo = [[RCUserInfoCache sharedCache] getUserInfo:userId];
        if (cacheUserInfo) {
            if (completeBlock) {
                completeBlock(cacheUserInfo);
            }
        } else if ([RCIM sharedRCIM].userInfoDataSource &&
                   [[RCIM sharedRCIM]
                           .userInfoDataSource respondsToSelector:@selector(getUserInfoWithUserId:completion:)]) {
            dispatch_async(self.requestQueue, ^{
                __weak typeof(self) weakSelf = self;
                [[RCIM sharedRCIM]
                        .userInfoDataSource getUserInfoWithUserId:userId
                                                       completion:^(RCUserInfo *userInfo) {
                                                           [weakSelf updateUserInfo:userInfo forUserId:userId];
                                                                if (completeBlock) {
                                                                    completeBlock(userInfo);
                                                                }
                                                       }];
            });
        } else {
            if (completeBlock) {
                completeBlock(nil);
            }
        }
    } else {
        if (completeBlock) {
            completeBlock(nil);
        }
    }
}

- (RCUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId {
    if (userId) {
        return [[RCUserInfoCache sharedCache] getUserInfo:userId];
    } else {
        return nil;
    }
}

- (void)updateUserInfo:(RCUserInfo *)userInfo forUserId:(NSString *)userId {
    if (userId.length > 0 && !userInfo){
        [[RCUserInfoCache sharedCache] clearUserInfo:userId];
        return;
    }
    
    if (userId && userInfo) {
        [[RCUserInfoCache sharedCache] updateUserInfo:userInfo forUserId:userId];
    } else if (!userId && userInfo.userId) {
        [[RCUserInfoCache sharedCache] updateUserInfo:userInfo forUserId:userInfo.userId];
    }
}

- (void)clearUserInfoNetworkCacheOnly:(NSString *)userId {
    if (userId) {
        [[RCUserInfoCache sharedCache] clearUserInfoNetworkCacheOnly:userId];
    }
}

- (void)clearUserInfo:(NSString *)userId {
    if (userId) {
        [[RCUserInfoCache sharedCache] clearUserInfo:userId];
    }
}

- (void)clearAllUserInfo {
    [[RCUserInfoCache sharedCache] clearAllUserInfo];
}

#pragma mark - GroupUserInfo (sugar for ConversationUserInfo)

- (RCUserInfo *)getUserInfo:(NSString *)userId inGroupId:(NSString *)groupId {
    if (!self.groupUserInfoEnabled) {
        return [self getUserInfo:userId];
    }

    if (userId && groupId) {
        RCUserInfo *cacheUserInfo = [[RCConversationUserInfoCache sharedCache] getUserInfo:userId
                                                                          conversationType:ConversationType_GROUP
                                                                                  targetId:groupId];
        if (!cacheUserInfo && [RCIM sharedRCIM].groupUserInfoDataSource &&
            [[RCIM sharedRCIM]
                    .groupUserInfoDataSource respondsToSelector:@selector(getUserInfoWithUserId:inGroup:completion:)]) {
            dispatch_async(self.requestQueue, ^{
                __weak typeof(self) weakSelf = self;
                [[RCIM sharedRCIM]
                        .groupUserInfoDataSource
                    getUserInfoWithUserId:userId
                                  inGroup:groupId
                               completion:^(RCUserInfo *userInfo) {
                                   if (!userInfo) {
                                       userInfo = [[RCUserInfo alloc] initWithUserId:userId name:nil portrait:nil];
                                       RCLogE(@"getUserInfo:inGroupId: "
                                              @"error;;;groupUserInfoDataSource;;;groupId=%@;;;userInfo:userId=%@",
                                              groupId, userId);
                                   }
                                   [weakSelf updateUserInfo:userInfo forUserId:userId inGroup:groupId];
                               }];
            });
        }
        RCUserInfo *userInfo = [self fallBackOrdinaryUserInfo:cacheUserInfo forUserId:userId];
        if (userInfo == nil || userInfo.name.length == 0) {
            RCLogE(
                @"getUserInfo:inGroupId: error;;;groupId=%@;;;cacheUserInfo:userId=%@,userName=%@,userPortraitUri=%@",
                groupId, userInfo.userId, userInfo.name, userInfo.portraitUri);
        }
        return userInfo;
    } else {
        RCLogE(@"getUserInfo:inGroupId:error;;;useId or groupId is nil");
        return nil;
    }
}

- (void)getUserInfo:(NSString *)userId
          inGroupId:(NSString *)groupId
           complete:(void (^)(RCUserInfo *userInfo))completeBlock {
    if (!self.groupUserInfoEnabled) {
        [self getUserInfo:userId
                 complete:^(RCUserInfo *userInfo) {
                     if (completeBlock) {
                         completeBlock(userInfo);
                     }
                 }];
    }

    if (userId && groupId) {
        RCUserInfo *cacheUserInfo = [[RCConversationUserInfoCache sharedCache] getUserInfo:userId
                                                                          conversationType:ConversationType_GROUP
                                                                                  targetId:groupId];
        if (cacheUserInfo) {
            [self fallBackOrdinaryUserInfo:cacheUserInfo
                                 forUserId:userId
                                  complete:^(RCUserInfo *userInfo) {
                                      if (completeBlock) {
                                          completeBlock(cacheUserInfo);
                                      }
                                  }];
        } else if ([RCIM sharedRCIM].groupUserInfoDataSource &&
                   [[RCIM sharedRCIM]
                           .groupUserInfoDataSource
                       respondsToSelector:@selector(getUserInfoWithUserId:inGroup:completion:)]) {
            dispatch_async(self.requestQueue, ^{
                __weak typeof(self) weakSelf = self;
                [[RCIM sharedRCIM]
                        .groupUserInfoDataSource
                    getUserInfoWithUserId:userId
                                  inGroup:groupId
                               completion:^(RCUserInfo *userInfo) {
                                   if (!userInfo) {
                                       userInfo = [[RCUserInfo alloc] initWithUserId:userId name:nil portrait:nil];
                                   }
                                   [weakSelf updateUserInfo:userInfo forUserId:userId inGroup:groupId];
                                   [weakSelf fallBackOrdinaryUserInfo:userInfo
                                                            forUserId:userId
                                                             complete:^(RCUserInfo *userInfo) {
                                                                 if (completeBlock) {
                                                                     completeBlock(userInfo);
                                                                 }
                                                             }];
                               }];
            });
        } else {
            [self getUserInfo:userId
                     complete:^(RCUserInfo *userInfo) {
                        if (completeBlock) {
                            completeBlock(userInfo);
                        }
                     }];
        }
    } else {
        if (completeBlock) {
            completeBlock(nil);
        }
    }
}

- (RCUserInfo *)getUserInfoFromCacheOnly:(NSString *)userId inGroupId:(NSString *)groupId {
    if (!self.groupUserInfoEnabled) {
        return [self getUserInfoFromCacheOnly:userId];
    }

    if (userId && groupId) {
        RCUserInfo *cacheUserInfo = [[RCConversationUserInfoCache sharedCache] getUserInfo:userId
                                                                          conversationType:ConversationType_GROUP
                                                                                  targetId:groupId];
        return [self fallBackOrdinaryUserInfoFromCacheOnly:cacheUserInfo forUserId:userId];
    } else {
        return nil;
    }
}

//同步回落
- (RCUserInfo *)fallBackOrdinaryUserInfo:(RCUserInfo *)tempUserInfo forUserId:(NSString *)userId {
    if (!tempUserInfo) {
        return [self getUserInfo:userId];
    }

    if ([tempUserInfo.name length] <= 0 || [tempUserInfo.portraitUri length] <= 0) {
        RCUserInfo *ordinaryUserInfo = [self getUserInfo:userId];
        if ([tempUserInfo.name length] <= 0) {
            tempUserInfo.name = ordinaryUserInfo.name;
        }
        if ([tempUserInfo.portraitUri length] <= 0) {
            tempUserInfo.portraitUri = ordinaryUserInfo.portraitUri;
        }
    }
    return tempUserInfo;
}

- (RCUserInfo *)fallBackOrdinaryUserInfoFromCacheOnly:(RCUserInfo *)tempUserInfo forUserId:(NSString *)userId {
    if (!tempUserInfo) {
        return [self getUserInfoFromCacheOnly:userId];
    }

    if ([tempUserInfo.name length] <= 0 || [tempUserInfo.portraitUri length] <= 0) {
        RCUserInfo *ordinaryUserInfo = [self getUserInfo:userId];
        if ([tempUserInfo.name length] <= 0) {
            tempUserInfo.name = ordinaryUserInfo.name;
        }
        if ([tempUserInfo.portraitUri length] <= 0) {
            tempUserInfo.portraitUri = ordinaryUserInfo.portraitUri;
        }
    }
    return tempUserInfo;
}

//异步回落
- (void)fallBackOrdinaryUserInfo:(RCUserInfo *)tempUserInfo
                       forUserId:(NSString *)userId
                        complete:(void (^)(RCUserInfo *userInfo))completeBlock {
    if (!tempUserInfo) {
        [self getUserInfo:userId
                 complete:^(RCUserInfo *userInfo) {
                    if (completeBlock) {
                        completeBlock(userInfo);
                    }
                     
                 }];
    }

    if (!tempUserInfo.name || !tempUserInfo.portraitUri) {
        [self getUserInfo:userId
                 complete:^(RCUserInfo *userInfo) {
                     if (!tempUserInfo.name) {
                         tempUserInfo.name = userInfo.name;
                     }
                     if (!tempUserInfo.portraitUri) {
                         tempUserInfo.portraitUri = userInfo.portraitUri;
                     }
                    if (completeBlock) {
                        completeBlock(tempUserInfo);
                    }
                     
                 }];
    }
}

- (void)updateUserInfo:(RCUserInfo *)userInfo forUserId:(NSString *)userId inGroup:(NSString *)groupId {
    if (groupId) {
        if (userId.length > 0 && !userInfo){
            [[RCConversationUserInfoCache sharedCache] clearConversationUserInfo:userId conversationType:ConversationType_GROUP targetId:groupId];
            return;
        }

        if (userId && userInfo) {
            [[RCConversationUserInfoCache sharedCache] updateUserInfo:userInfo
                                                            forUserId:userId
                                                     conversationType:ConversationType_GROUP
                                                             targetId:groupId];
        } else if (!userId && userInfo.userId) {
            [[RCConversationUserInfoCache sharedCache] updateUserInfo:userInfo
                                                            forUserId:userInfo.userId
                                                     conversationType:ConversationType_GROUP
                                                             targetId:groupId];
        }
    }
}

- (void)clearGroupUserInfoNetworkCacheOnly:(NSString *)userId inGroup:(NSString *)groupId {
    if (userId && groupId) {
        [[RCConversationUserInfoCache sharedCache] clearConversationUserInfoNetworkCacheOnly:userId
                                                                            conversationType:ConversationType_GROUP
                                                                                    targetId:groupId];
    }
}

- (void)clearGroupUserInfo:(NSString *)userId inGroup:(NSString *)groupId {
    if (userId && groupId) {
        [[RCConversationUserInfoCache sharedCache] clearConversationUserInfo:userId
                                                            conversationType:ConversationType_GROUP
                                                                    targetId:groupId];
    }
}

- (void)clearAllGroupUserInfo {
    [[RCConversationUserInfoCache sharedCache] clearAllConversationUserInfo];
}

#pragma mark - GroupInfo (sugar for ConversationInfo)

- (RCGroup *)getGroupInfo:(NSString *)groupId {
    if (groupId) {
        RCConversationInfo *cacheConversationInfo =
            [[RCConversationInfoCache sharedCache] getConversationInfo:ConversationType_GROUP targetId:groupId];
        if (!cacheConversationInfo && [RCIM sharedRCIM].groupInfoDataSource &&
            [[RCIM sharedRCIM].groupInfoDataSource respondsToSelector:@selector(getGroupInfoWithGroupId:completion:)]) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(self.requestQueue, ^{
                [[RCIM sharedRCIM]
                        .groupInfoDataSource
                    getGroupInfoWithGroupId:groupId
                                 completion:^(RCGroup *groupInfo) {
                                     RCLogI(@"getUserInfo:;;;getGroupInfoDataSource:groupId=%@,groupName=%@,"
                                            @"groupPortraitUri=%@",
                                            groupInfo.groupId, groupInfo.groupName, groupInfo.portraitUri);
                                     [weakSelf updateGroupInfo:groupInfo forGroupId:groupId];
                                 }];
            });
        }
        RCGroup *groupInfo = [cacheConversationInfo translateToGroupInfo];
        RCLogI(@"getGroupInfo:;;;cacheGroupInfo:groupId=%@,groupName=%@,groupPortraitUri=%@", groupInfo.groupId,
               groupInfo.groupName, groupInfo.portraitUri);
        return groupInfo;
    } else {
        RCLogI(@"getGroupInfo:;;;groupId = nil");
        return nil;
    }
}

- (void)getGroupInfo:(NSString *)groupId complete:(void (^)(RCGroup *groupInfo))completeBlock {
    if (groupId) {
        RCConversationInfo *cacheConversationInfo =
            [[RCConversationInfoCache sharedCache] getConversationInfo:ConversationType_GROUP targetId:groupId];
        if (cacheConversationInfo) {
            if (completeBlock) {
                completeBlock([cacheConversationInfo translateToGroupInfo]);
            }
        } else if ([RCIM sharedRCIM].groupInfoDataSource &&
                   [[RCIM sharedRCIM]
                           .groupInfoDataSource respondsToSelector:@selector(getGroupInfoWithGroupId:completion:)]) {
            dispatch_async(self.requestQueue, ^{
                __weak typeof(self) weakSelf = self;
                [[RCIM sharedRCIM]
                        .groupInfoDataSource getGroupInfoWithGroupId:groupId
                                                          completion:^(RCGroup *groupInfo) {
                                                              [weakSelf updateGroupInfo:groupInfo forGroupId:groupId];
                                                                    if (completeBlock) {
                                                                        completeBlock(groupInfo);
                                                                    }
                                                              
                                                          }];
            });
        } else {
            if (completeBlock) {
                completeBlock(nil);
            }
        }
    } else {
        if (completeBlock) {
            completeBlock(nil);
        }
        
    }
}

- (RCGroup *)getGroupInfoFromCacheOnly:(NSString *)groupId {
    if (groupId) {
        RCConversationInfo *cacheConversationInfo =
            [[RCConversationInfoCache sharedCache] getConversationInfo:ConversationType_GROUP targetId:groupId];
        return [cacheConversationInfo translateToGroupInfo];
    } else {
        return nil;
    }
}

- (void)updateGroupInfo:(RCGroup *)groupInfo forGroupId:(NSString *)groupId {
    if (groupId.length > 0 && !groupInfo){
        [[RCConversationInfoCache sharedCache] clearConversationInfo:ConversationType_GROUP targetId:groupId];
        return;
    }
    if (groupId && groupInfo) {
        [[RCConversationInfoCache sharedCache]
            updateConversationInfo:[[RCConversationInfo alloc] initWithGroupInfo:groupInfo]
                  conversationType:ConversationType_GROUP
                          targetId:groupId];
    } else if (!groupId && groupInfo.groupId) {
        [[RCConversationInfoCache sharedCache]
            updateConversationInfo:[[RCConversationInfo alloc] initWithGroupInfo:groupInfo]
                  conversationType:ConversationType_GROUP
                          targetId:groupInfo.groupId];
    }
}

- (void)clearGroupInfoNetworkCacheOnly:(NSString *)groupId {
    if (groupId) {
        [[RCConversationInfoCache sharedCache] clearConversationInfoNetworkCacheOnly:ConversationType_GROUP
                                                                            targetId:groupId];
    }
}

- (void)clearGroupInfo:(NSString *)groupId {
    if (groupId) {
        [[RCConversationInfoCache sharedCache] clearConversationInfo:ConversationType_GROUP targetId:groupId];
    }
}

- (void)clearAllGroupInfo {
    [[RCConversationInfoCache sharedCache] clearAllConversationInfo];
}

#pragma mark - Post Notification
- (void)onUserInfoUpdate:(RCUserInfo *)userInfo {
    if (userInfo.userId) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchUserInfoUpdateNotification
                                                            object:@{
                                                                @"userId" : userInfo.userId,
                                                                @"userInfo" : userInfo
                                                            }];
    }
}

- (void)onConversationUserInfoUpdate:(RCUserInfo *)userInfo
                      inConversation:(RCConversationType)conversationType
                            targetId:(NSString *)targetId {
    if (conversationType == ConversationType_GROUP && userInfo.userId) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchGroupUserInfoUpdateNotification
                                                            object:@{
                                                                @"userId" : userInfo.userId,
                                                                @"userInfo" : userInfo,
                                                                @"inGroupId" : targetId
                                                            }];
    }
}

- (void)onConversationInfoUpdate:(RCConversationInfo *)conversationInfo {
    if (conversationInfo.conversationType == ConversationType_GROUP && conversationInfo.targetId) {
        RCGroup *cacheGroupInfo = [conversationInfo translateToGroupInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchGroupInfoUpdateNotification
                                                            object:@{
                                                                @"groupId" : cacheGroupInfo.groupId,
                                                                @"groupInfo" : cacheGroupInfo
                                                            }];
    }
}

- (RCPublicServiceProfile *)getPublicServiceProfile:(NSString *)serviceId {
    if (serviceId.length > 0) {
        RCPublicServiceProfile *cacheProfile = nil;
        if ([[RCIM sharedRCIM].publicServiceInfoDataSource respondsToSelector:@selector(publicServiceProfile:)]) {
            cacheProfile = [[RCIM sharedRCIM].publicServiceInfoDataSource publicServiceProfile:serviceId];
        }
        if (!cacheProfile &&
            [[RCIM sharedRCIM]
                    .publicServiceInfoDataSource respondsToSelector:@selector(getPublicServiceProfile:completion:)]) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(self.requestQueue, ^{
                [[RCIM sharedRCIM]
                        .publicServiceInfoDataSource
                    getPublicServiceProfile:serviceId
                                 completion:^(RCPublicServiceProfile *profile) {
                                     [weakSelf updatePublicServiceProfileInfo:profile forServiceId:serviceId];
                                 }];
            });
        } else {
            if (![RCIM sharedRCIM].publicServiceInfoDataSource) {
                NSLog(@"...................公众号信息提供者为空请检查是否设置 [RCIM "
                      @"sharedRCIM].publicServiceInfoDataSource "
                      @",并且保证设置的对象没有被释放 [RCIM sharedRCIM].publicServiceInfoDataSource 是 weak "
                      @"属性...................");
            }
        }
        return cacheProfile;
    } else {
        return nil;
    }
}

- (void)updatePublicServiceProfileInfo:(RCPublicServiceProfile *)profileInfo forServiceId:(NSString *)serviceId {
    if (profileInfo && serviceId) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchPublicServiceInfoNotification
        object:@{
            @"serviceId" : serviceId,
            @"serviceInfo" : profileInfo
        }];
    }
}

@end
