//
//  RCUserInfoCacheDBHelper.h
//  RongIMKit
//
//  Created by 岑裕 on 16/5/11.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCConversationInfo.h"
#import "RCloudFMDatabase.h"
#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

@interface RCUserInfoCacheDBHelper : NSObject

- (instancetype)initWithPath:(NSString *)storagePath;

- (void)createDBTableIfNeed;

- (void)closeDBIfNeed;

#pragma mark - ConversationInfo DB

- (RCConversationInfo *)selectConversationInfoFromDB:(RCConversationType)conversationType targetId:(NSString *)targetId;

- (NSArray *)selectAllConversationInfoFromDB;

- (void)replaceConversationInfoFromDB:(RCConversationInfo *)conversationInfo
                     conversationType:(RCConversationType)conversationType
                             targetId:(NSString *)targetId;

- (void)deleteConversationInfoFromDB:(RCConversationType)conversationType targetId:(NSString *)targetId;

- (void)deleteAllConversationInfoFromDB;

#pragma mark - ConversationUserInfo DB

- (RCUserInfo *)selectUserInfoFromDB:(NSString *)userId
                    conversationType:(RCConversationType)conversationType
                            targetId:(NSString *)targetId;

- (NSArray *)selectAllConversationUserInfoFromDB;

- (void)replaceUserInfoFromDB:(RCUserInfo *)userInfo
                    forUserId:(NSString *)userId
             conversationType:(RCConversationType)conversationType
                     targetId:(NSString *)targetId;

- (void)deleteConversationUserInfoFromDB:(NSString *)userId
                        conversationType:(RCConversationType)conversationType
                                targetId:(NSString *)targetId;

- (void)deleteAllConversationUserInfoFromDB;

#pragma mark - UserInfo DB

- (RCUserInfo *)selectUserInfoFromDB:(NSString *)userId;

- (NSArray *)selectAllUserInfoFromDB;

- (void)replaceUserInfoFromDB:(RCUserInfo *)userInfo forUserId:(NSString *)userId;

- (void)deleteUserInfoFromDB:(NSString *)userId;

- (void)deleteAllUserInfoFromDB;

@end
