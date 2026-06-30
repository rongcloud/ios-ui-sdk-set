//
//  RCMessageReactionDetailViewModel.h
//  RongIMKit
//
//  Created by RC on 2026/6/12.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCMessageReactionDetailUserItem.h"

NS_ASSUME_NONNULL_BEGIN

@class RCMessageModel;
@class RCMessageReaction;
@class RCUserInfo;

typedef void (^RCMessageReactionDetailUserLoader)(RCGetMessageReactionUsersParam *param,
                                                  void (^success)(RCPagingQueryResult<RCMessageReactionUser *> *result),
                                                  void (^error)(RCErrorCode errorCode));

typedef RCUserInfo *_Nullable (^RCMessageReactionDetailUserInfoProvider)(NSString *userId,
                                                                         RCConversationType conversationType,
                                                                         NSString *targetId);

@interface RCMessageReactionDetailViewModel : NSObject

@property (nonatomic, copy, readonly) NSArray<RCMessageReaction *> *reactions;
@property (nonatomic, strong, readonly, nullable) RCMessageReaction *selectedReaction;
@property (nonatomic, copy, readonly) NSArray<RCMessageReactionDetailUserItem *> *userItems;
@property (nonatomic, assign, readonly) NSInteger totalCount;
@property (nonatomic, copy, readonly, nullable) NSString *nextPageToken;
@property (nonatomic, assign, readonly) BOOL loading;
@property (nonatomic, assign, readonly) BOOL hasMore;

@property (nonatomic, copy) RCMessageReactionDetailUserLoader userLoader;
@property (nonatomic, copy) RCMessageReactionDetailUserInfoProvider userInfoProvider;

@property (nonatomic, copy, nullable) void (^onUsersChanged)(BOOL append);
@property (nonatomic, copy, nullable) void (^onLoadingStateChanged)(BOOL loading);
@property (nonatomic, copy, nullable) void (^onLoadFailed)(RCErrorCode errorCode);

- (instancetype)initWithMessageModel:(RCMessageModel *)messageModel
                            reactions:(NSArray<RCMessageReaction *> *)reactions
                    selectedReactionId:(NSString *)selectedReactionId;

- (void)loadInitialUsers;
- (void)selectReaction:(RCMessageReaction *)reaction;
- (void)loadMoreUsers;
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
