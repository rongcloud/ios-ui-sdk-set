//
//  RCEditInputBarConfig.m
//  RongIMKit
//
//  Created by Lang on 2025/7/23.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCEditInputBarConfig.h"
#import "NSMutableDictionary+RCOperation.h"
#import "NSMutableArray+RCOperation.h"
#import "NSDictionary+RCAccessor.h"

static NSString *const messageUIdKey = @"messageUId";
static NSString *const sentTimeKey = @"sentTime";
static NSString *const stateDataKey = @"stateData";
static NSString *const stateDataTextContentKey = @"textContent";
static NSString *const stateDataMentionedKey = @"mentionedRangeInfoList";
static NSString *const stateDataReferenceInfoKey = @"referenceInfo";
static NSString *const stateDataReferenceSenderNameKey = @"senderName";
static NSString *const stateDataReferenceContentKey = @"content";
static NSString *const stateDataReferenceStatusKey = @"referencedMsgStatus";

@implementation RCEditInputBarConfig

- (instancetype)initWithData:(NSString *)data {
    self = [super init];
    if (self) {
        [self setupData:data];
    }
    return self;
}

- (void)setupData:(NSString *)data {
    NSData *draftData = [data dataUsingEncoding:NSUTF8StringEncoding];
    if (draftData) {
        __autoreleasing NSError *error = nil;
        NSDictionary *draftDict =
        [NSJSONSerialization JSONObjectWithData:draftData options:kNilOptions error:&error];
        if (!error && draftDict.count > 0) {
            self.messageUId = [draftDict rclib_stringForKey:messageUIdKey];
            self.sentTime = [draftDict rclib_longLongIntForKey:sentTimeKey];
            
            NSDictionary *stateData = [draftDict rclib_dictionaryForKey:stateDataKey];
            if (stateData) {
                self.textContent = [stateData rclib_stringForKey:stateDataTextContentKey];
                // @ 信息列表
                NSArray *mentionedRangeInfoList = [stateData rclib_arrayForKey:stateDataMentionedKey];
                if (mentionedRangeInfoList) {
                    NSMutableArray *mentionedRangeInfoTemp = [NSMutableArray array];
                    for (NSString *encodedInfo in mentionedRangeInfoList) {
                        RCMentionedStringRangeInfo *info = [[RCMentionedStringRangeInfo alloc] initWithDecodeString:encodedInfo];
                        if (info) {
                            [mentionedRangeInfoTemp addObject:info];
                        }
                    }
                    self.mentionedRangeInfo = [mentionedRangeInfoTemp copy];
                }
                // 引用消息信息
                NSDictionary *referenceInfo = [stateData rclib_dictionaryForKey:stateDataReferenceInfoKey];
                if (referenceInfo) {
                    self.referencedSenderName = [referenceInfo rclib_stringForKey:stateDataReferenceSenderNameKey];
                    self.referencedContent = [referenceInfo rclib_stringForKey:stateDataTextContentKey];
                    self.referencedMsgStatus = [referenceInfo rclib_intForKey:stateDataReferenceStatusKey];
                }
            }
        }
    }
}

- (NSString *)encode {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict rclib_setObject:self.messageUId forKey:messageUIdKey];
    [dict rclib_setObject:@(self.sentTime) forKey:sentTimeKey];
    
    NSMutableDictionary *stateData = [NSMutableDictionary dictionary];
    [stateData rclib_setObject:self.textContent forKey:stateDataTextContentKey];
    
    // @ 信息列表
    NSMutableArray *mentionedRangeInfoList = [NSMutableArray array];
    for (RCMentionedStringRangeInfo *info in self.mentionedRangeInfo) {
        [mentionedRangeInfoList rclib_addObject:[info encodeToString]];
    }
    [stateData rclib_setObject:mentionedRangeInfoList forKey:stateDataMentionedKey];
    
    // 引用消息信息
    if (_referencedSenderName || _referencedContent) {  
        NSMutableDictionary *referenceInfo = [NSMutableDictionary dictionary];
        [referenceInfo rclib_setObject:self.referencedSenderName forKey:stateDataReferenceSenderNameKey];
        [referenceInfo rclib_setObject:self.referencedContent forKey:stateDataTextContentKey];
        [referenceInfo rclib_setObject:@(self.referencedMsgStatus) forKey:stateDataReferenceStatusKey];
        
        [stateData rclib_setObject:referenceInfo forKey:stateDataReferenceInfoKey];
    }
    [dict rclib_setObject:stateData forKey:stateDataKey];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}



@end
