//
//  RCUserInfoUpdateMessage.m
//  RongIMKit
//
//  Created by 岑裕 on 16/1/28.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCUserInfoUpdateMessage.h"

@implementation RCUserInfoUpdateMessage

- (instancetype)initWithUserInfoList:(NSArray *)userInfoList {
    self = [super init];
    if (self) {
        _userInfoList = userInfoList;
    }
    return self;
}

+ (RCMessagePersistent)persistentFlag {
    return MessagePersistent_NONE;
}

- (void)decodeWithData:(NSData *)data {
    __autoreleasing NSError *__error = nil;
    if (!data) {
        return;
    }
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&__error];
    if (!__error && dict && [dict isKindOfClass:[NSDictionary class]]) {
        NSMutableArray *updatedUserInfoList = [dict objectForKey:@"updatedUserInfoList"];
        if ([updatedUserInfoList isKindOfClass:[NSArray class]] && [updatedUserInfoList count] > 0) {
            NSMutableArray *userInfoList = [[NSMutableArray alloc] init];

            for (NSDictionary *userInfoDic in updatedUserInfoList) {
                if ([userInfoDic isKindOfClass:[NSDictionary class]]) {
                    RCUserInfo *userInfo = [[RCUserInfo alloc] init];
                    userInfo.userId = userInfoDic[@"userId"];
                    userInfo.name = userInfoDic[@"name"];
                    userInfo.portraitUri = userInfoDic[@"portraitUri"];
                    [userInfoList addObject:userInfo];
                }
            }

            self.userInfoList = [userInfoList copy];
        }
        self.extra = [dict objectForKey:@"extra"];
        NSDictionary *userinfoDic = [dict objectForKey:@"user"];
        [self decodeUserInfo:userinfoDic];
    } else {
        self.rawJSONData = data;
    }
}

- (NSData *)encode {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    if ([self.userInfoList count] > 0) {
        NSMutableArray *updatedUserInfoList = [[NSMutableArray alloc] init];

        for (RCUserInfo *userInfo in self.userInfoList) {
            NSMutableDictionary *userInfoDic = [[NSMutableDictionary alloc] init];
            if ([userInfo.userId length] > 0) {
                [userInfoDic setObject:userInfo.userId forKey:@"userId"];
            } else {
                continue;
            }
            if ([userInfo.name length] > 0) {
                [userInfoDic setObject:userInfo.name forKey:@"name"];
            }
            if ([userInfo.portraitUri length] > 0) {
                [userInfoDic setObject:userInfo.portraitUri forKey:@"portraitUri"];
            }
            [updatedUserInfoList addObject:userInfoDic];
        }

        [dict setObject:updatedUserInfoList forKey:@"updatedUserInfoList"];
    }

    if (self.senderUserInfo) {
        [dict setObject:[self encodeUserInfo:self.senderUserInfo] forKey:@"user"];
    }
    if (self.extra) {
        [dict setObject:self.extra forKey:@"extra"];
    }

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil];
    return jsonData;
}

+ (NSString *)getObjectName {
    return RCUserInfoUpdateMessageIdentifier;
}

@end
