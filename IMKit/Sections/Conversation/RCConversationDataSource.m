//
//  RCConversationDataSource.m
//  RongIMKit
//
//  Created by Sin on 2020/7/6.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCConversationDataSource.h"
#import <RongIMLibCore/RongIMLibCore.h>
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
#import "RCAlertView.h"
#import "RCStreamMessageCell.h"
#import "RCConversationDataSource+Edit.h"
#import "RCConversationDataSource+RRS.h"
#import "RCMenuController.h"
#import "RCRRSUtil.h"

typedef enum : NSUInteger {
    RCConversationLoadMessageVersion1,//消息先加载本地，本地加载完之后加载远端
    RCConversationLoadMessageVersion2,//使用消息断档方法异步加载
} RCConversationLoadMessageVersion;

#define COLLECTION_VIEW_REFRESH_CONTROL_HEIGHT 30
#define COLLECTION_VIEW_CELL_MAX_COUNT 3000
#define COLLECTION_VIEW_CELL_REMOVE_COUNT 200

static BOOL msgRoamingServiceAvailable = YES;
@interface RCConversationDataSource ()

@property (nonatomic, weak) RCConversationViewController *chatVC;
@property (nonatomic, strong) NSOperationQueue *appendMessageQueue;

@property (nonatomic, assign) BOOL loadHistoryMessageFromRemote;
@property (nonatomic, assign) BOOL isLoadingHistoryMessage;//是否正在加载历史消息

@property (nonatomic, assign) BOOL isShowingLastestMessage;//是否展示最新的消息

@property (nonatomic, assign) BOOL allMessagesAreLoaded; /// YES  表示所有消息都已加载完 NO 表示还有剩余消息
@property (nonatomic, assign) BOOL isIndicatorLoading;

@property (nonatomic, assign) long long recordTime;
@property (nonatomic, assign) long long showUnreadViewMessageId; //显示查看未读的消息 id

//会话页面的CollectionView Layout
@property (nonatomic, strong) RCConversationViewLayout *customFlowLayout;
@property (nonatomic, strong) RCMessage *firstUnreadMessage; //第一条未读消息,进入会话时存储起来，因为加载消息之后会改变所有消息的未读状态
@property (nonatomic, copy) void(^throttleReloadAction)(void);

@property (nonatomic, assign) RCConversationLoadMessageVersion loadMessageVersion;

//是否因为点击@人按钮, 检查清空未读按钮
@property (nonatomic, assign) BOOL hideUnreadBtnForMentioned;

@end

@implementation RCConversationDataSource
- (instancetype)init:(RCConversationViewController *)chatVC {
    self = [super init];
    if(self) {
        self.cachedReloadMessages = [NSMutableArray new];
        self.chatVC = chatVC;
        self.loadHistoryMessageFromRemote = NO;
        self.allMessagesAreLoaded = NO;
        self.isShowingLastestMessage = YES;
        self.customFlowLayout = [[RCConversationViewLayout alloc] init];
        self.isIndicatorLoading = NO;
        self.unreadNewMsgArr = [NSMutableArray new];

        self.appendMessageQueue = [NSOperationQueue new];
        self.appendMessageQueue.maxConcurrentOperationCount = 1;
        self.appendMessageQueue.name = @"cn.rongcloud.appendMessageQueue";
        self.unreadMentionedMessages = [[NSMutableArray alloc] init];
        self.loadMessageVersion = RCConversationLoadMessageVersion2;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(streamMessageCellDidUpdate:) name:RCStreamMessageCellUpdateEndNotification object:nil];
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
            [[RCCoreClient sharedCoreClient] getFirstUnreadMessage:self.chatVC.conversationType targetId:self.chatVC.targetId completion:^(RCMessage * _Nullable message) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.firstUnreadMessage = message;
                });
            }];
        }
        if((self.chatVC.conversationType == ConversationType_GROUP || self.chatVC.conversationType == ConversationType_DISCUSSION || self.chatVC.conversationType == ConversationType_ULTRAGROUP)) {
            if(RCKitConfigCenter.message.enableMessageMentioned) {
                self.chatVC.chatSessionInputBarControl.isMentionedEnabled = YES;
                self.chatVC.editInputBarControl.isMentionedEnabled = YES;
                if (conversation.hasUnreadMentioned) {
                    self.unreadMentionedMessages =
                        [[[RCCoreClient sharedCoreClient] getUnreadMentionedMessages:self.chatVC.conversationType targetId:self.chatVC.targetId] mutableCopy];
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
                RCMessageModel *model = [RCMessageModel modelWithMessage:rcMessage];
                [chatVC.util figureOutLatestModel:model];
                if ([ws appendMessageModel:model]) {
                    [self.cachedReloadMessages addObject:model];
                    ws.throttleReloadAction();
                }
            }
        });
        [NSThread sleepForTimeInterval:0.01];
    }];
}

- (void(^)(void))getThrottleActionWithTimeInteval:(double)timeInteval action:(void(^)(void))action {
    __block BOOL canAction = NO;
    __weak typeof(self) weakSelf = self;
    return ^{
        if (weakSelf.chatVC.sendMsgAndNeedScrollToBottom) {
            canAction = NO;
            dispatch_main_async_safe(^{
                action();
            });
            return;
        }else if (canAction == NO) {
            canAction = YES;
        } else {
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInteval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!canAction) {
                return;
            }
            canAction = NO;
            action();
        });
    };
}

- (void (^)(void))throttleReloadAction{
    if (!_throttleReloadAction) {
        __weak typeof(self) ws = self;
        _throttleReloadAction = [self getThrottleActionWithTimeInteval:0.3 action:^{
                if(ws.cachedReloadMessages.count <= 0) {
                    return;
                }
                RCConversationViewController *chatVC = ws.chatVC;
                NSUInteger dataRepositorycount = ws.chatVC.conversationDataRepository.count;
                [chatVC.conversationDataRepository addObjectsFromArray:ws.cachedReloadMessages];
            
                // v5
                NSMutableArray *itemToFetchReceipt = [NSMutableArray array];
                [itemToFetchReceipt addObjectsFromArray:ws.cachedReloadMessages];
                [self rrs_fetchReadReceiptV5Info:itemToFetchReceipt];
            
                NSInteger itemsCount = [chatVC.conversationMessageCollectionView numberOfItemsInSection:0];
                NSInteger differenceValue = chatVC.conversationDataRepository.count - itemsCount;
            
                // 符合insert条件才执行
                if (itemsCount > 0 && ws.cachedReloadMessages.count == differenceValue) {
                    NSMutableArray *reloadIndexPaths = [NSMutableArray new];
                    for (int i=0 ; i<ws.cachedReloadMessages.count ; i++) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(dataRepositorycount + i) inSection:0];
                        [reloadIndexPaths addObject:indexPath];
                    }
                    [chatVC.conversationMessageCollectionView insertItemsAtIndexPaths:reloadIndexPaths];
                } else {
                    [chatVC.conversationMessageCollectionView reloadData];
                }

                [ws.cachedReloadMessages removeAllObjects];
       
                if (chatVC.sendMsgAndNeedScrollToBottom || [ws isAtTheBottomOfTableView]) {
                    [chatVC scrollToBottomAnimated:YES];
                    chatVC.sendMsgAndNeedScrollToBottom = NO;
                } else {
                    if (chatVC.conversationType == ConversationType_CHATROOM) {
                        [chatVC scrollToBottomAnimated:NO];
                    } else {
                        [chatVC updateUnreadMsgCountLabel];
                    }
                }
          
        }];
    }
    return _throttleReloadAction;
}

- (BOOL)appendMessageModel:(RCMessageModel *)model {
    long newId = model.messageId;
    /*
     fix:PAASIOSDEV-392
     */
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.chatVC.conversationDataRepository];
    if (self.cachedReloadMessages.count) {
        [array addObjectsFromArray:self.cachedReloadMessages];
    }
    for (RCMessageModel *__item in array) {

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
    
    BOOL isUnknown = [RCKitUtility isUnkownMessage:model.messageId content:model.content];
    if (isUnknown && !RCKitConfigCenter.message.showUnkownMessage) {// 未知消息设置不显示
        return NO;
    }
    if (newId != -1 && !([[model.content class] persistentFlag] & MessagePersistent_ISPERSISTED)) {// 不入库不显示
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
    return YES;
}

- (BOOL)pushOldMessageModel:(RCMessageModel *)model {
    
    BOOL isUnknown = [RCKitUtility isUnkownMessage:model.messageId content:model.content];
    if (isUnknown && !RCKitConfigCenter.message.showUnkownMessage) {// 未知消息设置不显示
        return NO;
    }
    if (!([[model.content class] persistentFlag] & MessagePersistent_ISPERSISTED)) {
        return NO;
    }

    long ne_wId = model.messageId;
    for (RCMessageModel *__item in self.chatVC.conversationDataRepository) {

        if (ne_wId == __item.messageId && ne_wId != -1) {
            return NO;
        }
    }
    model = [self setModelIsDisplayNickName:model];
    if ([self appendMessageModel:model]) {
        [self.chatVC.conversationDataRepository insertObject:model atIndex:0];
    }
    return YES;
}

- (void)loadLatestHistoryMessage {
    if (self.loadMessageVersion == RCConversationLoadMessageVersion1 || self.chatVC.conversationType == ConversationType_CHATROOM) {
        [self loadLatestHistoryMessageV1];
    }else{
        if (self.chatVC.locatedMessageSentTime > 0) {
            [self loadHistorylocatedMessageV2];
        }else{
            [self loadHistoryMessageBeforeTimeV2:0];
            //PAASIOSDEV-77 解决用户点击聊天列表中的"新消息"按钮后, 输入文字频繁刷新问题(isLoadingHistoryMessage为YES, 引起频繁刷新)
            self.isLoadingHistoryMessage = NO;
        }
        
    }
}

- (void)showUnreadViewInMessageCell:(RCMessageModel *)model {
    if ([self isSupportReadReceiptV5]) {
        return;
    }
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
    if (self.loadMessageVersion == RCConversationLoadMessageVersion1 ||  self.chatVC.conversationType == ConversationType_CHATROOM) {
        msgRoamingServiceAvailable = YES;
        NSArray *__messageArray = [self loadMoreLocalMessage];
        
        if (__messageArray.count == 0 && self.loadHistoryMessageFromRemote && msgRoamingServiceAvailable &&
            self.chatVC.conversationType != ConversationType_CHATROOM) {
            [self loadRemoteHistoryMessages];
        }
    }else{
        self.recordTime = 0;
        if (self.chatVC.conversationDataRepository.count > 0) {
            for (RCMessageModel *model in self.chatVC.conversationDataRepository) {
                if (![model.content isKindOfClass:[RCOldMessageNotificationMessage class]]) {
                    self.recordTime = model.sentTime;
                    break;
                }
            }
        }
        [self loadHistoryMessageBeforeTimeV2:self.recordTime];
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
    
    NSArray *__messageArray = [[RCCoreClient sharedCoreClient] getHistoryMessages:self.chatVC.conversationType
                                                                       targetId:self.chatVC.targetId
                                                                oldestMessageId:lastMessageId
                                                                          count:self.chatVC.defaultMessageCount];
    [self.chatVC.util sendReadReceiptResponseForMessages:__messageArray];
    if (__messageArray.count > 0) {
        [self handleMessagesAfterLoadMore:__messageArray];
        RCMessage *message = __messageArray.lastObject;
        self.recordTime = message.sentTime;
    }
    if (__messageArray.count < self.chatVC.defaultMessageCount) {
        self.allMessagesAreLoaded = NO;
        self.loadHistoryMessageFromRemote = YES;
        [self loadRemoteHistoryMessages];
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
    if (conversationType == ConversationType_Encrypted) {
        self.allMessagesAreLoaded = YES;
        [self.chatVC.collectionViewHeader stopAnimating];
        self.isIndicatorLoading = NO;
        return;
    }
    
    RCRemoteHistoryMsgOption *option = [RCRemoteHistoryMsgOption new];
    option.recordTime = self.recordTime;
    option.count = self.chatVC.defaultMessageCount;
    option.order = RCRemoteHistoryOrderDesc;
    __weak __typeof(self)weakSelf = self;
    [[RCCoreClient sharedCoreClient] getRemoteHistoryMessages:conversationType
        targetId:targetId
        option:option
        success:^(NSArray *messages, BOOL isRemaining) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.allMessagesAreLoaded = !isRemaining;
                if (!isRemaining && messages.count == 0) {
                    [strongSelf resetSectionHeaderView];
                } else {
                    [strongSelf handleMessagesAfterLoadMore:messages];
                }
                [strongSelf.chatVC.collectionViewHeader stopAnimating];
                strongSelf.isIndicatorLoading = NO;
            });
        }
        error:^(RCErrorCode status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == MSG_ROAMING_SERVICE_UNAVAILABLE) {
                    msgRoamingServiceAvailable = NO;
                }
                self.allMessagesAreLoaded = YES;
                [self resetSectionHeaderView];
                [self.chatVC.collectionViewHeader stopAnimating];
                self.isIndicatorLoading = NO;
            });

            DebugLog(@"load remote history message failed(%ld)", (long)status);
        }];
}

- (void)loadMoreNewerMessage {
    if (self.loadMessageVersion == RCConversationLoadMessageVersion1 || self.chatVC.conversationType == ConversationType_CHATROOM) {
        [self loadMoreNewerMessageV1];
    }else{
        RCMessageModel *model = self.chatVC.conversationDataRepository.lastObject;
        [self loadHistoryMessageAfterTimeV2:model.sentTime];
    }
}

/// 返回添加入conversationDataRepository中消息数量
- (NSInteger)appendLastestMessageToDataSource {
    NSArray *messageArray =
        [[RCCoreClient sharedCoreClient] getLatestMessages:self.chatVC.conversationType targetId:self.chatVC.targetId count:self.chatVC.defaultMessageCount];
    if (!messageArray || messageArray.count < self.chatVC.defaultMessageCount) {
        self.isLoadingHistoryMessage = NO;
    }
    [self.chatVC.util sendReadReceiptResponseForMessages:messageArray];
    NSInteger count = 0;
    NSMutableArray *itemToFetchReceipt = [NSMutableArray array];
    for (RCMessage *message in messageArray.reverseObjectEnumerator.allObjects) {
        RCMessage *checkedmessage = [self.chatVC willAppendAndDisplayMessage:message];
        if (checkedmessage) {
            RCMessageModel *model = [RCMessageModel modelWithMessage:checkedmessage];
            [self.chatVC.util figureOutLatestModel:model];
            [self.chatVC.conversationDataRepository addObject:model];
            [itemToFetchReceipt addObject:model];
            count++;
        }
    }
    [self rrs_fetchReadReceiptV5Info:itemToFetchReceipt];
    self.isIndicatorLoading = NO;
    return count;
}
- (void)handleMessagesAfterLoadMore:(NSArray *)__messageArray {
    [self handleMessagesAfterLoadMore:__messageArray checkUnreadMessage:YES];
}
- (void)handleMessagesAfterLoadMore:(NSArray *)__messageArray checkUnreadMessage:(BOOL)check {
    CGFloat increasedHeight = 0;
    NSMutableArray *indexPathes = [[NSMutableArray alloc] initWithCapacity:self.chatVC.defaultMessageCount];
    int indexPathCount = 0;
    NSMutableArray *itemToFetchReceipt = [NSMutableArray array];
    
    for (int i = 0; i < __messageArray.count; i++) {
        RCMessage *rcMsg = [__messageArray objectAtIndex:i];
        RCMessageModel *model = [RCMessageModel modelWithMessage:rcMsg];
        //__messageArray 数据源是倒序的，所以采用下列判断
        
        if ([model isKindOfClass:[RCCustomerServiceMessageModel class]]) {
            RCCustomerServiceMessageModel *csModel = (RCCustomerServiceMessageModel *)model;
            [csModel disableEvaluate];
        }
        if ([self pushOldMessageModel:model]) {
            [itemToFetchReceipt addObject:model];
            [self showUnreadViewInMessageCell:model];
            [indexPathes addObject:[NSIndexPath indexPathForItem:indexPathCount++ inSection:0]];
            CGSize itemSize = [self.chatVC collectionView:self.chatVC.conversationMessageCollectionView
                                            layout:self.customFlowLayout
                            sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            increasedHeight += itemSize.height;
            if ([self p_showTime:__messageArray index:i]) {
                CGFloat increment = [RCConversationVCUtil incrementOfTimeLabelBy:model];

                CGSize size = model.cellSize;
                size.height = model.cellSize.height + increment;
                model.cellSize = size;
                model.isDisplayMessageTime = YES;
                increasedHeight += increment;
            }
        }
        if (self.firstUnreadMessage && rcMsg.messageId == self.firstUnreadMessage.messageId &&
            self.chatVC.enableUnreadMessageIcon && !self.chatVC.unReadButton.selected && self.chatVC.unReadMessage > self.chatVC.defaultMessageCount) {
            //如果会话里都是未注册自定义消息，这时获取到的数据源是 0，点击右上角未读按钮会崩溃
            if (self.chatVC.conversationDataRepository.count > 0) {
                RCMessageModel *model = [RCMessageModel modelWithMessage:[self generateOldMessage]];
                model.messageId = rcMsg.messageId;
                [self.chatVC.conversationDataRepository insertObject:model atIndex:0];
                [itemToFetchReceipt addObject:model];
                [indexPathes addObject:[NSIndexPath indexPathForItem:indexPathCount++ inSection:0]];
                CGSize itemSize = [self.chatVC collectionView:self.chatVC.conversationMessageCollectionView
                                                layout:self.customFlowLayout
                                sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
                increasedHeight += itemSize.height;
            }
            if (check) {
                [self.chatVC.unReadButton removeFromSuperview];
                self.chatVC.unReadButton = nil;
                self.chatVC.unReadMessage = 0;
            }
        }
    }
    [self rrs_fetchReadReceiptV5Info:itemToFetchReceipt];

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
    
    [UIView setAnimationsEnabled:NO];
    @try {
        if (self.chatVC.conversationDataRepository.count == 1 ||
            [self.chatVC.conversationMessageCollectionView numberOfItemsInSection:0] ==
                self.chatVC.conversationDataRepository.count) {
            [self.chatVC.conversationMessageCollectionView reloadData];
        } else {
            if (check) { // @人按钮点击后(check=NO) 前边的数据源已经刷新过, 后续scrollToSpecifiedPosition 会重新刷新, 此时, 已无需更新
                // ios15上可能出现只insert不reload，导致cell重用未刷新
                [self.chatVC.conversationMessageCollectionView performBatchUpdates:^{
                    [self.chatVC.conversationMessageCollectionView insertItemsAtIndexPaths:indexPathes];
                } completion:^(BOOL finished) {
                }];
            }
           
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

- (BOOL)p_showTime:(NSArray *)messageArray index:(int)index{
    BOOL showTime = NO;
    if (index == messageArray.count - 1) {
        showTime = YES;
    } else {
        NSInteger previousIndex = index + 1;
        RCMessageModel *premodel = messageArray[previousIndex];
        RCMessage *rcMsg = messageArray[index];

        long long previous_time = premodel.sentTime;
        long long current_time = rcMsg.sentTime;
        long long interval = llabs(current_time - previous_time);
        showTime = interval / 1000 > 3 * 60;
    }
    return showTime;
}

#pragma mark - loadMessageV1
- (void)loadLatestHistoryMessageV1{
    self.loadHistoryMessageFromRemote = NO;
    int beforeCount = self.chatVC.defaultMessageCount;
    int afterCount = self.chatVC.defaultMessageCount;

    if ([RCKitUtility currentDeviceIsIPad]) {
        beforeCount = 15;
        afterCount = 15;
    }
    NSArray *__messageArray = [[RCCoreClient sharedCoreClient] getHistoryMessages:self.chatVC.conversationType
                                                                       targetId:self.chatVC.targetId
                                                                       sentTime:self.chatVC.locatedMessageSentTime
                                                                    beforeCount:beforeCount
                                                                     afterCount:afterCount];
    [self.chatVC.util sendReadReceiptResponseForMessages:__messageArray];

    // 1.如果 self.locatedMessageSentTime == 0,
    // ==0,__messageArray.count<self.defaultMessageCount,证明本地消息已经拉完，如果再次拉取，需要从远端拉消息
    if (self.chatVC.conversationType != ConversationType_CHATROOM) {
        if (!self.chatVC.locatedMessageSentTime && __messageArray.count < self.chatVC.defaultMessageCount) {
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
        //不为0,判断定位的那条消息之前的消息如果小于拉取的数量self.defaultMessageCount，则再次拉取需要从远端拉消息，如果定位的那条消息之后的消息大于拉取的数量self.defaultMessageCount，证明此时已经没有最新消息，isLoadingHistoryMessage
        if (self.chatVC.locatedMessageSentTime && model.sentTime == self.chatVC.locatedMessageSentTime) {
            if (i < self.chatVC.defaultMessageCount) {
                self.isLoadingHistoryMessage = NO;
            } else {
                self.isLoadingHistoryMessage = YES;
            }
            if (__messageArray.count - 1 - i < self.chatVC.defaultMessageCount) {
                self.loadHistoryMessageFromRemote = YES;
            }
        }
    }
    [self.chatVC.util figureOutAllConversationDataRepository];
    [self handleAfterLoadLastestMessage];
}

- (void)loadMoreNewerMessageV1{
    RCMessageModel *model = self.chatVC.conversationDataRepository.lastObject;
    NSArray *messageArray = [[RCCoreClient sharedCoreClient] getHistoryMessages:self.chatVC.conversationType
                                                                     targetId:self.chatVC.targetId
                                                                   objectName:nil
                                                                baseMessageId:model.messageId
                                                                    isForward:NO
                                                                        count:self.chatVC.defaultMessageCount];
    if (!messageArray || messageArray.count < self.chatVC.defaultMessageCount) {
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

#pragma mark - loadMessageV2

- (void)loadHistorylocatedMessageV2{
    __weak typeof(self) weakSelf = self;
    [self getHistoryMessageV2:self.chatVC.locatedMessageSentTime+1 order:RCHistoryMessageOrderDesc loadType:self.chatVC.loadMessageType complete:^(NSArray *oldMsgs, BOOL isRemaining, RCConversationLoadMessageType type, BOOL isDoubleCallback) {
        long long time = self.chatVC.locatedMessageSentTime-1;
        if (oldMsgs.count > 0) {
            RCMessage *msg = oldMsgs.firstObject;
            time = msg.sentTime;
        }
        [self getHistoryMessageV2:time order:RCHistoryMessageOrderAsc loadType:type complete:^(NSArray *newMsgs, BOOL isRemaining, RCConversationLoadMessageType type, BOOL isDoubleCallback) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (oldMsgs.count < strongSelf.chatVC.defaultMessageCount) {
                strongSelf.allMessagesAreLoaded = YES;
            }else{
                strongSelf.allMessagesAreLoaded = NO;
            }
            if (newMsgs.count < strongSelf.chatVC.defaultMessageCount) {
                weakSelf.isLoadingHistoryMessage = NO;
            }else{
                strongSelf.isLoadingHistoryMessage = YES;
            }
            NSMutableArray *msgArr = [[NSMutableArray alloc] init];
            [msgArr addObjectsFromArray:[[newMsgs reverseObjectEnumerator] allObjects]];
            [msgArr addObjectsFromArray:oldMsgs];
            [strongSelf loadLatestHistoryMessageV2:msgArr isDoubleCallback:isDoubleCallback];
        }];
    }];
}

- (void)loadHistoryMessageBeforeTimeV2:(long long)time{
    __weak typeof(self) weakSelf = self;
    [self getHistoryMessageV2:time order:RCHistoryMessageOrderDesc loadType:self.chatVC.loadMessageType complete:^(NSArray *messages, BOOL isRemaining, RCConversationLoadMessageType type, BOOL isDoubleCallback) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.allMessagesAreLoaded = !isRemaining;
        
        if (messages.count > 0) {
            if (time == 0) {
                [strongSelf loadLatestHistoryMessageV2:messages isDoubleCallback:isDoubleCallback];
            }else{
                [strongSelf.chatVC.util sendReadReceiptResponseForMessages:messages];
                [strongSelf handleMessagesAfterLoadMore:messages];
                RCMessage *message = messages.lastObject;
                strongSelf.recordTime = message.sentTime;
            }
        }
    }];
}

- (void)loadHistoryMessageAfterTimeV2:(long long)time{
    __weak typeof(self) weakSelf = self;
    [self getHistoryMessageV2:time order:RCHistoryMessageOrderAsc loadType:self.chatVC.loadMessageType complete:^(NSArray *messages, BOOL isRemaining, RCConversationLoadMessageType type, BOOL isDoubleCallback) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (messages.count < strongSelf.chatVC.defaultMessageCount) {
            strongSelf.isLoadingHistoryMessage = NO;
        }else{
            strongSelf.isLoadingHistoryMessage = YES;
        }
        [strongSelf loadMoreNewerMessageV2:messages];
    }];
}

// 只有首次加载数据才会触发 double callback，isDoubleCallback 表明两次返回同一批数据源（第一次返回本地数据，第二次返回远端数据， 以第二次数据为准）
- (void)loadLatestHistoryMessageV2:(NSArray *)messages isDoubleCallback:(BOOL)isDoubleCallback {
    if (messages.count <= 0) {
        return;
    }
    [self.chatVC.util sendReadReceiptResponseForMessages:messages];
    if (self.chatVC.conversationType != ConversationType_CHATROOM) {
        if (!self.chatVC.locatedMessageSentTime && messages.count < self.chatVC.defaultMessageCount) {
            self.isLoadingHistoryMessage = NO;
            self.recordTime = ((RCMessage *)messages.lastObject).sentTime;
        }
    }

    // 只有首次加载数据才会触发 double callback，isDoubleCallback 表明两次返回同一批数据源（第一次返回本地数据，第二次返回远端数据， 以第二次数据为准）， 需要先 remove 第一批的数据
    if (isDoubleCallback) {
        [self.chatVC.conversationDataRepository removeAllObjects];
    }
    NSMutableArray *itemToFetchReceipt = [NSMutableArray array];
    
    for (int i = 0; i < messages.count; i++) {
        RCMessage *rcMsg = [messages objectAtIndex:i];
        RCMessageModel *model = [RCMessageModel modelWithMessage:rcMsg];
        if ([self pushOldMessageModel:model]) {
            [itemToFetchReceipt addObject:model];
        }
        [self showUnreadViewInMessageCell:model];
    }
    [self rrs_fetchReadReceiptV5Info:itemToFetchReceipt];
    [self.chatVC.util figureOutAllConversationDataRepository];
    [self.chatVC.conversationMessageCollectionView reloadData];
    [self handleAfterLoadLastestMessage];
}

- (void)loadMoreNewerMessageV2:(NSArray *)messages{
    if (messages.count <= 0) {
        return;
    }
    [self.chatVC.util sendReadReceiptResponseForMessages:messages];
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSMutableArray *itemToFetchReceipt = [NSMutableArray array];
    for (RCMessage *message in messages) {
        RCMessage *checkedmessage = [self.chatVC willAppendAndDisplayMessage:message];
        if (checkedmessage) {
            RCMessageModel *model = [RCMessageModel modelWithMessage:message];
            [self.chatVC.util figureOutLatestModel:model];
            if ([self appendMessageModel:model]) {
                [self.chatVC.conversationDataRepository addObject:model];
                [itemToFetchReceipt addObject:model];
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.chatVC.conversationDataRepository.count - 1 inSection:0];
                [indexPaths addObject:indexPath];
            }
        }
    }
    [self rrs_fetchReadReceiptV5Info:itemToFetchReceipt];
    if (indexPaths.count > 0) {
        /* bugfix:PAASIOSDEV-259
         调用在 insertItemsAtIndexPaths 时, 需要满足以下公式:
         要更新的indexPaths 数量 + 当前collectionView的cell数量 = 数据源数量
         否则 会导致 App 在 iOS 12 crash
         */
        
        [self.chatVC.conversationMessageCollectionView reloadData];
    }
}
    
// 只有首次加载数据才会触发 double callback，isDoubleCallback 表明两次返回同一批数据源（第一次返回本地数据，第二次返回远端数据， 以第二次数据为准）
- (void)getHistoryMessageV2:(long long)time order:(RCHistoryMessageOrder)order loadType:(RCConversationLoadMessageType)loadType complete:(void (^)(NSArray *messages, BOOL isRemaining, RCConversationLoadMessageType type, BOOL isDoubleCallback))complete{
    RCHistoryMessageOption *option = [[RCHistoryMessageOption alloc] init];
    option.recordTime = time;
    option.count = self.chatVC.defaultMessageCount;
    option.order = order;
    __weak typeof(self) weakSelf = self;
    
    void (^updateMessageListBlock)(NSArray *messages, BOOL isRemaining, RCErrorCode code, BOOL isDoubleCallback) = ^(NSArray *messages, BOOL isRemaining, RCErrorCode code, BOOL isDoubleCallback) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.isIndicatorLoading = NO;
            [strongSelf.chatVC.collectionViewHeader stopAnimating];
            if (code == RC_SUCCESS) {
                if (complete) {
                    complete(messages, isRemaining, loadType, isDoubleCallback);
                }
            }else{
                switch (loadType) {
                    case RCConversationLoadMessageTypeAlways:{
                        if (complete) {
                            complete(messages, isRemaining,loadType, isDoubleCallback);
                        }
                    }break;
                    case RCConversationLoadMessageTypeAsk:{
                        [RCAlertView showAlertController:nil message:RCLocalizedString(@"LoadMsgAskInfo") actionTitles:nil cancelTitle:RCLocalizedString(@"Cancel") confirmTitle:RCLocalizedString(@"OK") preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:^{
                            if (complete) {
                                complete(messages, isRemaining, RCConversationLoadMessageTypeAlways, isDoubleCallback);
                            }
                        } inViewController:strongSelf.chatVC];
                    }break;
                    default:
                        break;
                }
            }
        });
    };
    
    
    void (^completeHandle)(NSArray *messages, BOOL isRemaining, RCErrorCode code, BOOL isDoubleCallback) = ^(NSArray *messages, BOOL isRemaining, RCErrorCode code, BOOL isDoubleCallback) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf edit_refreshReferenceMessage:messages complete:^(NSArray<RCMessage *> *results) {
            updateMessageListBlock(results, isRemaining, code, isDoubleCallback);
        }];
    };
    
    if (self.chatVC.conversationType == ConversationType_ULTRAGROUP) {
        [[RCChannelClient sharedChannelManager] getMessages:self.chatVC.conversationType targetId:self.chatVC.targetId channelId:self.chatVC.channelId option:option complete:^(NSArray<RCMessage *> * _Nullable messages, long long timestamp, BOOL isRemaining, RCErrorCode code) {
            completeHandle(messages, isRemaining, code, NO);
        } error:^(RCErrorCode status) {
            completeHandle(nil, YES, status, NO);
        }];
    } else {
        // 首页加载，time 为 0 时，才需要先加载本地
        BOOL isFirstLoadLocal = (0 == time);
        if (isFirstLoadLocal) {
            // 普通单群聊, 自 V5.6.1, 先读取本地，再读取断档接口
            // 解决弱网下首页白屏问题
            // 1. 先读取本地
            [[RCCoreClient sharedCoreClient] getHistoryMessages:self.chatVC.conversationType targetId:self.chatVC.targetId oldestMessageId:-1 count:self.chatVC.defaultMessageCount completion:^(NSArray<RCMessage *> * _Nullable messages) {
                completeHandle(messages, YES, RC_SUCCESS, NO);

                // 2. 再读取断档接口
                [[RCChannelClient sharedChannelManager] getMessages:self.chatVC.conversationType targetId:self.chatVC.targetId channelId:self.chatVC.channelId option:option complete:^(NSArray<RCMessage *> * _Nullable messages, long long timestamp, BOOL isRemaining, RCErrorCode code) {
                    // 因为消息列表做了排重，需要先清空步骤 1 拉取到的消息，防止断档拉到的消息排序有问题
                    // 清空数据源的操作，由二次回调，通知上一级调用者来统一操作（防止数据源和UI数据不一致），清空后再使用本次返回的消息
                    // isDoubleCallback YES 表明两次返回同一批数据源（第一次返回本地数据，第二次返回远端数据， 以第二次数据为准）， 调用者需要先 remove 第一次的数据
                    completeHandle(messages, isRemaining, code, YES);
                } error:^(RCErrorCode status) {
                    completeHandle(nil, YES, status, YES);
                }];
            }];
        }else {
            [[RCChannelClient sharedChannelManager] getMessages:self.chatVC.conversationType targetId:self.chatVC.targetId channelId:self.chatVC.channelId option:option complete:^(NSArray<RCMessage *> * _Nullable messages, long long timestamp, BOOL isRemaining, RCErrorCode code) {
                completeHandle(messages, isRemaining, code, NO);
            } error:^(RCErrorCode status) {
                completeHandle(nil, YES, status, NO);
            }];
        }
    }
}

- (void)handleAfterLoadLastestMessage{
    [self.chatVC updateUnreadMsgCountLabel];
    if (self.chatVC.unReadMessage > 0) {
        [self.chatVC.util syncReadStatus];
        [self.chatVC.util sendReadReceipt];
        [[RCCoreClient sharedCoreClient] clearMessagesUnreadStatus:self.chatVC.conversationType targetId:self.chatVC.targetId completion:^(BOOL ret) {
            /// 清除完未读数需要通知更新UI
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.chatVC notifyUpdateUnreadMessageCount];
            });
        }];
    }

    if (self.chatVC.conversationDataRepository.count == 0 && self.chatVC.unReadButton != nil) {
        [self.chatVC.unReadButton removeFromSuperview];
        self.chatVC.unReadMessage = 0;
    }
    if (self.chatVC.unReadMessage > self.chatVC.defaultMessageCount && self.chatVC.enableUnreadMessageIcon == YES && !self.chatVC.unReadButton.selected) {
        [self.chatVC setupUnReadMessageView];
    }
    if (self.chatVC.locatedMessageSentTime > 0) {
        [self scrollToSuitablePosition];
    }else{
        [self.chatVC scrollToBottomAnimated:NO];
    }
    [self setupUnReadMentionedButton];
}

#pragma mark - Notification Selector
- (void)didReceiveMessageNotification:(RCMessage *)message leftDic:(NSDictionary *)leftDic {
    __block RCMessage *rcMessage = message;
    RCMessageModel *model = [RCMessageModel modelWithMessage:rcMessage];
    if ([self p_enableCurrentConversation:message]) {
        [self.chatVC.csUtil startNotReciveMessageAlertTimer];
        [self p_setMessageReadStats:rcMessage];
        
        Class messageContentClass = model.content.class;

        NSInteger persistentFlag = [messageContentClass persistentFlag];
        //如果开启消息回执，收到消息要发送已读消息，发送失败存入数据库
        if (leftDic && [leftDic[@"left"] isEqual:@(0)]) {
            [self p_receiveMessageAndUpdateReadStatus:message persistentFlag:persistentFlag];
        }

        __weak typeof(self) __blockSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(__blockSelf) strongSelf = __blockSelf;

            if (!strongSelf.chatVC.isViewLoaded && (persistentFlag & MessagePersistent_ISCOUNTED)) {
                strongSelf.chatVC.unReadMessage++;
            }
            //数量不可能无限制的大，这里限制收到消息过多时，就对显示消息数量进行限制。
            //用户可以手动下拉更多消息，查看更多历史消息。
            [strongSelf clearOldestMessagesWhenMemoryWarning];
            rcMessage = [strongSelf.chatVC willAppendAndDisplayMessage:rcMessage];
            if (rcMessage) {
                if (rcMessage.messageDirection == MessageDirection_SEND) {
                    strongSelf.showUnreadViewMessageId = rcMessage.messageId;
                }
                if (!strongSelf.isLoadingHistoryMessage) {
                    [strongSelf appendAndDisplayMessage:rcMessage];
                }
                if (rcMessage.messageDirection == MessageDirection_SEND) {
                    [strongSelf.appendMessageQueue addOperationWithBlock:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [strongSelf.chatVC updateForMessageSendSuccess:rcMessage];
                        });
                    }];
                }
                UIMenuController *menu = [UIMenuController sharedMenuController];
                menu.menuVisible = NO;
                [[RCMenuController sharedMenuController] hideMenuAnimated:NO];
                // 是否显示右下未读消息数
                if (strongSelf.chatVC.enableNewComingMessageIcon == YES
                    && (MessagePersistent_ISCOUNTED == persistentFlag)
                    && ![strongSelf isAtTheBottomOfTableView]
                    && ![rcMessage.senderUserId isEqualToString:[RCIM sharedRCIM].currentUserInfo.userId]) {
                    [strongSelf.unreadNewMsgArr addObject:rcMessage];
                    [strongSelf.chatVC updateUnreadMsgCountLabel];
                }
                if(![strongSelf isAtTheBottomOfTableView] && ![rcMessage.senderUserId isEqualToString:[RCIM sharedRCIM].currentUserInfo.userId]){
                    RCMentionedInfo *mentionedInfo = rcMessage.content.mentionedInfo;
                    if (mentionedInfo.isMentionedMe) {
                        [strongSelf.unreadMentionedMessages addObject:rcMessage];
                        [strongSelf setupUnReadMentionedButton];
                    }
                }

            }
        });
    } else {
        if (leftDic && [leftDic[@"left"] isEqual:@(0)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.chatVC notifyUpdateUnreadMessageCount];
            });
        }
    }
}

- (BOOL)p_enableCurrentConversation:(RCMessage *)message{
    if(message.conversationType == self.chatVC.conversationType && [message.targetId isEqual:self.chatVC.targetId] && ([message.channelId isEqual:self.chatVC.channelId] || (message.channelId.length == 0 && self.chatVC.channelId.length == 0))){
        return YES;
    }
    return NO;
}

- (void)p_setMessageReadStats:(RCMessage *)message {
    if (self.chatVC.isConversationAppear) {
        if (self.chatVC.conversationType != ConversationType_CHATROOM && message.messageId > 0) {
            [message.receivedStatusInfo markAsRead];
            [[RCCoreClient sharedCoreClient] setMessageReceivedStatus:message.messageId
                                                   receivedStatusInfo:message.receivedStatusInfo
                                                           completion:nil];
        }
    }
}

- (void)p_receiveMessageAndUpdateReadStatus:(RCMessage *)model persistentFlag:(NSInteger)persistentFlag{
    if (self.chatVC.isConversationAppear && model.messageDirection == MessageDirection_RECEIVE &&
        (persistentFlag & MessagePersistent_ISPERSISTED)) {
        [self.chatVC.util syncReadStatus:model.sentTime needDelay:YES];
        if (![RCRRSUtil isSupportReadReceiptV5] &&
            [RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.chatVC.conversationType)] &&
            (self.chatVC.conversationType == ConversationType_PRIVATE ||
             self.chatVC.conversationType == ConversationType_Encrypted)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self delaySendReadReceiptMessage:model.sentTime];
            });
        }
    }
}

- (void)setAllMessagesAreLoaded:(BOOL)allMessagesAreLoaded {
    _allMessagesAreLoaded = allMessagesAreLoaded;
    if (allMessagesAreLoaded && [self.loadDelegate respondsToSelector:@selector(noMoreMessageToFetch)]) {
        [self.loadDelegate noMoreMessageToFetch];
    }
}

#pragma mark - util
- (void)joinChatRoomIfNeed {
    if(self.chatVC.conversationType != ConversationType_CHATROOM) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[RCChatRoomClient sharedChatRoomClient] joinChatRoom:self.chatVC.targetId messageCount:self.chatVC.defaultHistoryMessageCountOfChatRoom success:^{
    } error:^(RCErrorCode status) {
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
    [self hideUnreadButtonAfterLoadMetionedMessageWith:model];
    return model;
}

- (void)appendSendOutMessage:(RCMessage *)message {
    __weak typeof(self) __weakself = self;
    RCConversationViewController *chatVC = self.chatVC;

    RCMessage *tempMessage = [chatVC willAppendAndDisplayMessage:message];
    self.showUnreadViewMessageId = message.messageId;
    [self appendAndDisplayMessage:tempMessage];
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
        
        
        [self.chatVC updateUnreadMsgCountLabel];
    }
    if (self.firstUnreadMessage && self.firstUnreadMessage.messageId == recalledMsg.messageId) {
    }
    [self didReloadRecalledMessage:recalledMsg.messageId];
}

//cell 展示时
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
    [[RCCoreClient sharedCoreClient] getMessage:recalledMsgId completion:^(RCMessage * _Nullable newMsg) {
        if (newMsg.messageUId) {
            [self edit_setUIReferenceMessagesEditStatus:RCReferenceMessageStatusRecalled forMessageUIds:@[newMsg.messageUId]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            int index = -1;
            RCMessageModel *msgModel;
            //先过滤延时刷新的消息，再刷新数据源
            if(self.cachedReloadMessages.count > 0) {
                for(int i=0 ; i < self.cachedReloadMessages.count ; i++) {
                    msgModel = [self.cachedReloadMessages objectAtIndex:i];
                    if(msgModel.messageId == recalledMsgId) {
                        index = i;
                        break;
                    }
                }
    
                if(index >= 0) {
                    if(newMsg) {
                        RCMessageModel *newModel = [RCMessageModel modelWithMessage:newMsg];
                        newModel.isDisplayMessageTime = msgModel.isDisplayMessageTime;
                        newModel.isDisplayNickname = msgModel.isDisplayNickname;
                        self.cachedReloadMessages[index] = newModel;
                    }
                    return;
                }
            }
            
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
        });
    }];
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
        if (self.isLoadingHistoryMessage) {
            /// 0.35 的作用时在滚动动画完成后执行 滚动动画的执行时间大约是0.35
            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    NSInteger count = [self appendLastestMessageToDataSource];
                    NSInteger totalcount = self.chatVC.conversationDataRepository.count;
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
    [self loadRightTopUnreadMessages];
}

- (void)addOldMessageNotificationMessage {
    if (self.chatVC.unReadButton != nil && self.chatVC.enableUnreadMessageIcon) {
        //如果会话里都是未注册自定义消息，这时获取到的数据源是 0，点击右上角未读按钮会崩溃
        if (self.chatVC.conversationDataRepository.count > 0) {
            RCMessageModel *model = [RCMessageModel modelWithMessage:[self generateOldMessage]];
            RCMessageModel *lastMessageModel = [self.chatVC.conversationDataRepository objectAtIndex:0];
            model.messageId = lastMessageModel.messageId;
            [self.chatVC.conversationDataRepository insertObject:model atIndex:0];
            if (model) {
                [self rrs_fetchReadReceiptV5Info:@[model]];
            }
        }
        [self.chatVC.unReadButton removeFromSuperview];
        self.chatVC.unReadButton = nil;
        self.chatVC.unReadMessage = 0;
    }
}

- (RCMessage *)generateOldMessage{
    RCOldMessageNotificationMessage *oldMessageTip = [[RCOldMessageNotificationMessage alloc] init];
    RCMessage *oldMessage = [[RCMessage alloc] initWithType:self.chatVC.conversationType targetId:self.chatVC.targetId direction:MessageDirection_SEND content:oldMessageTip];
    return oldMessage;
}

- (void)loadUnReadMentionedMessages{
    RCMessage *firstUnReadMentionedMessagge = [self.unreadMentionedMessages firstObject];
    long long localTime = firstUnReadMentionedMessagge.sentTime;
    __weak typeof(self) weakSelf = self;
    [self getHistoryMessageV2:localTime+1 order:RCHistoryMessageOrderDesc loadType:self.chatVC.loadMessageType complete:^(NSArray *oldMsgs, BOOL isRemaining, RCConversationLoadMessageType type, BOOL isDoubleCallback) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        long long time = localTime-1;
        if (oldMsgs.count > 0) {
            RCMessage *msg = oldMsgs.firstObject;
            time = msg.sentTime;
        }
        __weak typeof(strongSelf) weakSelf2 = strongSelf;

        [strongSelf getHistoryMessageV2:time order:RCHistoryMessageOrderAsc loadType:type complete:^(NSArray *newMsgs, BOOL isRemaining, RCConversationLoadMessageType type, BOOL isDoubleCallback) {
            __strong typeof(weakSelf2) strongSelf2 = weakSelf2;

            NSMutableArray *msgArr = [NSMutableArray array];
            if (oldMsgs != nil) {
                msgArr = [[oldMsgs reverseObjectEnumerator] allObjects].mutableCopy;
            }
            [msgArr addObjectsFromArray:newMsgs];
            
            if (strongSelf2.firstUnreadMessage) {
                for (int i = 0; i < msgArr.count; i ++) {
                    RCMessage *message = msgArr[i];
                    if(message.messageId == strongSelf2.firstUnreadMessage.messageId){
                        RCMessage *oldMsg = [strongSelf2 generateOldMessage];
                        if(oldMsg) {
                            [msgArr insertObject:oldMsg atIndex:i];
                        }
                        break;
                    }
                }
            }
            //移除所有的已经加载的消息
            [strongSelf2.chatVC.conversationDataRepository removeAllObjects];
            [strongSelf2.chatVC.conversationMessageCollectionView reloadData];
            /*
             bugID=50466:
             reloadData 之后 collectionView 还没有完成渲染, 此时直接访问 collectionView 的 UI 内容会有问题, 需要先标记视图
             为脏数据, 再启用渲染, 之后的 UI 访问才能正常
             */
            [strongSelf2.chatVC.conversationMessageCollectionView setNeedsLayout];
            [strongSelf2.chatVC.conversationMessageCollectionView layoutIfNeeded];

            [strongSelf2 loadMoreNewerMessageV2:msgArr];
           
            [strongSelf2 scrollToSpecifiedPosition:YES baseMeassage:firstUnReadMentionedMessagge];
            // message 加载完成后, 再次滚动需要检测是否移除未读消息按钮
            if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"18.0")) {
                if (firstUnReadMentionedMessagge.messageId == self.firstUnreadMessage.messageId) {
                    self.hideUnreadBtnForMentioned = NO;
                    [self.chatVC.unReadButton removeFromSuperview];
                    self.chatVC.unReadButton = nil;
                    self.chatVC.unReadMessage = 0;
                } else {
                    strongSelf2.hideUnreadBtnForMentioned = YES;
                }
            } else {
                strongSelf2.hideUnreadBtnForMentioned = YES;
            }

            //判断是否是最后一条消息,如果是，隐藏底部新消息按钮
            NSArray *latestMessageArray = [[RCCoreClient sharedCoreClient] getLatestMessages:weakSelf.chatVC.conversationType targetId:weakSelf.chatVC.targetId count:1];
            if (latestMessageArray.count > 0) {
                RCMessage *curLastMessage = [msgArr lastObject];
                RCMessage *latestMessage = [latestMessageArray lastObject];
                if (latestMessage.messageId == curLastMessage.messageId) {
                    strongSelf2.chatVC.unreadRightBottomIcon.hidden = YES;
                    [strongSelf2.unreadNewMsgArr removeAllObjects];
                }
            }
            [strongSelf2.unreadMentionedMessages removeObject:firstUnReadMentionedMessagge];
            [strongSelf2 setupUnReadMentionedButton];
        }];
    }];
}

- (void)hideUnreadButtonAfterLoadMetionedMessageWith:(RCMessageModel *)message {
// bugfix: 50540
    if (!self.hideUnreadBtnForMentioned) {
        return;
    }
    if (self.chatVC.unReadMessage == 0) {
        self.hideUnreadBtnForMentioned = NO;
        return;
    }
    if(message.messageId == self.firstUnreadMessage.messageId) {
        self.hideUnreadBtnForMentioned = NO;
        [self.chatVC.unReadButton removeFromSuperview];
        self.chatVC.unReadButton = nil;
        self.chatVC.unReadMessage = 0;
    }
}

- (void)loadRightTopUnreadMessages{
    __weak typeof(self) weakSelf = self;
    [self getHistoryMessageV2:self.firstUnreadMessage.sentTime order:RCHistoryMessageOrderAsc loadType:self.chatVC.loadMessageType complete:^(NSArray *messages, BOOL isRemaining, RCConversationLoadMessageType type, BOOL isDoubleCallback) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        //移除所有的已经加载的消息，页面只剩下从第一条未读开始的消息
        [strongSelf.chatVC.conversationDataRepository removeAllObjects];
        NSMutableArray *oldMessageArray = [NSMutableArray array];
        if (strongSelf.firstUnreadMessage) {
            [oldMessageArray addObject:strongSelf.firstUnreadMessage];
        }
        [oldMessageArray addObjectsFromArray:messages];
        if (oldMessageArray.count > 0) {
            RCMessage *oldMsg = [strongSelf generateOldMessage];
            if(oldMsg) {
                [oldMessageArray insertObject:oldMsg atIndex:0];
            }
        }
        [strongSelf loadMoreNewerMessageV2:oldMessageArray];
        [strongSelf scrollToSpecifiedPosition:NO baseMeassage:strongSelf.firstUnreadMessage];
        [strongSelf.chatVC.unReadButton removeFromSuperview];
        strongSelf.chatVC.unReadButton = nil;
        strongSelf.chatVC.unReadMessage = 0;
    }];
}

- (void)scrollToSpecifiedPosition:(BOOL)ifUnReadMentioned baseMeassage:(RCMessage *)baseMeassage{
    [self.chatVC.conversationMessageCollectionView reloadData];
    [self.chatVC.conversationMessageCollectionView setNeedsLayout];
    [self.chatVC.conversationMessageCollectionView layoutIfNeeded];
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
    if (self.chatVC.conversationDataRepository.count > 0) {
        if (self.unreadMentionedMessages && self.chatVC.enableUnreadMentionedIcon == YES) {
            if (self.unreadMentionedMessages.count == 0) {
                self.chatVC.unReadMentionedButton.hidden = YES;
            }else{
                self.chatVC.unReadMentionedButton.hidden = NO;
                NSString *unReadMentionedMessagesCount = [NSString stringWithFormat:@"%ld", (long)self.unreadMentionedMessages.count];
                NSString *stringUnReadMentioned = [NSString stringWithFormat:RCLocalizedString(@"HaveMentionedMeCount"), unReadMentionedMessagesCount];
                
                self.chatVC.unReadMentionedLabel.text = stringUnReadMentioned;
                [self.chatVC.util adaptUnreadButtonSize:self.chatVC.unReadMentionedLabel];
            }
        }else {
            self.chatVC.unReadMentionedButton.hidden = YES;
        }
    }else {
        [self.unreadMentionedMessages removeAllObjects];
        self.chatVC.unReadMentionedButton.hidden = YES;
    }
}

- (void)tapRightTopUnReadMentionedButton:(UIButton *)sender {
    if (self.unreadMentionedMessages.count <= 0) {
        return;
    }
    self.isLoadingHistoryMessage = YES;
    [self loadUnReadMentionedMessages];
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
            if ([RCRRSUtil isSupportReadReceiptV5]) {
                return;
            }
            [[RCCoreClient sharedCoreClient] sendReadReceiptMessage:self.chatVC.conversationType
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

- (void)scrollDidEnd{
    if (!self.isLoadingHistoryMessage) {
        CGFloat height = self.chatVC.conversationMessageCollectionView.frame.size.height;
        CGFloat contentOffsetY = self.chatVC.conversationMessageCollectionView.contentOffset.y;
        CGFloat bottomOffset = self.chatVC.conversationMessageCollectionView.contentSize.height - contentOffsetY;
        //经常出现滚动到底部bottomOffset比height大，误差值在0.2左右，这里加10是规避误差值
        if (bottomOffset <= height+10){
            //在最底部
            self.isShowingLastestMessage = YES;
        }else{
            self.isShowingLastestMessage = NO;
        }
    }
}

- (BOOL)isAtTheBottomOfTableView {
    if (self.isLoadingHistoryMessage){
        return NO;
    }
    if (!self.isShowingLastestMessage) {
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:self.chatVC.conversationDataRepository.count - 1
                                                         inSection:0];
        BOOL isLastMessageVisible = [[self.chatVC.conversationMessageCollectionView indexPathsForVisibleItems] containsObject:lastIndexPath];
        self.isShowingLastestMessage = isLastMessageVisible;
    }
    return self.isShowingLastestMessage;
}

- (BOOL)isLoadingHistoryMessage {
    if (self.chatVC.conversationDataRepository.count == 0) {
        return NO;
    }
    return _isLoadingHistoryMessage;
}

- (void)streamMessageCellDidUpdate:(NSNotification *)notifi {
    if (self.isShowingLastestMessage || [self isAtTheBottomOfTableView]) {
        [self.chatVC scrollToBottomAnimated:YES];
    }
}

- (BOOL)isSupportReadReceiptV5 {
    return [[RCCoreClient sharedCoreClient] getAppSettings].readReceiptVersion == RCMessageReadReceiptVersion5;
}

#pragma mark - getter

- (BOOL)isMentionedEnabled {
    if((self.chatVC.conversationType == ConversationType_GROUP || self.chatVC.conversationType == ConversationType_DISCUSSION || self.chatVC.conversationType == ConversationType_ULTRAGROUP)) {
        return RCKitConfigCenter.message.enableMessageMentioned;
    }
    return NO;
}

@end
