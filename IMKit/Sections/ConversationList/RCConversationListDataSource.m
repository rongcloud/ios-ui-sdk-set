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
#import <RongIMLib/RongIMLib.h>
#import "RCConversationCellUpdateInfo.h"
#import "RCKitConfig.h"
#import "RCIMNotificationDataContext.h"
#define PagingCount 100

@interface RCConversationListDataSource ()
@property (nonatomic, strong) dispatch_queue_t updateEventQueue;
@property (nonatomic, assign) NSInteger currentCount;
@property (nonatomic, strong) NSMutableDictionary *collectedModelDict;
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
        self.cellBackgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                            darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
        self.topCellBackgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xf2faff)
                                                               darkColor:[HEXCOLOR(0x171717) colorWithAlphaComponent:0.8]];
        [self registerNotifications];
    }
    return self;
}
- (void)loadMoreConversations:(void (^)(NSMutableArray<RCConversationModel *> *modelList))completion {
    __block RCConversationModel *lastModel;
    __block long long sentTime = 0;
    __weak typeof(self) ws = self;
    dispatch_async(self.updateEventQueue, ^{
        NSMutableArray *modelList = [[NSMutableArray alloc] init];
        if ([[RCIM sharedRCIM] getConnectionStatus] != ConnectionStatus_SignOut) {
            lastModel = ws.dataList.lastObject;
            if (lastModel && lastModel.sentTime > 0) {
                sentTime = lastModel.sentTime;
            }
            NSArray *conversationList =
                [[RCIMClient sharedRCIMClient] getConversationList:ws.displayConversationTypeArray
                                                             count:PagingCount
                                                         startTime:sentTime];
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
        }
        if (modelList.count > 0) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:willReloadTableData:)]) {
                modelList = [ws.delegate dataSource:ws willReloadTableData:modelList];
            }
            modelList = [ws collectConversation:modelList collectionTypes:ws.collectionConversationTypeArray];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if(modelList.count > 0) {
                [ws.dataList addObjectsFromArray:modelList.copy];
            }
            if(completion) {
                completion(modelList);
            }
        });
    });
}

- (BOOL)containInCurrentDataSource:(RCConversationModel *)model {
    for (RCConversationModel *tmpModel in self.dataList) {
        if (tmpModel.conversationType == model.conversationType && [tmpModel.targetId isEqualToString:model.targetId]) {
            return YES;
        }
    }
    return NO;
}

- (void)forceLoadConversationModelList:(void (^)(NSMutableArray<RCConversationModel *> *modelList))completion {
    dispatch_async(self.updateEventQueue, ^{
        NSMutableArray<RCConversationModel *> *modelList = [[NSMutableArray alloc] init];

        if ([[RCIM sharedRCIM] getConnectionStatus] != ConnectionStatus_SignOut) {
            int c = self.currentCount < PagingCount ? PagingCount : (int)self.currentCount;
            NSArray *conversationList =
                [[RCIMClient sharedRCIMClient] getConversationList:self.displayConversationTypeArray
                                                             count:c
                                                         startTime:0];
            [RCIMNotificationDataContext updateNotificationLevelWith:conversationList];
            for (RCConversation *conversation in conversationList) {
                RCConversationModel *model = [[RCConversationModel alloc] initWithConversation:conversation extend:nil];
                model.topCellBackgroundColor = self.topCellBackgroundColor;
                model.cellBackgroundColor = self.cellBackgroundColor;
                RCLogI(@"conversation targetid:%@,type:%@,unreadMessageCount:%@", conversation.targetId, @(conversation.conversationType), @(model.unreadMessageCount));
                [modelList addObject:model];
            }
        }
        self.currentCount = modelList.count;
        self.collectedModelDict = [NSMutableDictionary new];
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:willReloadTableData:)]) {
            modelList = [self.delegate dataSource:self willReloadTableData:modelList];
        }
        modelList = [self collectConversation:modelList collectionTypes:self.collectionConversationTypeArray];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataList = modelList;
            if (completion) {
                completion(modelList);
            }
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
            RCConversation *conversation =
                [[RCIMClient sharedRCIMClient] getConversation:conversationType
                                                      targetId:targetId];
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
        }
    });
}

#pragma mark - Notification

- (void)didReceiveMessageNotification:(NSNotification *)notification {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.updateEventQueue, ^{
        if (weakSelf.isConverstaionListAppear) {
            weakSelf.throttleReloadAction();
        }else {
            int left = [notification.userInfo[@"left"] intValue];
            if (left == 0) {
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(notifyUpdateUnreadMessageCountInDataSource)]) {
                    [weakSelf.delegate notifyUpdateUnreadMessageCountInDataSource];
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
        if (messageId == 0) {
            return;
        }
        dispatch_async(self.updateEventQueue, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                for (RCConversationModel *model in self.dataList) {
                    if (model.lastestMessageId == messageId) {
                        RCConversationCellUpdateInfo *updateInfo = [[RCConversationCellUpdateInfo alloc] init];

                        RCConversation *conversation =
                            [[RCIMClient sharedRCIMClient] getConversation:model.conversationType
                                                                  targetId:model.targetId];
                        model.lastestMessage = conversation.lastestMessage;
                        model.sentStatus = conversation.sentStatus;
                        updateInfo.model = model;
                        updateInfo.updateType = RCConversationCell_MessageContent_Update;
                        [[NSNotificationCenter defaultCenter]
                            postNotificationName:RCKitConversationCellUpdateNotification
                                          object:updateInfo
                                        userInfo:nil];
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
            RCConversation *conversation =
                [[RCIMClient sharedRCIMClient] getConversation:message.conversationType targetId:message.targetId];
            RCConversationModel *model = [[RCConversationModel alloc] initWithConversation:conversation extend:nil];
            model.topCellBackgroundColor = self.topCellBackgroundColor;
            model.cellBackgroundColor = self.cellBackgroundColor;
            self.dataList[refreshIndex] = model;
            if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:willReloadAtIndexPaths:)]) {
                [self.delegate dataSource:self willReloadAtIndexPaths:@[[NSIndexPath indexPathForRow:refreshIndex inSection:0]]];
            }
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

                        if ([senderUserId isEqualToString:[RCIMClient sharedRCIMClient]
                                                              .currentUserInfo
                                                              .userId]) { //由于多端阅读消息数同步而触发通知执行该方法时
                            if (model.unreadMessageCount != 0) {
                                NSInteger unreadMessageCount;
                                if (model.lastestMessageDirection == MessageDirection_RECEIVE &&
                                    model.sentTime <= readTime) {
                                    unreadMessageCount = 0;
                                } else {
                                    unreadMessageCount = [RCKitUtility getConversationUnreadCount:model];
                                }

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
                            }

                            if (model.hasUnreadMentioned) {
                                BOOL hasUnreadMentioned = [RCKitUtility getConversationUnreadMentionedStatus:model];
                                if (hasUnreadMentioned != model.hasUnreadMentioned) {
                                    if (hasUnreadMentioned) {
                                        model.mentionedCount += 1;
                                    }
                                    RCConversationCellUpdateInfo *updateInfo =
                                        [[RCConversationCellUpdateInfo alloc] init];
                                    updateInfo.model = model;
                                    updateInfo.updateType = RCConversationCell_MessageContent_Update;
                                    [[NSNotificationCenter defaultCenter]
                                        postNotificationName:RCKitConversationCellUpdateNotification
                                                      object:updateInfo
                                                    userInfo:nil];
                                }
                            }
                            if(self.delegate && [self.delegate respondsToSelector:@selector(notifyUpdateUnreadMessageCountInDataSource)]){
                                [self.delegate notifyUpdateUnreadMessageCountInDataSource];
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
    dispatch_async(self.updateEventQueue, ^{
        long messageId = [notification.object longValue];

        dispatch_async(dispatch_get_main_queue(), ^{
            RCMessage *message = [[RCIMClient sharedRCIMClient] getMessage:messageId];
            NSString *targetId = message.targetId;
            for (RCConversationModel *model in self.dataList) {
                if ([targetId isEqualToString:model.targetId] || model.lastestMessageId == messageId) {

                    RCConversation *conversation =
                        [[RCIMClient sharedRCIMClient] getConversation:model.conversationType targetId:model.targetId];
                    model.lastestMessage = conversation.lastestMessage;
                    model.lastestMessageId = conversation.lastestMessageId;
                    model.mentionedCount = conversation.mentionedCount;
                    NSInteger unreadMessageCount =
                        [[RCIMClient sharedRCIMClient] getUnreadCount:model.conversationType targetId:model.targetId];
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
                    break;
                } else if (!message) {
                    if (model.unreadMessageCount > 0) {
                        RCConversationCellUpdateInfo *unreadUpdateInfo = [[RCConversationCellUpdateInfo alloc] init];
                        model.unreadMessageCount = [[RCIMClient sharedRCIMClient] getUnreadCount:model.conversationType
                                                                                        targetId:model.targetId];
                        unreadUpdateInfo.model = model;
                        unreadUpdateInfo.updateType = RCConversationCell_UnreadCount_Update;
                        [[NSNotificationCenter defaultCenter]
                            postNotificationName:RCKitConversationCellUpdateNotification
                                          object:unreadUpdateInfo
                                        userInfo:nil];
                    }
                }
            }
        });
    });
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

#pragma mark - getter

- (void (^)(void))throttleReloadAction{
    if (!_throttleReloadAction) {
        __weak typeof(self) weakSelf = self;
        _throttleReloadAction = [self getThrottleActionWithTimeInteval:0.5 action:^{
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(refreshConversationTableViewIfNeededInDataSource:)]) {
                [weakSelf.delegate refreshConversationTableViewIfNeededInDataSource:weakSelf];
            }
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(notifyUpdateUnreadMessageCountInDataSource)]) {
                [weakSelf.delegate notifyUpdateUnreadMessageCountInDataSource];
            }
        }];
    }
    return _throttleReloadAction;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
