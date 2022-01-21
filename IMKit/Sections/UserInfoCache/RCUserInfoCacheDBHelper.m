//
//  RCUserInfoCacheDBHelper.m
//  RongIMKit
//
//  Created by 岑裕 on 16/5/11.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCUserInfoCacheDBHelper.h"

int const RCKitStorageVersion = 4;

@interface RCUserInfoCacheDBHelper ()

@property (nonatomic, strong) RCloudFMDatabase *workingDB;

@end

@implementation RCUserInfoCacheDBHelper

- (instancetype)initWithPath:(NSString *)storagePath {
    self = [super init];
    if (self) {
        self.workingDB = [[RCloudFMDatabase alloc] initWithPath:storagePath];
        [self createDBTableIfNeed];
    }
    return self;
}

- (void)createDBTableIfNeed {
    if ([self.workingDB open]) {
        [self updateDBVersionIfNeed:RCKitStorageVersion];
        [self.workingDB executeUpdate:@"CREATE TABLE IF NOT EXISTS USER_INFO(user_id TEXT PRIMARY KEY, name TEXT, alias TEXT, "
                                      @"portrait_uri TEXT, extra TEXT)"];
        [self.workingDB executeUpdate:@"CREATE TABLE IF NOT EXISTS CONVERSATION_USER_INFO(conversation_type INTEGER, "
                                      @"target_id TEXT, user_id TEXT, name TEXT, alias TEXT, portrait_uri TEXT, extra TEXT,  PRIMARY "
                                      @"KEY(conversation_type, target_id, user_id))"];
        [self.workingDB
            executeUpdate:@"CREATE TABLE IF NOT EXISTS CONVERSATION_INFO(conversation_type INTEGER, target_id TEXT, "
                          @"name TEXT, portrait_uri TEXT, PRIMARY KEY(conversation_type, target_id))"];
    } else {
        self.workingDB = nil;
    }
}

- (void)updateDBVersionIfNeed:(int)version {
    if ([self.workingDB open]) {
        [self.workingDB executeUpdate:@"CREATE TABLE IF NOT EXISTS VERSION(version INTEGER PRIMARY KEY)"];
        int oldVersion = 0;
        RCloudFMResultSet *resultSet = [self.workingDB executeQuery:@"SELECT * FROM VERSION"];
        if ([resultSet next]) {
            oldVersion = [resultSet intForColumn:@"version"];
        }
        [resultSet close];
        if (oldVersion < version) {
            [self.workingDB executeUpdate:@"DELETE FROM VERSION"];
            [self.workingDB executeUpdate:@"INSERT OR REPLACE INTO VERSION (version) VALUES(?)", @(version)];
            if (oldVersion == 1) {
                [self.workingDB executeUpdate:@"ALTER TABLE USER_INFO ADD COLUMN extra TEXT"];
                [self.workingDB executeUpdate:@"ALTER TABLE USER_INFO ADD COLUMN alias TEXT"];
                [self.workingDB executeUpdate:@"ALTER TABLE CONVERSATION_USER_INFO ADD COLUMN extra TEXT"];
                [self.workingDB executeUpdate:@"ALTER TABLE CONVERSATION_USER_INFO ADD COLUMN alias TEXT"];
            } else if (oldVersion == 2) {
                [self.workingDB executeUpdate:@"ALTER TABLE USER_INFO ADD COLUMN alias TEXT"];
                [self.workingDB executeUpdate:@"ALTER TABLE CONVERSATION_USER_INFO ADD COLUMN extra TEXT"];
                [self.workingDB executeUpdate:@"ALTER TABLE CONVERSATION_USER_INFO ADD COLUMN alias TEXT"];
            } else if (oldVersion == 3){
                [self.workingDB executeUpdate:@"ALTER TABLE CONVERSATION_USER_INFO ADD COLUMN extra TEXT"];
                [self.workingDB executeUpdate:@"ALTER TABLE CONVERSATION_USER_INFO ADD COLUMN alias TEXT"];
            }
        }
    }
}

- (void)closeDBIfNeed {
    if (self.workingDB) {
        [self.workingDB close];
        self.workingDB = nil;
    }
}

- (void)dealloc {
    [self closeDBIfNeed];
}

#pragma mark - ConversationInfo DB

- (RCConversationInfo *)selectConversationInfoFromDB:(RCConversationType)conversationType
                                            targetId:(NSString *)targetId {
    if ([self.workingDB open]) {
        RCloudFMResultSet *resultSet = [self.workingDB
            executeQuery:@"SELECT * FROM CONVERSATION_INFO WHERE conversation_type = ? AND target_id = ?",
                         @(conversationType), targetId];
        if ([resultSet next]) {
            RCConversationInfo *dbConversationInfo = [[RCConversationInfo alloc] init];
            dbConversationInfo.conversationType = [resultSet intForColumn:@"conversation_type"];
            dbConversationInfo.targetId = [resultSet stringForColumn:@"target_id"];
            dbConversationInfo.name = [resultSet stringForColumn:@"name"];
            dbConversationInfo.portraitUri = [resultSet stringForColumn:@"portrait_uri"];
            [resultSet close];
            return dbConversationInfo;
        } else {
            [resultSet close];
            return nil;
        }
    } else {
        return nil;
    }
}

- (NSArray *)selectAllConversationInfoFromDB {
    if ([self.workingDB open]) {
        NSMutableArray *dbConversationInfoList = [[NSMutableArray alloc] init];
        RCloudFMResultSet *resultSet = [self.workingDB executeQuery:@"SELECT * FROM CONVERSATION_INFO"];
        while ([resultSet next]) {
            RCConversationInfo *dbConversationInfo = [[RCConversationInfo alloc] init];
            dbConversationInfo.conversationType = [resultSet intForColumn:@"conversation_type"];
            dbConversationInfo.targetId = [resultSet stringForColumn:@"target_id"];
            dbConversationInfo.name = [resultSet stringForColumn:@"name"];
            dbConversationInfo.portraitUri = [resultSet stringForColumn:@"portrait_uri"];
            [dbConversationInfoList addObject:dbConversationInfo];
        }
        [resultSet close];
        return [dbConversationInfoList copy];
    } else {
        return nil;
    }
}

- (void)replaceConversationInfoFromDB:(RCConversationInfo *)conversationInfo
                     conversationType:(RCConversationType)conversationType
                             targetId:(NSString *)targetId {
    if ([self.workingDB open]) {
        [self.workingDB executeUpdate:@"INSERT OR REPLACE INTO CONVERSATION_INFO (conversation_type, target_id, name, "
                                      @"portrait_uri) VALUES(?, ?, ?, ?)",
                                      @(conversationType), targetId, conversationInfo.name,
                                      conversationInfo.portraitUri];
    }
}

- (void)deleteConversationInfoFromDB:(RCConversationType)conversationType targetId:(NSString *)targetId {
    if ([self.workingDB open]) {
        [self.workingDB executeUpdate:@"DELETE FROM CONVERSATION_INFO WHERE conversation_type = ? AND target_id = ?",
                                      @(conversationType), targetId];
    }
}

- (void)deleteAllConversationInfoFromDB {
    if ([self.workingDB open]) {
        [self.workingDB executeUpdate:@"DELETE FROM CONVERSATION_INFO"];
    }
}

#pragma mark - ConversationUserInfo DB

- (RCUserInfo *)selectUserInfoFromDB:(NSString *)userId
                    conversationType:(RCConversationType)conversationType
                            targetId:(NSString *)targetId {
    if ([self.workingDB open]) {
        RCloudFMResultSet *resultSet = [self.workingDB
            executeQuery:
                @"SELECT * FROM CONVERSATION_USER_INFO WHERE conversation_type = ? AND target_id = ? AND user_id = ?",
                @(conversationType), targetId, userId];
        if ([resultSet next]) {
            RCUserInfo *dbUserInfo = [[RCUserInfo alloc] init];
            dbUserInfo.userId = [resultSet stringForColumn:@"user_id"];
            dbUserInfo.name = [resultSet stringForColumn:@"name"];
            dbUserInfo.alias = [resultSet stringForColumn:@"alias"];
            dbUserInfo.portraitUri = [resultSet stringForColumn:@"portrait_uri"];
            dbUserInfo.extra = [resultSet stringForColumn:@"extra"];
            [resultSet close];
            return dbUserInfo;
        } else {
            [resultSet close];
            return nil;
        }
    } else {
        return nil;
    }
}

- (NSArray *)selectAllConversationUserInfoFromDB {
    if ([self.workingDB open]) {
        NSMutableArray *dbConversationUserInfoList = [[NSMutableArray alloc] init];
        RCloudFMResultSet *resultSet = [self.workingDB executeQuery:@"SELECT * FROM CONVERSATION_USER_INFO"];
        while ([resultSet next]) {
            RCUserInfo *dbUserInfo = [[RCUserInfo alloc] init];
            dbUserInfo.userId = [resultSet stringForColumn:@"user_id"];
            dbUserInfo.name = [resultSet stringForColumn:@"name"];
            dbUserInfo.alias = [resultSet stringForColumn:@"alias"];
            dbUserInfo.portraitUri = [resultSet stringForColumn:@"portrait_uri"];
            dbUserInfo.extra = [resultSet stringForColumn:@"extra"];
            [dbConversationUserInfoList addObject:dbUserInfo];
        }
        [resultSet close];
        return [dbConversationUserInfoList copy];
    } else {
        return nil;
    }
}

- (void)replaceUserInfoFromDB:(RCUserInfo *)userInfo
                    forUserId:(NSString *)userId
             conversationType:(RCConversationType)conversationType
                     targetId:(NSString *)targetId {
    if ([self.workingDB open]) {
        [self.workingDB executeUpdate:@"INSERT OR REPLACE INTO CONVERSATION_USER_INFO (conversation_type, target_id, "
                                      @"user_id, name, alias, portrait_uri, extra) VALUES(?, ?, ?, ?, ?, ?, ?)",
                                      @(conversationType), targetId, userId, userInfo.name, userInfo.alias, userInfo.portraitUri, userInfo.extra];
    }
}

- (void)deleteConversationUserInfoFromDB:(NSString *)userId
                        conversationType:(RCConversationType)conversationType
                                targetId:(NSString *)targetId {
    if ([self.workingDB open]) {
        [self.workingDB
            executeUpdate:
                @"DELETE FROM CONVERSATION_USER_INFO WHERE conversation_type = ? AND target_id = ? AND user_id = ?",
                @(conversationType), targetId, userId];
    }
}

- (void)deleteAllConversationUserInfoFromDB {
    if ([self.workingDB open]) {
        [self.workingDB executeUpdate:@"DELETE FROM CONVERSATION_USER_INFO"];
    }
}

#pragma mark - UserInfo DB

- (RCUserInfo *)selectUserInfoFromDB:(NSString *)userId {
    if ([self.workingDB open]) {
        RCloudFMResultSet *resultSet =
            [self.workingDB executeQuery:@"SELECT * FROM USER_INFO WHERE user_id = ?", userId];
        if ([resultSet next]) {
            RCUserInfo *dbUserInfo = [[RCUserInfo alloc] init];
            dbUserInfo.userId = [resultSet stringForColumn:@"user_id"];
            dbUserInfo.name = [resultSet stringForColumn:@"name"];
            dbUserInfo.alias = [resultSet stringForColumn:@"alias"];
            dbUserInfo.portraitUri = [resultSet stringForColumn:@"portrait_uri"];
            dbUserInfo.extra = [resultSet stringForColumn:@"extra"];
            [resultSet close];
            return dbUserInfo;
        } else {
            [resultSet close];
            return nil;
        }
    } else {
        return nil;
    }
}

- (NSArray *)selectAllUserInfoFromDB {
    if ([self.workingDB open]) {
        NSMutableArray *dbUserInfoList = [[NSMutableArray alloc] init];
        RCloudFMResultSet *resultSet = [self.workingDB executeQuery:@"SELECT * FROM USER_INFO"];
        while ([resultSet next]) {
            RCUserInfo *dbUserInfo = [[RCUserInfo alloc] init];
            dbUserInfo.userId = [resultSet stringForColumn:@"user_id"];
            dbUserInfo.name = [resultSet stringForColumn:@"name"];
            dbUserInfo.alias = [resultSet stringForColumn:@"alias"];
            dbUserInfo.portraitUri = [resultSet stringForColumn:@"portrait_uri"];
            dbUserInfo.extra = [resultSet stringForColumn:@"extra"];
            [dbUserInfoList addObject:dbUserInfo];
        }
        [resultSet close];
        return [dbUserInfoList copy];
    } else {
        return nil;
    }
}

- (void)replaceUserInfoFromDB:(RCUserInfo *)userInfo forUserId:(NSString *)userId {
    if ([self.workingDB open]) {
        [self.workingDB
            executeUpdate:@"INSERT OR REPLACE INTO USER_INFO (user_id, name, alias, portrait_uri, extra) VALUES(?, ?, ?, ?, ?)",
                          userId, userInfo.name, userInfo.alias, userInfo.portraitUri, userInfo.extra ?: @""];
    }
}

- (void)deleteUserInfoFromDB:(NSString *)userId {
    if ([self.workingDB open]) {
        [self.workingDB executeUpdate:@"DELETE FROM USER_INFO WHERE user_id = ?", userId];
    }
}

- (void)deleteAllUserInfoFromDB {
    if ([self.workingDB open]) {
        [self.workingDB executeUpdate:@"DELETE FROM USER_INFO"];
    }
}

@end
