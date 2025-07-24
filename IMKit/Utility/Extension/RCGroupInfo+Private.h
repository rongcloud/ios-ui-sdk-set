//
//  RCGroupInfo+Private.h
//  RongIMLibCore
//
//  Created by Lang on 2024/7/24.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import <RongIMLibCore/RCGroupInfo.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCGroupInfo ()

/// 创建者 userId
@property (nonatomic, copy) NSString *creatorId;

/// 群主 userId
@property (nonatomic, copy) NSString *ownerId;

/// 当前用户群昵称：用户主动设置的群昵称
@property (nonatomic, copy, nullable) NSString *remark;

/// 群组创建时间。
@property (nonatomic, assign) long long createTime;

/// 群当前成员人数。
@property (nonatomic, assign) NSUInteger membersCount;

/// 当前用户加入时间：用户多次加入群组时，以最后一次加入时间为准
@property (nonatomic, assign) long long joinedTime;

/// 我的群身份
@property (nonatomic, assign) RCGroupMemberRole role;

/// 获取用户有修改的属性值，不包含 groupId
- (NSDictionary<NSString *, NSString *> *)getUserModifiedParams;

/// 不解析 groupId 和 readonly 属性
- (void)decodeBaseData:(NSDictionary<NSString *, NSString *> *)data;

+ (NSArray<NSString *> *)convertKeysToNames:(NSArray<RCGroupInfoKeys> *)keys;

@end

NS_ASSUME_NONNULL_END
