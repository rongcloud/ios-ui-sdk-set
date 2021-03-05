//
//  RCConversationDataSource.m
//  RongIMKit
//
//  Created by Sin on 2020/7/6.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCConversationDataSource.h"
#import <RongIMLib/RongIMLib.h>
#import "RCMessageModel.h"
#import "RCConversationViewController.h"
#import "RCKitConfig.h"
#import "RCKitUtility.h"
#import "RCConversationVCUtil.h"
#import "RCConversationCSUtil.h"
#import "RCCustomerServiceMessageModel.h"
#import "RCConversationCollectionViewHeader.h"
#import "RCConversationViewLayout.h"
#import "RCOldMessageNotificationMessage.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCMessageCell.h"
#import <RongChatRoom/RongChatRoom.h>
#import "RCConversationViewController+internal.h"

#define COLLECTION_VIEW_REFRESH_CONTROL_HEIGHT 30
#define COLLECTION_VIEW_CELL_MAX_COUNT 3000
#define COLLECTION_VIEW_CELL_REMOVE_COUNT 200

static BOOL msgRoamingServiceAvailable = YES;
@interface RCConversationDataSource ()

@property (nonatomic, weak) RCConversationViewController *chatVC;
@property (nonatomic, strong) NSOperationQueue *appendMessageQueue;

@property (nonatomic, assign) BOOL loadHistoryMessageFromRemote;
@property (nonatomic, assign) BOOL isLoadingHistoryMessage;//是否正在加载历史消息
@property (nonatomic, assign) BOOL allMessagesAreLoaded; /// YES  表示所有消息都已加载完 NO 表示还有剩余消息
@property (nonatomic, assign) BOOL isIndicatorLoading;

@property (nonatomic, assign) long long recordTime;
@property (nonatomic, assign) long long showUnreadViewMessageId; //显示查看未读的消息 id

//会话页面的CollectionView Layout
@property (nonatomic, strong) RCConversationViewLayout *customFlowLayout;
@property (nonatomic, strong) RCMessage *firstUnreadMessage; //第一条未读消息,进入会话时存储起来，因为加载消息之后会改变所有消息的未读状态
@end

@implementation RCConversationDataSource
- (instancetype)init:(RCConversationViewController *)chatVC {
    self = [super init];
    if(self) {
        self.chatVC = chatVC;
        self.loadHistoryMessageFromRemote = NO;
        self.allMessagesAreLoaded = YES;
        self.customFlowLayout = [[RCConversationViewLayout alloc] init];
        self.isIndicatorLoading = NO;
        self.unreadNewMsgArr = [NSMutableArray new];

        self.appendMessageQueue = [NSOperationQueue new];
        self.appendMessageQueue.maxConcurrentOperationCount = 1;
        self.appendMessageQueue.name = @"cn.rongcloud.appendMessageQueue";
        self.unreadMentionedMessages = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - 消息数据源处理
- (void)getInitialMessage:(RCConversation *)conversation {
    if(self.chatVC.conversationType == ConversationType_CHATROOM) {
        //聊天室从服务器拉取消息，设置初始状态为为加载完成
        [self joinChatRoomIfNeed];
    }else {
        //非聊天室加载历史数据
        [self loadLatestHistoryMessage];
        self.chatVC.unReadMessage = conversation.unreadMessageCount;
        if (self.chatVC.unReadMessage) {
            self.firstUnreadMessage =
                [[RCIMClient sharedRCIMClient] getFirstUnreadMessage:self.chatVC.conversationType targetId:self.chatVC.targetId];
        }
        if((self.chatVC.conversationType == ConversationType_GROUP || self.chatVC.conversationType == ConversationType_DISCUSSION)) {
            if(RCKitConfigCenter.message.enableMessageMentioned) {
                self.chatVC.chatSessionInputBarControl.isMentionedEnabled = YES;
                if (conversation.hasUnreadMentioned) {
                    self.unreadMentionedMessages =
                        [[[RCIMClient sharedRCIMClient] getUnreadMentionedMessages:self.chatVC.conversationType targetId:self.chatVC.targetId] mutableCopy];
                }
            }
        }else if (self.chatVC.conversationType == ConversationType_CUSTOMERSERVICE) {
            [self.chatVC.csUtil startCustomerService];
        }else if(ConversationType_APPSERVICE == self.chatVC.conversationType ||
                 ConversationType_PUBLICSERVICE == self.chatVC.conversationType) {
            [self.chatVC fetchPublicServiceProfile];
        }
    }
}

- (void)appendAndDisplayMessage:(RCMessage *)rcMessage {
    if (!rcMessage) {
        return;
    }
    __weak typeof(self) ws = self;
    RCConversationViewController *chatVC = self.chatVC;
    [self.appendMessageQueue addOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                if (!chatVC.needAutoScrollToBottom && chatVC.conversationDataRepository.count > 0) {
                    chatVC.needAutoScrollToBottom =
                        [chatVC.conversationMessageCollectionView
                            cellForItemAtIndexPath:[NSIndexPath indexPathForItem:chatVC.conversationDataRepository.count - 1
                                                                       inSection:0]] != nil;
                }

                RCMessageModel *model = [RCMessageModel modelWithMessage:rcMessage];
                [chatVC.util figureOutLatestModel:model];
                if ([ws appendMessageModel:model]) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:chatVC.conversationDataRepository.count - 1 inSection:0];
                    if ([chatVC.conversationMessageCollectionView numberOfItemsInSection:0] !=
                        chatVC.conversationDataRepository.count - 1) {
                        DebugLog(@"Error, datasource and collectionview are inconsistent!!");
                        [chatVC.conversationMessageCollectionView reloadData];
                        return;
                    }
                    [chatVC.conversationMessageCollectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
                    if (chatVC.needAutoScrollToBottom) {
                        [chatVC scrollToBottomAnimated:YES];
                        chatVC.needAutoScrollToBottom = NO;
                    } else {
                        if (chatVC.conversationType == ConversationType_CHATROOM) {
                            [chatVC scrollToBottomAnimated:NO];
                        } else {
                            [chatVC updateUnreadMsgCountLabel];
                        }
                    }
                }
            }
        });
        [NSThread sleepForTimeInterval:0.01];
    }];
}

- (BOOL)appendMessageModel:(RCMessageModel *)model {
    long newId = model.messageId;
    for (RCMessageModel *__item in self.chatVC.conversationDataRepository) {

        /*
         * 当id为－1时，不检查是否重复，直接插入
         * 该场景用于插入临时提示。
         */
        if (newId == -1) {
            break;
        }
        if (newId == __item.messageId) {
            return NO;
        }
    }

    if (newId != -1 && !(!model.content && model.messageId > 0 && RCKitConfigCenter.message.showUnkownMessage) &&
        !([[model.content class] persistentFlag] & MessagePersistent_ISPERSISTED)) {
        return NO;
    }

    model = [self setModelIsDisplayNickName:model];
    if (model.messageDirection != MessageDirection_RECEIVE) {
        if ([self isShowUnreadView:model]) {
            model.isCanSendReadReceipt = YES;
            if (!model.readReceiptInfo) {
                model.readReceiptInfo = [[RCReadReceiptInfo alloc] init];
            }
        }
    }
    [self.chatVC.conversationDataRepository addObject:model];
    return YES;
}

- (BOOL)pushOldMessageModel:(RCMessageModel *)model {
    if (!(!model.content && model.messageId > 0 && RCKitConfigCenter.message.showUnkownMessage) &&
        !([[model.content class] persistentFlag] & MessagePersistent_ISPERSISTED)) {
        return NO;
    }

    long ne_wId = model.messageId;
    for (RCMessageModel *__item in self.chatVC.conversationDataRepository) {

        if (ne_wId == __item.messageId && ne_wId != -1) {
            return NO;
        }
    }
    model = [self setModelIsDisplayNickName:model];

    [self.chatVC.conversationDataRepository insertObject:model atIndex:0];
    return YES;
}

- (void)loadLatestHistoryMessage {
    self.loadHistoryMessageFromRemote = NO;
    int beforeCount = self.chatVC.defaultLocalHistoryMessageCount;
    int afterCount = self.chatVC.defaultLocalHistoryMessageCount;

    if ([RCKitUtility currentDeviceIsIPad]) {
        beforeCount = 15;
        afterCount = 15;
    }
    NSArray *__messageArray = [[RCIMClient sharedRCIMClient] getHistoryMessages:self.chatVC.conversationType
                                                                       targetId:self.chatVC.targetId
                                                                       sentTime:self.chatVC.locatedMessageSentTime
                                                                    beforeCount:beforeCount
                                                                     afterCount:afterCount];
    [self.chatVC.util sendReadReceiptResponseForMessages:__messageArray];

    // 1.如果 self.locatedMessageSentTime == 0,
    // ==0,__messageArray.count<self.defaultLocalHistoryMessageCount,证明本地消息已经拉完，如果再次拉取，需要从远端拉消息
    if (self.chatVC.conversationType != ConversationType_CHATROOM) {
        if (!self.chatVC.locatedMessageSentTime && __messageArray.count < self.chatVC.defaultLocalHistoryMessageCount) {
            self.loadHistoryMessageFromRemote = YES;
            self.isLoadingHistoryMessage = NO;
            self.recordTime = ((RCMessage *)__messageArray.lastObject).sentTime;
//            [self loadRemoteHistoryMessages];
        }
        self.allMessagesAreLoaded = NO;
    }

    for (int i = 0; i < __messageArray.count; i++) {
        RCMessage *rcMsg = [__messageArray objectAtIndex:i];
        RCMessageModel *model = [RCMessageModel modelWithMessage:rcMsg];
        if ([model isKindOfClass:[RCCustomerServiceMessageModel class]]) {
            RCCustomerServiceMessageModel *csModel = (RCCustomerServiceMessageModel *)model;
            [csModel disableEvaluate];
        }
        [self pushOldMessageModel:model];
        [self showUnreadViewInMessageCell:model];
        // 2.如果 self.locatedMessageSentTime
        //不为0,判断定位的那条消息之前的消息如果小于拉取的数量self.defaultLocalHistoryMessageCount，则再次拉取需要从远端拉消息，如果定位的那条消息之后的消息大于拉取的数量self.defaultLocalHistoryMessageCount，证明此时已经没有最新消息，isLoadingHistoryMessage
        if (self.chatVC.locatedMessageSentTime && model.sentTime == self.chatVC.locatedMessageSentTime) {
            if (i < self.chatVC.defaultLocalHistoryMessageCount) {
                self.isLoadingHistoryMessage = NO;
            } else {
                self.isLoadingHistoryMessage = YES;
            }
            if (__messageArray.count - 1 - i < self.chatVC.defaultLocalHistoryMessageCount) {
                self.loadHistoryMessageFromRemote = YES;
            }
        }
    }

    [self.chatVC.util figureOutAllConversationDataRepository];
}

- (void)showUnreadViewInMessageCell:(RCMessageModel *)model {
    RCMessageModel *lastModel = self.chatVC.conversationDataRepository.lastObject;

    if (!self.showUnreadViewMessageId && !self.isLoadingHistoryMessage &&
        [RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.chatVC.conversationType)] &&
        (self.chatVC.conversationType == ConversationType_DISCUSSION || self.chatVC.conversationType == ConversationType_GROUP) &&
        lastModel.messageId == model.messageId) {
        if (model.messageDirection == MessageDirection_SEND) {
            NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970] * 1000;
            if (((nowTime - model.sentTime) < 1000 * RCKitConfigCenter.message.maxReadRequestDuration) &&
                [self.chatVC.util enabledReadReceiptMessage:model] && model.sentTime && !model.readReceiptInfo) {
                model.isCanSendReadReceipt = YES;
                self.showUnreadViewMessageId = model.messageId;
                if (!model.readReceiptInfo) {
                    model.readReceiptInfo = [[RCReadReceiptInfo alloc] init];
                }
            }
        }
    }
}

- (void)loadMoreHistoryMessage {
    msgRoamingServiceAvailable = YES;
    
    NSArray *__messageArray = [self loadMoreLocalMessage];
    
    if (__messageArray.count == 0 && self.loadHistoryMessageFromRemote && msgRoamingServiceAvailable &&
        self.chatVC.conversationType != ConversationType_CHATROOM && self.chatVC.conversationType != ConversationType_APPSERVICE &&
        self.chatVC.conversationType != ConversationType_PUBLICSERVICE) {
        [self loadRemoteHistoryMessages];
    }
}

- (NSArray *)loadMoreLocalMessage {
    long lastMessageId = -1;
    self.recordTime = 0;
    if (self.chatVC.conversationDataRepository.count > 0) {
        for (RCMessageModel *model in self.chatVC.conversationDataRepository) {
            if (![model.content isKindOfClass:[RCOldMessageNotificationMessage class]]) {
                lastMessageId = model.messageId;
                self.recordTime = model.sentTime;
                break;
            }
        }
    }
    
    NSArray *__messageArray = [[RCIMClient sharedRCIMClient] getHistoryMessages:self.chatVC.conversationType
                                                                       targetId:self.chatVC.targetId
                                                                oldestMessageId:lastMessageId
                                                                          count:self.chatVC.defaultLocalHistoryMessageCount];
    [self.chatVC.util sendReadReceiptResponseForMessages:__messageArray];
    if (__messageArray.count > 0) {
        [self handleMessagesAfterLoadMore:__messageArray];
        RCMessage *message = __messageArray.lastObject;
        self.recordTime = message.sentTime;
    }
    if (__messageArray.count < self.chatVC.defaultLocalHistoryMessageCount) {
        self.allMessagesAreLoaded = NO;
        self.loadHistoryMessageFromRemote = YES;
//        [self loadRemoteHistoryMessages];
    }
    self.isIndicatorLoading = NO;
    [self.chatVC.collectionViewHeader stopAnimating];
    return __messageArray;;
}


- (void)loadMoreHistoryMessageIfNeed {
    if (!self.isIndicatorLoading && !self.allMessagesAreLoaded) {
        self.isIndicatorLoading = YES;
        [self loadMoreHistoryMessage];
    }
}

- (void)loadRemoteHistoryMessages {
    RCConversationType conversationType = self.chatVC.conversationType;
    NSString *targetId = self.chatVC.targetId;
    __weak typeof(self) weakSelf = self;
    if (conversationType == ConversationType_Encrypted) {
        self.allMessagesAreLoaded = YES;
        [self.chatVC.collectionViewHeader stopAnimating];
        self.isIndicatorLoading = NO;
        return;
    }
    
    RCRemoteHistoryMsgOption *option = [RCRemoteHistoryMsgOption new];
    option.recordTime = self.recordTime;
    option.count = self.chatVC.defaultRemoteHistoryMessageCount;
    option.order = RCRemoteHistoryOrderDesc;
    [[RCIMClient sharedRCIMClient] getRemoteHistoryMessages:conversationType
        targetId:targetId
        option:option
        success:^(NSArray *messages, BOOL isRemaining) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.allMessagesAreLoaded = !isRemaining;
                if (!isRemaining && messages.count == 0) {
                    [weakSelf resetSectionHeaderView];
                } else {
                    [weakSelf handleMessagesAfterLoadMore:messages];
                }
                [weakSelf.chatVC.collectionViewHeader stopAnimating];
                weakSelf.isIndicatorLoading = NO;
            });
        }
        error:^(RCErrorCode status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == MSG_ROAMING_SERVICE_UNAVAILABLE) {
                    msgRoamingServiceAvailable = NO;
                }
                weakSelf.allMessagesAreLoaded = YES;
                [weakSelf resetSectionHeaderView];
                [weakSelf.chatVC.collectionViewHeader stopAnimating];
                weakSelf.isIndicatorLoading = NO;
            });

            DebugLog(@"load remote history message failed(%ld)", (long)status);
        }];
}

- (void)loadMoreNewerMessage {
    RCMessageModel *model = self.chatVC.conversationDataRepository.lastObject;
    NSArray *messageArray = [[RCIMClient sharedRCIMClient] getHistoryMessages:self.chatVC.conversationType
                                                                     targetId:self.chatVC.targetId
                                                                   objectName:nil
                                                                baseMessageId:model.messageId
                                                                    isForward:NO
                                                                        count:self.chatVC.defaultLocalHistoryMessageCount];
    if (!messageArray || messageArray.count < self.chatVC.defaultLocalHistoryMessageCount) {
        self.isLoadingHistoryMessage = NO;
    }
    [self.chatVC.util sendReadReceiptResponseForMessages:messageArray];
    for (RCMessage *message in messageArray) {
        RCMessage *checkedmessage = [self.chatVC willAppendAndDisplayMessage:message];
        if (checkedmessage) {
            [self appendAndDisplayMessage:message];
        }
    }
    self.isIndicatorLoading = NO;
}

/// 返回添加入conversationDataRepository中消息数量
- (NSInteger)appendLastestMessageToDataSource {
    NSArray *messageArray =
        [[RCIMClient sharedRCIMClient] getLatestMessages:self.chatVC.conversationType targetId:self.chatVC.targetId count:self.chatVC.defaultLocalHistoryMessageCount];
    if (!messageArray || messageArray.count < self.chatVC.defaultLocalHistoryMessageCount) {
        self.isLoadingHistoryMessage = NO;
    }
    [self.chatVC.util sendReadReceiptResponseForMessages:messageArray];
    NSInteger count = 0;
    for (RCMessage *message in messageArray.reverseObjectEnumerator.allObjects) {
        RCMessage *checkedmessage = [self.chatVC willAppendAndDisplayMessage:message];
        if (checkedmessage) {
            RCMessageModel *model = [RCMessageModel modelWithMessage:checkedmessage];
            [self.chatVC.util figureOutLatestModel:model];
            [self.chatVC.conversationDataRepository addObject:model];
            count++;
        }
    }
    self.isIndicatorLoading = NO;
    return count;
}

- (void)handleMessagesAfterLoadMore:(NSArray *)__messageArray {
    CGFloat increasedHeight = 0;
    NSMutableArray *indexPathes = [[NSMutableArray alloc] initWithCapacity:self.chatVC.defaultLocalHistoryMessageCount];

    int indexPathCount = 0;
    for (int i = 0; i < __messageArray.count; i++) {
        RCMessage *rcMsg = [__messageArray objectAtIndex:i];
        RCMessageModel *model = [RCMessageModel modelWithMessage:rcMsg];
        //__messageArray 数据源是倒序的，所以采用下列判断
        BOOL showTime = NO;
        if (i == __messageArray.count - 1) {
            showTime = YES;
        } else {
            NSInteger previousIndex = i + 1;
            RCMessageModel *premodel = __messageArray[previousIndex];
            long long previous_time = premodel.sentTime;
            long long current_time = model.sentTime;
            long long interval = llabs(current_time - previous_time);
            showTime = interval / 1000 > 3 * 60;
        }
        if ([model isKindOfClass:[RCCustomerServiceMessageModel class]]) {
            RCCustomerServiceMessageModel *csModel = (RCCustomerServiceMessageModel *)model;
            [csModel disableEvaluate];
        }
        if ([self pushOldMessageModel:model]) {
            [self showUnreadViewInMessageCell:model];
            [indexPathes addObject:[NSIndexPath indexPathForItem:indexPathCount++ inSection:0]];
            CGSize itemSize = [self.chatVC collectionView:self.chatVC.conversationMessageCollectionView
                                            layout:self.customFlowLayout
                            sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            increasedHeight += itemSize.height;
            if (showTime) {
                CGSize size = model.cellSize;
                size.height = model.cellSize.height + 45;
                model.cellSize = size;
                model.isDisplayMessageTime = YES;
                increasedHeight += 45;
            }
        }
        if (self.firstUnreadMessage && rcMsg.messageId == self.firstUnreadMessage.messageId &&
            self.chatVC.enableUnreadMessageIcon) {
            //如果会话里都是未注册自定义消息，这时获取到的数据源是 0，点击右上角未读按钮会崩溃
            if (self.chatVC.conversationDataRepository.count > 0) {
                RCOldMessageNotificationMessage *oldMessageTip = [[RCOldMessageNotificationMessage alloc] init];
                RCMessage *oldMessage = [[RCMessage alloc] initWithType:self.chatVC.conversationType
                                                               targetId:self.chatVC.targetId
                                                              direction:MessageDirection_SEND
                                                              messageId:-1
                                                                content:oldMessageTip];
                RCMessageModel *model = [RCMessageModel modelWithMessage:oldMessage];
                model.messageId = rcMsg.messageId;
                [self.chatVC.conversationDataRepository insertObject:model atIndex:0];
                [indexPathes addObject:[NSIndexPath indexPathForItem:indexPathCount++ inSection:0]];
                CGSize itemSize = [self.chatVC collectionView:self.chatVC.conversationMessageCollectionView
                                                layout:self.customFlowLayout
                                sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
                increasedHeight += itemSize.height;
            }
            [self.chatVC.unReadButton removeFromSuperview];
            self.chatVC.unReadButton = nil;
            self.firstUnreadMessage = nil;
            self.chatVC.unReadMessage = 0;
        }
    }

    if (self.chatVC.conversationDataRepository.count <= 0) {
        return;
    }

    if (indexPathes.count <= 0) {
        return;
    }

    CGSize contentSize = self.chatVC.conversationMessageCollectionView.contentSize;
    contentSize.height += increasedHeight;
    if (self.allMessagesAreLoaded) {
        contentSize.height -= COLLECTION_VIEW_REFRESH_CONTROL_HEIGHT;
    }
    self.customFlowLayout.collectionViewNewContentSize = contentSize;
    if (indexPathes.count <= 0) {
        return;
    }
    [UIView setAnimationsEnabled:NO];
    @try {
        if (self.chatVC.conversationDataRepository.count == 1 ||
            [self.chatVC.conversationMessageCollectionView numberOfItemsInSection:0] ==
                self.chatVC.conversationDataRepository.count) {
            [self.chatVC.conversationMessageCollectionView reloadData];
        } else {
            [self.chatVC.conversationMessageCollectionView insertItemsAtIndexPaths:indexPathes];
        }
        [UIView setAnimationsEnabled:YES];
        [self.chatVC.collectionViewHeader stopAnimating];
        self.isIndicatorLoading = NO;
        if (self.allMessagesAreLoaded) {
            UICollectionViewLayout *layout = self.chatVC.conversationMessageCollectionView.collectionViewLayout;
            [self.chatVC.conversationMessageCollectionView.collectionViewLayout invalidateLayout];
            [self.chatVC.conversationMessageCollectionView setCollectionViewLayout:layout];
        }
    } @catch (NSException *except) {
        DebugLog(@"----handleMessagesAfterLoadMore %@", except.description);
    }
}



#pragma mark - Notification Selector
- (void)didReceiveMessageNotification:(RCMessage *)message leftDic:(NSDictionary *)leftDic {
    __block RCMessage *rcMessage = message;
    RCMessageModel *model = [RCMessageModel modelWithMessage:rcMessage];
    if (model.conversationType == self.chatVC.conversationType && [model.targetId isEqual:self.chatVC.targetId]) {
        [self.chatVC.csUtil startNotReciveMessageAlertTimer];
        if (self.chatVC.isConversationAppear) {
            if (self.chatVC.conversationType != ConversationType_CHATROOM && rcMessage.messageId > 0) {
                [[RCIMClient sharedRCIMClient] setMessageReceivedStatus:rcMessage.messageId
                                                         receivedStatus:ReceivedStatus_READ];
            }
        } else {
            self.chatVC.unReadMessage++;
        }
        Class messageContentClass = model.content.class;

        NSInteger persistentFlag = [messageContentClass persistentFlag];
        //如果开启消息回执，收到消息要发送已读消息，发送失败存入数据库
        if (leftDic && [leftDic[@"left"] isEqual:@(0)]) {
            if (self.chatVC.isConversationAppear && [self.chatVC.targetId isEqualToString:model.targetId] &&
                self.chatVC.conversationType == model.conversationType && model.messageDirection == MessageDirection_RECEIVE &&
                (persistentFlag & MessagePersistent_ISPERSISTED)) {
                if ([RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.chatVC.conversationType)] &&
                    (self.chatVC.conversationType == ConversationType_PRIVATE ||
                     self.chatVC.conversationType == ConversationType_Encrypted)) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self delaySendReadReceiptMessage:model.sentTime];
                    });
                }
            }
        }

        __weak typeof(self) __blockSelf = self;

        dispatch_async(dispatch_get_main_queue(), ^{
            //数量不可能无限制的大，这里限制收到消息过多时，就对显示消息数量进行限制。
            //用户可以手动下拉更多消息，查看更多历史消息。
            [__blockSelf clearOldestMessagesWhenMemoryWarning];
            rcMessage = [self.chatVC willAppendAndDisplayMessage:rcMessage];
            if (rcMessage) {
                if (rcMessage.messageDirection == MessageDirection_SEND) {
                    __blockSelf.showUnreadViewMessageId = rcMessage.messageId;
                }
                if (!self.isLoadingHistoryMessage) {
                    [__blockSelf appendAndDisplayMessage:rcMessage];
                }
                if (rcMessage.messageDirection == MessageDirection_SEND) {
                    [self.appendMessageQueue addOperationWithBlock:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [__blockSelf.chatVC updateForMessageSendSuccess:rcMessage.messageId content:rcMessage.content];
                        });
                    }];
                }
                UIMenuController *menu = [UIMenuController sharedMenuController];
                menu.menuVisible = NO;
                // 是否显示右下未读消息数
                if (__blockSelf.chatVC.enableNewComingMessageIcon == YES && (persistentFlag & MessagePersistent_ISPERSISTED)) {
                    if (![__blockSelf isAtTheBottomOfTableView] &&
                        ![rcMessage.senderUserId isEqualToString:[RCIM sharedRCIM].currentUserInfo.userId]) {
                        [__blockSelf.unreadNewMsgArr addObject:rcMessage];
                        [__blockSelf.chatVC updateUnreadMsgCountLabel];
                    }
                }
                if(![__blockSelf isAtTheBottomOfTableView] && ![rcMessage.senderUserId isEqualToString:[RCIM sharedRCIM].currentUserInfo.userId]){
                    RCMentionedInfo *mentionedInfo = rcMessage.content.mentionedInfo;
                    if (mentionedInfo.isMentionedMe) {
                        [self.unreadMentionedMessages addObject:rcMessage];
                        [self setupUnReadMentionedButton];
                    }
                }

            }
        });
    } else {
        if (leftDic && [leftDic[@"left"] isEqual:@(0)]) {
            [self.chatVC notifyUpdateUnreadMessageCount];
        }
    }
}

#pragma mark - util
- (void)joinChatRoomIfNeed {
    if(self.chatVC.conversationType != ConversationType_CHATROOM) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[RCChatRoomClient sharedChatRoomClient] joinChatRoom:self.chatVC.targetId
    messageCount:self.chatVC.defaultHistoryMessageCountOfChatRoom
    success:^{
    }
    error:^(RCErrorCode status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == KICKED_FROM_CHATROOM) {
                [weakSelf.chatVC alertErrorAndLeft:RCLocalizedString(@"JoinChatRoomRejected")];
            } else {
                [weakSelf.chatVC
                    alertErrorAndLeft:RCLocalizedString(@"JoinChatRoomFailed")];
            }
        });
    }];
}

- (void)quitChatRoomIfNeed {
    if (self.chatVC.conversationType == ConversationType_CHATROOM) {
        [[RCChatRoomClient sharedChatRoomClient] quitChatRoom:self.chatVC.targetId
            success:^{

            }
            error:^(RCErrorCode status){

            }];
    }
}
- (RCMessageModel *)setModelIsDisplayNickName:(RCMessageModel *)model {
    if (!model) {
        return nil;
    }
    if (model.messageDirection == MessageDirection_RECEIVE) {
        model.isDisplayNickname = self.chatVC.displayUserNameInCell;
    } else {
        model.isDisplayNickname = NO;
    }
    return model;
}

- (void)appendSendOutMessage:(RCMessage *)message {
    __weak typeof(self) __weakself = self;
    RCConversationViewController *chatVC = self.chatVC;
    dispatch_async(dispatch_get_main_queue(), ^{
        RCMessage *tempMessage = [chatVC willAppendAndDisplayMessage:message];
        __weakself.showUnreadViewMessageId = message.messageId;
        [__weakself appendAndDisplayMessage:tempMessage];
    });
}

- (void)didRecallMessage:(RCMessage *)recalledMsg{
    // 更新右下角未读数(条件：同一个会话／开启提示／未在底部／不是搜索进入的界面／未读数不为0)
    if (self.chatVC.enableNewComingMessageIcon && recalledMsg.conversationType == self.chatVC.conversationType &&
        [recalledMsg.targetId isEqual:self.chatVC.targetId] && ![self isAtTheBottomOfTableView] &&
        self.chatVC.locatedMessageSentTime == 0 && self.unreadNewMsgArr.count != 0) {
        for (RCMessage *messagge in self.unreadNewMsgArr) {
            if (messagge.messageId == recalledMsg.messageId) {
                [self.unreadNewMsgArr removeObject:messagge];
                break;
            }
        }
        
        if (self.firstUnreadMessage) {
            self.firstUnreadMessage = recalledMsg;

        }
        [self.chatVC updateUnreadMsgCountLabel];
    }
    [self didReloadRecalledMessage:recalledMsg.messageId];
}

- (void)removeMentionedMessage:(long )curMessageId {
    if (self.unreadMentionedMessages.count <= 0 || !curMessageId) {
        return;
    }
    NSArray *tempUnreadMentionedMessages = self.unreadMentionedMessages;
    for (RCMessage *message in tempUnreadMentionedMessages) {
        if (message.messageId == curMessageId) {
            [self.unreadMentionedMessages removeObject:message];
            [self setupUnReadMentionedButton];
            break;
        }
    }
}

- (void)didReloadRecalledMessage:(long)recalledMsgId {
    int index = -1;
    RCMessageModel *msgModel;
    for (int i = 0; i < self.chatVC.conversationDataRepository.count; i++) {
        msgModel = [self.chatVC.conversationDataRepository objectAtIndex:i];
        if (msgModel.messageId == recalledMsgId &&
            ![msgModel.content isKindOfClass:[RCOldMessageNotificationMessage class]]) {
            index = i;
            break;
        }
    }
    if (index >= 0) {
        NSIndexPath *indexPath =  [NSIndexPath indexPathForRow:index inSection:0];
        [self.chatVC.conversationDataRepository removeObject:msgModel];
        RCMessage *newMsg = [[RCIMClient sharedRCIMClient] getMessage:recalledMsgId];
        if (newMsg) {
            RCMessageModel *newModel = [RCMessageModel modelWithMessage:newMsg];
            newModel.isDisplayMessageTime = msgModel.isDisplayMessageTime;
            newModel.isDisplayNickname = msgModel.isDisplayNickname;
            [self.chatVC.conversationDataRepository insertObject:newModel atIndex:index];
            [self.chatVC.conversationMessageCollectionView reloadItemsAtIndexPaths:@[ indexPath ]];
        } else {
            [self.chatVC.conversationMessageCollectionView deleteItemsAtIndexPaths:@[ indexPath ]];
        }
    }
}

- (void)scrollToLoadMoreHistoryMessage {
    self.isIndicatorLoading = YES;
    [self performSelector:@selector(loadMoreHistoryMessage) withObject:nil afterDelay:0.5f];
}

- (void)scrollToLoadMoreNewerMessage {
    self.isIndicatorLoading = YES;
    [self performSelector:@selector(loadMoreNewerMessage) withObject:nil afterDelay:0.5f];
}

- (void)scrollToSuitablePosition {
    //滚动到用户指定时间的消息
    [self scrollToLocatedMessage];
}

- (void)cancelAppendMessageQueue {
    [self.appendMessageQueue cancelAllOperations];
}

- (void)tapRightBottomMsgCountIcon:(UIGestureRecognizer *)gesture {
    [self.unreadNewMsgArr removeAllObjects];
    if (gesture.state == UIGestureRecognizerStateEnded) {
        NSInteger count = 0;
        if (self.isLoadingHistoryMessage) {
            count = [self appendLastestMessageToDataSource];
            NSInteger totalcount = self.chatVC.conversationDataRepository.count;
            /// 0.35 的作用时在滚动动画完成后执行 滚动动画的执行时间大约是0.35
            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.chatVC.conversationDataRepository removeObjectsInRange:NSMakeRange(0, totalcount - count)];
                    [self.chatVC.conversationMessageCollectionView reloadData];
                });
        }
        [self.chatVC scrollToBottomAnimated:YES];
    }
    self.isLoadingHistoryMessage = NO;
}

- (void)tapRightTopMsgUnreadButton {
    self.isLoadingHistoryMessage = YES;
    [self getSpecifiedPositionMessage:self.firstUnreadMessage ifUnReadMentionedButton:NO];
}

- (void)addOldMessageNotificationMessage {
    if (self.chatVC.unReadButton != nil && self.chatVC.enableUnreadMessageIcon) {
        //如果会话里都是未注册自定义消息，这时获取到的数据源是 0，点击右上角未读按钮会崩溃
        if (self.chatVC.conversationDataRepository.count > 0) {
            RCOldMessageNotificationMessage *oldMessageTip = [[RCOldMessageNotificationMessage alloc] init];
            RCMessage *oldMessage = [[RCMessage alloc] initWithType:self.chatVC.conversationType
                                                           targetId:self.chatVC.targetId
                                                          direction:MessageDirection_SEND
                                                          messageId:-1
                                                            content:oldMessageTip];
            RCMessageModel *model = [RCMessageModel modelWithMessage:oldMessage];
            RCMessageModel *lastMessageModel = [self.chatVC.conversationDataRepository objectAtIndex:0];
            model.messageId = lastMessageModel.messageId;
            [self.chatVC.conversationDataRepository insertObject:model atIndex:0];
        }
        [self.chatVC.unReadButton removeFromSuperview];
        self.chatVC.unReadButton = nil;
        self.chatVC.unReadMessage = 0;
    }
}

- (void)getSpecifiedPositionMessage:(RCMessage *)baseMeassage ifUnReadMentionedButton:(BOOL)ifUnReadMentionedButton{
    [self.chatVC.conversationDataRepository removeAllObjects]; //移除所有的已经加载的消息，页面只剩下从第一条未读开始的消息
    NSArray *__messageArray;
    NSArray *tempArray;
    NSMutableArray *oldMessageArray;
    BOOL ifNewMsgMentioned = NO;
    RCMessage * firstNewMsg = self.unreadNewMsgArr.firstObject;
    if (firstNewMsg && baseMeassage.sentTime >= firstNewMsg.sentTime && ifUnReadMentionedButton) {
        //点击的是新消息中的@消息
        __messageArray = [[RCIMClient sharedRCIMClient] getHistoryMessages:self.chatVC.conversationType
                                                                  targetId:self.chatVC.targetId
                                                                  sentTime:baseMeassage.sentTime
                                                               beforeCount:self.chatVC.defaultLocalHistoryMessageCount
                                                                afterCount:self.chatVC.defaultLocalHistoryMessageCount];
        oldMessageArray = [[NSMutableArray arrayWithArray:__messageArray] mutableCopy];
        [self.chatVC.util sendReadReceiptResponseForMessages:oldMessageArray.copy];
        for (int i = 0; i < oldMessageArray.count; i++) {
            RCMessage *rcMsg = [oldMessageArray objectAtIndex:i];
            RCMessageModel *model = [RCMessageModel modelWithMessage:rcMsg];
            [self pushOldMessageModel:model];
        }

        ifNewMsgMentioned = YES;
        //判断是否是最后一条消息
        NSArray *latestMessageArray = [[RCIMClient sharedRCIMClient] getLatestMessages:self.chatVC.conversationType targetId:self.chatVC.targetId count:1];
        if (latestMessageArray.count > 0) {
            RCMessage *curLastMessage = [oldMessageArray firstObject];
            RCMessage *latestMessage = [latestMessageArray lastObject];
            if (latestMessage.messageId == curLastMessage.messageId) {
                self.chatVC.unreadRightBottomIcon.hidden = YES;
                [self.unreadNewMsgArr removeAllObjects];
            }
        }
    }else {
        __messageArray = [[RCIMClient sharedRCIMClient] getHistoryMessages:self.chatVC.conversationType
                                                                  targetId:self.chatVC.targetId
                                                                objectName:nil
                                                             baseMessageId:baseMeassage.messageId
                                                                 isForward:NO
                                                                     count:self.chatVC.defaultLocalHistoryMessageCount];
        tempArray = [[__messageArray reverseObjectEnumerator] allObjects];
        oldMessageArray = [NSMutableArray arrayWithArray:tempArray];
        [oldMessageArray addObject:baseMeassage];
        [self.chatVC.util sendReadReceiptResponseForMessages:oldMessageArray.copy];
        for (int i = 0; i < oldMessageArray.count; i++) {
            RCMessage *rcMsg = [oldMessageArray objectAtIndex:i];
            RCMessageModel *model = [RCMessageModel modelWithMessage:rcMsg];
            [self pushOldMessageModel:model];
        }
        ifNewMsgMentioned = NO;
    }
    [self.chatVC.util figureOutAllConversationDataRepository];
    if (ifUnReadMentionedButton) {
        //点击的未读@消息数按钮
        if (self.chatVC.enableUnreadMessageIcon && self.firstUnreadMessage && baseMeassage && baseMeassage.messageId == self.firstUnreadMessage.messageId) {
            [self addOldMessageNotificationMessage];
        }
    }else {
        //点击的未读消息数按钮
        [self addOldMessageNotificationMessage];
    }
    [self scrollToSpecifiedPosition:ifNewMsgMentioned baseMeassage:baseMeassage];
}

- (void)scrollToSpecifiedPosition:(BOOL)ifUnReadMentioned baseMeassage:(RCMessage *)baseMeassage{
    [self.chatVC.conversationMessageCollectionView reloadData];
    if (self.chatVC.conversationDataRepository.count > 0) {
        if (ifUnReadMentioned) {
            for (int i = 0; i < self.chatVC.conversationDataRepository.count; i++) {
                RCMessageModel *model = self.chatVC.conversationDataRepository[i];
                if (baseMeassage.messageId == model.messageId) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                    [self.chatVC.conversationMessageCollectionView scrollToItemAtIndexPath:indexPath
                                                                   atScrollPosition:UICollectionViewScrollPositionTop
                                                                           animated:NO];
                    break;
                }
            }
        }else {
            [self.chatVC.conversationMessageCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                                           atScrollPosition:UICollectionViewScrollPositionTop
                                                                   animated:YES];
        }
        
    }
}

- (void)setupUnReadMentionedButton {
    if (self.unreadMentionedMessages && self.chatVC.enableUnreadMentionedIcon == YES) {
        if (self.unreadMentionedMessages.count == 0) {
            self.chatVC.unReadMentionedButton.hidden = YES;
        }else{
            self.chatVC.unReadMentionedButton.hidden = NO;
            NSString *unReadMentionedMessagesCount = [NSString stringWithFormat:@"%ld", (long)self.unreadMentionedMessages.count];
            NSString *stringUnReadMentioned = [NSString stringWithFormat:NSLocalizedStringFromTable(@"HaveMentionedMeCount", @"RongCloudKit", nil), unReadMentionedMessagesCount];
            
            self.chatVC.unReadMentionedLabel.text = stringUnReadMentioned;
            [self.chatVC.util adaptUnreadButtonSize:self.chatVC.unReadMentionedLabel];
        }
    }else {
        self.chatVC.unReadMentionedButton.hidden = YES;
    }
}

- (void)tapRightTopUnReadMentionedButton:(UIButton *)sender {
    if (self.unreadMentionedMessages.count <= 0) {
        return;
    }
    
    RCMessage *firstUnReadMentionedMessagge = [self.unreadMentionedMessages firstObject];
    [self getSpecifiedPositionMessage:firstUnReadMentionedMessagge ifUnReadMentionedButton:YES];
    [self.unreadMentionedMessages removeObject:firstUnReadMentionedMessagge];
    [self setupUnReadMentionedButton];

}

- (BOOL)isShowUnreadView:(RCMessageModel *)model {
    if (model.messageDirection == MessageDirection_SEND && model.sentStatus == SentStatus_SENT &&
        model.messageId == self.showUnreadViewMessageId) {
        if ([RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.chatVC.conversationType)] &&
            [self.chatVC.util enabledReadReceiptMessage:model] &&
            (self.chatVC.conversationType == ConversationType_DISCUSSION || self.chatVC.conversationType == ConversationType_GROUP)) {
            return YES;
        }
    }
    return NO;
}


- (void)resetSectionHeaderView {
    self.isIndicatorLoading = YES;
    CGPoint offset = self.chatVC.conversationMessageCollectionView.contentOffset;
    if (!self.allMessagesAreLoaded) {
        offset.y += COLLECTION_VIEW_REFRESH_CONTROL_HEIGHT;
    }
    [UIView setAnimationsEnabled:NO];
    UICollectionViewLayout *layout = self.chatVC.conversationMessageCollectionView.collectionViewLayout;
    [self.chatVC.conversationMessageCollectionView.collectionViewLayout invalidateLayout];
    [self.chatVC.conversationMessageCollectionView setCollectionViewLayout:layout];
    [self.chatVC.conversationMessageCollectionView performBatchUpdates:^{
        self.chatVC.conversationMessageCollectionView.contentOffset = offset;
    }
        completion:^(BOOL finished) {
            self.isIndicatorLoading = NO;
            [UIView setAnimationsEnabled:YES];
        }];
}



- (void)delaySendReadReceiptMessage:(long long)sentTime {
    if (sentTime > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[RCIMClient sharedRCIMClient] sendReadReceiptMessage:self.chatVC.conversationType
                                                         targetId:self.chatVC.targetId
                                                             time:sentTime
                                                          success:nil
                                                            error:nil];
        });
    }
}

//数量不可能无限制的大，这里限制收到消息过多时，就对显示消息数量进行限制。
//用户可以手动下拉更多消息，查看更多历史消息。
- (void)clearOldestMessagesWhenMemoryWarning {
    if (self.chatVC.conversationDataRepository.count > COLLECTION_VIEW_CELL_MAX_COUNT) {
        NSArray *array = [self.chatVC.conversationMessageCollectionView indexPathsForVisibleItems];
        if (array.count > 0) {
            NSIndexPath *indexPath = array.firstObject;
            //当前可见的 cell 是否在即将清理的 200
            //条数据源内，如果在，用户可能正在拉取历史消息，或者查看历史消息，暂不清理，判断大于300，预留100个数据缓冲，避免用户感觉突兀
            if (indexPath.row > 300) {
                NSRange range = NSMakeRange(0, COLLECTION_VIEW_CELL_REMOVE_COUNT);
                [self.chatVC.conversationDataRepository removeObjectsInRange:range];
                [self.chatVC.conversationMessageCollectionView reloadData];
            }
        } else {
            //聊天页面生命周期未结束但是又不在当前展示页面，直接清理
            NSRange range = NSMakeRange(0, COLLECTION_VIEW_CELL_REMOVE_COUNT);
            [self.chatVC.conversationDataRepository removeObjectsInRange:range];
            [self.chatVC.conversationMessageCollectionView reloadData];
        }
    }
}


- (void)scrollToFirstUnreadMentionedMessage {
    if (self.unreadMentionedMessages) {
        for (int j = 0; j < self.unreadMentionedMessages.count; j++) {
            RCMessage *mentionedMsg = [self.unreadMentionedMessages objectAtIndex:j];
            BOOL isFindMentionedMessage = NO;
            for (int i = 0; i < self.chatVC.conversationDataRepository.count; i++) {
                RCMessage *rcMsg = [self.chatVC.conversationDataRepository objectAtIndex:i];
                RCMessageModel *model = [RCMessageModel modelWithMessage:rcMsg];
                if (model.messageId == mentionedMsg.messageId) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                    [self.chatVC.conversationMessageCollectionView scrollToItemAtIndexPath:indexPath
                                                                   atScrollPosition:UICollectionViewScrollPositionTop
                                                                           animated:NO];
                    isFindMentionedMessage = YES;
                    break;
                }
            }
            if (isFindMentionedMessage) {
                break;
            }
        }
    }
}



- (void)scrollToLocatedMessage {
    if (self.chatVC.locatedMessageSentTime != 0) {
        for (int i = 0; i < self.chatVC.conversationDataRepository.count; i++) {
            RCMessageModel *model = self.chatVC.conversationDataRepository[i];
            if (model.sentTime == self.chatVC.locatedMessageSentTime) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                [self.chatVC.conversationMessageCollectionView scrollToItemAtIndexPath:indexPath
                                                               atScrollPosition:UICollectionViewScrollPositionTop
                                                                       animated:NO];
                self.chatVC.locatedMessageSentTime = 0;
                break;
            }
        }
    }
}


- (BOOL)isAtTheBottomOfTableView {
    if (self.isLoadingHistoryMessage)
        return NO;
    if (self.chatVC.conversationMessageCollectionView.contentSize.height <=
        self.chatVC.conversationMessageCollectionView.frame.size.height) {
        return YES;
    }

    if (self.chatVC.conversationMessageCollectionView.contentOffset.y + 200 >=
        (self.chatVC.conversationMessageCollectionView.contentSize.height -
         self.chatVC.conversationMessageCollectionView.frame.size.height)) {
        return YES;
    } else {
        return NO;
    }
}
- (void)clearUnreadMentionedMessages {
    self.unreadMentionedMessages = nil;
}

- (BOOL)isLoadingHistoryMessage {
    if (self.chatVC.conversationDataRepository.count == 0) {
        return NO;
    }
    return _isLoadingHistoryMessage;
}
@end
