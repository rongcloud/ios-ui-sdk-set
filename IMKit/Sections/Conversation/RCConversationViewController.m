//
//  RCConversationViewController.m
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All AVrights reserved.
//

#import "RCConversationViewController.h"
#import "RCCSPullLeaveMessageCell.h"
#import "RCConversationCollectionViewHeader.h"
#import "RCCustomerServiceMessageModel.h"
#import "RCExtensionService.h"
#import "RCFilePreviewViewController.h"
#import "RCDestructImageBrowseController.h"
#import "RCKitCommonDefine.h"
#import "RCOldMessageNotificationMessage.h"
#import "RCOldMessageNotificationMessageCell.h"
#import "RCPublicServiceImgTxtMsgCell.h"
#import "RCPublicServiceMultiImgTxtCell.h"
#import "RCRecallMessageImageView.h"
#import "RCSightMessageCell.h"
#import "RCHQVoiceMessageCell.h"
#import "RCSightSlideViewController.h"
#import "RCDestructSightViewController.h"
#import "RCSystemSoundPlayer.h"
#import "RCUserInfoCacheManager.h"
#import "RCVoicePlayer.h"
#import "RongIMKitExtensionManager.h"
#import <AVFoundation/AVFoundation.h>
#import <SafariServices/SafariServices.h>
#import "RCMessageSelectionUtility.h"
#import "RCConversationViewLayout.h"
#import "RCHQVoiceMsgDownloadManager.h"
#import "RCHQVoiceMsgDownloadInfo.h"
#import "RCGIFPreviewViewController.h"
#import "RCDestructGIFPreviewViewController.h"
#import "RCCombineMessagePreviewViewController.h"
#import "RCCombineMessageUtility.h"
#import "RCActionSheetView.h"
#import "RCSelectConversationViewController.h"
#import "RCForwardManager.h"
#import "RCCombineMessageCell.h"
#import "RCReeditMessageManager.h"
#import "RCReferencingView.h"
#import "RCReferenceMessageCell.h"
#import "RCConversationDataSource.h"
#import "RCConversationVCUtil.h"
#import "RCConversationCSUtil.h"
#import "RCKitConfig.h"
#import "RCTextPreviewView.h"
#import <RongPublicService/RongPublicService.h>
#import <RongDiscussion/RongDiscussion.h>
#import <RongCustomerService/RongCustomerService.h>
#import "RCButton.h"
#define UNREAD_MESSAGE_MAX_COUNT 99
#define COLLECTION_VIEW_REFRESH_CONTROL_HEIGHT 30

extern NSString *const RCKitDispatchDownloadMediaNotification;

@interface RCConversationViewController () <
    UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, RCMessageCellDelegate,
    RCChatSessionInputBarControlDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,
    UINavigationControllerDelegate, RCPublicServiceMessageCellDelegate, RCTypingStatusDelegate,
    RCChatSessionInputBarControlDataSource, RCMessagesMultiSelectedProtocol, RCReferencingViewDelegate, RCTextPreviewViewDelegate>

@property (nonatomic, strong) RCConversationDataSource *dataSource;
@property (nonatomic, strong) RCConversationVCUtil *util;
@property (nonatomic, strong) RCConversationCSUtil *csUtil;

#pragma mark flag
@property (nonatomic, assign) BOOL isConversationAppear;
@property (nonatomic, assign) BOOL isTakeNewPhoto;//发送的图片是否是刚拍摄的，是拍摄的则决定是否写入相册
@property (nonatomic, assign) BOOL isContinuousPlaying;     //是否正在连续播放语音消息
@property (nonatomic, assign) BOOL isTouchScrolled; /// 表示是否是触摸滚动
@property (nonatomic, assign) BOOL needAutoScrollToBottom;

#pragma mark data
@property (nonatomic, strong) NSMutableArray *typingMessageArray;
@property (nonatomic, strong) NSArray<RCExtensionMessageCellInfo *> *extensionMessageCellInfoList;
@property (nonatomic, strong) NSMutableDictionary *cellMsgDict;
@property (nonatomic, strong) RCMessageModel *currentSelectedModel;

#pragma mark view
@property (nonatomic, strong) UITapGestureRecognizer *resetBottomTapGesture;
@property (nonatomic, strong) RCConversationCollectionViewHeader *collectionViewHeader;

#pragma mark 通用
@property (nonatomic, copy) NSString *navigationTitle;
@property (nonatomic, strong) NSArray<UIBarButtonItem *> *leftBarButtonItems;
@property (nonatomic, strong) NSArray<UIBarButtonItem *> *rightBarButtonItems;

@end

static NSString *const rcUnknownMessageCellIndentifier = @"rcUnknownMessageCellIndentifier";

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation RCConversationViewController
#pragma mark - LifeCycle
- (id)initWithConversationType:(RCConversationType)conversationType targetId:(NSString *)targetId {
    self = [super init];
    if (self) {
        self.conversationType = conversationType;
        self.targetId = targetId;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self rcinit];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self rcinit];
    }
    return self;
}

- (void)rcinit {
    self.isConversationAppear = NO;
    /* 先假设所有消息都已加载完，Header 的 Size.height 为 0，
            如果服务返回还有消息，修改 Header 的 Size.height 为 30*/
    self.conversationDataRepository = [[NSMutableArray alloc] init];
    self.conversationMessageCollectionView = nil;

    self.displayUserNameInCell = YES;
    self.defaultHistoryMessageCountOfChatRoom = 10;
    self.enableContinuousReadUnreadVoice = YES;
    self.typingMessageArray = [[NSMutableArray alloc] init];
    self.cellMsgDict = [[NSMutableDictionary alloc] init];
    self.csEvaInterval = 60;
    self.isContinuousPlaying = NO;
    [[RCMessageSelectionUtility sharedManager] setMultiSelect:NO];
    
    self.dataSource = [[RCConversationDataSource alloc] init:self];
    self.util = [[RCConversationVCUtil alloc] init:self];
    self.csUtil = [[RCConversationCSUtil alloc] init:self];
    self.enableUnreadMentionedIcon = YES;
    self.defaultLocalHistoryMessageCount = 10;
    self.defaultRemoteHistoryMessageCount = 10;

    [self registerNotification];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //-----
    // Do any additional setup after loading the view.
    // self.edgesForExtendedLayout = UIRectEdgeBottom | UIRectEdgeTop;
    if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        // 左滑返回 和 按住事件冲突
        self.extendedLayoutIncludesOpaqueBars = YES;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [self initializedSubViews];
    [self registerAllInternalClass];

    [RCMessageSelectionUtility sharedManager].delegate = self;

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_10_3
    if (@available(iOS 11.0, *)) {
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(-[self getSafeAreaExtraBottomHeight], 0, 0, 0);
    }
#endif
    [[RCSystemSoundPlayer defaultPlayer] setIgnoreConversationType:self.conversationType targetId:self.targetId];
    RCConversation *conversation =
        [[RCIMClient sharedRCIMClient] getConversation:self.conversationType targetId:self.targetId];
    
    [self.dataSource getInitialMessage:conversation];

    if (ConversationType_APPSERVICE == self.conversationType ||
        ConversationType_PUBLICSERVICE == self.conversationType){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:RCResourceImage(@"rc_setting")
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(rightBarButtonItemClicked:)];
    }


    NSString *draft = conversation.draft;
    self.chatSessionInputBarControl.draft = draft;

    [self registerSectionHeaderView];
    if (!RCKitConfigCenter.message.enableDestructMessage) {
        [self.chatSessionInputBarControl.pluginBoardView removeItemWithTag:PLUGIN_BOARD_ITEM_DESTRUCT_TAG];
    }
    [self.chatSessionInputBarControl.pluginBoardView removeItemWithTag:PLUGIN_BOARD_ITEM_TRANSFER_TAG];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.messageSelectionToolbar.frame =
        CGRectMake(0, self.view.bounds.size.height - RC_ChatSessionInputBar_Height - [self getSafeAreaExtraBottomHeight],
                   self.view.bounds.size.width, RC_ChatSessionInputBar_Height);
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }
        completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self layoutSubview:size];
        }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateUnreadMsgCountLabel];
    if (self.unReadMessage > 0) {
        [self.util syncReadStatus];
        [self.util sendReadReceipt];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[RCIMClient sharedRCIMClient] clearMessagesUnreadStatus:self.conversationType targetId:self.targetId];
            /// 清除完未读数需要通知更新UI
            [self notifyUpdateUnreadMessageCount];
        });
    }
    self.navigationController.interactivePopGestureRecognizer.delaysTouchesBegan = NO;

    [self.conversationMessageCollectionView addGestureRecognizer:self.resetBottomTapGesture];

    [self.chatSessionInputBarControl containerViewWillAppear];

    [[RCSystemSoundPlayer defaultPlayer] setIgnoreConversationType:self.conversationType targetId:self.targetId];
    if (self.conversationDataRepository.count == 0 && self.unReadButton != nil) {
        [self.unReadButton removeFromSuperview];
        self.unReadMessage = 0;
    }
    if (self.unReadMessage > self.defaultLocalHistoryMessageCount && self.enableUnreadMessageIcon == YES && !self.unReadButton.selected) {
        [self setupUnReadMessageView];
    }
    
    [self.dataSource scrollToSuitablePosition];
    [self.dataSource setupUnReadMentionedButton];
    
    [[RongIMKitExtensionManager sharedManager] extensionViewWillAppear:self.conversationType
                                                              targetId:self.targetId
                                                         extensionView:self.extensionView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    DebugLog(@"%s======%@", __func__, self);
    self.isConversationAppear = YES;

    [self.chatSessionInputBarControl containerViewDidAppear];
    self.navigationTitle = self.navigationItem.title;
    [[RCIMClient sharedRCIMClient] setRCTypingStatusDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.util syncReadStatus];
    
    [self.conversationMessageCollectionView removeGestureRecognizer:self.resetBottomTapGesture];
    [[RCSystemSoundPlayer defaultPlayer] resetIgnoreConversation];
    [self stopPlayingVoiceMessage];
    self.isConversationAppear = NO;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[RCIMClient sharedRCIMClient] clearMessagesUnreadStatus:self.conversationType targetId:self.targetId];
    });
    [self.util saveDraftIfNeed];

    [self.chatSessionInputBarControl cancelVoiceRecord];
    [[RCIMClient sharedRCIMClient] setRCTypingStatusDelegate:nil];
    self.navigationItem.title = self.navigationTitle;
    [self.chatSessionInputBarControl containerViewWillDisappear];
    [[RongIMKitExtensionManager sharedManager] extensionViewWillDisappear:self.conversationType targetId:self.targetId];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!self.navigationController || ![self.navigationController.viewControllers containsObject:self]) {
        [self.dataSource cancelAppendMessageQueue];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self quitConversationViewAndClear];
    [[RCReeditMessageManager defaultManager] resetAndInvalidateTimer];
    [self.csUtil stopCSTimer];
    DebugLog(@"%s======%@", __func__, self);
}

#pragma mark - Register Message

- (void)registerAllInternalClass {
    //常见消息
    [self registerClass:[RCTextMessageCell class] forMessageClass:[RCTextMessage class]];
    [self registerClass:[RCImageMessageCell class] forMessageClass:[RCImageMessage class]];
    [self registerClass:[RCGIFMessageCell class] forMessageClass:[RCGIFMessage class]];
    [self registerClass:[RCCombineMessageCell class] forMessageClass:[RCCombineMessage class]];
    [self registerClass:[RCVoiceMessageCell class] forMessageClass:[RCVoiceMessage class]];
    [self registerClass:[RCHQVoiceMessageCell class] forMessageClass:[RCHQVoiceMessage class]];
    [self registerClass:[RCRichContentMessageCell class] forMessageClass:[RCRichContentMessage class]];
    [self registerClass:[RCLocationMessageCell class] forMessageClass:[RCLocationMessage class]];
    [self registerClass:[RCFileMessageCell class] forMessageClass:[RCFileMessage class]];
    [self registerClass:[RCReferenceMessageCell class] forMessageClass:[RCReferenceMessage class]];
    if (NSClassFromString(@"RCSightCapturer")) {
        [self registerClass:[RCSightMessageCell class] forMessageClass:[RCSightMessage class]];
    }

    [self registerClass:[RCTipMessageCell class] forMessageClass:[RCInformationNotificationMessage class]];
    [self registerClass:[RCTipMessageCell class] forMessageClass:[RCDiscussionNotificationMessage class]];
    [self registerClass:[RCTipMessageCell class] forMessageClass:[RCGroupNotificationMessage class]];
    [self registerClass:[RCTipMessageCell class] forMessageClass:[RCRecallNotificationMessage class]];

    [self registerClass:[RCCSPullLeaveMessageCell class] forMessageClass:[RCCSPullLeaveMessage class]];

    [self registerClass:[RCPublicServiceMultiImgTxtCell class]
        forMessageClass:[RCPublicServiceMultiRichContentMessage class]];
    [self registerClass:[RCPublicServiceImgTxtMsgCell class] forMessageClass:[RCPublicServiceRichContentMessage class]];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self registerClass:[RCUnknownMessageCell class] forCellWithReuseIdentifier:rcUnknownMessageCellIndentifier];
#pragma clang diagnostic pop
    [self registerClass:[RCOldMessageNotificationMessageCell class]
        forMessageClass:[RCOldMessageNotificationMessage class]];

    //注册 Extention 消息，如 callkit 的
    self.extensionMessageCellInfoList =
        [[RongIMKitExtensionManager sharedManager] getMessageCellInfoList:self.conversationType targetId:self.targetId];
    for (RCExtensionMessageCellInfo *cellInfo in self.extensionMessageCellInfoList) {
        [self registerClass:cellInfo.messageCellClass forMessageClass:cellInfo.messageContentClass];
    }
}

- (void)registerClass:(Class)cellClass forMessageClass:(Class)messageClass {
    [self.conversationMessageCollectionView registerClass:cellClass
                               forCellWithReuseIdentifier:[messageClass getObjectName]];
    [self.cellMsgDict setObject:cellClass forKey:[messageClass getObjectName]];
}

- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier {
    [self.conversationMessageCollectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
}

#pragma mark - UI 显示
- (void)initializedSubViews {
    self.view.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x1c1c1c);
    [self.view addSubview:self.conversationMessageCollectionView];
}
//更新 ipad UI 布局
- (void)layoutSubview:(CGSize)size {
    if (![RCKitUtility currentDeviceIsIPad]) {
        return;
    }
    CGRect frame = CGRectMake(0, 0, size.width, size.height);
    frame.size.height = frame.size.height - self.chatSessionInputBarControl.frame.size.height;
    self.conversationMessageCollectionView.frame = frame;
    for (RCMessageModel *model in self.conversationDataRepository) {
        model.cellSize = CGSizeZero;
    }
    [self.conversationMessageCollectionView reloadData];
    self.collectionViewHeader.frame = CGRectMake(0, -40, size.width, 40);

    CGRect controlFrame = self.chatSessionInputBarControl.frame;
    controlFrame.size.width = self.view.frame.size.width;
    controlFrame.origin.y =
        self.conversationMessageCollectionView.frame.size.height - self.chatSessionInputBarControl.frame.size.height;
    self.chatSessionInputBarControl.frame = controlFrame;
    [self.chatSessionInputBarControl containerViewSizeChangedNoAnnimation];
}

- (void)updateUnreadMsgCountLabel {
    if (self.conversationDataRepository.count > 0) {
        if (self.dataSource.unreadNewMsgArr.count > 0) {
            NSIndexPath *indexPath =
                [NSIndexPath indexPathForItem:self.conversationDataRepository.count - 1 inSection:0];
            UICollectionViewCell *cell = [self.conversationMessageCollectionView cellForItemAtIndexPath:indexPath];
            if (cell) {
                [self.dataSource.unreadNewMsgArr removeAllObjects];
                self.unreadRightBottomIcon.hidden = YES;
            } else {
                self.unreadRightBottomIcon.hidden = NO;
                self.unReadNewMessageLabel.text =
                    (self.dataSource.unreadNewMsgArr.count > 99)
                        ? @"99+"
                        : [NSString stringWithFormat:@"%li", (long)self.dataSource.unreadNewMsgArr.count];
            }
        } else {
            self.unreadRightBottomIcon.hidden = YES;
        }
    } else {
        self.unreadRightBottomIcon.hidden = YES;
    }
    [self updateUnreadMsgCountLabelFrame];
}

- (void)updateUnreadMsgCountLabelFrame {
    if (!self.unreadRightBottomIcon.hidden) {
        CGRect rect = self.unreadRightBottomIcon.frame;
        if (self.referencingView) {
            rect.origin.y =
                self.chatSessionInputBarControl.frame.origin.y - 12 - 35 - self.referencingView.frame.size.height;
        } else {
            rect.origin.y = self.chatSessionInputBarControl.frame.origin.y - 12 - 35;
        }
        [self.unreadRightBottomIcon setFrame:rect];
    }
}

- (void)setupUnReadMessageView {
    if (self.unReadButton != nil) {
        [self.unReadButton removeFromSuperview];
    }
    [self.view addSubview:self.unReadButton];
    [self.unReadButton bringSubviewToFront:self.conversationMessageCollectionView];
    [self.util adaptUnreadButtonSize:self.unReadMessageLabel];
}

- (void)tapRightTopUnReadMentionedButton:(UIButton *)sender {
    if (self.dataSource.unreadMentionedMessages.count <= 0) {
        return;
    }
    [self.dataSource tapRightTopUnReadMentionedButton:sender];
}

- (void)loadRemainMessageAndScrollToBottom:(BOOL)animated {
    self.locatedMessageSentTime = 0;
    self.conversationDataRepository = [[NSMutableArray alloc] init];
    [self.dataSource loadLatestHistoryMessage];
    [self.conversationMessageCollectionView reloadData];
    [self scrollToBottomAnimated:animated];
}


#pragma mark - Notification selector

- (void)registerNotification {

    //注册接收消息
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMessageNotification:)
                                                 name:RCKitDispatchMessageNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSendingMessageNotification:)
                                                 name:@"RCKitSendingMessageNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveMessageHasReadNotification:)
                                                 name:RCLibDispatchReadReceiptNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAppResumeNotification)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillResignActiveNotification)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveRecallMessageNotification:)
                                                 name:RCKitDispatchRecallMessageNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onReceiveMessageReadReceiptResponse:)
                                                 name:RCKitDispatchMessageReceiptResponseNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onReceiveMessageReadReceiptRequest:)
                                                 name:RCKitDispatchMessageReceiptRequestNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopPlayingVoiceMessage)
                                                 name:UIWindowDidResignKeyNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onConnectionStatusChangedNotification:)
                                                 name:RCKitDispatchConnectionStatusChangedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMessageDestructing:)
                                                 name:RCKitMessageDestructingNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadStatus:)
                                                 name:RCHQDownloadStatusChangeNotify
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadMediaNotification:)
                                                 name:RCKitDispatchDownloadMediaNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveContinuousPlayNotification:)
                                                 name:@"RCContinuousPlayNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currentViewFrameChange:)
                                                 name:UIApplicationWillChangeStatusBarFrameNotification
                                               object:nil];
}

- (void)didReceiveMessageNotification:(NSNotification *)notification {
    RCMessage *rcMessage = notification.object;
    NSDictionary *leftDic = notification.userInfo;
    [self.dataSource didReceiveMessageNotification:rcMessage leftDic:leftDic];
}

- (void)didSendingMessageNotification:(NSNotification *)notification {
    RCMessage *rcMessage = notification.object;
    NSDictionary *statusDic = notification.userInfo;
    self.needAutoScrollToBottom = YES;
    if (rcMessage) {
        // 插入消息
        if (rcMessage.conversationType == self.conversationType && [rcMessage.targetId isEqual:self.targetId]) {
            [self updateForMessageSendOut:rcMessage];
        }
    } else if (statusDic) {
        // 更新消息状态
        NSNumber *conversationType = statusDic[@"conversationType"];
        NSString *targetId = statusDic[@"targetId"];
        if (conversationType.intValue == self.conversationType && [targetId isEqual:self.targetId]) {
            NSNumber *messageId = statusDic[@"messageId"];
            NSNumber *sentStatus = statusDic[@"sentStatus"];
            if (sentStatus.intValue == SentStatus_SENDING) {
                NSNumber *progress = statusDic[@"progress"];
                [self updateForMessageSendProgress:progress.intValue messageId:messageId.longValue];
            } else if (sentStatus.intValue == SentStatus_SENT) {
                RCMessageContent *content = statusDic[@"content"];
                [self updateForMessageSendSuccess:messageId.longValue content:content];
            } else if (sentStatus.intValue == SentStatus_FAILED) {
                NSNumber *errorCode = statusDic[@"error"];
                RCMessageContent *content = statusDic[@"content"];
                bool ifResendNotification = [statusDic.allKeys containsObject:@"resend"];
                [self updateForMessageSendError:errorCode.intValue messageId:messageId.longValue content:content ifResendNotification:ifResendNotification];
            } else if (sentStatus.intValue == SentStatus_CANCELED) {
                RCMessageContent *content = statusDic[@"content"];
                [self updateForMessageSendCanceled:messageId.longValue content:content];
            }
        }
    }
}

- (void)receiveMessageHasReadNotification:(NSNotification *)notification {
    NSNumber *ctype = [notification.userInfo objectForKey:@"cType"];
    NSNumber *time = [notification.userInfo objectForKey:@"messageTime"];
    NSString *targetId = [notification.userInfo objectForKey:@"tId"];

    if (ctype.intValue == (int)self.conversationType && [targetId isEqualToString:self.targetId]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (RCMessageModel *model in self.conversationDataRepository) {
                if (model.messageDirection == MessageDirection_SEND && model.sentTime <= time.longLongValue &&
                    model.sentStatus == SentStatus_SENT) {
                    model.sentStatus = SentStatus_READ;
                    [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_HASREAD messageId:model.messageId progress:0];
                }
            }
        });
    }
}

- (void)handleAppResumeNotification {
    self.isConversationAppear = YES;
    [self.conversationMessageCollectionView reloadData];
    if ([[RCIMClient sharedRCIMClient] getConnectionStatus] == ConnectionStatus_Connected) {
        [self.util syncReadStatus];
        [self.util sendReadReceipt];
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[RCIMClient sharedRCIMClient] clearMessagesUnreadStatus:self.conversationType targetId:self.targetId];
    });
}

- (void)handleWillResignActiveNotification {
    self.isConversationAppear = NO;
    [self.chatSessionInputBarControl endVoiceRecord];
    //直接从会话页面杀死 app，保存或者清除草稿
    [self.util saveDraftIfNeed];
}

- (void)didReceiveRecallMessageNotification:(NSNotification *)notification {
    __weak typeof(self) __blockSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        long recalledMsgId = [notification.object longValue];
        if ([RCVoicePlayer defaultPlayer].isPlaying &&
            [RCVoicePlayer defaultPlayer].messageId == recalledMsgId) {
            [[RCVoicePlayer defaultPlayer] stopPlayVoice];
        }
        RCMessage *recalledMsg = [[RCIMClient sharedRCIMClient] getMessage:recalledMsgId];
        [__blockSelf.dataSource didRecallMessage:recalledMsg];
        if (self.enableUnreadMentionedIcon && recalledMsg.conversationType == self.conversationType &&
            [recalledMsg.targetId isEqual:self.targetId] &&
            ![self isRemainMessageExisted] && self.dataSource.unreadMentionedMessages.count != 0) {
            //遍历删除对应的@消息
            [self.dataSource removeMentionedMessage:recalledMsgId];
        }
        if (self.referencingView && self.referencingView.referModel.messageId == recalledMsgId) {
            [self.chatSessionInputBarControl resetToDefaultStatus];
            [self dismissReferencingView:self.referencingView];
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"MessageRecallAlert") cancelTitle:RCLocalizedString(@"Confirm") inViewController:self];
        }
    });
}

/**
 *  收到回执消息的响应，更新这条消息的已读数
 *
 *  @param notification notification description
 */
- (void)onReceiveMessageReadReceiptResponse:(NSNotification *)notification {
    NSDictionary *dic = notification.object;
    if ([self.targetId isEqualToString:dic[@"targetId"]] &&
        self.conversationType == [dic[@"conversationType"] intValue]) {
        for (int i = 0; i < self.conversationDataRepository.count; i++) {
            RCMessageModel *model = self.conversationDataRepository[i];
            if ([model.messageUId isEqualToString:dic[@"messageUId"]]) {
                NSDictionary *readerList = dic[@"readerList"];
                model.readReceiptCount = readerList.count;
                model.readReceiptInfo = [[RCReadReceiptInfo alloc] init];
                model.readReceiptInfo.isReceiptRequestMessage = YES;
                model.readReceiptInfo.userIdList = [NSMutableDictionary dictionaryWithDictionary:readerList];
                
                [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_READCOUNT messageId:model.messageId progress:readerList.count];
            }
        }
    }
}

/**
 *  收到消息请求回执，如果当前列表中包含需要回执的messageUId，发送回执响应
 *
 *  @param notification notification description
 */
- (void)onReceiveMessageReadReceiptRequest:(NSNotification *)notification {
    NSDictionary *dic = notification.object;
    if ([self.targetId isEqualToString:dic[@"targetId"]] &&
        self.conversationType == [dic[@"conversationType"] intValue]) {
        [self.conversationDataRepository enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RCMessageModel *model = (RCMessageModel *)obj;
            if ([model.messageUId isEqualToString:dic[@"messageUId"]]) {
                if (model.messageDirection == MessageDirection_RECEIVE) {
                    RCMessage *msg = [[RCIMClient sharedRCIMClient] getMessage:model.messageId];
                    if (msg) {
                        NSArray *msgList = [NSArray arrayWithObject:msg];
                        [[RCIMClient sharedRCIMClient] sendReadReceiptResponse:self.conversationType
                            targetId:self.targetId
                            messageList:msgList
                            success:^{

                            }
                            error:^(RCErrorCode nErrorCode){

                            }];
                    }
                    if (!model.readReceiptInfo) {
                        model.readReceiptInfo = [[RCReadReceiptInfo alloc] init];
                    }
                    model.readReceiptInfo.isReceiptRequestMessage = YES;
                    model.readReceiptInfo.hasRespond = YES;
                } else {
                    model.readReceiptCount = 0;
                    model.readReceiptInfo = [[RCReadReceiptInfo alloc] init];
                    model.readReceiptInfo.isReceiptRequestMessage = YES;
                    model.isCanSendReadReceipt = NO;
                    
                    [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_READCOUNT messageId:model.messageId progress:0];
                }
            }
        }];
    }
}

- (void)stopPlayingVoiceMessage {
    if ([RCVoicePlayer defaultPlayer].isPlaying) {
        [[RCVoicePlayer defaultPlayer] stopPlayVoice];
    }
}

- (void)onConnectionStatusChangedNotification:(NSNotification *)status {
    if (ConnectionStatus_Connected == [status.object integerValue]) {
        [self.util syncReadStatus];
        [self.util sendReadReceipt];
    }
}

- (void)currentViewFrameChange:(NSNotification *)notification {
    if(!self.isConversationAppear) {
        return;
    }
    [self.chatSessionInputBarControl containerViewSizeChanged];
}

#pragma mark 语音连续播放
- (void)receiveContinuousPlayNotification:(NSNotification *)notification {
    if(!self.isConversationAppear) {
        return;
    }
    if (self.enableContinuousReadUnreadVoice) {
        if (!self.isContinuousPlaying) {
            return;
        }
        long messageId = [notification.object longValue];
        RCConversationType conversationType = [notification.userInfo[@"conversationType"] longValue];
        NSString *targetId = notification.userInfo[@"targetId"];
        RCMessage *msg = [[RCIMClient sharedRCIMClient] getMessage:messageId];
        if (messageId > 0 && conversationType == self.conversationType && [targetId isEqualToString:self.targetId] &&
            msg.content.destructDuration == 0) {

            [self performSelector:@selector(playNextVoiceMesage:)
                       withObject:@(messageId)
                       afterDelay:0.3f]; //延时0.3秒播放
        }
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.isTouchScrolled = YES;
    if (self.chatSessionInputBarControl.currentBottomBarStatus != KBottomBarDefaultStatus &&
        self.chatSessionInputBarControl.currentBottomBarStatus != KBottomBarRecordStatus) {
        [self.chatSessionInputBarControl resetToDefaultStatus];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // isTouchScrolled 只有人为滑动页面才需要加载更新或者更旧的消息
    // 其他的时机如 reloadData 和弹出键盘等不需要加载消息
    if (scrollView.contentOffset.y <= 0 && !self.dataSource.isIndicatorLoading && !self.dataSource.allMessagesAreLoaded &&
        self.isTouchScrolled) {
        [self.collectionViewHeader startAnimating];
        [self.dataSource scrollToLoadMoreHistoryMessage];
    } else if (scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height &&
               !self.dataSource.isIndicatorLoading && self.isTouchScrolled) {
        [self.dataSource scrollToLoadMoreNewerMessage];
    }
}

/// 调用scrollToItemAtIndexPath方法，滚动动画执行完时调用
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    /// 请在停止滚动时、滚动动画执行完时更新右下角未读数气泡 或者在collectionview未处于底部时更新
    /// 又或者在撤回未读消息时更新，不要在其他时机更新，或者进行不必要的更新，浪费资源。
    [self updateUnreadMsgCountLabel];
}

/// 停止滚动时调用
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self updateUnreadMsgCountLabel];
    self.isTouchScrolled = NO;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        self.isTouchScrolled = NO;
    }
}

//点击状态栏屏蔽系统动作手动滚动到顶部并加载历史消息
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    if ([self.conversationMessageCollectionView numberOfItemsInSection:0] > 0) {
        [self.conversationMessageCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                                       atScrollPosition:(UICollectionViewScrollPositionTop)
                                                               animated:YES];
    }
    [self.dataSource loadMoreHistoryMessageIfNeed];
    return NO;
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    if ([self.conversationMessageCollectionView numberOfSections] == 0) {
        return;
    }

    NSUInteger finalRow = MAX(0, [self.conversationMessageCollectionView numberOfItemsInSection:0] - 1);
    if (finalRow == 0) {
        return;
    }
    NSIndexPath *finalIndexPath = [NSIndexPath indexPathForItem:finalRow inSection:0];
    [self.conversationMessageCollectionView scrollToItemAtIndexPath:finalIndexPath
                                                   atScrollPosition:UICollectionViewScrollPositionBottom
                                                           animated:animated];
    //页面滚动到最新处，右下方气泡消失
    [self.dataSource.unreadNewMsgArr removeAllObjects];
    [self updateUnreadMsgCountLabel];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.conversationDataRepository.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RCMessageModel *model = [self.conversationDataRepository objectAtIndex:indexPath.row];

    model = [self.dataSource setModelIsDisplayNickName:model];

    RCMessageContent *messageContent = model.content;
    RCMessageBaseCell *cell = nil;
    NSString *objName = [[messageContent class] getObjectName];
    if (self.cellMsgDict[objName]) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:objName forIndexPath:indexPath];

        if ([messageContent isMemberOfClass:[RCPublicServiceMultiRichContentMessage class]]) {
            [(RCPublicServiceMultiImgTxtCell *)cell
                setPublicServiceDelegate:(id<RCPublicServiceMessageCellDelegate>)self];
        } else if ([messageContent isMemberOfClass:[RCPublicServiceRichContentMessage class]]) {
            [(RCPublicServiceImgTxtMsgCell *)cell
                setPublicServiceDelegate:(id<RCPublicServiceMessageCellDelegate>)self];
        }
        [cell setDataModel:model];
        [cell setDelegate:self];
    } else if (!messageContent && RCKitConfigCenter.message.showUnkownMessage) {
        cell = [self rcUnkownConversationCollectionView:collectionView cellForItemAtIndexPath:indexPath];
        [cell setDataModel:model];
        [cell setDelegate:self];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        cell = [self rcConversationCollectionView:collectionView cellForItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
    }

    if ((self.conversationType == ConversationType_PRIVATE || self.conversationType == ConversationType_Encrypted) &&
        [RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(model.conversationType)] && ![self.targetId isEqualToString:[RCIM sharedRCIM].currentUserInfo.userId]) {
        cell.isDisplayReadStatus = YES;
    }
    //接口向后兼容 [[++
    [self performSelector:@selector(willDisplayConversationTableCell:atIndexPath:)
               withObject:cell
               withObject:indexPath];
    //接口向后兼容 --]]
    [self willDisplayMessageCell:cell atIndexPath:indexPath];
    [self.dataSource removeMentionedMessage:model.messageId];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        RCConversationCollectionViewHeader *headerView =
            [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                               withReuseIdentifier:@"RefreshHeadView"
                                                      forIndexPath:indexPath];
        self.collectionViewHeader = headerView;
        return headerView;
    }
    return nil;
}

//修复ios7下不断下拉加载历史消息偶尔崩溃的bug
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    RCMessageModel *model = [self.conversationDataRepository objectAtIndex:indexPath.row];
    model = [self.dataSource setModelIsDisplayNickName:model];
    if (model.cellSize.height > 0 &&
        !(model.conversationType == ConversationType_CUSTOMERSERVICE &&
          [model.content isKindOfClass:[RCTextMessage class]])) {
        return model.cellSize;
    }

    RCMessageContent *messageContent = model.content;
    NSString *objectName = [[messageContent class] getObjectName];
    Class cellClass = self.cellMsgDict[objectName];
    if([cellClass respondsToSelector:@selector(sizeForMessageModel:withCollectionViewWidth:referenceExtraHeight:)]) {
        CGFloat extraHeight = [self.util referenceExtraHeight:cellClass messageModel:model];
        CGSize size = [cellClass sizeForMessageModel:model
                             withCollectionViewWidth:collectionView.frame.size.width
                                referenceExtraHeight:extraHeight];

        if (size.width != 0 && size.height != 0) {
            model.cellSize = size;
            return size;
        }
    }

    if (!messageContent && RCKitConfigCenter.message.showUnkownMessage) {
        CGSize _size = [self rcUnkownConversationCollectionView:collectionView
                                                         layout:collectionViewLayout
                                         sizeForItemAtIndexPath:indexPath];
        _size.height += [self.util referenceExtraHeight:RCUnknownMessageCell.class messageModel:model];
        model.cellSize = _size;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CGSize _size = [self rcConversationCollectionView:collectionView
                                                   layout:collectionViewLayout
                                   sizeForItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
        DebugLog(@"%@", NSStringFromCGSize(_size));
        _size.height += [self.util referenceExtraHeight:RCUnknownMessageCell.class messageModel:model];
        model.cellSize = _size;
    }

    return model.cellSize;
}

- (RCMessageBaseCell *)rcUnkownConversationCollectionView:(UICollectionView *)collectionView
                                   cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RCMessageModel *model = [self.conversationDataRepository objectAtIndex:indexPath.row];
    RCMessageCell *__cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:rcUnknownMessageCellIndentifier forIndexPath:indexPath];
    [__cell setDataModel:model];
    return __cell;
}

- (CGSize)rcUnkownConversationCollectionView:(UICollectionView *)collectionView
                                      layout:(UICollectionViewLayout *)collectionViewLayout
                      sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    CGFloat __width = CGRectGetWidth(collectionView.frame);
    CGFloat maxMessageLabelWidth = __width - 30 * 2;
    NSString *localizedMessage = RCLocalizedString(@"unknown_message_cell_tip");
    CGSize __textSize = [RCKitUtility getTextDrawingSize:localizedMessage
                                                    font:[[RCKitConfig defaultConfig].font fontOfFourthLevel]
                                         constrainedSize:CGSizeMake(maxMessageLabelWidth, 2000)];
    __textSize = CGSizeMake(ceilf(__textSize.width), ceilf(__textSize.height));
    CGSize __labelSize = CGSizeMake(__textSize.width + 5, __textSize.height + 6);
    return CGSizeMake(collectionView.bounds.size.width, __labelSize.height);
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                             layout:(UICollectionViewLayout *)collectionViewLayout
    referenceSizeForHeaderInSection:(NSInteger)section {
    CGFloat width = self.conversationMessageCollectionView.frame.size.width;
    CGFloat height = 0;
    // 当加载本地历史消息小于 10 时，allMessagesAreLoaded 为 NO，此时高度设置为 0，否则会向下偏移 COLLECTION_VIEW_REFRESH_CONTROL_HEIGHT 的高度
    if(!self.dataSource.allMessagesAreLoaded) {
        if (self.conversationDataRepository.count < self.defaultLocalHistoryMessageCount) {
            height = 0;
        } else {
            height = COLLECTION_VIEW_REFRESH_CONTROL_HEIGHT;
        }
    }
    return (CGSize){width, height};
}

#pragma mark <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (RCMessageBaseCell *)rcConversationCollectionView:(UICollectionView *)collectionView
                             cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    RCMessageModel *model = [self.conversationDataRepository objectAtIndex:indexPath.row];
    // RCMessageContent *messageContent = model.content;
    RCMessageCell *__cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:rcUnknownMessageCellIndentifier forIndexPath:indexPath];
    [__cell setDataModel:model];
    return __cell;
}

- (CGSize)rcConversationCollectionView:(UICollectionView *)collectionView
                                layout:(UICollectionViewLayout *)collectionViewLayout
                sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat __width = CGRectGetWidth(collectionView.frame);
    CGFloat __height = 0;
    CGFloat maxMessageLabelWidth = __width - 30 * 2;
    NSString *localizedMessage = RCLocalizedString(@"unknown_message_cell_tip");
    CGSize __textSize = [RCKitUtility getTextDrawingSize:localizedMessage
                                                    font:[[RCKitConfig defaultConfig].font fontOfFourthLevel]
                                         constrainedSize:CGSizeMake(maxMessageLabelWidth, 2000)];
    __textSize = CGSizeMake(ceilf(__textSize.width), ceilf(__textSize.height));
    CGSize __labelSize = CGSizeMake(__textSize.width + 5, __textSize.height + 6);
    __height = __labelSize.height;
    return CGSizeMake(collectionView.bounds.size.width, __height);
}




#pragma mark - 进入其他的子页面
/**
 *  打开大图。开发者可以重写，自己下载并且展示图片。默认使用内置controller
 *
 *  @param imageMessageContent 图片消息内容
 */
- (void)presentImagePreviewController:(RCMessageModel *)model {
    [self presentImagePreviewController:model onlyPreviewCurrentMessage:NO];
}

- (void)presentImagePreviewController:(RCMessageModel *)model
            onlyPreviewCurrentMessage:(BOOL)onlyPreviewCurrentMessage {
    RCImageSlideController *_imagePreviewVC = [[RCImageSlideController alloc] init];
    _imagePreviewVC.messageModel = model;
    _imagePreviewVC.onlyPreviewCurrentMessage = onlyPreviewCurrentMessage;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:_imagePreviewVC];

    if (self.navigationController) {
        //导航和原有的配色保持一直
        UIImage *image = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
        [nav.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    }
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)presentDestructImagePreviewController:(RCMessageModel *)model {
    RCDestructImageBrowseController *_imagePreviewVC = [[RCDestructImageBrowseController alloc] init];
    _imagePreviewVC.messageModel = model;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:_imagePreviewVC];
    if (self.navigationController) {
        //导航和原有的配色保持一直
        UIImage *image = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
        [nav.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    }
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav
                       animated:YES
                     completion:^{

                     }];
}

- (void)pushGIFPreviewViewController:(RCMessageModel *)model {
    RCGIFPreviewViewController *gifPreviewVC = [[RCGIFPreviewViewController alloc] init];
    gifPreviewVC.messageModel = model;
    [self.navigationController pushViewController:gifPreviewVC animated:NO];
}

- (void)pushDestructGIFPreviewViewController:(RCMessageModel *)model {
    RCDestructGIFPreviewViewController *gifPreviewVC = [[RCDestructGIFPreviewViewController alloc] init];
    gifPreviewVC.messageModel = model;
    [self.navigationController pushViewController:gifPreviewVC animated:NO];
}

- (void)pushCombinePreviewViewController:(RCMessageModel *)model {
    NSString *navTitle = [RCCombineMessageUtility getCombineMessagePreviewVCTitle:(RCCombineMessage *)(model.content)];
    RCCombineMessagePreviewViewController *combinePreviewVC =
        [[RCCombineMessagePreviewViewController alloc] initWithMessageModel:model navTitle:navTitle];
    [self.navigationController pushViewController:combinePreviewVC animated:YES];
}

- (void)presentSightViewPreviewViewController:(RCMessageModel *)model {
    RCSightSlideViewController *svc = [[RCSightSlideViewController alloc] init];
    svc.messageModel = model;
    UINavigationController *navc = [[UINavigationController alloc] initWithRootViewController:svc];
    navc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navc animated:YES completion:nil];
}

- (void)presentDestructSightViewPreviewViewController:(RCMessageModel *)model {
    RCDestructSightViewController *svc = [[RCDestructSightViewController alloc] init];
    svc.messageModel = model;
    UINavigationController *navc = [[UINavigationController alloc] initWithRootViewController:svc];
    navc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navc
                       animated:YES
                     completion:^{

                     }];
}

/**
 *  打开地理位置。开发者可以重写，自己根据经纬度打开地图显示位置。默认使用内置地图
 *
 *  @param locationMessageContent 位置消息
 */
- (void)presentLocationViewController:(RCLocationMessage *)locationMessageContent {
    //默认方法跳转
    RCLocationViewController *locationViewController = [[RCLocationViewController alloc] init];
    locationViewController.locationName = locationMessageContent.locationName;
    locationViewController.location = locationMessageContent.location;
    locationViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    UINavigationController *navc = [[UINavigationController alloc] initWithRootViewController:locationViewController];
    if (self.navigationController) {
        //导航和原有的配色保持一直
        UIImage *image = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];

        [navc.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    }
    navc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navc animated:YES completion:NULL];
}

- (void)presentFilePreviewViewController:(RCMessageModel *)model {
    RCFilePreviewViewController *fileViewController = [[RCFilePreviewViewController alloc] init];
    fileViewController.messageModel = model;
    [self.navigationController pushViewController:fileViewController animated:YES];
}

#pragma mark - 消息发送
- (void)sendMessage:(RCMessageContent *)messageContent pushContent:(NSString *)pushContent {
    messageContent = [self willSendMessage:messageContent];
    if (messageContent == nil) {
        return;
    }
    [self.util doSendMessage:messageContent pushContent:pushContent];
}

- (void)sendMediaMessage:(RCMessageContent *)messageContent pushContent:(NSString *)pushContent {
    messageContent = [self willSendMessage:messageContent];
    if (messageContent == nil) {
        return;
    }
    [self.util doSendMessage:messageContent pushContent:pushContent];
}

- (void)sendMediaMessage:(RCMessageContent *)messageContent
             pushContent:(NSString *)pushContent
               appUpload:(BOOL)appUpload {
    if (!appUpload) {
        [self sendMessage:messageContent pushContent:pushContent];
        return;
    }
    __weak typeof(self) ws = self;
    RCConversationType conversationType = self.conversationType;
    NSString *targetId = [self.targetId copy];
    RCMessage *rcMessage = [[RCIMClient sharedRCIMClient] sendMediaMessage:conversationType
        targetId:targetId
        content:messageContent
        pushContent:pushContent
        pushData:@""
        uploadPrepare:^(RCUploadMediaStatusListener *uploadListener) {
            [ws uploadMedia:uploadListener.currentMessage uploadListener:uploadListener];
        }
        progress:^(int progress, long messageId) {
            NSDictionary *statusDic = @{
                @"targetId" : targetId,
                @"conversationType" : @(conversationType),
                @"messageId" : @(messageId),
                @"sentStatus" : @(SentStatus_SENDING),
                @"progress" : @(progress)
            };
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RCKitSendingMessageNotification"
                                                                object:nil
                                                              userInfo:statusDic];
        }
        success:^(long messageId) {
            NSDictionary *statusDic = @{
                @"targetId" : targetId,
                @"conversationType" : @(conversationType),
                @"messageId" : @(messageId),
                @"sentStatus" : @(SentStatus_SENT),
                @"content" : messageContent
            };
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RCKitSendingMessageNotification"
                                                                object:nil
                                                              userInfo:statusDic];
        }
        error:^(RCErrorCode errorCode, long messageId) {
            NSDictionary *statusDic = @{
                @"targetId" : targetId,
                @"conversationType" : @(conversationType),
                @"messageId" : @(messageId),
                @"sentStatus" : @(SentStatus_FAILED),
                @"error" : @(errorCode),
                @"content" : messageContent
            };
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RCKitSendingMessageNotification"
                                                                object:nil
                                                              userInfo:statusDic];
        }
        cancel:^(long messageId) {
            NSDictionary *statusDic = @{
                @"targetId" : targetId,
                @"conversationType" : @(conversationType),
                @"messageId" : @(messageId),
                @"sentStatus" : @(SentStatus_CANCELED),
                @"content" : messageContent
            };
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RCKitSendingMessageNotification"
                                                                object:nil
                                                              userInfo:statusDic];
        }];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"RCKitSendingMessageNotification"
                                                        object:rcMessage
                                                      userInfo:nil];
}

- (void)uploadMedia:(RCMessage *)message uploadListener:(RCUploadMediaStatusListener *)uploadListener {
    uploadListener.errorBlock(-1);
    NSLog(@"error, App应该实现uploadMedia:uploadListener:函数用来上传媒体");
    //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //            int i = 0;
    //            for (i = 0; i < 100; i++) {
    //                uploadListener.updateBlock(i);
    //                [NSThread sleepForTimeInterval:0.2];
    //            }
    //            RCImageMessage *imageMsg = (RCImageMessage*)message.content;
    //            imageMsg.imageUrl = @"http://www.rongcloud.cn/images/newVersion/bannerInner.png?0717";
    //            uploadListener.successBlock(imageMsg);
    //        });
}

//接口向后兼容 [[++
- (void)sendImageMessage:(RCImageMessage *)imageMessage pushContent:(NSString *)pushContent {
    [self sendMessage:imageMessage pushContent:pushContent];
}

- (void)sendImageMessage:(RCImageMessage *)imageMessage pushContent:(NSString *)pushContent appUpload:(BOOL)appUpload {
    if (!appUpload) {
        [self sendMessage:imageMessage pushContent:pushContent];
        return;
    }
    [self sendMediaMessage:imageMessage pushContent:pushContent appUpload:appUpload];
}

- (void)resendMessage:(RCMessageContent *)messageContent {
    if ([messageContent isMemberOfClass:RCImageMessage.class]) {
        RCImageMessage *imageMessage = (RCImageMessage *)messageContent;
        if (imageMessage.imageUrl) {
            imageMessage.originalImage = [UIImage imageWithContentsOfFile:imageMessage.imageUrl];
        } else {
            imageMessage.originalImage = [UIImage imageWithContentsOfFile:imageMessage.localPath];
        }
        [self sendMessage:imageMessage pushContent:nil];
    } else if ([messageContent isMemberOfClass:RCFileMessage.class]) {
        RCFileMessage *fileMessage = (RCFileMessage *)messageContent;
        [self sendMessage:fileMessage pushContent:nil];
    } else {
        [self sendMessage:messageContent pushContent:nil];
    }
}

- (void)uploadImage:(RCMessage *)message uploadListener:(RCUploadImageStatusListener *)uploadListener {
    if (!uploadListener) {
        NSLog(@"error, App应该实现uploadImage函数用来上传图片");
        return;
    }
    uploadListener.errorBlock(-1);
    NSLog(@"error, App应该实现uploadImage函数用来上传图片");
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //        int i = 0;
    //        for (i = 0; i < 100; i++) {
    //            uploadListener.updateBlock(i);
    //            [NSThread sleepForTimeInterval:0.2];
    //        }
    //        uploadListener.successBlock(@"http://www.rongcloud.cn/images/newVersion/bannerInner.png?0717");
    //    });
}
//接口向后兼容 --]]

- (void)cancelUploadMedia:(RCMessageModel *)model {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[RCIM sharedRCIM] cancelSendMediaMessage:model.messageId];
    });
}

#pragma mark - RCChatSessionInputBarControlDelegate 输入工具栏回调

- (void)chatInputBar:(RCChatSessionInputBarControl *)chatInputBar shouldChangeFrame:(CGRect)frame {
    if ([self updateReferenceViewFrame]) {
        return;
    }
    CGRect collectionViewRect = self.conversationMessageCollectionView.frame;
    collectionViewRect.size.height = CGRectGetMinY(frame) - collectionViewRect.origin.y;
    if (!chatInputBar.hidden) {
        [self.conversationMessageCollectionView setFrame:collectionViewRect];
    }
    if ([RCKitUtility isRTL]) {
        [self.unreadRightBottomIcon setFrame:CGRectMake(5.5, self.chatSessionInputBarControl.frame.origin.y - 12 - 35, 35, 35)];
    } else {
        [self.unreadRightBottomIcon setFrame:CGRectMake(self.view.frame.size.width - 5.5 - 35, self.chatSessionInputBarControl.frame.origin.y - 12 - 35, 35, 35)];
    }
    if (self.locatedMessageSentTime == 0 || self.isConversationAppear) {
        //在viewwillapear和viewdidload之前，如果强制定位，则不滑动到底部
        if (self.dataSource.isLoadingHistoryMessage || [self isRemainMessageExisted]) {
            [self loadRemainMessageAndScrollToBottom:YES];
        } else {
            [self scrollToBottomAnimated:NO];
        }
    }
}

- (void)inputTextViewDidTouchSendKey:(UITextView *)inputTextView {
    if ([self sendReferenceMessage:inputTextView.text]) {
        return;
    }
    RCTextMessage *rcTextMessage = [RCTextMessage messageWithContent:inputTextView.text];
    rcTextMessage.mentionedInfo = self.chatSessionInputBarControl.mentionedInfo;
    [self sendMessage:rcTextMessage pushContent:nil];
}

- (void)inputTextView:(UITextView *)inputTextView
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text {
    if (RCKitConfigCenter.message.enableTypingStatus && ![text isEqualToString:@"\n"]) {
        [[RCIMClient sharedRCIMClient] sendTypingStatus:self.conversationType
                                               targetId:self.targetId
                                            contentType:[RCTextMessage getObjectName]];
    }
    //接收 10 条以上消息,进入到聊天页面点击键盘使弹起,再次点击右上角 x 条未读消息,键盘输入文本，页面没有滚动到底部
    if (self.dataSource.isLoadingHistoryMessage || [self isRemainMessageExisted]) {
        [self loadRemainMessageAndScrollToBottom:YES];
    }
}

- (void)pluginBoardView:(RCPluginBoardView *)pluginBoardView clickedItemWithTag:(NSInteger)tag {
    switch (tag) {
    case PLUGIN_BOARD_ITEM_ALBUM_TAG: {
        [self openSystemAlbum];
    } break;
    case PLUGIN_BOARD_ITEM_CAMERA_TAG: {
        [self openSystemCamera];
    } break;
    case PLUGIN_BOARD_ITEM_LOCATION_TAG: {
        [self openLocationPicker];
    } break;
    case PLUGIN_BOARD_ITEM_DESTRUCT_TAG: {
        [self switchDestructMessageMode];
    } break;
    case PLUGIN_BOARD_ITEM_FILE_TAG: {
        [self openFileSelector];
    } break;
    case PLUGIN_BOARD_ITEM_EVA_TAG: {
        [self commentCustomerServiceWithStatus:self.csUtil.currentServiceStatus commentId:nil quitAfterComment:NO];
    } break;
    case PLUGIN_BOARD_ITEM_VOICE_INPUT_TAG: {
        if ([[RCExtensionService sharedService] isAudioHolding]) {
            NSString *alertMessage = RCLocalizedString(@"AudioHoldingWarning");
            [RCAlertView showAlertController:alertMessage message:nil hiddenAfterDelay:1 inViewController:self];
        } else {
            [self openDynamicFunction:tag];
        }
    } break;
    default: { [self openDynamicFunction:tag]; } break;
    }
}

- (void)presentViewController:(UIViewController *)viewController functionTag:(NSInteger)functionTag {
    switch (functionTag) {
    case PLUGIN_BOARD_ITEM_ALBUM_TAG:
    case PLUGIN_BOARD_ITEM_CAMERA_TAG:
    case PLUGIN_BOARD_ITEM_LOCATION_TAG:
    case PLUGIN_BOARD_ITEM_FILE_TAG:
    case INPUT_MENTIONED_SELECT_TAG: {
        viewController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.navigationController presentViewController:viewController animated:YES completion:nil];
    } break;
    default: { } break; }
}

#pragma mark 输入工具栏各种扩展功能点击事件
//打开系统相册
- (void)openSystemAlbum {
    [self.chatSessionInputBarControl openSystemAlbum];
}
//打开相机
- (void)openSystemCamera {
    [self.chatSessionInputBarControl openSystemCamera];
}
//打开位置
- (void)openLocationPicker {
    [self.chatSessionInputBarControl openLocationPicker];
}
//开关阅后即焚功能
- (void)switchDestructMessageMode {
    if (self.chatSessionInputBarControl.destructMessageMode) {
        [self.chatSessionInputBarControl resetToDefaultStatus];
    } else {
        [self.util alertDestructMessageRemind];
        [self.chatSessionInputBarControl setDefaultInputType:RCChatSessionInputBarInputDestructMode];
    }
}
//打开文件选择
- (void)openFileSelector {
    [self.chatSessionInputBarControl openFileSelector];
}
//打开其他的 Extention 功能，如音视频功能
- (void)openDynamicFunction:(NSInteger)functionTag {
    [self.chatSessionInputBarControl openDynamicFunction:functionTag];
}

- (void)emojiView:(RCEmojiBoardView *)emojiView didTouchedEmoji:(NSString *)touchedEmoji {

    if (RCKitConfigCenter.message.enableTypingStatus) {
        [[RCIMClient sharedRCIMClient] sendTypingStatus:self.conversationType
                                               targetId:self.targetId
                                            contentType:[RCTextMessage getObjectName]];
    }
}

- (void)emojiView:(RCEmojiBoardView *)emojiView didTouchSendButton:(UIButton *)sendButton {
    if ([self sendReferenceMessage:self.chatSessionInputBarControl.inputTextView.text]) {
        return;
    }
    RCTextMessage *rcTextMessage =
        [RCTextMessage messageWithContent:self.chatSessionInputBarControl.inputTextView.text];
    rcTextMessage.mentionedInfo = self.chatSessionInputBarControl.mentionedInfo;

    [self sendMessage:rcTextMessage pushContent:nil];
}

//点击常用语的回调
- (void)commonPhrasesViewDidTouch:(NSString *)commonPhrases {
    RCTextMessage *rcTextMessage = [RCTextMessage messageWithContent:commonPhrases];
    [self sendMessage:rcTextMessage pushContent:nil];
}
#pragma mark 录音
//语音消息开始录音
- (void)recordDidBegin {
    if (RCKitConfigCenter.message.enableTypingStatus) {
        [[RCIMClient sharedRCIMClient] sendTypingStatus:self.conversationType
                                               targetId:self.targetId
                                            contentType:[RCVoiceMessage getObjectName]];
    }

    [self onBeginRecordEvent];
}

//语音消息录音结束
- (void)recordDidEnd:(NSData *)recordData duration:(long)duration error:(NSError *)error {
    if (error == nil) {
        if (self.conversationType == ConversationType_CUSTOMERSERVICE ||
            [RCIMClient sharedRCIMClient].voiceMsgType == RCVoiceMessageTypeOrdinary) {
            RCVoiceMessage *voiceMessage = [RCVoiceMessage messageWithAudio:recordData duration:duration];
            [self sendMessage:voiceMessage pushContent:nil];
        } else if ([RCIMClient sharedRCIMClient].voiceMsgType == RCVoiceMessageTypeHighQuality) {
            NSString *path = [self.util getHQVoiceMessageCachePath];
            [recordData writeToFile:path atomically:YES];
            RCHQVoiceMessage *hqVoiceMsg = [RCHQVoiceMessage messageWithPath:path duration:duration];
            [self sendMessage:hqVoiceMsg pushContent:nil];
        }
    }

    [self onEndRecordEvent];
}

//语音消息开始录音
- (void)recordDidCancel {
    [self onCancelRecordEvent];
}

//接口向后兼容[[++
- (void)onBeginRecordEvent {
}

- (void)onEndRecordEvent {
}

- (void)onCancelRecordEvent {
}
//接口向后兼容--]]

#pragma mark 事件回调
//图片选择回调
- (void)imageDataDidSelect:(NSArray *)selectedImages fullImageRequired:(BOOL)full {
    [self becomeFirstResponder];
    self.isTakeNewPhoto = NO;
    [self.util doSendSelectedMediaMessage:selectedImages fullImageRequired:full];
}
//位置选择回调
- (void)locationDidSelect:(CLLocationCoordinate2D)location
             locationName:(NSString *)locationName
            mapScreenShot:(UIImage *)mapScreenShot {
    [self becomeFirstResponder];
    RCLocationMessage *locationMessage =
        [RCLocationMessage messageWithLocationImage:mapScreenShot location:location locationName:locationName];
    [self sendMessage:locationMessage pushContent:nil];
}

//选择相册图片或者拍照回调
- (void)imageDidCapture:(UIImage *)image {
    [self becomeFirstResponder];
    image = [RCKitUtility fixOrientation:image];
    RCImageMessage *imageMessage = [RCImageMessage messageWithImage:image];
    self.isTakeNewPhoto = YES;
    [self sendMessage:imageMessage pushContent:nil];
}
//视频完成录制
- (void)sightDidFinishRecord:(NSString *)url thumbnail:(UIImage *)image duration:(NSUInteger)duration {
    RCSightMessage *sightMessage = [RCSightMessage messageWithLocalPath:url thumbnail:image duration:duration];
    [self sendMessage:sightMessage pushContent:nil];
}

//文件列表被选中
- (void)fileDidSelect:(NSArray *)filePathList {
    [self becomeFirstResponder];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSString *filePath in filePathList) {
            RCFileMessage *fileMessage = [RCFileMessage messageWithFile:filePath];
            [self sendMessage:fileMessage pushContent:nil];
            [NSThread sleepForTimeInterval:0.5];
        }
    });
}

#pragma mark <RCChatSessionInputBarControlDataSource>
- (void)getSelectingUserIdList:(void (^)(NSArray<NSString *> *userIdList))completion
                   functionTag:(NSInteger)functionTag {
    switch (functionTag) {
    case INPUT_MENTIONED_SELECT_TAG: {
        if (self.conversationType == ConversationType_DISCUSSION) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [[RCDiscussionClient sharedDiscussionClient] getDiscussion:self.targetId
                success:^(RCDiscussion *discussion) {
                    if (completion) {
                        completion(discussion.memberIdList);
                    }
                }
                error:^(RCErrorCode status) {
                    if (completion) {
                        completion(nil);
                    }
                }];
#pragma clang diagnostic pop
        } else if (self.conversationType == ConversationType_GROUP) {
            if ([[RCIM sharedRCIM].groupMemberDataSource respondsToSelector:@selector(getAllMembersOfGroup:result:)]) {
                [[RCIM sharedRCIM]
                        .groupMemberDataSource getAllMembersOfGroup:self.targetId
                                                             result:^(NSArray<NSString *> *userIdList) {
                                                                 if (completion) {
                                                                     completion(userIdList);
                                                                 }
                                                             }];
            } else {
                if (completion) {
                    completion(nil);
                }
            }
        }
    } break;
    default: {
        if (completion) {
            completion(nil);
        }

    } break;
    }
}

- (RCUserInfo *)getSelectingUserInfo:(NSString *)userId {
    if (self.conversationType == ConversationType_GROUP) {
        return [[RCUserInfoCacheManager sharedManager] getUserInfo:userId inGroupId:self.targetId];
    } else {
        return [[RCUserInfoCacheManager sharedManager] getUserInfo:userId];
    }
}

#pragma mark - 单条消息处理
//复制消息内容
- (void)onCopyMessage:(id)sender {
    // self.msgInputBar.msgColumnTextView.disableActionMenu = NO;
    self.chatSessionInputBarControl.inputTextView.disableActionMenu = NO;
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    // RCMessageCell* cell = _RCMessageCell;
    //判断是否文本消息
    if ([self.currentSelectedModel.content isKindOfClass:[RCTextMessage class]]) {
        RCTextMessage *text = (RCTextMessage *)self.currentSelectedModel.content;
        [pasteboard setString:text.content];
    } else if ([self.currentSelectedModel.content isKindOfClass:[RCReferenceMessage class]]) {
        RCReferenceMessage *refer = (RCReferenceMessage *)self.currentSelectedModel.content;
        [pasteboard setString:refer.content];
    }
}
//删除消息内容
- (void)onDeleteMessage:(id)sender {
    self.chatSessionInputBarControl.inputTextView.disableActionMenu = NO;
    RCMessageModel *model = self.currentSelectedModel;

    //删除消息时如果是当前播放的消息就停止播放
    if ([RCVoicePlayer defaultPlayer].isPlaying && [RCVoicePlayer defaultPlayer].messageId == model.messageId) {
        [[RCVoicePlayer defaultPlayer] stopPlayVoice];
    }
    [self deleteMessage:model];
}
//撤回消息动作
- (void)onRecallMessage:(id)sender {
    if ([self.util canRecallMessageOfModel:self.currentSelectedModel]) {
        self.chatSessionInputBarControl.inputTextView.disableActionMenu = NO;
        RCMessageModel *model = self.currentSelectedModel;
        [self recallMessage:model.messageId];
    } else {
        [RCAlertView showAlertController:nil message:RCLocalizedString(@"CanNotRecall") cancelTitle:RCLocalizedString(@"OK") inViewController:self];
    }
}
//撤回消息事件
- (void)recallMessage:(long)messageId {
    RCMessage *msg = [[RCIMClient sharedRCIMClient] getMessage:messageId];
    if (msg.messageDirection != MessageDirection_SEND && msg.sentStatus != SentStatus_SENT) {
        NSLog(@"Error，only successfully sent messages can be recalled！！！");
        return;
    }

    __block RCRecallMessageImageView *recallMessageImageView =
        [[RCRecallMessageImageView alloc] initWithFrame:CGRectMake(0, 0, 135, 135)];
    //将 recallMessageImageView 添加到优先级最高的 window 上,避免键盘被遮挡
    [[RCKitUtility getKeyWindow] addSubview:recallMessageImageView];
    [recallMessageImageView setCenter:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2)];
    [recallMessageImageView startAnimating];
    __weak typeof(self) ws = self;
    [[RCIMClient sharedRCIMClient] recallMessage:msg
        pushContent:nil
        success:^(long messageId) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([RCVoicePlayer defaultPlayer].isPlaying &&
                    [RCVoicePlayer defaultPlayer].messageId == msg.messageId) {
                    [[RCVoicePlayer defaultPlayer] stopPlayVoice];
                }

                [ws reloadRecalledMessage:messageId];

                [recallMessageImageView stopAnimating];
                [recallMessageImageView removeFromSuperview];
                // private method
                [[NSNotificationCenter defaultCenter] postNotificationName:@"RCEConversationUpdateNotification"
                                                                    object:nil];
            });
        }
        error:^(RCErrorCode errorcode) {
            dispatch_async(dispatch_get_main_queue(), ^{

                [recallMessageImageView stopAnimating];
                [recallMessageImageView removeFromSuperview];
                [RCAlertView showAlertController:nil message:RCLocalizedString(@"MessageRecallFailed") cancelTitle:RCLocalizedString(@"OK") inViewController:self];
            });
        }];
}
//重新加载撤回消息
- (void)reloadRecalledMessage:(long)recalledMsgId {
    [self.dataSource didReloadRecalledMessage:recalledMsgId];

    if (self.referencingView && self.referencingView.referModel.messageId == recalledMsgId) {
        [self dismissReferencingView:self.referencingView];
    }
}
//删除消息
- (void)deleteMessage:(RCMessageModel *)model {
    if (self.conversationDataRepository.count == 0) {
        return;
    }
    [self.util stopVoiceMessageIfNeed:model];
    
    NSIndexPath *indexPath = [self.util findDataIndexFromMessageList:model];
    if (!indexPath) {
        return;
    } else{
        //如果要删除的消息是显示时间的，且下一条消息又没有显示时间，则删除消息之后，下一条消息需要显示时间
        RCMessageModel *msgModel = self.conversationDataRepository[indexPath.row];
        if (msgModel.isDisplayMessageTime) {
            int nextIndex = (int)indexPath.row+1;
            if(nextIndex < self.conversationDataRepository.count){
                RCMessageModel *nextModel = self.conversationDataRepository[nextIndex];
                if (nextModel && !nextModel.isDisplayMessageTime) {
                    nextModel.isDisplayMessageTime = YES;
                    nextModel.cellSize = CGSizeZero;
                    [self.conversationMessageCollectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:nextIndex inSection:0]]];
                }
            }
        }
    }
    
    long msgId = model.messageId;
    [[RCIMClient sharedRCIMClient] deleteMessages:@[ @(msgId) ]];
    [self.conversationDataRepository removeObjectAtIndex:indexPath.item];
    //偶现 查看阅后即焚小视频或者图片， 切换到后台在进入崩溃，原因是 indexPath 越界，怀疑从后台进入后会自动重新刷新 collecttionView
    if (indexPath.row < [self.conversationMessageCollectionView numberOfItemsInSection:0]) {
        [self.conversationMessageCollectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
    }
    
    [self deleteOldMessageNotificationMessageIfNeed];
    
    if (model) {
        if ([[RCMessageSelectionUtility sharedManager] isContainMessage:model]) {
            [[RCMessageSelectionUtility sharedManager] removeMessageModel:model];
        }
    }
}

- (void)deleteOldMessageNotificationMessageIfNeed {
    //如果“以上是历史消息(RCOldMessageNotificationMessage)”上面或者下面没有消息了，把RCOldMessageNotificationMessage也删除
    if (self.conversationDataRepository.count > 0) {
        RCMessageModel *lastOldModel = self.conversationDataRepository[0];
        RCMessageModel *lastNewModel = self.conversationDataRepository[self.conversationDataRepository.count - 1];

        if ([lastOldModel.content isKindOfClass:[RCOldMessageNotificationMessage class]]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self.conversationDataRepository removeObject:lastOldModel];
            [self.conversationMessageCollectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];

            //删除“以上是历史消息”之后，会话的第一条消息显示时间，并且调整高度
            RCMessageModel *topMsg = (self.conversationDataRepository)[0];
            topMsg.isDisplayMessageTime = YES;
            topMsg.cellSize = CGSizeMake(topMsg.cellSize.width, topMsg.cellSize.height + 30);
            RCMessageCell *__cell = (RCMessageCell *)[self.conversationMessageCollectionView
                cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            if (__cell) {
                [__cell setDataModel:topMsg];
            }
            [self.conversationMessageCollectionView reloadData];
        }
        if ([lastNewModel.content isKindOfClass:[RCOldMessageNotificationMessage class]]) {
            NSIndexPath *indexPath =
                [NSIndexPath indexPathForRow:self.conversationDataRepository.count - 1 inSection:0];
            [self.conversationDataRepository removeObject:lastNewModel];
            [self.conversationMessageCollectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
        }
    }
}

- (void)notifyUpdateUnreadMessageCount {
    __weak typeof(self) __weakself = self;
    //如果消息是选择状态，不更新leftBar
    if (self.allowsMessageCellSelection) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __weakself.rightBarButtonItems = __weakself.navigationItem.rightBarButtonItems;
            __weakself.leftBarButtonItems = __weakself.navigationItem.leftBarButtonItems;
            __weakself.navigationItem.rightBarButtonItems = nil;
            __weakself.navigationItem.leftBarButtonItems = nil;
            UIBarButtonItem *left =
                [[UIBarButtonItem alloc] initWithTitle:RCLocalizedString(@"Cancel")
                                                 style:UIBarButtonItemStylePlain
                                                target:self
                                                action:@selector(onCancelMultiSelectEvent:)];

            [left setTintColor:RCKitConfigCenter.ui.globalNavigationBarTintColor];
            self.navigationItem.leftBarButtonItem = left;
        });
    } else {
        if(!self.displayConversationTypeArray) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __weakself.navigationItem.leftBarButtonItems = __weakself.leftBarButtonItems;
                __weakself.leftBarButtonItems = nil;
                if (__weakself.conversationType != ConversationType_Encrypted && __weakself.rightBarButtonItems) {
                    __weakself.navigationItem.rightBarButtonItems = __weakself.rightBarButtonItems;
                    __weakself.rightBarButtonItems = nil;
                }
            });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [__weakself.navigationItem setLeftBarButtonItems:[__weakself getLeftBackButton]];
            __weakself.leftBarButtonItems = nil;
            if (__weakself.rightBarButtonItems) {
                __weakself.navigationItem.rightBarButtonItems = __weakself.rightBarButtonItems;
                __weakself.rightBarButtonItems = nil;
            }
        });
    }
}


#pragma mark override
- (void)didTapImageTxtMsgCell:(NSString *)tapedUrl webViewController:(UIViewController *)rcWebViewController {
    rcWebViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    if ([rcWebViewController isKindOfClass:[SFSafariViewController class]]) {
        [self presentViewController:rcWebViewController animated:YES completion:nil];
    } else {
        UIWindow *window = [RCKitUtility getKeyWindow];
        UINavigationController *navigationController = (UINavigationController *)window.rootViewController;
        [navigationController pushViewController:rcWebViewController animated:YES];
    }
}

#pragma mark - PublicService
- (void)fetchPublicServiceProfile {
    if ([[RCIM sharedRCIM].publicServiceInfoDataSource respondsToSelector:@selector(publicServiceProfile:)]) {
        RCPublicServiceProfile *serviceProfile =
            [[RCIM sharedRCIM].publicServiceInfoDataSource publicServiceProfile:self.targetId];
        __weak typeof(self) weakSelf = self;
        void (^configureInputBar)(RCPublicServiceProfile *profile) = ^(RCPublicServiceProfile *profile) {
            if (profile.menu.menuItems) {
                [weakSelf.chatSessionInputBarControl
                    setInputBarType:RCChatSessionInputBarControlPubType
                              style:RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION];
                weakSelf.chatSessionInputBarControl.publicServiceMenu = profile.menu;
            }
            if (profile.disableInput && profile.disableMenu) {
                weakSelf.chatSessionInputBarControl.hidden = YES;
                CGFloat screenHeight = self.view.bounds.size.height;
                CGRect originFrame = weakSelf.conversationMessageCollectionView.frame;
                originFrame.size.height =
                    screenHeight - originFrame.origin.y - [weakSelf getSafeAreaExtraBottomHeight];
                weakSelf.conversationMessageCollectionView.frame = originFrame;
            }
        };
        if (serviceProfile) {
            configureInputBar(serviceProfile);
        } else {
            [[RCIM sharedRCIM]
                    .publicServiceInfoDataSource getPublicServiceProfile:self.targetId
                                                              completion:^(RCPublicServiceProfile *profile) {
                                                                  configureInputBar(serviceProfile);
                                                              }];
        }

    } else {
        RCPublicServiceProfile *profile =
            [[RCPublicServiceClient sharedPublicServiceClient] getPublicServiceProfile:(RCPublicServiceType)self.conversationType
                                                   publicServiceId:self.targetId];
        if (profile.menu.menuItems) {
            [self.chatSessionInputBarControl setInputBarType:RCChatSessionInputBarControlPubType
                                                       style:RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION];
            self.chatSessionInputBarControl.publicServiceMenu = profile.menu;
        }
    }

    RCPublicServiceCommandMessage *entryCommond =
        [RCPublicServiceCommandMessage messageWithCommand:@"entry" data:nil];
    [self sendMessage:entryCommond pushContent:nil];
}

- (void)onPublicServiceMenuItemSelected:(RCPublicServiceMenuItem *)selectedMenuItem {
    if (selectedMenuItem.type == RC_PUBLIC_SERVICE_MENU_ITEM_VIEW) {
        [RCKitUtility openURLInSafariViewOrWebView:selectedMenuItem.url base:self];
    }
    /// VIEW  要不要发消息
    RCPublicServiceCommandMessage *command = [RCPublicServiceCommandMessage messageFromMenuItem:selectedMenuItem];
    if (command) {
        [[RCIMClient sharedRCIMClient] sendMessage:self.conversationType
            targetId:self.targetId
            content:command
            pushContent:nil
            pushData:nil
            success:^(long messageId) {

            }
            error:^(RCErrorCode nErrorCode, long messageId){

            }];
    }
}

- (void)didTapUrlInPublicServiceMessageCell:(NSString *)url model:(RCMessageModel *)model {
    UIViewController *viewController = nil;
    url = [RCKitUtility checkOrAppendHttpForUrl:url];
    if (![RCIM sharedRCIM].embeddedWebViewPreferred && RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        viewController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url]];
    } else {
        viewController = [[RCPublicServiceClient sharedPublicServiceClient] getPublicServiceWebViewController:url];
        [viewController setValue:RCKitConfigCenter.ui.globalNavigationBarTintColor forKey:@"backButtonTextColor"];
    }
    [self didTapImageTxtMsgCell:url webViewController:viewController];
}
- (void)didLongTouchPublicServiceMessageCell:(RCMessageModel *)model inView:(UIView *)view {
    [self didLongTouchMessageCell:model inView:view];
}

#pragma mark - 点击事件
//点击cell
- (void)didTapMessageCell:(RCMessageModel *)model {
    DebugLog(@"%s", __FUNCTION__);
    if (nil == model) {
        return;
    }

    RCMessageContent *_messageContent = model.content;

    if (model.messageDirection == MessageDirection_RECEIVE && _messageContent.destructDuration > 0) {
        if ([self.util alertDestructMessageRemind]) {
            return;
        }
    }

    if ([_messageContent isMemberOfClass:[RCImageMessage class]]) {
        RCImageMessage *imageMsg = (RCImageMessage *)_messageContent;
        if (imageMsg.destructDuration > 0) {
            [self presentDestructImagePreviewController:model];
        } else {
            [self presentImagePreviewController:model];
        }

    } else if ([_messageContent isMemberOfClass:[RCSightMessage class]]) {
        if ([[RCExtensionService sharedService] isCameraHolding]) {
            NSString *alertMessage = RCLocalizedString(@"VoIPVideoCallExistedWarning");
            [RCAlertView showAlertController:nil message:alertMessage hiddenAfterDelay:1 inViewController:self];
            return;
        }
        if ([[RCExtensionService sharedService] isAudioHolding]) {
            NSString *alertMessage = RCLocalizedString(@"VoIPAudioCallExistedWarning");
            [RCAlertView showAlertController:nil message:alertMessage hiddenAfterDelay:1 inViewController:self];
            return;
        }
        RCSightMessage *sightMsg = (RCSightMessage *)_messageContent;
        if (sightMsg.destructDuration > 0) {
            [self presentDestructSightViewPreviewViewController:model];
        } else {
            [self presentSightViewPreviewViewController:model];
        }

    } else if ([_messageContent isMemberOfClass:[RCGIFMessage class]]) {
        RCGIFMessage *gifMsg = (RCGIFMessage *)_messageContent;
        if (gifMsg.destructDuration > 0) {
            [self pushDestructGIFPreviewViewController:model];
        } else {
            [self pushGIFPreviewViewController:model];
        }

    } else if ([_messageContent isMemberOfClass:[RCCombineMessage class]]) {
        RCCombineMessage *combineMsg = (RCCombineMessage *)_messageContent;
        if (combineMsg.destructDuration > 0) {
        } else {
            [self pushCombinePreviewViewController:model];
        }

    } else if ([_messageContent isMemberOfClass:[RCVoiceMessage class]]) {
        if ([[RCExtensionService sharedService] isAudioHolding]) {
            NSString *alertMessage = RCLocalizedString(@"AudioHoldingWarning");
            [RCAlertView showAlertController:nil message:alertMessage hiddenAfterDelay:1 inViewController:self];
            return;
        }
        if (model.messageDirection == MessageDirection_RECEIVE && model.receivedStatus != ReceivedStatus_LISTENED) {
            self.isContinuousPlaying = YES;
        } else {
            self.isContinuousPlaying = NO;
        }
        model.receivedStatus = ReceivedStatus_LISTENED;
        NSUInteger row = [self.conversationDataRepository indexOfObject:model];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        RCVoiceMessageCell *cell =
            (RCVoiceMessageCell *)[self.conversationMessageCollectionView cellForItemAtIndexPath:indexPath];
        if (cell) {
            [cell playVoice];
        }
    } else if ([_messageContent isMemberOfClass:[RCHQVoiceMessage class]]) {
        if ([[RCExtensionService sharedService] isAudioHolding]) {
            NSString *alertMessage = RCLocalizedString(@"AudioHoldingWarning");
            [RCAlertView showAlertController:nil message:alertMessage hiddenAfterDelay:1 inViewController:self];
            return;
        }
        if (model.messageDirection == MessageDirection_RECEIVE && model.receivedStatus != ReceivedStatus_LISTENED) {
            self.isContinuousPlaying = YES;
        } else {
            self.isContinuousPlaying = NO;
        }
        if (((RCHQVoiceMessage *)_messageContent).localPath.length > 0) {
            model.receivedStatus = ReceivedStatus_LISTENED;
        }
        NSUInteger row = [self.conversationDataRepository indexOfObject:model];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        RCHQVoiceMessageCell *cell =
            (RCHQVoiceMessageCell *)[self.conversationMessageCollectionView cellForItemAtIndexPath:indexPath];
        if (cell) {
            [cell playVoice];
        }
    } else if ([_messageContent isMemberOfClass:[RCLocationMessage class]]) {
        // Show the location view controller
        RCLocationMessage *locationMessage = (RCLocationMessage *)(_messageContent);
        [self presentLocationViewController:locationMessage];
    } else if ([_messageContent isMemberOfClass:[RCTextMessage class]]) {
        // link
        RCTextMessage *textMsg = (RCTextMessage *)(_messageContent);
        if (model.messageDirection == MessageDirection_RECEIVE && textMsg.destructDuration > 0) {
            NSUInteger row = [self.conversationDataRepository indexOfObject:model];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            if (model.messageDirection == MessageDirection_RECEIVE && textMsg.destructDuration > 0) {
                [[RCIMClient sharedRCIMClient]
                    messageBeginDestruct:[[RCIMClient sharedRCIMClient] getMessage:model.messageId]];
            }
            model.cellSize = CGSizeZero;
            //更新UI
            [self.conversationMessageCollectionView reloadItemsAtIndexPaths:@[ indexPath ]];
        }
        // phoneNumber
    } else if ([self isExtensionCell:_messageContent]) {
        [[RongIMKitExtensionManager sharedManager] didTapMessageCell:model];
    } else if ([_messageContent isMemberOfClass:[RCFileMessage class]]) {
        [self presentFilePreviewViewController:model];
    } else if ([_messageContent isMemberOfClass:[RCCSPullLeaveMessage class]]) {
        [self.csUtil didTapCSPullLeaveMessage:model];
    }
}

//长按消息内容
- (void)didLongTouchMessageCell:(RCMessageModel *)model inView:(UIView *)view {
    //长按消息需要停止播放语音消息
    [self.util stopVoiceMessageIfNeed:model];

    self.chatSessionInputBarControl.inputTextView.disableActionMenu = YES;
    self.currentSelectedModel = model;
    if (![self.chatSessionInputBarControl.inputTextView isFirstResponder]) {
        //聊天界面不为第一响应者时，长按消息，UIMenuController不能正常显示菜单
        // inputTextView 是第一响应者时，不需要再设置 self 为第一响应者，否则会导致键盘收起
        [self becomeFirstResponder];
    }
    CGRect rect = [self.view convertRect:view.frame fromView:view.superview];

    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setMenuItems:[self getLongTouchMessageCellMenuList:model]];
    if (@available(iOS 13.0, *)) {
        [menu showMenuFromView:self.view rect:rect];
    } else {
        [menu setTargetRect:rect inView:self.view];
        [menu setMenuVisible:YES animated:YES];
    }
}

- (NSArray<UIMenuItem *> *)getLongTouchMessageCellMenuList:(RCMessageModel *)model {
    UIMenuItem *copyItem = [[UIMenuItem alloc] initWithTitle:RCLocalizedString(@"Copy")
                                                      action:@selector(onCopyMessage:)];
    UIMenuItem *deleteItem =
        [[UIMenuItem alloc] initWithTitle:RCLocalizedString(@"Delete")
                                   action:@selector(onDeleteMessage:)];

    UIMenuItem *recallItem =
        [[UIMenuItem alloc] initWithTitle:RCLocalizedString(@"Recall")
                                   action:@selector(onRecallMessage:)];
    UIMenuItem *multiSelectItem =
        [[UIMenuItem alloc] initWithTitle:RCLocalizedString(@"MessageTapMore")
                                   action:@selector(onMultiSelectMessageCell:)];

    UIMenuItem *referItem =
        [[UIMenuItem alloc] initWithTitle:RCLocalizedString(@"Reference")
                                   action:@selector(onReferenceMessageCell:)];
    NSMutableArray *items = @[].mutableCopy;
    if (model.content.destructDuration > 0) {
        [items addObject:deleteItem];
        if ([self.util canRecallMessageOfModel:model]) {
            [items addObject:recallItem];
        }
        [items addObject:multiSelectItem];
    } else {
        if ([model.content isMemberOfClass:[RCTextMessage class]] ||
            [model.content isMemberOfClass:[RCReferenceMessage class]]) {
            [items addObject:copyItem];
        }
        [items addObject:deleteItem];
        if ([self.util canRecallMessageOfModel:model]) {
            [items addObject:recallItem];
        }
        if ([self.util canReferenceMessage:model]) {
            [items addObject:referItem];
        }

        [items addObject:multiSelectItem];
    }
    return items.copy;
}

- (void)didTapUrlInMessageCell:(NSString *)url model:(RCMessageModel *)model {
    [RCKitUtility openURLInSafariViewOrWebView:url base:self];
}

- (void)didTapReedit:(RCMessageModel *)model {
    // 获取被撤回的文本消息的内容
    RCRecallNotificationMessage *recallMessage = (RCRecallNotificationMessage *)model.content;
    NSString *content = recallMessage.recallContent;
    if (content.length > 0) {
        [self.chatSessionInputBarControl.inputTextView becomeFirstResponder];
        self.chatSessionInputBarControl.inputTextView.text =
            [NSString stringWithFormat:@"%@%@", self.chatSessionInputBarControl.inputTextView.text, content];
    }
}

- (void)didTapReferencedContentView:(RCMessageModel *)model {
    [self previewReferenceView:model];
}

- (void)didTapPhoneNumberInMessageCell:(NSString *)phoneNumber model:(RCMessageModel *)model {
    NSString *phoneStr = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneStr]];
}

//点击头像
- (void)didTapCellPortrait:(NSString *)userId {
}

- (void)didLongPressCellPortrait:(NSString *)userId {
    if (!self.chatSessionInputBarControl.isMentionedEnabled ||
        [userId isEqualToString:[RCIM sharedRCIM].currentUserInfo.userId]) {
        return;
    }

    [self.chatSessionInputBarControl addMentionedUser:[self getSelectingUserInfo:userId]];
    [self.chatSessionInputBarControl.inputTextView becomeFirstResponder];
}

#pragma mark 内部点击方法
- (void)tapRightBottomMsgCountIcon:(UIGestureRecognizer *)gesture {
    [self.dataSource tapRightBottomMsgCountIcon:gesture];
}

- (void)tap4ResetDefaultBottomBarStatus:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (self.chatSessionInputBarControl.currentBottomBarStatus != KBottomBarDefaultStatus &&
            self.chatSessionInputBarControl.currentBottomBarStatus != KBottomBarRecordStatus) {
            [self.chatSessionInputBarControl resetToDefaultStatus];
        }
    }
}

- (void)tapRightTopMsgUnreadButton:(UIButton *)sender {
    //表明已点击过UnReadButton，加载了新消息，用来判断已加载了多少新消息
    self.unReadButton.selected = YES;
    [self.dataSource tapRightTopMsgUnreadButton];
}

- (void)didTapCancelUploadButton:(RCMessageModel *)model {
    [self cancelUploadMedia:model];
}

- (void)didTapmessageFailedStatusViewForResend:(RCMessageModel *)model {
    // resending message.
    DebugLog(@"%s", __FUNCTION__);

    RCMessageContent *content = model.content;
    long msgId = model.messageId;
    NSIndexPath *indexPath = [self.util findDataIndexFromMessageList:model];
    if (!indexPath) {
        return;
    }
    if ([content isMemberOfClass:[RCHQVoiceMessage class]] && model.messageDirection == MessageDirection_RECEIVE) {
        RCMessage *message = [[RCIMClient sharedRCIMClient] getMessage:model.messageId];
        [[RCHQVoiceMsgDownloadManager defaultManager] pushVoiceMsgs:@[ message ] priority:NO];
        [self.conversationMessageCollectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
    } else {
        [[RCIMClient sharedRCIMClient] deleteMessages:@[ @(msgId) ]];
        [self.conversationDataRepository removeObject:model];
        [self.conversationMessageCollectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
        [self resendMessage:content];
    }
}

- (void)onTypingStatusChanged:(RCConversationType)conversationType
                     targetId:(NSString *)targetId
                       status:(NSArray *)userTypingStatusList {
    if (conversationType == self.conversationType && [targetId isEqualToString:self.targetId] &&
        RCKitConfigCenter.message.enableTypingStatus) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (userTypingStatusList == nil || userTypingStatusList.count == 0) {
                self.navigationItem.title = self.navigationTitle;
            } else {
                RCUserTypingStatus *typingStatus = (RCUserTypingStatus *)userTypingStatusList[0];
                if ([typingStatus.contentType isEqualToString:[RCTextMessage getObjectName]]) {
                    self.navigationItem.title = RCLocalizedString(@"typing");
                } else if ([typingStatus.contentType isEqualToString:[RCVoiceMessage getObjectName]]) {
                    self.navigationItem.title = RCLocalizedString(@"Speaking");
                }
            }
        });
    }
}

- (void)leftBarButtonItemPressed:(id)sender {
    [self quitConversationViewAndClear];
    if (self.navigationController && [self.navigationController.viewControllers.lastObject isEqual:self]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)customerServiceLeftCurrentViewController{
    [self.csUtil customerServiceLeftCurrentViewController];
}

- (void)alertErrorAndLeft:(NSString *)errorInfo {
    [RCAlertView showAlertController:nil message:errorInfo hiddenAfterDelay:1 inViewController:self dismissCompletion:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)rightBarButtonItemClicked:(id)sender {
    RCPublicServiceProfile *serviceProfile =
    [[RCPublicServiceClient sharedPublicServiceClient] getPublicServiceProfile:(RCPublicServiceType)self.conversationType
                                                               publicServiceId:self.targetId];
    
    RCPublicServiceProfileViewController *infoVC = [[RCPublicServiceProfileViewController alloc] init];
    infoVC.serviceProfile = serviceProfile;
    infoVC.fromConversation = YES;
    [self.navigationController pushViewController:infoVC animated:YES];
}

#pragma mark - Cell multi select
- (void)setAllowsMessageCellSelection:(BOOL)allowsMessageCellSelection {
    [[RCMessageSelectionUtility sharedManager] clear];
    [[RCMessageSelectionUtility sharedManager] setMultiSelect:allowsMessageCellSelection];
    dispatch_main_async_safe(^{
        [self updateConversationMessageCollectionView];
    });
}

- (BOOL)allowsMessageCellSelection {
    return [RCMessageSelectionUtility sharedManager].multiSelect;
}

- (void)onMultiSelectMessageCell:(id)sender {
    self.allowsMessageCellSelection = YES;
}

- (void)onCancelMultiSelectEvent:(UIBarButtonItem *)item {
    self.allowsMessageCellSelection = NO;
}

- (void)forwardMessageEnd {
    self.allowsMessageCellSelection = NO;
}

- (void)updateConversationMessageCollectionView {
    [self updateNavigationBarItem];
    if ([RCMessageSelectionUtility sharedManager].multiSelect) {
        if (self.chatSessionInputBarControl.currentBottomBarStatus != KBottomBarRecordStatus) {
            [self.chatSessionInputBarControl resetToDefaultStatus];
        }
        [[RCMessageSelectionUtility sharedManager] addMessageModel:self.currentSelectedModel];
    } else {
        self.currentSelectedModel = nil;
    }
    [self showToolBar:[RCMessageSelectionUtility sharedManager].multiSelect];
    NSArray<NSIndexPath *> *indexPathsForVisibleItems =
        [self.conversationMessageCollectionView indexPathsForVisibleItems];
    if (indexPathsForVisibleItems) {
        [self.conversationMessageCollectionView reloadItemsAtIndexPaths:indexPathsForVisibleItems];
    }
}

- (void)showToolBar:(BOOL)show {
    if (show) {
        [self.view addSubview:self.messageSelectionToolbar];
        [self dismissReferencingView:self.referencingView];
    } else {
        [self.messageSelectionToolbar removeFromSuperview];
    }
}

- (NSArray<RCMessageModel *> *)selectedMessages {
    return [[RCMessageSelectionUtility sharedManager] selectedMessages];
}

- (void)deleteMessages {
    for (int i = 0; i < self.selectedMessages.count; i++) {
        [self deleteMessage:self.selectedMessages[i]];
    }
    self.allowsMessageCellSelection = NO;
}

/// RCMessagesMultiSelectedProtocol method
/// @param status 选择状态：选择/取消选择
/// @param model cell 数据模型
- (BOOL)onMessagesMultiSelectedCountWillChanged:(RCMessageMultiSelectStatus)status model:(RCMessageModel *)model {
    BOOL executed = YES;
    switch (status) {
    case RCMessageMultiSelectStatusSelected:
        executed = [self willSelectMessage:model];
        break;
    case RCMessageMultiSelectStatusCancelSelected:
        executed = [self willCancelSelectMessage:model];
        break;
    default:
        break;
    }
    return executed;
}

- (void)onMessagesMultiSelectedCountDidChanged:(RCMessageMultiSelectStatus)status model:(RCMessageModel *)model {
    if (self.selectedMessages.count == 0) {
        for (UIBarButtonItem *item in self.messageSelectionToolbar.items) {
            item.enabled = NO;
        }
    } else {
        for (UIBarButtonItem *item in self.messageSelectionToolbar.items) {
            item.enabled = YES;
        }
    }
}

#pragma mark - Update Message SendStatus
- (void)updateForMessageSendOut:(RCMessage *)message {
    if ([message.content isKindOfClass:[RCImageMessage class]]) {
        RCImageMessage *img = (RCImageMessage *)message.content;
        img.originalImage = nil;
    }
    [self.dataSource appendSendOutMessage:message];
}

- (void)updateForMessageSendProgress:(int)progress messageId:(long)messageId {
    [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_PROGRESS messageId:messageId progress:progress];
}

- (void)updateForMessageSendSuccess:(long)messageId content:(RCMessageContent *)content {
    DebugLog(@"message<%ld> send succeeded ", messageId);
    [self.csUtil startNotSendMessageAlertTimer];

    __weak typeof(self) __weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (RCMessageModel *model in __weakself.conversationDataRepository) {
            if (model.messageId == messageId) {
                model.sentStatus = SentStatus_SENT;
                if (model.messageId > 0) {
                    RCMessage *message = [[RCIMClient sharedRCIMClient] getMessage:model.messageId];
                    if (message) {
                        model.sentTime = message.sentTime;
                        model.messageUId = message.messageUId;
                        model.content = message.content;
                    }
                }
                break;
            }
        }
        [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_SUCCESS messageId:messageId progress:0];
        if (messageId == __weakself.dataSource.showUnreadViewMessageId) {
            [__weakself updateLastMessageReadReceiptStatus:messageId content:content];
        }
    });

    [self didSendMessage:0 content:content];

    if ([content isKindOfClass:[RCImageMessage class]]) {
        RCImageMessage *imageMessage = (RCImageMessage *)content;
        if (self.enableSaveNewPhotoToLocalSystem && self.isTakeNewPhoto) {
            UIImage *image = [UIImage imageWithContentsOfFile:imageMessage.localPath];
            imageMessage = [RCImageMessage messageWithImage:image];
            [self saveNewPhotoToLocalSystemAfterSendingSuccess:imageMessage.originalImage];
        }
    }
}

- (void)updateLastMessageReadReceiptStatus:(long)messageId content:(RCMessageContent *)content {
    RCMessage *message = [[RCIMClient sharedRCIMClient] getMessage:messageId];
    RCMessageModel *model = [RCMessageModel modelWithMessage:message];
    if ([self.util enabledReadReceiptMessage:model]) {
        if ([RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.conversationType)] &&
            (self.conversationType == ConversationType_GROUP || self.conversationType == ConversationType_DISCUSSION)) {
            int len = (int)self.conversationDataRepository.count - 1;
            for (int i = len; i >= 0; i--) {
                RCMessageModel *model = self.conversationDataRepository[i];
                if (model.messageId == messageId) {
                    model.isCanSendReadReceipt = YES;
                    if (!model.readReceiptInfo) {
                        model.readReceiptInfo = [[RCReadReceiptInfo alloc] init];
                    }
                } else {
                    model.isCanSendReadReceipt = NO;
                }
            }
        }
        if ([RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.conversationType)] &&
            (self.conversationType == ConversationType_DISCUSSION || self.conversationType == ConversationType_GROUP)) {
            NSDictionary *statusDic = @{
                @"targetId" : self.targetId,
                @"conversationType" : @(self.conversationType),
                @"messageId" : @(messageId)
            };
            [[NSNotificationCenter defaultCenter]
                postNotificationName:@"KNotificationMessageBaseCellUpdateCanReceiptStatus"
                              object:statusDic];
        }
    }
    dispatch_after(
        // 0.3s之后再刷新一遍，防止没有Cell绘制太慢
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_SUCCESS messageId:messageId progress:0];
            if ([RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.conversationType)] &&
                (self.conversationType == ConversationType_DISCUSSION ||
                 self.conversationType == ConversationType_GROUP) &&
                [content isMemberOfClass:[RCTextMessage class]]) {
                NSDictionary *statusDic = @{
                    @"targetId" : self.targetId,
                    @"conversationType" : @(self.conversationType),
                    @"messageId" : @(messageId)
                };
                [[NSNotificationCenter defaultCenter]
                    postNotificationName:@"KNotificationMessageBaseCellUpdateCanReceiptStatus"
                                  object:statusDic];
            }
        });
}

- (void)updateForMessageSendError:(RCErrorCode)nErrorCode
                        messageId:(long)messageId
                          content:(RCMessageContent *)content
             ifResendNotification:(bool)ifResendNotification{
    DebugLog(@"message<%ld> send failed error code %d", messageId, (int)nErrorCode);


    __weak typeof(self) __weakself = self;
    dispatch_after(
        // 发送失败0.3s之后再刷新，防止没有Cell绘制太慢
        dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.3f), dispatch_get_main_queue(), ^{
            for (RCMessageModel *model in __weakself.conversationDataRepository) {
                if (model.messageId == messageId) {
                    model.sentStatus = SentStatus_FAILED;
                    break;
                }
            }
            [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_FAILED messageId:messageId progress:0];
        });

    [self didSendMessage:nErrorCode content:content];

    RCInformationNotificationMessage *informationNotifiMsg = [self.util getInfoNotificationMessageByErrorCode:nErrorCode];
    if (nil != informationNotifiMsg && !ifResendNotification) {
        __block RCMessage *tempMessage = [[RCIMClient sharedRCIMClient] insertOutgoingMessage:self.conversationType
                                                                                     targetId:self.targetId
                                                                                   sentStatus:SentStatus_SENT
                                                                                      content:informationNotifiMsg];
        dispatch_async(dispatch_get_main_queue(), ^{
            tempMessage = [__weakself willAppendAndDisplayMessage:tempMessage];
            if (tempMessage) {
                [__weakself appendAndDisplayMessage:tempMessage];
            }
        });
    }
}

- (void)updateForMessageSendCanceled:(long)messageId content:(RCMessageContent *)content {
    DebugLog(@"message<%ld> canceled", messageId);

    __weak typeof(self) __weakself = self;
    dispatch_after(
        // 发送失败0.3s之后再刷新，防止没有Cell绘制太慢
        dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.3f), dispatch_get_main_queue(), ^{
            for (RCMessageModel *model in __weakself.conversationDataRepository) {
                if (model.messageId == messageId) {
                    model.sentStatus = SentStatus_CANCELED;
                    break;
                }
            }

            [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_CANCELED messageId:messageId progress:0];
        });

    [self didCancelMessage:content];
}

#pragma mark - download
- (void)updateDownloadStatus:(NSNotification *)noti {
    RCHQVoiceMsgDownloadInfo *info = noti.object;
    RCMessageModel *model;
    RCHQVoiceMessage *message;
    if (info.status == RCHQDownloadStatusSuccess) {
        for (int i = (int)self.conversationDataRepository.count - 1; i >= 0; i--) {
            model = self.conversationDataRepository[i];
            if (model.messageId == info.hqVoiceMsg.messageId &&
                [model.content isKindOfClass:[RCHQVoiceMessage class]]) {
                message = (RCHQVoiceMessage *)model.content;
                message.localPath = ((RCHQVoiceMessage *)info.hqVoiceMsg.content).localPath;
                break;
            }
        }
    }
}

- (void)downloadMediaNotification:(NSNotification *)noti {
    NSDictionary *info = noti.userInfo;
    if ([[info objectForKey:@"type"] isEqualToString:@"success"]) {
        NSInteger messageid = [[info objectForKey:@"messageId"] integerValue];
        RCMessageModel *model;
        RCGIFMessage *message;
        for (int i = 0; i < self.conversationDataRepository.count; i++) {
            model = self.conversationDataRepository[i];
            if (model.messageId == messageid && [model.content isKindOfClass:[RCGIFMessage class]]) {
                message = (RCGIFMessage *)model.content;
                message.localPath = [info objectForKey:@"mediaPath"];
                break;
            }
        }
    }
}

#pragma mark - 消息阅后即焚

/**
 阅后即焚消息正在焚烧的回调

 @param notification 通知对象
 notification的object为nil，userInfo为NSDictionary对象，
 其中key值分别为@"message"、@"remainDuration"
 对应的value为焚烧的消息对象、该消息剩余的焚烧时间。

 @discussion
 该方法即RCKitMessageDestructingNotification通知方法，如果继承该类则不需要注册RCKitMessageDestructingNotification通知，直接实现该方法即可
 @discussion 如果您使用IMLib请参考RCIMClient的RCMessageDestructDelegate
 */
- (void)onMessageDestructing:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *dataDict = notification.userInfo;
        RCMessage *message = dataDict[@"message"];
        NSTimeInterval duration = [dataDict[@"remainDuration"] doubleValue];

        if (duration > 0) {
            NSString *msgUId = message.messageUId;
            RCMessageModel *msgModel;
            for (RCMessageCell *cell in self.conversationMessageCollectionView.visibleCells) {
                msgModel = cell.model;
                if ([msgModel.messageUId isEqualToString:msgUId] &&
                    [cell respondsToSelector:@selector(messageDestructing)]) {
                    [cell performSelectorOnMainThread:@selector(messageDestructing) withObject:nil waitUntilDone:NO];
                }
            }
        } else {
            [self deleteMessage:[RCMessageModel modelWithMessage:message]];
        }

        //钩子
        [self messageDestructing:notification];
    });
}

- (void)messageDestructing:(NSNotification *)notification {
}

- (void)updateNavigationBarItem {
    [self notifyUpdateUnreadMessageCount];
}

- (void)forwardMessages {
    [self showForwardActionSheet];
}

- (void)showForwardActionSheet {
    __weak typeof(self) weakSelf = self;
    NSArray *titleArray = [[NSMutableArray alloc]
        initWithObjects:RCLocalizedString(@"OneByOneForward"),
                        RCLocalizedString(@"CombineAndForward"), nil];
    [RCActionSheetView showActionSheetView:nil
                                 cellArray:titleArray
                               cancelTitle:RCLocalizedString(@"Cancel")
                             selectedBlock:^(NSInteger index) {
        NSArray *selectedMessage = [NSArray arrayWithArray:weakSelf.selectedMessages];
        if (index == 0) {
            if ([RCCombineMessageUtility allSelectedOneByOneForwordMessagesAreLegal:self.selectedMessages]) {
                //逐条转发
                [self forwardMessage:0
                           completed:^(NSArray<RCConversation *> *conversationList) {
                    if (conversationList) {
                        [[RCForwardManager sharedInstance] doForwardMessageList:selectedMessage
                                                               conversationList:conversationList
                                                                      isCombine:NO
                                                        forwardConversationType:weakSelf.conversationType
                                                                      completed:^(BOOL success){
                        }];
                        [weakSelf forwardMessageEnd];
                    }
                }];
            } else {
                [RCAlertView showAlertController:nil message:RCLocalizedString(@"OneByOneForwardingNotSupported") cancelTitle:RCLocalizedString(@"OK") inViewController:self];
            }
            
        } else if (index == 1) {
            if ([RCCombineMessageUtility allSelectedCombineForwordMessagesAreLegal:self.selectedMessages]) {
                [self forwardMessage:1
                           completed:^(NSArray<RCConversation *> *conversationList) {
                    if (conversationList) {
                        [[RCForwardManager sharedInstance] doForwardMessageList:selectedMessage
                                                               conversationList:conversationList
                                                                      isCombine:YES
                                                        forwardConversationType:weakSelf.conversationType
                                                                      completed:^(BOOL success){
                        }];
                        [weakSelf forwardMessageEnd];
                    }
                }];
            } else {
                [RCAlertView showAlertController:nil message:RCLocalizedString(@"CombineForwardingNotSupported") cancelTitle:RCLocalizedString(@"OK") inViewController:self];
            }
        }
    }cancelBlock:^{
        
    }];
}

- (void)forwardMessage:(NSInteger)index
             completed:(void (^)(NSArray<RCConversation *> *conversationList))completedBlock {
    RCSelectConversationViewController *forwardSelectedVC = [[RCSelectConversationViewController alloc]
        initSelectConversationViewControllerCompleted:^(NSArray<RCConversation *> *conversationList) {
            completedBlock(conversationList);
        }];
    [self.navigationController pushViewController:forwardSelectedVC animated:NO];
}

#pragma mark - Helper
- (void)registerSectionHeaderView {
    [self.conversationMessageCollectionView registerClass:[RCConversationCollectionViewHeader class]
                               forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                      withReuseIdentifier:@"RefreshHeadView"];
}


#pragma mark - dark
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self fitDarkMode];
}

- (void)fitDarkMode {
    if (!RCKitConfigCenter.ui.enableDarkMode) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        if (self.unReadButton) {
            [self.unReadButton setBackgroundImage:RCResourceImage(@"up") forState:UIControlStateNormal];
        }
        if (self.unReadMentionedButton) {
            [self.unReadMentionedButton setBackgroundImage:RCResourceImage(@"up") forState:UIControlStateNormal];
        }
        [self.conversationMessageCollectionView reloadData];
    }
}

#pragma mark - Reference
- (void)onReferenceMessageCell:(id)sender {
    [self removeReferencingView];
    self.referencingView = [[RCReferencingView alloc] initWithModel:self.currentSelectedModel inView:self.view];
    self.referencingView.delegate = self;
    [self.view addSubview:self.referencingView];
    [self.referencingView
        setOffsetY:CGRectGetMinY(self.chatSessionInputBarControl.frame) - self.referencingView.frame.size.height];
    [self.chatSessionInputBarControl.inputTextView becomeFirstResponder];
    [self updateReferenceViewFrame];
}

#pragma mark RCReferencingViewDelegate
- (void)dismissReferencingView:(RCReferencingView *)referencingView {
    [self removeReferencingView];
    __block CGRect messageCollectionView = self.conversationMessageCollectionView.frame;
    [UIView animateWithDuration:0.25
                     animations:^{
        if (self.chatSessionInputBarControl) {
            messageCollectionView.size.height =
            CGRectGetMinY(self.chatSessionInputBarControl.frame) - messageCollectionView.origin.y;
            self.conversationMessageCollectionView.frame = messageCollectionView;
        }
        
    }];
}

- (void)previewReferenceView:(RCMessageModel *)messageModel {
    RCMessageContent *msgContent = messageModel.content;
    if ([messageModel.content isKindOfClass:[RCReferenceMessage class]]) {
        RCReferenceMessage *refer = (RCReferenceMessage *)messageModel.content;
        msgContent = refer.referMsg;
    }

    if ([msgContent isKindOfClass:[RCImageMessage class]]) {
        RCMessage *referencedMsg = [[RCMessage alloc] initWithType:self.conversationType
                                                          targetId:self.targetId
                                                         direction:MessageDirection_SEND
                                                         messageId:messageModel.messageId
                                                           content:msgContent];
        RCMessageModel *imageModel = [RCMessageModel modelWithMessage:referencedMsg];
        [self presentImagePreviewController:imageModel onlyPreviewCurrentMessage:YES];
    } else if ([msgContent isKindOfClass:[RCFileMessage class]]) {
        [self presentFilePreviewViewController:messageModel];
    } else if ([msgContent isKindOfClass:[RCRichContentMessage class]]) {
        RCRichContentMessage *richMsg = (RCRichContentMessage *)msgContent;
        if (richMsg.url.length > 0) {
            [RCKitUtility openURLInSafariViewOrWebView:richMsg.url base:self];
        } else if (richMsg.imageURL.length > 0) {
            [RCKitUtility openURLInSafariViewOrWebView:richMsg.imageURL base:self];
        }
    }else if ([msgContent isKindOfClass:[RCTextMessage class]] || [msgContent isKindOfClass:[RCReferenceMessage class]]){
        if ([self.chatSessionInputBarControl.inputTextView isFirstResponder]) {
            [self.chatSessionInputBarControl.inputTextView resignFirstResponder];
        }
        [RCTextPreviewView showText:[RCKitUtility formatMessage:msgContent targetId:self.targetId conversationType:self.conversationType isAllMessage:YES] delegate:self];
    }
}

- (BOOL)updateReferenceViewFrame {
    if (self.referencingView) {
        UIButton *recordBtn = (UIButton *)self.chatSessionInputBarControl.recordButton;
        UIButton *emojiBtn = (UIButton *)self.chatSessionInputBarControl.emojiButton;
        UIButton *additionalBtn = (UIButton *)self.chatSessionInputBarControl.additionalButton;
        //文本输入或者表情输入状态下，才可以发送引用消息
        if ((recordBtn.hidden || emojiBtn.state == UIControlStateHighlighted) &&
            additionalBtn.state == UIControlStateNormal) {
            [self.referencingView setOffsetY:CGRectGetMinY(self.chatSessionInputBarControl.frame) -
                                             self.referencingView.frame.size.height];

            __block CGRect messageCollectionView = self.conversationMessageCollectionView.frame;
            [UIView
                animateWithDuration:0.25
                         animations:^{
                             messageCollectionView.size.height =
                                 CGRectGetMinY(self.referencingView.frame) - messageCollectionView.origin.y;
                             self.conversationMessageCollectionView.frame = messageCollectionView;
                             if (self.conversationMessageCollectionView.contentSize.height >
                                 messageCollectionView.size.height) {
                                 [self.conversationMessageCollectionView
                                     setContentOffset:CGPointMake(
                                                          0, self.conversationMessageCollectionView.contentSize.height -
                                                                 messageCollectionView.size.height)
                                             animated:NO];
                                 //引用view显示时，页面滚动到最新处，右下方气泡消失
                                 [self.dataSource.unreadNewMsgArr removeAllObjects];
                                 [self updateUnreadMsgCountLabel];
                             }
                         }];
            return YES;
        } else {
            [self removeReferencingView];
        }
    }
    return NO;
}

- (BOOL)sendReferenceMessage:(NSString *)content {
    if (self.referencingView.referModel) {
        RCReferenceMessage *reference = [[RCReferenceMessage alloc] init];
        reference.content = content;
        reference.referMsg = self.referencingView.referModel.content;
        reference.referMsgUserId = self.referencingView.referModel.senderUserId;
        reference.mentionedInfo = self.chatSessionInputBarControl.mentionedInfo;
        [self sendMessage:reference pushContent:nil];
        [self dismissReferencingView:self.referencingView];
        return YES;
    }
    return NO;
}

- (void)removeReferencingView {
    if (self.referencingView) {
        [self.referencingView removeFromSuperview];
        self.referencingView = nil;
        [self updateUnreadMsgCountLabelFrame];
    }
}

#pragma mark - Config
- (void)setDefaultInputType:(RCChatSessionInputBarInputType)defaultInputType {
    if (_defaultInputType != defaultInputType) {
        _defaultInputType = defaultInputType;
        if (self.chatSessionInputBarControl) {
            [self.chatSessionInputBarControl setDefaultInputType:defaultInputType];
        }
    }
}

- (void)setLocatedMessageSentTime:(long long)locatedMessageSentTime {
    _locatedMessageSentTime = locatedMessageSentTime;
}

- (void)setDefaultHistoryMessageCountOfChatRoom:(int)defaultHistoryMessageCountOfChatRoom {
    if (RC_IOS_SYSTEM_VERSION_LESS_THAN(@"8.0") && defaultHistoryMessageCountOfChatRoom > 30) {
        defaultHistoryMessageCountOfChatRoom = 30;
    }
    _defaultHistoryMessageCountOfChatRoom = defaultHistoryMessageCountOfChatRoom;
}

- (void)setdefaultLocalHistoryMessageCount:(int)defaultLocalHistoryMessageCount {
    if (defaultLocalHistoryMessageCount > 100) {
        defaultLocalHistoryMessageCount = 100;
    }else if (defaultLocalHistoryMessageCount < 0){
        defaultLocalHistoryMessageCount = 10;
    }
    _defaultLocalHistoryMessageCount = defaultLocalHistoryMessageCount;
}

- (void)setDefaultRemoteHistoryMessageCount:(int)defaultRemoteHistoryMessageCount {
    if (defaultRemoteHistoryMessageCount > 100) {
        defaultRemoteHistoryMessageCount = 100;
    }else if(defaultRemoteHistoryMessageCount < 0){
        defaultRemoteHistoryMessageCount = 10;
    }
    _defaultRemoteHistoryMessageCount = defaultRemoteHistoryMessageCount;
}

//设置头像样式
- (void)setMessageAvatarStyle:(RCUserAvatarStyle)avatarStyle {
    RCKitConfigCenter.ui.globalMessageAvatarStyle = avatarStyle;
}

//设置头像大小
- (void)setMessagePortraitSize:(CGSize)size {
    RCKitConfigCenter.ui.globalMessagePortraitSize = size;
}

#pragma mark - Util
- (void)refreshVisibleCells {
    //刷新当前屏幕的cell
    NSMutableArray *indexPathes = [[NSMutableArray alloc] init];
    for (RCMessageCell *cell in self.conversationMessageCollectionView.visibleCells) {
        NSIndexPath *indexPath = [self.conversationMessageCollectionView indexPathForCell:cell];
        [indexPathes addObject:indexPath];
    }
    [self.conversationMessageCollectionView reloadItemsAtIndexPaths:[indexPathes copy]];
}

- (void)playNextVoiceMesage:(NSNumber *)msgId {
    dispatch_async(dispatch_get_main_queue(), ^{
        long messageId = [msgId longValue];
        RCMessageModel *rcMsg;
        int index = 0;
        for (int i = 0; i < self.conversationDataRepository.count; i++) {
            rcMsg = [self.conversationDataRepository objectAtIndex:i];
            if (messageId < rcMsg.messageId && ([rcMsg.content isMemberOfClass:[RCVoiceMessage class]] ||
                                                [rcMsg.content isMemberOfClass:[RCHQVoiceMessage class]]) &&
                rcMsg.receivedStatus != ReceivedStatus_LISTENED && rcMsg.messageDirection == MessageDirection_RECEIVE &&
                rcMsg.content.destructDuration == 0) {
                index = i;
                break;
            }
        }
        if (index == self.conversationDataRepository.count - 1) {
            self.isContinuousPlaying = NO;
        }

        if (index != 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
            RCVoiceMessageCell *__cell =
                (RCVoiceMessageCell *)[self.conversationMessageCollectionView cellForItemAtIndexPath:indexPath];
            //如果是空说明被回收了，重新dequeue一个cell
            if (__cell) {
                rcMsg.receivedStatus = ReceivedStatus_LISTENED;
                [__cell setDataModel:rcMsg];
                [__cell playVoice];
            } else {
                if ([rcMsg.content isKindOfClass:RCVoiceMessage.class]) {
                    __cell = (RCVoiceMessageCell *)[self.conversationMessageCollectionView
                        dequeueReusableCellWithReuseIdentifier:[[RCVoiceMessage class] getObjectName]
                                                  forIndexPath:indexPath];
                    rcMsg.receivedStatus = ReceivedStatus_LISTENED;
                } else if ([rcMsg.content isKindOfClass:RCHQVoiceMessage.class]) {
                    __cell = [self.conversationMessageCollectionView
                        dequeueReusableCellWithReuseIdentifier:[[RCHQVoiceMessage class] getObjectName]
                                                  forIndexPath:indexPath];
                    if (((RCHQVoiceMessage *)rcMsg.content).localPath.length > 0) {
                        rcMsg.receivedStatus = ReceivedStatus_LISTENED;
                    }
                }
                [self.conversationMessageCollectionView reloadItemsAtIndexPaths:@[ indexPath ]];
                [__cell setDataModel:rcMsg];
                [__cell setDelegate:self];
                [__cell playVoice];
            }
        }
    });
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return [super canPerformAction:action withSender:sender];
}

- (float)getSafeAreaExtraBottomHeight {
    return [RCKitUtility getWindowSafeAreaInsets].bottom;
}

- (BOOL)isExtensionCell:(RCMessageContent *)messageContent {
    for (RCExtensionMessageCellInfo *cellInfo in self.extensionMessageCellInfoList) {
        if (cellInfo.messageContentClass == [messageContent class]) {
            return YES;
        }
    }
    return NO;
}

// 清理环境（退出讨论组、移除监听等）
- (void)quitConversationViewAndClear {

    [[RongIMKitExtensionManager sharedManager] containerViewWillDestroy:self.conversationType
                                                               targetId:self.targetId];
    
    [self.dataSource quitChatRoomIfNeed];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (BOOL)isRemainMessageExisted {
    return self.locatedMessageSentTime != 0;
}

#pragma mark - 钩子
- (RCMessageContent *)willSendMessage:(RCMessageContent *)message {
    DebugLog(@"super %s", __FUNCTION__);
    return message;
}

- (RCMessage *)willAppendAndDisplayMessage:(RCMessage *)message {
    DebugLog(@"super %s", __FUNCTION__);
    return message;
}

- (void)appendAndDisplayMessage:(RCMessage *)message{
    [self.dataSource appendAndDisplayMessage:message];
}

- (void)didSendMessage:(NSInteger)status content:(RCMessageContent *)messageContent {
    DebugLog(@"super %s, %@", __FUNCTION__, messageContent);
}

- (void)didCancelMessage:(RCMessageContent *)messageContent {
    DebugLog(@"super %s, %@", __FUNCTION__, messageContent);
}

- (BOOL)willSelectMessage:(RCMessageModel *)model {
    DebugLog(@"super %s, %@", __FUNCTION__, model);
    return YES;
}

- (BOOL)willCancelSelectMessage:(RCMessageModel *)model {
    DebugLog(@"super %s, %@", __FUNCTION__, model);
    return YES;
}

- (void)saveNewPhotoToLocalSystemAfterSendingSuccess:(UIImage *)newImage {
}

- (void)willDisplayMessageCell:(RCMessageBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath {
}

//历史遗留接口
- (void)willDisplayConversationTableCell:(RCMessageBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - Getter & Setter
- (UIImageView *)unreadRightBottomIcon {
    if (!_unreadRightBottomIcon) {
        UIImage *msgCountIcon = RCResourceImage(@"bubble");
        CGRect frame = CGRectMake(self.view.frame.size.width - 5.5 - 35, self.chatSessionInputBarControl.frame.origin.y - 12 - 35, 35, 35);
        if ([RCKitUtility isRTL]) {
            frame.origin.x = 5.5;
        }
        _unreadRightBottomIcon = [[UIImageView alloc] initWithFrame:frame];
        _unreadRightBottomIcon.userInteractionEnabled = YES;
        _unreadRightBottomIcon.image = msgCountIcon;
        //        _unreadRightBottomIcon.translatesAutoresizingMaskIntoConstraints = NO;
        UITapGestureRecognizer *tap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRightBottomMsgCountIcon:)];
        [_unreadRightBottomIcon addGestureRecognizer:tap];
        _unreadRightBottomIcon.hidden = YES;
        [self.view addSubview:_unreadRightBottomIcon];
    }
    return _unreadRightBottomIcon;
}

- (UILabel *)unReadNewMessageLabel {
    if (!_unReadNewMessageLabel) {
        _unReadNewMessageLabel = [[UILabel alloc] initWithFrame:_unreadRightBottomIcon.bounds];
        _unReadNewMessageLabel.backgroundColor = [UIColor clearColor];
        _unReadNewMessageLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        _unReadNewMessageLabel.textAlignment = NSTextAlignmentCenter;
        _unReadNewMessageLabel.textColor = RCDYCOLOR(0xffffff, 0x111111);
        _unReadNewMessageLabel.center = CGPointMake(_unReadNewMessageLabel.frame.size.width / 2,
                                                    _unReadNewMessageLabel.frame.size.height / 2 - 2.5);
        [self.unreadRightBottomIcon addSubview:_unReadNewMessageLabel];
    }
    return _unReadNewMessageLabel;
}

- (RCChatSessionInputBarControl *)chatSessionInputBarControl {
    if (!_chatSessionInputBarControl && self.conversationType != ConversationType_SYSTEM) {
        if(!self.viewLoaded) {
            //当出现这个日志的时候很可能用户在 init 方法调用了 UI 接口
            RCLogE(@"[Error] view didn't load: Method called before viewDidLoad");
        }
        _chatSessionInputBarControl = [[RCChatSessionInputBarControl alloc]
                                       initWithFrame:CGRectMake(0, self.view.bounds.size.height - RC_ChatSessionInputBar_Height -
                                                                       [self getSafeAreaExtraBottomHeight],
                                                                self.view.bounds.size.width, RC_ChatSessionInputBar_Height)
                                   withContainerView:self.view
                                         controlType:RCChatSessionInputBarControlDefaultType
                                        controlStyle:RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION
                                    defaultInputType:self.defaultInputType];

        _chatSessionInputBarControl.conversationType = self.conversationType;
        _chatSessionInputBarControl.targetId = self.targetId;
        _chatSessionInputBarControl.delegate = self;
        _chatSessionInputBarControl.dataSource = self;
        [self.view addSubview:_chatSessionInputBarControl];
    }
    return _chatSessionInputBarControl;
}

- (UITapGestureRecognizer *)resetBottomTapGesture {
    if (!_resetBottomTapGesture) {
        _resetBottomTapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap4ResetDefaultBottomBarStatus:)];
        [_resetBottomTapGesture setDelegate:self];
        _resetBottomTapGesture.cancelsTouchesInView = NO;
        _resetBottomTapGesture.delaysTouchesEnded = NO;
    }
    return _resetBottomTapGesture;
}

- (UICollectionView *)conversationMessageCollectionView {
    if (!_conversationMessageCollectionView) {

        CGRect _conversationViewFrame = self.view.bounds;

        CGFloat _conversationViewFrameY = CGRectGetMaxY([UIApplication sharedApplication].statusBarFrame) +
                                          CGRectGetMaxY(self.navigationController.navigationBar.bounds);

        if (RC_IOS_SYSTEM_VERSION_LESS_THAN(@"7.0")) {

            _conversationViewFrame.origin.y = 0;
        } else {
            _conversationViewFrame.origin.y = _conversationViewFrameY;
        }

        _conversationViewFrame.size.height =
            self.view.bounds.size.height - self.chatSessionInputBarControl.frame.size.height - _conversationViewFrameY;
        self.dataSource.customFlowLayout.sectionInset = UIEdgeInsetsMake(20, 0, 0, 0);
        _conversationMessageCollectionView =
            [[UICollectionView alloc] initWithFrame:_conversationViewFrame collectionViewLayout:self.dataSource.customFlowLayout];
        [_conversationMessageCollectionView
            setBackgroundColor:[RCKitUtility generateDynamicColor:HEXCOLOR(0xf5f6f9)
                                                        darkColor:HEXCOLOR(0x111111)]];
        _conversationMessageCollectionView.showsHorizontalScrollIndicator = NO;
        _conversationMessageCollectionView.alwaysBounceVertical = YES;

        _conversationMessageCollectionView.dataSource = self;
        _conversationMessageCollectionView.delegate = self;
    }
    return _conversationMessageCollectionView;
}

- (UIButton *)unReadButton {
    if (!_unReadButton) {
        _unReadButton = [UIButton new];
        CGFloat extraHeight = 0;
        if ([self getSafeAreaExtraBottomHeight] > 0) {
            extraHeight = 24; // 齐刘海屏的导航由20变成了44，需要额外加24
        }
        _unReadButton.frame = CGRectMake(0, [RCKitUtility getWindowSafeAreaInsets].top + self.navigationController.navigationBar.frame.size.height + 14, 0, 48);
        [_unReadButton setBackgroundImage:RCResourceImage(@"up") forState:UIControlStateNormal];
        [_unReadButton addSubview:self.unReadMessageLabel];
        [_unReadButton addTarget:self
                          action:@selector(tapRightTopMsgUnreadButton:)
                forControlEvents:UIControlEventTouchUpInside];
    }
    return _unReadButton;
}

- (UILabel *)unReadMessageLabel {
    if (!_unReadMessageLabel) {
        _unReadMessageLabel =
            [[UILabel alloc] initWithFrame:CGRectZero];
        NSString *newMessageCount = [NSString stringWithFormat:@"%ld", (long)_unReadMessage];
        if (_unReadMessage > UNREAD_MESSAGE_MAX_COUNT) {
            newMessageCount = [NSString stringWithFormat:@"%d+", UNREAD_MESSAGE_MAX_COUNT];
        }
        NSString *stringUnread = [NSString
            stringWithFormat:RCLocalizedString(@"Right_unReadMessage"), newMessageCount];
        _unReadMessageLabel.text = stringUnread;
        _unReadMessageLabel.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
        _unReadMessageLabel.textColor = RCDYCOLOR(0x111f2c, 0x0099ff);
        _unReadMessageLabel.textAlignment = NSTextAlignmentCenter;
        _unReadMessageLabel.tag = 1001;
    }
    return _unReadMessageLabel;
}

- (UIButton *)unReadMentionedButton {
    if (_unReadMentionedButton == nil) {
        _unReadMentionedButton = [UIButton new];
        CGFloat extraHeight = 0;
        if ([self getSafeAreaExtraBottomHeight] > 0) {
            extraHeight = 24; // iphonex 的导航由20变成了44，需要额外加24
        }
        
        _unReadMentionedButton.frame = CGRectMake(0, CGRectGetMaxY(self.unReadButton.frame) + 15, 0, 48);
        [_unReadMentionedButton setBackgroundImage:RCResourceImage(@"up") forState:UIControlStateNormal];
        [_unReadMentionedButton addTarget:self action:@selector(tapRightTopUnReadMentionedButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_unReadMentionedButton];
        [_unReadMentionedButton addSubview:self.unReadMentionedLabel];
        [_unReadMentionedButton bringSubviewToFront:self.conversationMessageCollectionView];
    }
    return _unReadMentionedButton;
}

- (UILabel *)unReadMentionedLabel {
    if (!_unReadMentionedLabel) {
        _unReadMentionedLabel = [[UILabel alloc] initWithFrame:CGRectMake(17 + 9 + 6, 0, 0, self.unReadMentionedButton.frame.size.height)];
        _unReadMentionedLabel.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
        _unReadMentionedLabel.textColor = RCDYCOLOR(0x111f2c, 0x0099ff);
        _unReadMentionedLabel.textAlignment = NSTextAlignmentCenter;
        _unReadMentionedLabel.tag = 1002;
    }
    return _unReadMentionedLabel;
}

- (UIToolbar *)messageSelectionToolbar {
    if (!_messageSelectionToolbar) {
        _messageSelectionToolbar = [[UIToolbar alloc] init];
        _messageSelectionToolbar.barTintColor = RCDYCOLOR(0xf5f6f9, 0x1c1c1c);
        //解决UIToolbar 顶部的黑色线条问题
        _messageSelectionToolbar.clipsToBounds = YES;
        RCButton *forwardBtn = [[RCButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        [forwardBtn setImage:RCResourceImage(@"forward_message") forState:UIControlStateNormal];
        [forwardBtn addTarget:self action:@selector(forwardMessages) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *forwardBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:forwardBtn];

        RCButton *deleteBtn = [[RCButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        [deleteBtn setImage:RCResourceImage(@"delete_message") forState:UIControlStateNormal];
        [deleteBtn addTarget:self action:@selector(deleteMessages) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *deleteBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:deleteBtn];
        UIBarButtonItem *spaceItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                          target:nil
                                                          action:nil];

        NSArray *items = nil;
        if (RCKitConfigCenter.message.enableSendCombineMessage &&
            (self.conversationType == ConversationType_PRIVATE || self.conversationType == ConversationType_GROUP)) {
            items = @[ spaceItem, forwardBarButtonItem, spaceItem, deleteBarButtonItem, spaceItem ];
        } else {
            items = @[ spaceItem, deleteBarButtonItem, spaceItem ];
        }

        [_messageSelectionToolbar setItems:items animated:YES];
        _messageSelectionToolbar.translucent = NO;
    }
    return _messageSelectionToolbar;
}

- (NSArray *)getLeftBackButton {
    int count = [[RCIMClient sharedRCIMClient] getUnreadCount:self.displayConversationTypeArray];
    
    NSString *backString = nil;
    if (count > 0 && count < 100) {
        backString = [NSString
            stringWithFormat:@"%@(%d)", RCLocalizedString(@"Back"), count];
    } else if (count >= 100 && count < 1000) {
        backString = [NSString
            stringWithFormat:@"%@(99+)", RCLocalizedString(@"Back")];
    } else if (count >= 1000) {
        backString =
            [NSString stringWithFormat:@"%@(...)", RCLocalizedString(@"Back")];
    } else {
        backString = RCLocalizedString(@"Back");
    }
    NSArray *items;
    if (self.conversationType == ConversationType_CUSTOMERSERVICE) {
        items = [RCKitUtility getLeftNavigationItems:RCResourceImage(@"navigator_btn_back") title:backString target:self action:@selector(customerServiceLeftCurrentViewController)];
    } else {
        items = [RCKitUtility getLeftNavigationItems:RCResourceImage(@"navigator_btn_back") title:backString target:self action:@selector(leftBarButtonItemPressed:)];
    }
    return items;
}

//接口向后兼容[[++
- (void)setCsInfo:(RCCustomerServiceInfo *)csInfo {
    self.csUtil.csInfo = csInfo;
}

- (RCCustomerServiceInfo *)csInfo {
    return self.csUtil.csInfo;
}

//接口向后兼容--]]

- (UIView *)extensionView {
    if (!_extensionView) {
        _extensionView = [[UIView alloc] init];
        [self.view addSubview:_extensionView];
    }
    return _extensionView;
}
@end
