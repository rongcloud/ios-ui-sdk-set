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
    NSMutableDictionary *dataDict = [self encodeBaseData];
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
    self.packageId = [jsonDic objectForKey:KEY_STICKERMSG_PACKAGEID];
    self.stickerId = [jsonDic objectForKey:KEY_STICKERMSG_STICKERID];
    self.digest = [jsonDic objectForKey:KEY_STICKERMSG_DIGEST];
    self.width = [[jsonDic objectForKey:KEY_STICKERMSG_WIDTH] longValue];
    self.height = [[jsonDic objectForKey:KEY_STICKERMSG_HEIGHT] longValue];
}

- (NSString *)conversationDigest {
    NSString *conversationDigest = [NSString stringWithFormat:@"[%@]", self.digest];
    return conversationDigest;
}

@end
