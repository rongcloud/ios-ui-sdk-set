//
//  RCContactCardMessage.m
//  RongContactCard
//
//  Created by Sin on 16/8/19.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCContactCardMessage.h"
#import "RongContactCardAdaptiveHeader.h"
#import "NSMutableDictionary+RCOperation.h"
#import "NSDictionary+RCAccessor.h"

@implementation RCContactCardMessage
+ (instancetype)messageWithUserInfo:(RCUserInfo *)userInfo {
    RCContactCardMessage *cardMessage = [[RCContactCardMessage alloc] init];
    if (cardMessage) {
        cardMessage.userId = userInfo.userId;
        cardMessage.name = userInfo.name;
        cardMessage.portraitUri = userInfo.portraitUri;
    }
    return cardMessage;
}

#pragma mark - NSCoding protocol methods
#define KEY_CARDMSG_USERID @"userId"
#define KEY_CARDMSG_NAME @"name"
#define KEY_CARDMSG_PORTRAITURI @"portraitUri"
#define KEY_CARDMSG_DESTRUCTDURATION @"burnDuration"
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.userId = [aDecoder decodeObjectForKey:KEY_CARDMSG_USERID];
        self.name = [aDecoder decodeObjectForKey:KEY_CARDMSG_NAME];
        self.portraitUri = [aDecoder decodeObjectForKey:KEY_CARDMSG_PORTRAITURI];
        self.destructDuration = [aDecoder decodeIntegerForKey:KEY_CARDMSG_DESTRUCTDURATION];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.userId forKey:KEY_CARDMSG_USERID];
    [aCoder encodeObject:self.name forKey:KEY_CARDMSG_NAME];
    if (![RCUtilities isLocalPath:self.portraitUri]) {
        [aCoder encodeObject:self.portraitUri forKey:KEY_CARDMSG_PORTRAITURI];
    }
    [aCoder encodeInteger:self.destructDuration forKey:KEY_CARDMSG_DESTRUCTDURATION];
}

#pragma mark RCMessageCoding

- (NSData *)encode {
    NSMutableDictionary *dataDict = [self encodeBaseData];
    [dataDict rclib_setObject:self.userId forKey:KEY_CARDMSG_USERID];
    [dataDict rclib_setObject:self.name forKey:KEY_CARDMSG_NAME];
    if (![RCUtilities isLocalPath:self.portraitUri]) {
        [dataDict rclib_setObject:self.portraitUri forKey:KEY_CARDMSG_PORTRAITURI];
    }

    [dataDict rclib_setObject:self.sendUserId forKey:@"sendUserId"];
    [dataDict rclib_setObject:self.sendUserName forKey:@"sendUserName"];

    NSData *data = [NSJSONSerialization dataWithJSONObject:dataDict options:kNilOptions error:nil];
    return data;
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
    self.userId = [jsonDic rclib_stringForKey:KEY_CARDMSG_USERID];
    self.name = [jsonDic rclib_stringForKey:KEY_CARDMSG_NAME];
    self.portraitUri = [jsonDic rclib_stringForKey:KEY_CARDMSG_PORTRAITURI];
    self.sendUserId = [jsonDic rclib_stringForKey:@"sendUserId"];
    self.sendUserName = [jsonDic rclib_stringForKey:@"sendUserName"];
}

+ (NSString *)getObjectName {
    return RCContactCardMessageTypeIdentifier;
}

#pragma mark RCMessagePersistentCompatible
+ (RCMessagePersistent)persistentFlag {
    return (MessagePersistent_ISPERSISTED | MessagePersistent_ISCOUNTED);
}

#pragma mark RCMessageContentView
- (NSString *)conversationDigest {

    NSString *displayContent;
    if ([[RCCoreClient sharedCoreClient].currentUserInfo.userId isEqualToString:self.sendUserId]) {
        displayContent = [NSString
            stringWithFormat:RCLocalizedString(@"SharedContactCard"), self.name];
    } else {
        displayContent = [NSString
            stringWithFormat:RCLocalizedString(@"RecommendedToYou"), self.name];
    }
    return displayContent;
}

#if !__has_feature(objc_arc)
- (void)dealloc {
    [super dealloc];
}
#endif //__has_feature(objc_arc)
@end
