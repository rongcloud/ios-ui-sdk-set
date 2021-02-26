//
//  RCContactCardMessage.m
//  RongContactCard
//
//  Created by Sin on 16/8/19.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCContactCardMessage.h"
#import "RongIMKitHeader.h"
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
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setValue:self.userId forKey:KEY_CARDMSG_USERID];
    [dataDict setValue:self.name forKey:KEY_CARDMSG_NAME];
    if (![RCUtilities isLocalPath:self.portraitUri]) {
        [dataDict setValue:self.portraitUri forKey:KEY_CARDMSG_PORTRAITURI];
    }

    if (self.destructDuration > 0) {
        [dataDict setObject:@(self.destructDuration) forKey:KEY_CARDMSG_DESTRUCTDURATION];
    }

    if (self.senderUserInfo) {
        [dataDict setObject:[self encodeUserInfo:self.senderUserInfo] forKey:@"user"];
    }

    if (self.extra) {
        [dataDict setObject:self.extra forKey:@"extra"];
    }
    [dataDict setObject:self.sendUserId forKey:@"sendUserId"];
    [dataDict setObject:self.sendUserName forKey:@"sendUserName"];

    NSData *data = [NSJSONSerialization dataWithJSONObject:dataDict options:kNilOptions error:nil];
    return data;
}

- (void)decodeWithData:(NSData *)data {
    __autoreleasing NSError *__error = nil;
    if (!data) {
        return;
    }
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&__error];
    if (dictionary) {
        self.userId = dictionary[KEY_CARDMSG_USERID];
        self.name = dictionary[KEY_CARDMSG_NAME];
        self.portraitUri = dictionary[KEY_CARDMSG_PORTRAITURI];
        self.destructDuration = [dictionary[KEY_CARDMSG_DESTRUCTDURATION] integerValue];
        self.extra = dictionary[@"extra"];
        self.sendUserId = dictionary[@"sendUserId"];
        self.sendUserName = dictionary[@"sendUserName"];
        NSDictionary *userinfoDic = dictionary[@"user"];
        [self decodeUserInfo:userinfoDic];
    }
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
    if ([[RCIMClient sharedRCIMClient].currentUserInfo.userId isEqualToString:self.sendUserId]) {
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
