//
//  RCUserInfoUpdateMessage.m
//  RongIMKit
//
//  Created by 岑裕 on 16/1/28.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCUserInfoUpdateMessage.h"
#import "NSMutableDictionary+RCOperation.h"
#import "NSDictionary+RCAccessor.h"

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
    NSDictionary *jsonDic = [[self class] dictionaryFromJsonData:data];
    if (!jsonDic) {
        // 解析失败保存原数据
        self.rawJSONData = data;
        return;
    }
    // 基类负责解析基类属性
    [self decodeBaseData:jsonDic];
    
    //子类只解析子类属性
    NSArray *updatedUserInfoList = [jsonDic rclib_arrayForKey:@"updatedUserInfoList"];
    if ([updatedUserInfoList count] == 0) {
        return;
    }
    
    NSMutableArray<RCUserInfo *> *userInfoList = [[NSMutableArray alloc] init];
    
    for (NSDictionary *userInfoDic in updatedUserInfoList) {
        if ([userInfoDic isKindOfClass:[NSDictionary class]]) {
            RCUserInfo *userInfo = [[RCUserInfo alloc] init];
            userInfo.userId = [userInfoDic rclib_stringForKey:@"userId"];
            userInfo.name = [userInfoDic rclib_stringForKey:@"name"];
            userInfo.portraitUri = [userInfoDic rclib_stringForKey:@"portraitUri"];
            [userInfoList addObject:userInfo];
        }
    }
    
    self.userInfoList = [userInfoList copy];
}

- (NSData *)encode {
    NSMutableDictionary *dict = [self encodeBaseData];

    if ([self.userInfoList count] > 0) {
        NSMutableArray *updatedUserInfoList = [[NSMutableArray alloc] init];

        for (RCUserInfo *userInfo in self.userInfoList) {
            NSMutableDictionary *userInfoDic = [[NSMutableDictionary alloc] init];
            if ([userInfo.userId length] > 0) {
                [userInfoDic rclib_setObject:userInfo.userId forKey:@"userId"];
            } else {
                continue;
            }
            if ([userInfo.name length] > 0) {
                [userInfoDic rclib_setObject:userInfo.name forKey:@"name"];
            }
            if ([userInfo.portraitUri length] > 0) {
                [userInfoDic rclib_setObject:userInfo.portraitUri forKey:@"portraitUri"];
            }
            [updatedUserInfoList addObject:userInfoDic];
        }

        [dict rclib_setObject:updatedUserInfoList forKey:@"updatedUserInfoList"];
    }

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil];
    return jsonData;
}

+ (NSString *)getObjectName {
    return RCUserInfoUpdateMessageIdentifier;
}

@end
