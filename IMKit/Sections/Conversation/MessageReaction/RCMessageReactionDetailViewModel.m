//
//  RCMessageReactionDetailViewModel.m
//  RongIMKit
//
//  Created by RC on 2026/6/12.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageReactionDetailViewModel.h"
#import "RCIM.h"
#import "RCMessageModel.h"
#import "RCMessageReactionDetailUserItem.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"

static NSInteger const RCMessageReactionDetailPageSize = 50;

@interface RCMessageReactionDetailViewModel ()

@property (nonatomic, weak) RCMessageModel *messageModel;
@property (nonatomic, copy, readwrite) NSArray<RCMessageReaction *> *reactions;
@property (nonatomic, strong, readwrite, nullable) RCMessageReaction *selectedReaction;
@property (nonatomic, copy, readwrite) NSArray<RCMessageReactionDetailUserItem *> *userItems;
@property (nonatomic, assign, readwrite) NSInteger totalCount;
@property (nonatomic, copy, readwrite, nullable) NSString *nextPageToken;
@property (nonatomic, assign, readwrite) BOOL loading;
@property (nonatomic, assign) NSUInteger requestVersion;
@property (nonatomic, assign) BOOL invalidated;

@end

@implementation RCMessageReactionDetailViewModel

- (instancetype)initWithMessageModel:(RCMessageModel *)messageModel
                            reactions:(NSArray<RCMessageReaction *> *)reactions
                    selectedReactionId:(NSString *)selectedReactionId {
    self = [super init];
    if (self) {
        _messageModel = messageModel;
        _reactions = [reactions copy] ?: @[];
        _selectedReaction = [self reactionWithReactionId:selectedReactionId] ?: _reactions.firstObject;
        _totalCount = _selectedReaction ? _selectedReaction.totalCount : 0;
        _userItems = @[];
        [self setupDefaultBlocks];
    }
    return self;
}

- (BOOL)hasMore {
    return self.nextPageToken.length > 0;
}

- (void)loadInitialUsers {
    [self loadUsersWithPageToken:nil append:NO];
}

- (void)selectReaction:(RCMessageReaction *)reaction {
    if (!reaction || [reaction.reactionId isEqualToString:self.selectedReaction.reactionId]) {
        return;
    }
    self.selectedReaction = reaction;
    self.userItems = @[];
    self.nextPageToken = nil;
    self.totalCount = reaction.totalCount;
    [self loadUsersWithPageToken:nil append:NO];
}

- (void)loadMoreUsers {
    if (self.loading || self.nextPageToken.length == 0) {
        return;
    }
    [self loadUsersWithPageToken:self.nextPageToken append:YES];
}

- (void)invalidate {
    self.invalidated = YES;
    self.requestVersion++;
    self.loading = NO;
}

- (void)setupDefaultBlocks {
    __weak typeof(self) weakSelf = self;
    self.userLoader = ^(RCGetMessageReactionUsersParam *param,
                        void (^success)(RCPagingQueryResult<RCMessageReactionUser *> *result),
                        void (^error)(RCErrorCode errorCode)) {
        [[RCCoreClient sharedCoreClient] getMessageReactionUsers:param success:success error:error];
    };
    self.userInfoProvider = ^RCUserInfo *(NSString *userId, RCConversationType conversationType, NSString *targetId) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        return [strongSelf userInfoForUserId:userId conversationType:conversationType targetId:targetId];
    };
}

- (void)loadUsersWithPageToken:(NSString *)pageToken append:(BOOL)append {
    RCMessageReaction *reaction = self.selectedReaction;
    RCMessageModel *model = self.messageModel;
    if (model.messageUId.length == 0 || reaction.reactionId.length == 0 || !self.userLoader) {
        return;
    }
    self.invalidated = NO;
    self.loading = YES;
    if (self.onLoadingStateChanged) {
        self.onLoadingStateChanged(YES);
    }

    NSUInteger currentVersion = ++self.requestVersion;
    NSString *requestReactionId = reaction.reactionId;
    RCGetMessageReactionUsersParam *param = [[RCGetMessageReactionUsersParam alloc] init];
    param.messageUId = model.messageUId;
    param.reactionId = requestReactionId;
    param.count = RCMessageReactionDetailPageSize;
    param.pageToken = pageToken;

    __weak typeof(self) weakSelf = self;
    self.userLoader(param, ^(RCPagingQueryResult<RCMessageReactionUser *> *result) {
        dispatch_main_async_safe(^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (![strongSelf shouldHandleCallbackWithVersion:currentVersion reactionId:requestReactionId]) {
                return;
            }
            NSArray<RCMessageReactionDetailUserItem *> *items = [strongSelf userItemsWithUsers:result.data ?: @[]];
            if (append) {
                strongSelf.userItems = [strongSelf.userItems arrayByAddingObjectsFromArray:items];
            } else {
                strongSelf.userItems = items;
            }
            strongSelf.totalCount = result.totalCount;
            strongSelf.nextPageToken = result.pageToken;
            [strongSelf setLoadingAndNotify:NO];
            if (strongSelf.onUsersChanged) {
                strongSelf.onUsersChanged(append);
            }
        });
    }, ^(RCErrorCode errorCode) {
        dispatch_main_async_safe(^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (![strongSelf shouldHandleCallbackWithVersion:currentVersion reactionId:requestReactionId]) {
                return;
            }
            [strongSelf setLoadingAndNotify:NO];
            if (strongSelf.onLoadFailed) {
                strongSelf.onLoadFailed(errorCode);
            }
        });
    });
}

- (BOOL)shouldHandleCallbackWithVersion:(NSUInteger)version reactionId:(NSString *)reactionId {
    if (self.invalidated || version != self.requestVersion) {
        return NO;
    }
    return [reactionId isEqualToString:self.selectedReaction.reactionId];
}

- (void)setLoadingAndNotify:(BOOL)loading {
    self.loading = loading;
    if (self.onLoadingStateChanged) {
        self.onLoadingStateChanged(loading);
    }
}

- (NSArray<RCMessageReactionDetailUserItem *> *)userItemsWithUsers:(NSArray<RCMessageReactionUser *> *)users {
    NSMutableArray<RCMessageReactionDetailUserItem *> *items = [NSMutableArray arrayWithCapacity:users.count];
    for (RCMessageReactionUser *user in users) {
        RCUserInfo *userInfo = self.userInfoProvider ? self.userInfoProvider(user.userId, self.messageModel.conversationType, self.messageModel.targetId) : nil;
        RCMessageReactionDetailUserItem *item = [[RCMessageReactionDetailUserItem alloc] initWithUser:user
                                                                                          displayName:[self displayNameForUser:user userInfo:userInfo]
                                                                                          portraitUri:userInfo.portraitUri];
        [items addObject:item];
    }
    return items.copy;
}

- (NSString *)displayNameForUser:(RCMessageReactionUser *)user userInfo:(RCUserInfo *)userInfo {
    NSString *userId = user.userId ?: @"";
    if (userId.length <= 0) {
        return @"";
    }
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement &&
        [self.messageModel.content.senderUserInfo.userId isEqualToString:userId]) {
        NSString *senderDisplayName = [RCKitUtility getDisplayName:self.messageModel.content.senderUserInfo];
        if (senderDisplayName.length > 0) {
            return senderDisplayName;
        }
    }
    NSString *displayName = [RCKitUtility getDisplayName:userInfo];
    return displayName.length > 0 ? displayName : userId;
}

- (RCUserInfo *)userInfoForUserId:(NSString *)userId conversationType:(RCConversationType)conversationType targetId:(NSString *)targetId {
    if (userId.length <= 0) {
        return nil;
    }
    NSString *groupId = conversationType == ConversationType_GROUP ? targetId : nil;
    return [RCKitUtility userInfoForDisplayWithUserId:userId groupId:groupId];
}

- (RCMessageReaction *)reactionWithReactionId:(NSString *)reactionId {
    if (reactionId.length <= 0) {
        return nil;
    }
    for (RCMessageReaction *reaction in self.reactions) {
        if ([reaction.reactionId isEqualToString:reactionId]) {
            return reaction;
        }
    }
    return nil;
}

@end
