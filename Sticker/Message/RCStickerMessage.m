//
//  RCStickerMessage.m
//  RongSticker
//
//  Created by liyan on 2018/8/7.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerMessage.h"

@implementation RCStickerMessage

+ (instancetype)messageWithPackageId:(NSString *)packageId
                           stickerId:(NSString *)stickerId
                              digest:(NSString *)digest
                               width:(long)width
                              height:(long)height {
    RCStickerMessage *sticker = [[RCStickerMessage alloc] init];
    if (sticker) {
        sticker.packageId = packageId;
        sticker.stickerId = stickerId;
        sticker.digest = digest;
        sticker.width = width;
        sticker.height = height;
    }
    return sticker;
}

+ (RCMessagePersistent)persistentFlag {
    return MessagePersistent_ISPERSISTED | MessagePersistent_ISCOUNTED;
}

+ (NSString *)getObjectName {
    return RCStickerMessageTypeIdentifier;
}

#pragma mark -NSCoding protocol methods
#define KEY_STICKERMSG_PACKAGEID @"packageId"
#define KEY_STICKERMSG_STICKERID @"stickerId"
#define KEY_STICKERMSG_DIGEST @"digest"
#define KEY_STICKERMSG_WIDTH @"width"
#define KEY_STICKERMSG_HEIGHT @"height"
#define KEY_STICKERMSG_DESTRUCTDURATION @"burnDuration"
#define KEY_STICKERMSG_EXTRA @"extra"

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.packageId = [aDecoder decodeObjectForKey:KEY_STICKERMSG_PACKAGEID];
        self.stickerId = [aDecoder decodeObjectForKey:KEY_STICKERMSG_STICKERID];
        self.digest = [aDecoder decodeObjectForKey:KEY_STICKERMSG_DIGEST];
        self.width = [[aDecoder decodeObjectForKey:KEY_STICKERMSG_WIDTH] longValue];
        self.height = [[aDecoder decodeObjectForKey:KEY_STICKERMSG_HEIGHT] longValue];
        self.destructDuration = [[aDecoder decodeObjectForKey:KEY_STICKERMSG_DESTRUCTDURATION] unsignedIntegerValue];
        self.extra = [aDecoder decodeObjectForKey:KEY_STICKERMSG_EXTRA];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.packageId forKey:KEY_STICKERMSG_PACKAGEID];
    [aCoder encodeObject:self.stickerId forKey:KEY_STICKERMSG_STICKERID];
    [aCoder encodeObject:self.digest forKey:KEY_STICKERMSG_DIGEST];
    [aCoder encodeObject:@(self.width) forKey:KEY_STICKERMSG_WIDTH];
    [aCoder encodeObject:@(self.height) forKey:KEY_STICKERMSG_HEIGHT];
    [aCoder encodeObject:@(self.destructDuration) forKey:KEY_STICKERMSG_DESTRUCTDURATION];
    [aCoder encodeObject:self.extra forKey:KEY_STICKERMSG_EXTRA];
}

#pragma mark - RCMessageCoding delegate methods

- (NSData *)encode {

    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.packageId) {
        [dataDict setObject:self.packageId forKey:KEY_STICKERMSG_PACKAGEID];
    }
    if (self.stickerId) {
        [dataDict setObject:self.stickerId forKey:KEY_STICKERMSG_STICKERID];
    }
    if (self.digest) {
        [dataDict setObject:self.digest forKey:KEY_STICKERMSG_DIGEST];
    }
    if (self.width) {
        [dataDict setObject:@(self.width) forKey:KEY_STICKERMSG_WIDTH];
    }
    if (self.height) {
        [dataDict setObject:@(self.height) forKey:KEY_STICKERMSG_HEIGHT];
    }
    if (self.destructDuration > 0) {
        [dataDict setObject:@(self.destructDuration) forKey:KEY_STICKERMSG_DESTRUCTDURATION];
    }
    if (self.extra) {
        [dataDict setObject:self.extra forKey:KEY_STICKERMSG_EXTRA];
    }
    if (self.senderUserInfo) {
        [dataDict setObject:[self encodeUserInfo:self.senderUserInfo] forKey:@"user"];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:dataDict options:kNilOptions error:nil];
    return data;
}

- (void)decodeWithData:(NSData *)data {
    __autoreleasing NSError *__error = nil;
    if (!data) {
        return;
    }
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&__error];
    NSDictionary *json = [[NSDictionary alloc] initWithDictionary:dictionary];
    if (json) {
        self.packageId = [json objectForKey:KEY_STICKERMSG_PACKAGEID];
        self.stickerId = [json objectForKey:KEY_STICKERMSG_STICKERID];
        self.digest = [json objectForKey:KEY_STICKERMSG_DIGEST];
        self.width = [[json objectForKey:KEY_STICKERMSG_WIDTH] floatValue];
        self.height = [[json objectForKey:KEY_STICKERMSG_HEIGHT] floatValue];
        self.destructDuration = [[json objectForKey:KEY_STICKERMSG_DESTRUCTDURATION] integerValue];
        self.extra = [json objectForKey:KEY_STICKERMSG_EXTRA];
        NSDictionary *userinfoDic = [json objectForKey:@"user"];
        [self decodeUserInfo:userinfoDic];
    }
}

- (NSString *)conversationDigest {
    NSString *conversationDigest = [NSString stringWithFormat:@"[%@]", self.digest];
    return conversationDigest;
}

@end
