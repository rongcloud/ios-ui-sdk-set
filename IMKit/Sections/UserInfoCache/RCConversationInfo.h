//
//  RCConversationInfo.h
//  RongIMKit
//
//  Created by 岑裕 on 16/1/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>

@interface RCConversationInfo : NSObject

@property (nonatomic, copy) NSString *targetId;
@property (nonatomic, assign) RCConversationType conversationType;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *portraitUri;
@property (nonatomic, copy) NSString *extra;

- (instancetype)initWithConversationId:(NSString *)targetId
                      conversationType:(RCConversationType)conversationType
                                  name:(NSString *)name
                           portraitUri:(NSString *)portraitUri
                                 extra:(NSString *)extra;

- (instancetype)initWithGroupInfo:(RCGroup *)groupInfo;

- (RCGroup *)translateToGroupInfo;

+ (NSString *)getConversationGUID:(RCConversationType)conversationType targetId:(NSString *)targetId;

@end
