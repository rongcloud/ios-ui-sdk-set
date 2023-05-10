//
//  RCConversationInfo.m
//  RongIMKit
//
//  Created by 岑裕 on 16/1/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCConversationInfo.h"

@implementation RCConversationInfo

- (instancetype)initWithConversationId:(NSString *)targetId
                      conversationType:(RCConversationType)conversationType
                                  name:(NSString *)name
                           portraitUri:(NSString *)portraitUri {
    self = [super init];

    if (self) {
        _targetId = targetId;
        _conversationType = conversationType;
        _name = name;
        _portraitUri = portraitUri;
    }

    return self;
}

- (instancetype)initWithGroupInfo:(RCGroup *)groupInfo {
    return [self initWithConversationId:groupInfo.groupId
                       conversationType:ConversationType_GROUP
                                   name:groupInfo.groupName
                            portraitUri:groupInfo.portraitUri];
}

- (RCGroup *)translateToGroupInfo {
    if (self.conversationType == ConversationType_GROUP) {
        return [[RCGroup alloc] initWithGroupId:self.targetId groupName:self.name portraitUri:self.portraitUri];
    } else {
        return nil;
    }
}

+ (NSString *)getConversationGUID:(RCConversationType)conversationType targetId:(NSString *)targetId {
    if (targetId) {
        return [NSString stringWithFormat:@"%lu;;;%@", (unsigned long)conversationType, targetId];
    } else {
        return nil;
    }
}
- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        RCConversationInfo *o = (RCConversationInfo *)object;
        return [_targetId isEqualToString:o.targetId] && (_conversationType == o.conversationType) &&
               (_portraitUri == o.portraitUri || [_portraitUri isEqualToString:o.portraitUri]) &&
               (_name == o.name || [_name isEqualToString:o.name]);
    }
    return NO;
}
@end
