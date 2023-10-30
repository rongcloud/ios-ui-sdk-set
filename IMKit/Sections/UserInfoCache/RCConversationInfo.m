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
                           portraitUri:(NSString *)portraitUri
                                 extra:(NSString *)extra{
    self = [super init];

    if (self) {
        _targetId = targetId;
        _conversationType = conversationType;
        _name = name;
        _portraitUri = portraitUri;
        _extra = extra;
    }

    return self;
}

- (instancetype)initWithGroupInfo:(RCGroup *)groupInfo {
    return [self initWithConversationId:groupInfo.groupId
                       conversationType:ConversationType_GROUP
                                   name:groupInfo.groupName
                            portraitUri:groupInfo.portraitUri
                                  extra:groupInfo.extra];
}

- (RCGroup *)translateToGroupInfo {
    if (self.conversationType == ConversationType_GROUP) {
        RCGroup *group = [[RCGroup alloc] initWithGroupId:self.targetId groupName:self.name portraitUri:self.portraitUri];
        group.extra = self.extra;
        return group;
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
               (_name == o.name || [_name isEqualToString:o.name]) &&
               (_extra == o.extra || [_extra isEqualToString:o.extra]);
    }
    return NO;
}
@end
