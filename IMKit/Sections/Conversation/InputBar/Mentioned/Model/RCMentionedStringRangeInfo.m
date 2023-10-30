//
//  RCMentionedStringRangeInfo.m
//  RongExtensionKit
//
//  Created by 杜立召 on 16/7/13.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCMentionedStringRangeInfo.h"

@implementation RCMentionedStringRangeInfo

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.userId = [aDecoder decodeObjectForKey:@"userId"];
        self.content = [aDecoder decodeObjectForKey:@"content"];
        self.range = NSRangeFromString([aDecoder decodeObjectForKey:@"range"]);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.userId forKey:@"userId"];
    [aCoder encodeObject:self.content forKey:@"content"];
    [aCoder encodeObject:NSStringFromRange(self.range) forKey:@"range"];
}

- (NSString *)encodeToString {
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setObject:self.content forKey:@"content"];
    [dataDict setObject:self.userId forKey:@"userId"];
    [dataDict setObject:NSStringFromRange(self.range) forKey:@"range"];

    NSData *data = [NSJSONSerialization dataWithJSONObject:dataDict options:kNilOptions error:nil];

    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (instancetype)initWithDecodeString:(NSString *)mentionedInfoString {
    self = [super init];
    if (self) {
        __autoreleasing NSError *error = nil;
        if (mentionedInfoString) {
            NSData *mentionedInfoData = [mentionedInfoString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *mentionedInfoDict =
                [NSJSONSerialization JSONObjectWithData:mentionedInfoData options:kNilOptions error:&error];
            if (!error && [mentionedInfoDict count] > 0) {
                self.content = [mentionedInfoDict objectForKey:@"content"];
                self.userId = [mentionedInfoDict objectForKey:@"userId"];
                self.range = NSRangeFromString([mentionedInfoDict objectForKey:@"range"]);
            }
        }
    }
    return self;
}

@end
