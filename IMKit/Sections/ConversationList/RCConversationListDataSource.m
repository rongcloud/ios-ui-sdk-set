//
//  RCConversationListDataSource.m
//  RongIMKit
//
//  Created by Sin on 2020/5/26.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCConversationListDataSource.h"
#import "RCIM.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCConversationCellUpdateInfo.h"
#import "RCKitConfig.h"
#import "RCIMNotificationDataContext.h"
#import "RCConversationListDataSource+RRS.h"
#import "RCUserOnlineStatusManager.h"
#import "RCUserOnlineStatusUtil.h"

#define PagingCount 100

@interface RCConversationListDataSource ()<RCReadReceiptV5Delegate, RCUserOnlineStatusManagerDelegate>
@property (nonatomic, strong) dispatch_queue_t updateEventQueue;
@property (nonatomic, assign) NSInteger currentCount;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, RCConversationModel *> *collectedModelDict;
@property (nonatomic, assign) BOOL isWaitingForForceRefresh;
@property (nonatomic, copy) void(^throttleReloadAction)(void);
@end

@implementation RCConversationListDataSource
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.updateEventQueue = dispatch_queue_create("cn.rongcloud.conversation.updateEventQueue", NULL);
        self.currentCount = 0;
        self.dataList = [[NSMutableArray alloc] init];
        self.isConverstaionListAppear = NO;
        self.cellBackgroundColor = RCDynamicColor(@"conversation-list_background_color", @"0xffffff", @"0x1c1c1e66");
        self.topCellBackgroundColor = RCDynamicColor(@"common_background_color", @"0xf2faff", @"0x171717CC");
        [self registerNotifications];
        
        [RCUserOnlineStatusManager sharedManager].delegate = self;
    }
    return self;
}
- (void)loadMoreConversations:(void (^)(NSMutableArray<RCConversationModel *> *modelList))completion {
    __block NSMutableArray *modelList = [[NSMutableArray alloc] init];
    if ([[RCIM sharedRCIM] getConnectionStatus] == ConnectionStatus_SignOut) {
        if(completion) {
            completion(modelList);
        }
        return;
    }
    
    RCConversationModel *lastModel;
    long long operationTime = 0;
    lastModel = self.dataList.lastObject;
    if (lastModel && lastModel.operationTime > 0) {
        operationTime = lastModel.operationTime;
    }
    __weak typeof(self) ws = self;

    BOOL topPriority = YES;
    if ([self.delegate respondsToSelector:@selector(showConversationOnTopPriority)]) {
        topPriority = [self.delegate showConversationOnTopPriority];
    }
    [[RCCoreClient sharedCoreClient] getConversationList:ws.displayConversationTypeArray
                                                   count:PagingCount
                                               startTime:operationTime
                                             topPriority:topPriority
                                              completion:^(NSArray<RCConversation *> * _Nullable conversationList) {
        dispatch_async(self.updateEventQueue, ^{
            [RCIMNotificationDataContext updateNotificationLevelWith:conversationList];
            ws.currentCount += conversationList.count;
            for (RCConversation *conversation in conversationList) {
                RCConversationModel *model = [[RCConversationModel alloc] initWithConversation:conversation extend:nil];
                if (![self containInCurrentDataSource:model]) {
                    model.topCellBackgroundColor = ws.topCellBackgroundColor;
                    model.cellBackgroundColor = ws.cellBackgroundColor;
                    [modelList addObject:model];
                }
            }
            if (modelList.count > 0) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:willReloadTableData:)]) {
                    modelList = [ws.delegate dataSource:ws willReloadTableData:modelList];
                }
                modelList = [ws collectConversation:modelList collectionTypes:ws.collectionConversationTypeArray];
            }
            
            [self rrs_refreshCachedAndFetchReceiptInfo:modelList];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if(modelList.count > 0) {
                    [ws.dataList addObjectsFromArray:modelList.copy];
                }
                if(completion) {
                    completion(modelList);
                }
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    [self fetchUserOnlineStatus:modelList.copy];
                });
            });
        });
    }];
}

- (BOOL)containInCurrentDataSource:(RCConversationModel *)model {
    NSArray *array = [self.dataList copy];
    for (RCConversationModel *tmpModel in array) {
        if (tmpModel.conversationType == model.conversationType && [tmpModel.targetId isEqualToString:model.targetId]) {
            return YES;
        }
    }
    return NO;
}

- (void)forceLoadConversationModelList:(void (^)(NSMutableArray<RCConversationModel *> *modelList))completion {
    dispatch_async(self.updateEventQueue, ^{
        NSMutableArray<RCConversationModel *> *modelList = [[NSMutableArray alloc] init];
        BOOL topPriority = YES;
        if ([self.delegate respondsToSelector:@selector(showConversationOnTopPriority)]) {
            topPriority = [self.delegate showConversationOnTopPriority];
        }
        if ([[RCIM sharedRCIM] getConnectionStatus] != ConnectionStatus_SignOut) {
            int count = (int)MAX(self.currentCount, PagingCount);
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [[RCCoreClient sharedCoreClient] getConversationList:self.displayConversationTypeArray count:count startTime:0 topPriority:topPriority completion:^(NSArray<RCConversation *> * _Nullable conversationList) {
                [RCIMNotificationDataContext updateNotificationLevelWith:conversationList];
                for (RCConversation *conversation in conversationList) {
                    RCConversationModel *model = [[RCConversationModel alloc] initWithConversation:conversation extend:nil];
                    model.topCellBackgroundColor = self.topCellBackgroundColor;
                    model.cellBackgroundColor = self.cellBackgroundColor;
                    RCLogI(@"conversation targetid:%@,type:%@,unreadMessageCount:%@", conversation.targetId, @(conversation.conversationType), @(model.unreadMessageCount));
                    [modelList addObject:model];
                }
                dispatch_semaphore_signal(semaphore);
            }];
            dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)));
        }
        self.currentCount = modelList.count;
        self.collectedModelDict = [NSMutableDictionary new];
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:willReloadTableData:)]) {
            modelList = [self.delegate dataSource:self willReloadTableData:modelList];
        }
        modelList = [self collectConversation:modelList collectionTypes:self.collectionConversationTypeArray];
        
        [self rrs_refreshCachedAndFetchReceiptInfo:modelList];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataList = modelList;
            if (completion) {
                completion(modelList);
            }
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [self fetchUserOnlineStatus:modelList.copy];
            });
        });
    });
}


- (NSMutableArray *)collectConversation:(NSMutableArray *)modelList collectionTypes:(NSArray *)collectionTypes {
    if (collectionTypes.count == 0) {
        return modelList;
    }

    for (RCConversationModel *model in modelList.copy) {
        if ([collectionTypes containsObject:@(model.conversationType)]) {
            RCConversationModel *collectedModel = self.collectedModelDict[@(model.conversationType)];
            if (collectedModel) {
                collectedModel.unreadMessageCount += model.unreadMessageCount;
                collectedModel.mentionedCount = model.mentionedCount;
                collectedModel.isTop |= model.isTop;
                [modelList removeObject:model];
            } else {
                model.conversationModelType = RC_CONVERSATION_MODEL_TYPE_COLLECTION;
                [self.collectedModelDict setObject:model forKey:@(model.conversationType)];
            }
        }
    }

    return modelList;
}

- (NSUInteger)getFirstModelIndex:(BOOL)isTop sentTime:(long long)sentTime {
    if (isTop || self.dataList.count == 0) {
        return 0;
    } else {
        for (NSUInteger index = 0; index < self.dataList.count; index++) {
            RCConversationModel *model = self.dataList[index];
            if (model.isTop == isTop && sentTime >= model.sentTime) {
                return index;
            }
        }
        return self.dataList.count - 1;
    }
}

- (void)refreshConversationModel:(RCConversationModel *)conversationModel {
    [self refreshConversationModel:conversationModel.conversationType targetId:conversationModel.targetId];
}

- (void)refreshConversationModel:(RCConversationType)conversationType targetId:(NSString *)targetId {
    dispatch_async(dispatch_get_main_queue(), ^{
        RCConversationModel *matchingModel = nil;
        for (RCConversationModel *model in self.dataList) {
            if ([model isMatching:conversationType targetId:targetId]) {
                matchingModel = model;
                break;
            }
        }

        if (matchingModel) {
            NSUInteger oldIndex = [self.dataList indexOfObject:matchingModel];
            NSUInteger newIndex = [self getFirstModelIndex:matchingModel.isTop sentTime:matchingModel.sentTime];

            if (oldIndex == newIndex) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:willReloadAtIndexPaths:)]) {
                    [self.delegate dataSource:self willReloadAtIndexPaths:@[ [NSIndexPath indexPathForRow:newIndex inSection:0]]];
                }
            } else {
                [self.dataList removeObjectAtIndex:oldIndex];
                [self.dataList insertObject:matchingModel atIndex:newIndex];
                if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:willDeleteAtIndexPaths:willInsertAtIndexPaths:)]) {
                    [self.delegate dataSource:self willDeleteAtIndexPaths:@[ [NSIndexPath indexPathForRow:oldIndex inSection:0] ] willInsertAtIndexPaths:@[ [NSIndexPath indexPathForRow:newIndex inSection:0] ]];
                }
            }
        } else {
            [[RCCoreClient sharedCoreClient] getConversation:conversationType
                                                    targetId:targetId
                                                  completion:^(RCConversation * _Nullable conversation) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    RCConversationModel *newModel =
                    [[RCConversationModel alloc] initWithConversation:conversation extend:nil];
                    if ([self.collectionConversationTypeArray
                         containsObject:@(conversation.conversationType)]) {
                        newModel.conversationModelType = RC_CONVERSATION_MODEL_TYPE_COLLECTION;
                    }
                    newModel.topCellBackgroundColor = self.topCellBackgroundColor;
                    newModel.cellBackgroundColor = self.cellBackgroundColor;
                    NSUInteger newIndex = [self getFirstModelIndex:newModel.isTop sentTime:newModel.sentTime];
                    [self.dataList insertObject:newModel atIndex:newIndex];
                    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:willInsertAtIndexPaths:)]) {
                        [self.delegate dataSource:self willInsertAtIndexPaths:@[ [NSIndexPath indexPathForRow:newIndex inSection:0] ]];
                    }
                    if (newModel) {
                        [self rrs_refreshCachedAndFetchReceiptInfo:@[newModel]];
                    }
                });
            }];
        }
    });
}

#pragma mark - Notification

- (void)didReceiveMessageNotification:(NSNotification *)notification {
    dispatch_async(self.updateEventQueue, ^{
        if (self.isConverstaionListAppear) {
            self.throttleReloadAction();
        }else {
            int left = [notification.userInfo[@"left"] intValue];
            if (left == 0) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(notifyUpdateUnreadMessageCountInDataSource)]) {
                    [self.delegate notifyUpdateUnreadMessageCountInDataSource];
                }
            }
        }
    });
}
- (void)onMessageSentStatusUpdate:(NSNotification *)notification {
    NSDictionary *statusDic = notification.userInfo;

    if (statusDic) {
        // 更新消息状态
        long messageId = [statusDic[@"messageId"] longValue];
        NSString *targetId = statusDic[@"targetId"];
        if (messageId == 0 || targetId.length == 0) {
            return;
        }
        dispatch_async(self.updateEventQueue, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *arrayDataList = [self.dataList copy];
                for (RCConversationModel *model in arrayDataList) {
                    if ([model.targetId isEqualToString:targetId]) {
                        RCConversationCellUpdateInfo *updateInfo = [[RCConversationCellUpdateInfo alloc] init];
                        [[RCCoreClient sharedCoreClient] getConversation:model.conversationType
                                                                targetId:model.targetId
                                                              completion:^(RCConversation * _Nullable conversation) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                model.lastestMessage = conversation.latestMessage;
                                model.latestMessageUId = conversation.latestMessageUId;
                                model.sentStatus = conversation.sentStatus;
                                updateInfo.model = model;
                                updateInfo.updateType = RCConversationCell_MessageContent_Update;
                                [[NSNotificationCenter defaultCenter]
                                 postNotificationName:RCKitConversationCellUpdateNotification
                                 object:updateInfo
                                 userInfo:nil];
                            });
                        }];
                        
                        break;
                    }
                }
            });
        });
    }
}

- (void)onMessageDestructing:(NSNotification *)notification {

    NSDictionary *dataDict = notification.userInfo;
    RCMessage *message = dataDict[@"message"];
    NSInteger duration = [dataDict[@"remainDuration"] integerValue];

    if (duration <= 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *refreshTargetId = message.targetId;
            NSInteger refreshIndex = -1;
            for (RCConversationModel *model in self.dataList) {
                if ([model.targetId isEqualToString:refreshTargetId]) {
                    refreshIndex = [self.dataList indexOfObject:model];
                    break;
                }
            }

            if (self.dataList.count <= 0) {
                if(self.delegate && [self.delegate respondsToSelector:@selector(refreshConversationTableViewIfNeededInDataSource:)]){
                    [self.delegate refreshConversationTableViewIfNeededInDataSource:self];
                }
                return;
            }

            if (refreshIndex < 0) {
                return;
            }
            [[RCCoreClient sharedCoreClient] getConversation:message.conversationType targetId:message.targetId completion:^(RCConversation * _Nullable conversation) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    RCConversationModel *model = [[RCConversationModel alloc] initWithConversation:conversation extend:nil];
                    model.topCellBackgroundColor = self.topCellBackgroundColor;
                    model.cellBackgroundColor = self.cellBackgroundColor;
                    self.dataList[refreshIndex] = model;
                    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:willReloadAtIndexPaths:)]) {
                        [self.delegate dataSource:self willReloadAtIndexPaths:@[[NSIndexPath indexPathForRow:refreshIndex inSection:0]]];
                    }
                });
            }];
           
        });
    }
}

- (void)didReceiveReadReceiptNotification:(NSNotification *)notification {
    dispatch_async(self.updateEventQueue, ^{
        RCConversationType conversationType = (RCConversationType)[notification.userInfo[@"cType"] integerValue];
        long long readTime = [notification.userInfo[@"messageTime"] longLongValue];
        NSString *targetId = notification.userInfo[@"tId"];
        NSString *senderUserId = notification.userInfo[@"fId"];

        if ([self.displayConversationTypeArray containsObject:@(conversationType)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                for (RCConversationModel *model in self.dataList) {
                    if ([model isMatching:conversationType targetId:targetId]) {

                        if ([senderUserId isEqualToString:[RCCoreClient sharedCoreClient]
                                                              .currentUserInfo
                                                              .userId]) { //由于多端阅读消息数同步而触发通知执行该方法时
                            if (model.unreadMessageCount != 0) {
                                void (^completion)(int) = ^(int unreadMessageCount) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        if (unreadMessageCount != model.unreadMessageCount) {
                                            model.unreadMessageCount = unreadMessageCount;
                                            RCConversationCellUpdateInfo *updateInfo =
                                                [[RCConversationCellUpdateInfo alloc] init];
                                            updateInfo.model = model;
                                            updateInfo.updateType = RCConversationCell_UnreadCount_Update;
                                            [[NSNotificationCenter defaultCenter]
                                                postNotificationName:RCKitConversationCellUpdateNotification
                                                              object:updateInfo
                                                            userInfo:nil];
                                        }
                                        if(self.delegate && [self.delegate respondsToSelector:@selector(notifyUpdateUnreadMessageCountInDataSource)]){
                                            [self.delegate notifyUpdateUnreadMessageCountInDataSource];
                                        }
                                    });
                                };
                                
                                if (model.lastestMessageDirection == MessageDirection_RECEIVE &&
                                    model.sentTime <= readTime && model.conversationModelType != RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
                                    completion(0);
                                } else {
                                    [self getConversationUnreadCount:model completion:completion];
                                }
                            }

                            if (model.hasUnreadMentioned) {
                                [RCKitUtility getConversationUnreadMentionedCount:model result:^(int num) {
                                    model.mentionedCount = num;
                                    RCConversationCellUpdateInfo *updateInfo = [[RCConversationCellUpdateInfo alloc] init];
                                    updateInfo.model = model;
                                    updateInfo.updateType = RCConversationCell_MessageContent_Update;
                                    [[NSNotificationCenter defaultCenter]
                                     postNotificationName:RCKitConversationCellUpdateNotification
                                     object:updateInfo
                                     userInfo:nil];
                                }];
                            }
                        } else { //由于已读回执而触发通知执行该方法时
                            if ([RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(conversationType)]) {
                                if (model.lastestMessageDirection == MessageDirection_SEND &&
                                    model.sentTime <= readTime && model.sentStatus != SentStatus_READ) {
                                    model.sentStatus = SentStatus_READ;
                                    RCConversationCellUpdateInfo *updateInfo =
                                        [[RCConversationCellUpdateInfo alloc] init];
                                    updateInfo.model = model;
                                    updateInfo.updateType = RCConversationCell_SentStatus_Update;
                                    [[NSNotificationCenter defaultCenter]
                                        postNotificationName:RCKitConversationCellUpdateNotification
                                                      object:updateInfo
                                                    userInfo:nil];
                                }
                            }
                        }
                        break;
                    }
                }
            });
        }
    });
}
- (void)didReceiveRecallMessageNotification:(NSNotification *)notification {
    long messageId = [notification.object longValue];
    [[RCCoreClient sharedCoreClient] getMessage:messageId completion:^(RCMessage * _Nullable message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *targetId = message.targetId;
            for (RCConversationModel *model in self.dataList) {
                if (model.lastestMessageId == messageId || [model isMatching:message.conversationType targetId:message.targetId]) {
                    [[RCCoreClient sharedCoreClient] getConversation:model.conversationType targetId:model.targetId completion:^(RCConversation * _Nullable conversation) {
                        model.lastestMessage = conversation.latestMessage;
                        model.lastestMessageId = conversation.latestMessageId;
                        model.mentionedCount = conversation.mentionedCount;
                        [self getConversationUnreadCount:model completion:^(int unreadMessageCount) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (unreadMessageCount != model.unreadMessageCount) {
                                    RCConversationCellUpdateInfo *unreadUpdateInfo = [[RCConversationCellUpdateInfo alloc] init];
                                    model.unreadMessageCount = unreadMessageCount;
                                    unreadUpdateInfo.model = model;
                                    unreadUpdateInfo.updateType = RCConversationCell_UnreadCount_Update;
                                    [[NSNotificationCenter defaultCenter]
                                     postNotificationName:RCKitConversationCellUpdateNotification
                                     object:unreadUpdateInfo
                                     userInfo:nil];
                                }
                                RCConversationCellUpdateInfo *updateInfo = [[RCConversationCellUpdateInfo alloc] init];
                                updateInfo.model = model;
                                updateInfo.updateType = RCConversationCell_MessageContent_Update;
                                [[NSNotificationCenter defaultCenter] postNotificationName:RCKitConversationCellUpdateNotification
                                                                                    object:updateInfo
                                                                                  userInfo:nil];
                            });
                        }];
                    }];
                    break;
                } else if (!message) {
                    if (model.unreadMessageCount > 0) {
                        RCConversationCellUpdateInfo *unreadUpdateInfo = [[RCConversationCellUpdateInfo alloc] init];
                         [[RCCoreClient sharedCoreClient] getUnreadCount:model.conversationType
                                                                                          targetId:model.targetId completion:^(int count) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 model.unreadMessageCount = count;
                                 unreadUpdateInfo.model = model;
                                 unreadUpdateInfo.updateType = RCConversationCell_UnreadCount_Update;
                                 [[NSNotificationCenter defaultCenter]
                                  postNotificationName:RCKitConversationCellUpdateNotification
                                  object:unreadUpdateInfo
                                  userInfo:nil];
                             });
                        }];
                    }
                }
            }
        });
    }];
}

- (void)registerNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMessageSentStatusUpdate:)
                                                 name:@"RCKitSendingMessageNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMessageDestructing:)
                                                 name:@"RCKitMessageDestructingNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveReadReceiptNotification:)
                                                 name:RCLibDispatchReadReceiptNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveRecallMessageNotification:)
                                                 name:RCKitDispatchRecallMessageNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMessagesModifiedNotification:)
                                                 name:RCKitDispatchMessagesModifiedNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUserOnlineStatusChangedNotification:)
                                                 name:RCKitUserOnlineStatusChangedNotification
                                               object:nil];
    
    [[RCCoreClient sharedCoreClient] addReadReceiptV5Delegate:self];
}

#pragma mark - helper
- (void(^)(void))getThrottleActionWithTimeInteval:(double)timeInteval action:(void(^)(void))action {
    __block BOOL canAction = NO;
    return ^{
        if (canAction == NO) {
            canAction = YES;
        } else {
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInteval * NSEC_PER_SEC)), self.updateEventQueue, ^{
            canAction = NO;
            action();
        });
    };
}

- (void)getConversationUnreadCount:(RCConversationModel *)model completion:(void (^)(int unreadMessageCount))completion {
    if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
        [[RCCoreClient sharedCoreClient] getUnreadCount:@[ @(model.conversationType) ] completion:completion];
    } else {
        [[RCCoreClient sharedCoreClient] getUnreadCount:model.conversationType targetId:model.targetId completion:completion];
    }
}

#pragma mark - getter

- (void (^)(void))throttleReloadAction{
    if (!_throttleReloadAction) {
        __weak typeof(self) weakSelf = self;
        _throttleReloadAction = [self getThrottleActionWithTimeInteval:0.5 action:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(refreshConversationTableViewIfNeededInDataSource:)]) {
                [strongSelf.delegate refreshConversationTableViewIfNeededInDataSource:strongSelf];
            }
            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(notifyUpdateUnreadMessageCountInDataSource)]) {
                [strongSelf.delegate notifyUpdateUnreadMessageCountInDataSource];
            }
        }];
    }
    return _throttleReloadAction;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 消息编辑

- (void)onMessagesModifiedNotification:(NSNotification *)notification {
    if (!self.isConverstaionListAppear) {// 列表页不显示时无需处理
        return;
    }
    NSArray<RCMessage *> *messages = notification.object;
    // 将 dataList 快照转为哈希表，key 为 latestMessageUId
    NSArray<RCConversationModel *> *arrayDataList = [self.dataList copy];
    NSMutableDictionary<NSString *, RCConversationModel *> *uidToModel = [NSMutableDictionary dictionaryWithCapacity:arrayDataList.count];
    for (RCConversationModel *model in arrayDataList) {
        if (model.latestMessageUId.length > 0) {
            uidToModel[model.latestMessageUId] = model;
        }
    }

    for (RCMessage *message in messages) {
        RCConversationModel *model = uidToModel[message.messageUId];
        if (!model) {
            continue;
        }
        // 更新最后一条消息的显示内容
        model.lastestMessage = message.content;
        
        RCConversationCellUpdateInfo *updateInfo = [[RCConversationCellUpdateInfo alloc] init];
        updateInfo.model = model;
        updateInfo.updateType = RCConversationCell_MessageContent_Update;
        [[NSNotificationCenter defaultCenter]
         postNotificationName:RCKitConversationCellUpdateNotification
         object:updateInfo
         userInfo:nil];
    }
}

#pragma mark - 已读回执v5
- (void)didReceiveMessageReadReceiptResponses:(NSArray<RCReadReceiptResponseV5 *> *)responses {
    if (!self.isConverstaionListAppear) {// 列表页不显示时无需处理
        return;
    }
    dispatch_async(self.updateEventQueue, ^{
        [self rrs_didReceiveMessageReadReceiptResponses:responses];
    });
}

- (void)onUserOnlineStatusChangedNotification:(NSNotification *)notification {
    NSArray<NSString *> *userIds = notification.userInfo[RCKitUserOnlineStatusChangedUserIdsKey];
    NSMutableDictionary<NSString *, RCConversationModel *> *userIdToModel = [NSMutableDictionary dictionaryWithCapacity:self.dataList.count];
    for (RCConversationModel *model in self.dataList) {
        if (model.targetId.length > 0 && model.conversationType == ConversationType_PRIVATE) {
            userIdToModel[model.targetId] = model;
        }
    }
    for (NSString *userId in userIds) {
        RCConversationModel *model = userIdToModel[userId];
        if (model) {
            model.onlineStatus = [[RCUserOnlineStatusManager sharedManager] getCachedOnlineStatus:userId];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitConversationCellOnlineStatusUpdateNotification object:nil userInfo:notification.userInfo];
}

#pragma mark - RCUserOnlineStatusManagerDelegate

- (NSArray<NSString *> *)userIdsNeedOnlineStatus:(RCUserOnlineStatusManager *)manager {
    // 筛选出需要显示在线状态的模型列表
    NSMutableArray *needShowUserIds = [NSMutableArray array];
    for (RCConversationModel *model in self.dataList) {
        if (model.conversationType == ConversationType_PRIVATE
            && model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL
            && model.targetId) {
            [needShowUserIds addObject:model.targetId];
        }
    }
    return needShowUserIds;
}

- (void)fetchUserOnlineStatus:(NSArray <RCConversationModel *>*)modelList {
    if (![RCUserOnlineStatusUtil shouldDisplayOnlineStatus]) {
        return;
    }
    // 需要显示在线状态的会话
    NSMutableArray *fetchUserIds = [NSMutableArray array];
    for (RCConversationModel *model in modelList) {
        if (model.conversationType == ConversationType_PRIVATE
            && model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL) {
            model.displayOnlineStatus = YES;
            RCSubscribeUserOnlineStatus *status = [RCUserOnlineStatusManager.sharedManager getCachedOnlineStatus:model.targetId];
            if (status) {
                model.onlineStatus = status;
            } else {
                [fetchUserIds addObject:model.targetId];
            }
        }
    }
    // 获取未获取到在线状态的模型列表中的用户ID列表
    if (fetchUserIds.count > 0) {
        [RCUserOnlineStatusManager.sharedManager fetchOnlineStatus:fetchUserIds];
    }
}

@end
