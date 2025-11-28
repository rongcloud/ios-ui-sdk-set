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
#import "RCImageSlideController.h"
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
#import "RCResendManager.h"
#import "RCReferencingView.h"
#import "RCReferenceMessageCell.h"
#import "RCConversationDataSource.h"
#import "RCConversationVCUtil.h"
#import "RCConversationCSUtil.h"
#import "RCKitConfig.h"
#import <RongPublicService/RongPublicService.h>
#import <RongDiscussion/RongDiscussion.h>
#import <RongCustomerService/RongCustomerService.h>
#import "RCButton.h"
#import "RCTranslationClient+Internal.h"
#import "RCMessageModel+Translation.h"
#import "RCTextTranslationMessageCell.h"
#import "RCVoiceTranslationMessageCell.h"
#import "RCTextMessageTranslatingCell.h"
#import "RCVoiceMessageTranslatingCell.h"
#import "RCLocationViewController+imkit.h"
#import "RCLocationMessage+imkit.h"
#import "RCSemanticContext.h"
#import "RCIMThreadLock.h"
#import "RCStreamMessageCell.h"
#import "RCStreamUtilities.h"

#import "RCConversationViewController+STT.h"

#import "RCEditInputBarControl.h"
#import "RCUserListViewController.h"
#import "RCConversationViewController+Edit.h"
#import "RCConversationDataSource+Edit.h"
#import "RCMessageModel+Edit.h"
#import "RCTextPreviewView+Edit.h"
#import "RCMessageModel+RRS.h"
#import "RCBatchSubmitManager.h"
#import "RCConversationViewController+RRS.h"
#import "RCMessageReadDetailViewController.h"

#import "RCMenuItem.h"
#import "RCMenuController.h"

#import "RCConversationTitleView.h"
#import "RCUserOnlineStatusManager.h"
#import "RCUserOnlineStatusUtil.h"

#define UNREAD_MESSAGE_MAX_COUNT 99
#define COLLECTION_VIEW_REFRESH_CONTROL_HEIGHT 30

extern NSString *const RCKitDispatchDownloadMediaNotification;

NSString *const RCConversationViewScrollNotification = @"RCConversationViewScrollNotification";
NSString *const RCKitReferencedMessageUId = @"referenceMessageUId";
NSUInteger const RCStreamMessageTextLimit = 10000;

@interface RCConversationViewController () <
    UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, RCMessageCellDelegate,
    RCChatSessionInputBarControlDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,
    UINavigationControllerDelegate, RCPublicServiceMessageCellDelegate, RCTypingStatusDelegate,
RCChatSessionInputBarControlDataSource, RCMessagesMultiSelectedProtocol, RCReferencingViewDelegate, RCTextPreviewViewDelegate, RCMessagesLoadProtocol, RCReadReceiptV5Delegate> {
    int _defaultLocalHistoryMessageCount;
    int _defaultMessageCount;
    int _defaultRemoteHistoryMessageCount;
}

@property (nonatomic, strong) RCConversationDataSource *dataSource;
@property (nonatomic, strong) RCConversationVCUtil *util;
@property (nonatomic, strong) RCConversationCSUtil *csUtil;

#pragma mark flag
@property (nonatomic, assign) BOOL isConversationAppear;
@property (nonatomic, assign) BOOL isTakeNewPhoto;//发送的图片是否是刚拍摄的，是拍摄的则决定是否写入相册
@property (nonatomic, assign) BOOL isContinuousPlaying;     //是否正在连续播放语音消息
@property (nonatomic, assign) BOOL isTouchScrolled; /// 表示是否是触摸滚动
@property (nonatomic, assign) BOOL sendMsgAndNeedScrollToBottom;

#pragma mark data
@property (nonatomic, strong) NSMutableArray *typingMessageArray;
@property (nonatomic, strong) NSArray<RCExtensionMessageCellInfo *> *extensionMessageCellInfoList;
@property (nonatomic, strong) NSMutableDictionary *cellMsgDict;
@property (nonatomic, strong) RCMessageModel *currentSelectedModel;
@property (nonatomic, strong) NSMutableArray *needReadResponseArray;
// 正在编辑中的配置
@property (nonatomic, strong) RCEditInputBarConfig *editingInputBarConfig;
// 输入框底部最后的状态，主要用来在界面恢复显示时，处理底部键盘的弹出
@property (nonatomic, assign) KBottomBarStatus latestInputBottomBarStatus;

#pragma mark view
@property (nonatomic, strong) UITapGestureRecognizer *resetBottomTapGesture;
@property (nonatomic, strong) RCConversationCollectionViewHeader *collectionViewHeader;
@property (nonatomic, strong) RCConversationTitleView *conversationTitleView;

#pragma mark 通用
@property (nonatomic, copy) NSString *navigationTitle;
@property (nonatomic, strong) NSArray<UIBarButtonItem *> *leftBarButtonItems;
@property (nonatomic, strong) NSArray<UIBarButtonItem *> *rightBarButtonItems;
@property (nonatomic, strong) RCIMThreadLock *threadLock;
@property (nonatomic, strong) RCBatchSubmitManager *readReceiptBatchManager; // 已读回执批量提交管理器
@end

static NSString *const rcUnknownMessageCellIndentifier = @"rcUnknownMessageCellIndentifier";
static NSString *const rcMessageBaseCellIndentifier = @"rcMessageBaseCellIndentifier";

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
    self.threadLock = [RCIMThreadLock new];
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
    self.needReadResponseArray = [NSMutableArray array];
    self.csEvaInterval = 60;
    self.isContinuousPlaying = NO;
    [[RCMessageSelectionUtility sharedManager] setMultiSelect:NO];
    
    self.dataSource = [[RCConversationDataSource alloc] init:self];
    self.dataSource.loadDelegate = self;
    self.util = [[RCConversationVCUtil alloc] init:self];
    self.csUtil = [[RCConversationCSUtil alloc] init:self];
    self.enableUnreadMentionedIcon = YES;
    self.defaultMessageCount = 10;
    // 5.6.3 修改为默认删除服务端消息
    self.needDeleteRemoteMessage = YES;
    
    // 初始化已读回执批量提交管理器
    [self setupReadReceiptBatchManager];
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
    [self registerCustomCellsAndMessages];
    [self registerNotification];

    [RCMessageSelectionUtility sharedManager].delegate = self;

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_10_3
    if (@available(iOS 11.0, *)) {
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(-[self getSafeAreaExtraBottomHeight], 0, 0, 0);
    }
#endif
    [[RCSystemSoundPlayer defaultPlayer] setIgnoreConversationType:self.conversationType targetId:self.targetId];
    [self updateDraftBeforeViewAppear];
    [self setNavigationItem];
    
    [self registerSectionHeaderView];
    if (!RCKitConfigCenter.message.enableDestructMessage) {
        [self.chatSessionInputBarControl.pluginBoardView removeItemWithTag:PLUGIN_BOARD_ITEM_DESTRUCT_TAG];
    }
    [self.chatSessionInputBarControl.pluginBoardView removeItemWithTag:PLUGIN_BOARD_ITEM_TRANSFER_TAG];
    
    Class cls = NSClassFromString(@"RCTranslationClient");
    if (cls && [cls respondsToSelector:@selector(sharedInstance)]) {// 添加翻译监听
        id obj = [[cls class] sharedInstance];
        if ([obj respondsToSelector:@selector(addTranslationDelegate:)]) {
            [obj addTranslationDelegate:self];
        }
    }
    if (self.disableSystemEmoji) {
        [self disableSystemDefaultEmoji];
    }
    
    // 更新导航栏标题的在线状态
    [self updateNavigationTitleOnlineStatus];
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
    [self edit_viewWillAppear:animated];
    
    //系统会话，没有输入框,无法根据输入框回调滚动，查看消息没有滚动到最底部
    if (!self.chatSessionInputBarControl && [self.dataSource isAtTheBottomOfTableView] && self.locatedMessageSentTime == 0) {
        [self.conversationMessageCollectionView performBatchUpdates:^{
            [self.conversationMessageCollectionView reloadData];
        } completion:^(BOOL finished) {
            [self scrollToBottomAnimated:NO];
        }];
    }
    
    self.navigationController.interactivePopGestureRecognizer.delaysTouchesBegan = NO;

    [self.conversationMessageCollectionView addGestureRecognizer:self.resetBottomTapGesture];
    
    // 如果正在编辑模式，不调用正常输入框的生命周期，避免状态冲突
    if (![self edit_isMessageEditing]) {
        [self.chatSessionInputBarControl containerViewWillAppear];
    }
    
    [[RCSystemSoundPlayer defaultPlayer] setIgnoreConversationType:self.conversationType targetId:self.targetId];
    
    [[RongIMKitExtensionManager sharedManager] extensionViewWillAppear:self.conversationType
                                                              targetId:self.targetId
                                                         extensionView:self.extensionView];
    if(self.placeholderLabel) {
        [self.placeholderLabel removeFromSuperview];
        [self.chatSessionInputBarControl.inputTextView addSubview:self.placeholderLabel];
        self.placeholderLabel.hidden = self.chatSessionInputBarControl.draft.length > 0;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    DebugLog(@"%s======%@", __func__, self);
    self.isConversationAppear = YES;
    [self edit_viewDidAppear:animated];
    
    [self sendGroupReadReceiptResponseForCache];
   
    // 如果正在编辑模式，不调用正常输入框的生命周期，避免状态冲突
    if (![self edit_isMessageEditing]) {
        [self.chatSessionInputBarControl containerViewDidAppear];
    }
    [self updateDraftAfterViewAppear];
    
    self.navigationTitle = [self currentNavigationTitle];
    
    [[RCCoreClient sharedCoreClient] setRCTypingStatusDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.util syncReadStatus];
    
    [self.conversationMessageCollectionView removeGestureRecognizer:self.resetBottomTapGesture];
    [[RCSystemSoundPlayer defaultPlayer] resetIgnoreConversation];
    [self stopPlayingVoiceMessage];
    self.isConversationAppear = NO;
    [[RCCoreClient sharedCoreClient] clearMessagesUnreadStatus:self.conversationType targetId:self.targetId completion:nil];

    [self.chatSessionInputBarControl cancelVoiceRecord];
    [[RCCoreClient sharedCoreClient] setRCTypingStatusDelegate:nil];
    
    // 恢复标题
    [self setNavigationTitle:self.navigationTitle];
    
    // 如果正在编辑模式，不调用正常输入框的生命周期，避免状态冲突
    if (![self edit_isMessageEditing]) {
        // 非编辑模式，才需处理普通输入框的草稿
        [self.util saveDraftIfNeed];
        
        [self.chatSessionInputBarControl containerViewWillDisappear];
    }
    [[RongIMKitExtensionManager sharedManager] extensionViewWillDisappear:self.conversationType targetId:self.targetId];
    
    // 保存编辑状态（被动离开场景）
    [self edit_saveCurrentEditStateIfNeeded];
    [self edit_viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!self.navigationController || ![self.navigationController.viewControllers containsObject:self]) {
        [self.dataSource cancelAppendMessageQueue];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // 保存编辑状态（内存警告场景）
    [self edit_saveCurrentEditStateIfNeeded];
}

- (void)didMoveToParentViewController:(UIViewController *)parent{
    [super didMoveToParentViewController:parent];
    if (!parent){
        [self quitConversationViewAndClear];
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
- (void)registerCustomCellsAndMessages {
    
}
- (void)registerAllInternalClass {
    //常见消息
    [self registerClass:[RCTextMessageCell class] forMessageClass:[RCTextMessage class]];
    [self registerClass:[RCImageMessageCell class] forMessageClass:[RCImageMessage class]];
    [self registerClass:[RCGIFMessageCell class] forMessageClass:[RCGIFMessage class]];
    [self registerClass:[RCCombineMessageCell class] forMessageClass:[RCCombineMessage class]];
    [self registerClass:[RCVoiceMessageCell class] forMessageClass:[RCVoiceMessage class]];
    [self registerClass:[RCHQVoiceMessageCell class] forMessageClass:[RCHQVoiceMessage class]];
    [self registerClass:[RCRichContentMessageCell class] forMessageClass:[RCRichContentMessage class]];
    [self registerClass:[RCFileMessageCell class] forMessageClass:[RCFileMessage class]];
    [self registerClass:[RCReferenceMessageCell class] forMessageClass:[RCReferenceMessage class]];
    [self registerClass:[RCSightMessageCell class] forMessageClass:[RCSightMessage class]];
    [self registerClass:[RCTipMessageCell class] forMessageClass:[RCInformationNotificationMessage class]];
    [self registerClass:[RCTipMessageCell class] forMessageClass:[RCDiscussionNotificationMessage class]];
    [self registerClass:[RCTipMessageCell class] forMessageClass:[RCGroupNotificationMessage class]];
    [self registerClass:[RCTipMessageCell class] forMessageClass:[RCRecallNotificationMessage class]];
    [self registerClass:[RCStreamMessageCell class] forMessageClass:[RCStreamMessage class]];

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
    [self registerClass:[RCMessageBaseCell class] forCellWithReuseIdentifier:rcMessageBaseCellIndentifier];
    //注册 Extention 消息，如 callkit 的
    self.extensionMessageCellInfoList =
        [[RongIMKitExtensionManager sharedManager] getMessageCellInfoList:self.conversationType targetId:self.targetId];
    for (RCExtensionMessageCellInfo *cellInfo in self.extensionMessageCellInfoList) {
        [self registerClass:cellInfo.messageCellClass forMessageClass:cellInfo.messageContentClass];
    }
    
    [self customRegisterClass:[RCTextTranslationMessageCell class]
                      withKey:RCTextTranslationMessageCellIdentifier];
  
    [self customRegisterClass:[RCTextMessageTranslatingCell class]
                      withKey:RCTextTranslatingMessageCellIdentifier];
    [self customRegisterClass:[RCVoiceMessageTranslatingCell class]
                      withKey:RCVoiceTranslatingMessageCellIdentifier];
    [self customRegisterClass:[RCVoiceTranslationMessageCell class]
                      withKey:RCVoiceTranslationMessageCellIdentifier];
}

- (void)registerClass:(Class)cellClass forMessageClass:(Class)messageClass {
    [self.conversationMessageCollectionView registerClass:cellClass
                               forCellWithReuseIdentifier:[messageClass getObjectName]];
    [self.cellMsgDict setObject:cellClass forKey:[messageClass getObjectName]];
}

- (void)customRegisterClass:(Class)cellClass withKey:(NSString *)key {
    if (!cellClass || !key) {
        return;
    }
    [self.conversationMessageCollectionView registerClass:cellClass
                               forCellWithReuseIdentifier:key];
    [self.cellMsgDict setObject:cellClass forKey:key];
}

- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier {
    [self.conversationMessageCollectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
}

#pragma mark - UI 显示
- (void)initializedSubViews {
    // 初始化控件
    [self createChatSessionInputBarControl];
    [self createConversationMessageCollectionView];
    
    self.view.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xf5f6f9", @"0x1c1c1c");
    [self.view addSubview:self.conversationMessageCollectionView];
}

- (void)createChatSessionInputBarControl {
    if (!self.chatSessionInputBarControl && self.conversationType != ConversationType_SYSTEM) {
        self.chatSessionInputBarControl = [[RCChatSessionInputBarControl alloc]
                                       initWithFrame:CGRectMake(0, self.view.bounds.size.height - RC_ChatSessionInputBar_Height -
                                                                       [self getSafeAreaExtraBottomHeight],
                                                                self.view.bounds.size.width, RC_ChatSessionInputBar_Height)
                                   withContainerView:self.view
                                         controlType:RCChatSessionInputBarControlDefaultType
                                        controlStyle:RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION
                                    defaultInputType:self.defaultInputType];

        self.chatSessionInputBarControl.conversationType = self.conversationType;
        self.chatSessionInputBarControl.targetId = self.targetId;
        self.chatSessionInputBarControl.delegate = self;
        self.chatSessionInputBarControl.dataSource = self;
        [self.view addSubview:self.chatSessionInputBarControl];
        
        // 初始化编辑控件
        [self edit_createEditBarControl];
    }
}



- (void)createConversationMessageCollectionView {
    if (!self.conversationMessageCollectionView) {

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
        self.conversationMessageCollectionView =
            [[RCBaseCollectionView alloc] initWithFrame:_conversationViewFrame collectionViewLayout:self.dataSource.customFlowLayout];
        UIColor *color = RCDynamicColor(@"auxiliary_background_1_color", @"0xf5f6f9", @"0x111111");
        [self.conversationMessageCollectionView setBackgroundColor:color];
        self.conversationMessageCollectionView.showsHorizontalScrollIndicator = NO;
        self.conversationMessageCollectionView.alwaysBounceVertical = YES;

        self.conversationMessageCollectionView.dataSource = self;
        self.conversationMessageCollectionView.delegate = self;
    }
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
    
    // 同步更新编辑控件位置
    self.editInputBarControl.frame = controlFrame;
}

- (void)setNavigationItem{
    if (ConversationType_APPSERVICE == self.conversationType ||
        ConversationType_PUBLICSERVICE == self.conversationType){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:RCDynamicImage(@"conversation_setting_img",@"rc_setting")
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(rightBarButtonItemClicked:)];
    }
    
    self.navigationItem.leftBarButtonItems = [self getLeftBackButton];
    
    // 对于单聊会话，使用自定义标题视图以显示在线状态
    if ([self isDisplayOnlineStatus]) {
        self.conversationTitleView = [[RCConversationTitleView alloc] init];
        self.navigationItem.titleView = self.conversationTitleView;
        
        // 如果之前已经设置了标题（通过 self.title 或 navigationItem.title），将其迁移到自定义标题视图
        NSString *existingTitle = self.title ?: self.navigationItem.title;
        if (existingTitle.length > 0) {
            [self updateNavigationTitle:existingTitle];
        }
    }
}

- (void)updateUnreadMsgCountLabel {
    if (self.conversationDataRepository.count > 0) {
        if (self.dataSource.unreadNewMsgArr.count > 0) {
            if ([self.dataSource isAtTheBottomOfTableView]) {
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
        if ([self edit_isMessageEditing]) {
            rect.origin.y = self.editInputBarControl.frame.origin.y - 12 - 35;
            [self.unreadRightBottomIcon setFrame:rect];
            return;
        }
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

// 当从搜索进来时，如果设置了草稿，会弹起键盘，导致列表滚动到底部
// 需要判断是否需要定位消息，如果不定位消息可以直接设置
- (void)updateDraftBeforeViewAppear {
    if (self.locatedMessageSentTime == 0) {
        [self setupDraft:^(BOOL editValid) {
            if (!self.isConversationAppear) {
                return;
            }
            if (editValid) {
                BOOL isFirstResponder = [self.editInputBarControl.editInputContainer.inputTextView isFirstResponder];
                if (!isFirstResponder) {
                    [self.editInputBarControl restoreFocus];
                }
            } else {
                BOOL isFirstResponder = [self.chatSessionInputBarControl.inputContainerView.inputTextView isFirstResponder];
                if (!isFirstResponder) {
                    [self.chatSessionInputBarControl.inputContainerView becomeFirstResponder];
                }
            }
        }];
    }
}

// 当从搜索进来时，如果设置了草稿，会弹起键盘，导致列表滚动到底部
// 需要判断是否需要定位消息，如果定位消息需要在 containerViewDidAppear 之后设置
- (void)updateDraftAfterViewAppear {
    if (self.locatedMessageSentTime) {
        [self setupDraft:nil];
    }
}

- (void)setupDraft:(void (^ _Nullable)(BOOL editValid))completion {
    [[RCChannelClient sharedChannelManager] getConversation:self.conversationType targetId:self.targetId channelId:self.channelId completion:^(RCConversation * _Nullable conversation) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dataSource getInitialMessage:conversation];
            [self.util sendReadReceiptWithTime:conversation.sentTime];
            RCEditedMessageDraft *editedMessageDraft = conversation.editedMessageDraft;
            BOOL editValid = editedMessageDraft && editedMessageDraft.content.length > 0;
            if (editValid) {
                [self edit_showEditingMessage:editedMessageDraft];
            } else {
                self.chatSessionInputBarControl.draft = conversation.draft;
            }
            if (completion) {
                completion(editValid);
            }
        });
    }];
}

- (void)setupReadReceiptBatchManager {
    self.readReceiptBatchManager = [[RCBatchSubmitManager alloc] init];
    __weak typeof(self) weakSelf = self;
    [self.readReceiptBatchManager setupSubmitCallback:^(NSArray *items, RCBatchSubmitResultCallback resultCallback) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            if (resultCallback) {
                resultCallback(ERRORCODE_UNKNOWN, YES);
            }
            return;
        }
        
        // items 中包含的是 messageUId 字符串
        NSArray *messageUIds = items;
        if (messageUIds.count == 0) {
            if (resultCallback) {
                resultCallback(INVALID_PARAMETER_MESSAGEUID, NO);
            }
            return;
        }
        
        RCConversationIdentifier *identifier = [RCConversationIdentifier new];
        identifier.type = strongSelf.conversationType;
        identifier.targetId = strongSelf.targetId;
        identifier.channelId = strongSelf.channelId;
        
        [[RCCoreClient sharedCoreClient] sendReadReceiptResponseV5:identifier
                                                       messageUIds:messageUIds
                                                        completion:^(RCErrorCode code) {
            
            if (resultCallback) {
                BOOL refillData = NO;
                if (code != RC_SUCCESS
                    && code != RC_SERVICE_RRSV5_UNAVAILABLE
                    && code != RC_SERVICE_RRSV5_READ_RECEIPT_NOT_SUPPORT
                    && code != MESSAGE_READ_RECEIPT_NOT_SUPPORT) {
                    refillData = YES;
                }
                resultCallback(code, refillData);
            }
        }];
    }];
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
                                                 name:RCKitDispatchRecallMessageDetailNotification
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
                                                 name:kRCContinuousPlayNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currentViewFrameChange:)
                                                 name:UIApplicationWillChangeStatusBarFrameNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMessagesModifiedNotification:)
                                                 name:RCKitDispatchMessagesModifiedNotification
                                               object:nil];
    
    // 注册在线状态变化通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUserOnlineStatusChanged:)
                                                 name:RCKitUserOnlineStatusChangedNotification
                                               object:nil];
    
    [self rrs_observeReadReceiptV5];
}

- (void)didReceiveMessageNotification:(NSNotification *)notification {
    RCMessage *rcMessage = notification.object;
    NSDictionary *leftDic = notification.userInfo;
    [self.dataSource didReceiveMessageNotification:rcMessage leftDic:leftDic];
}

- (void)didSendingMessageNotification:(NSNotification *)notification {
    RCMessage *rcMessage = notification.object;
    NSDictionary *statusDic = notification.userInfo;
    self.sendMsgAndNeedScrollToBottom = YES;
    if (rcMessage) {
        // 插入消息
        if (rcMessage.conversationType == self.conversationType && [rcMessage.targetId isEqual:self.targetId]) {
            [self updateForMessageSendOut:rcMessage];
            if (rcMessage.sentStatus == SentStatus_SENDING) {
                [self updateForMessageSendProgress:0 messageId:rcMessage.messageId];
            }
        }
    } else if (statusDic) {
        // 更新消息状态
        NSNumber *conversationType = statusDic[@"conversationType"];
        NSString *targetId = statusDic[@"targetId"];
        NSNumber *messageId = statusDic[@"messageId"];
        if (conversationType.intValue == self.conversationType && [targetId isEqual:self.targetId]) {
            NSNumber *sentStatus = statusDic[@"sentStatus"];
            if (sentStatus.intValue == SentStatus_SENDING) {
                NSNumber *progress = statusDic[@"progress"];
                [self updateForMessageSendProgress:progress.intValue messageId:messageId.longValue];
            } else if (sentStatus.intValue == SentStatus_SENT) {
                RCMessage *message = [[RCCoreClient sharedCoreClient] getMessage:messageId.longValue];
                [self updateForMessageSendSuccess:message];
            } else if (sentStatus.intValue == SentStatus_FAILED) {
                NSNumber *errorCode = statusDic[@"error"];
                RCMessage *message = [[RCCoreClient sharedCoreClient] getMessage:messageId.longValue];
                bool ifResendNotification = [statusDic.allKeys containsObject:@"resend"];
                [self updateForMessageSendError:errorCode.intValue message:message ifResendNotification:ifResendNotification];
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
            NSArray *conversationDataRepository = self.conversationDataRepository.copy;
            for (RCMessageModel *model in conversationDataRepository) {
                if (model.messageDirection == MessageDirection_SEND && model.sentTime <= time.longLongValue &&
                    model.sentStatus == SentStatus_SENT) {
                    model.sentStatus = SentStatus_READ;
                    [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_HASREAD messageId:model.messageId progress:0];
                }
            }
            NSArray *cacheArray = self.dataSource.cachedReloadMessages.copy;
            for (RCMessageModel *model in cacheArray){
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
    if ([[RCCoreClient sharedCoreClient] getConnectionStatus] == ConnectionStatus_Connected) {
        [self.util syncReadStatus];
        [self.util sendReadReceipt];
        [self sendGroupReadReceiptResponseForCache];
    }
    [[RCCoreClient sharedCoreClient] clearMessagesUnreadStatus:self.conversationType targetId:self.targetId completion:nil];
}

- (void)sendGroupReadReceiptResponseForCache{
    [self.threadLock performReadLockBlock:^{
        [self.util sendReadReceiptResponseForMessages:[self.needReadResponseArray copy]];
    }];
    [self.threadLock performWriteLockBlock:^{
        [self.needReadResponseArray removeAllObjects];
    }];
}

- (void)handleWillResignActiveNotification {
    self.isConversationAppear = NO;
    [self.chatSessionInputBarControl endVoiceRecord];
    
    // 保存编辑状态（应用进入后台场景）
    [self edit_saveCurrentEditStateIfNeeded];
    
    if (![self edit_isMessageEditing]) {
        // 非编辑模式，才需处理普通输入框的草稿
        //直接从会话页面杀死 app，保存或者清除草稿
        [self.util saveDraftIfNeed];
    }
}

- (void)didReceiveRecallMessageNotification:(NSNotification *)notification {
    __weak typeof(self) __blockSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(__blockSelf) strongSelf = __blockSelf;
        RCMessage *recalledMsg = notification.object;
        long recalledMsgId = recalledMsg.messageId;
        if ([RCVoicePlayer defaultPlayer].messageId == recalledMsgId) {
            [self stopPlayingVoiceMessage];
        }
        [[RCMessageSelectionUtility sharedManager] removeMessageModelByMessage:recalledMsg];
        
        [strongSelf.dataSource didRecallMessage:recalledMsg];
        if (strongSelf.enableUnreadMentionedIcon && recalledMsg.conversationType == strongSelf.conversationType &&
            [recalledMsg.targetId isEqual:strongSelf.targetId] &&
            ![strongSelf isRemainMessageExisted] && strongSelf.dataSource.unreadMentionedMessages.count != 0) {
            //遍历删除对应的@消息
            [strongSelf.dataSource removeMentionedMessage:recalledMsgId];
        }
        if (strongSelf.referencingView && strongSelf.referencingView.referModel.messageId == recalledMsgId) {
            [strongSelf.chatSessionInputBarControl resetToDefaultStatus];
            [strongSelf dismissReferencingView:strongSelf.referencingView];
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"MessageRecallAlert") cancelTitle:RCLocalizedString(@"Confirm") inViewController:strongSelf];
        }
        [strongSelf updateLeftBarUnreadMessageCount:recalledMsg];
        
        if ([self edit_isMessageEditing]) {
            // 刷新编辑输入框的引用消息状态
            RCMessageModel *model = [RCMessageModel modelWithMessage:recalledMsg];
            if (model) {
                [strongSelf edit_refreshEditInputReferenceViewIfNeeded:@[model] status:RCReferenceMessageStatusRecalled];
            }
        }
    });
}

- (void)updateLeftBarUnreadMessageCount:(RCMessage *)recalledMsg{
    if (recalledMsg.conversationType != self.conversationType || recalledMsg.targetId != self.targetId) {
        [self notifyUpdateUnreadMessageCount];
    }
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
                //onReceiveMessageReadReceiptRequest 方法里面发送通知延时处理，response 不延时，会导致时序错乱
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_READCOUNT messageId:model.messageId progress:readerList.count];
                });
            }
        }
    }
}

/**
 *  收到消息请求回执，如果当前列表中包含需要回执的messageUId，发送回执响应
 *
 *  @param notification notification description
 *
 *  @discussion 消息展示做了节流优化，部分消息在 cachedReloadMessages 中，另外，由于线程切换需要延时处理
 */
- (void)onReceiveMessageReadReceiptRequest:(NSNotification *)notification {
    NSDictionary *dic = notification.object;
    if (![self.targetId isEqualToString:dic[@"targetId"]]) return;
    if (self.conversationType != [dic[@"conversationType"] intValue]) return;
    
    NSString *messageUId = dic[@"messageUId"];
    if (messageUId.length == 0) return;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[RCCoreClient sharedCoreClient] getMessageByUId:messageUId completion:^(RCMessage * _Nullable message) {
            if (message.messageId <= 0) return;
            NSMutableArray *messages = [NSMutableArray array];
            [messages addObjectsFromArray:self.conversationDataRepository];
            [messages addObjectsFromArray:self.dataSource.cachedReloadMessages];
            [messages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                RCMessageModel *model = (RCMessageModel *)obj;
                if (model.receivedTime < message.receivedTime) {
                    *stop = YES;
                    return;
                }
                if (model.messageId != message.messageId) return;
                [self responseReceipt:model message:message];
                *stop = YES;
            }];
        }];
    });
}

- (void)responseReceipt:(RCMessageModel *)model message:(RCMessage *)message {
    if (model.messageDirection == MessageDirection_RECEIVE) {
        if(self.isConversationAppear){
            [[RCCoreClient sharedCoreClient] sendReadReceiptResponse:self.conversationType
                                                          targetId:self.targetId
                                                       messageList:@[message]
                                                           success:^{}
                                                             error:^(RCErrorCode nErrorCode){}];
            if (!model.readReceiptInfo) {
                model.readReceiptInfo = [[RCReadReceiptInfo alloc] init];
            }
            model.readReceiptInfo.isReceiptRequestMessage = YES;
            model.readReceiptInfo.hasRespond = YES;
        }else{
            [self.threadLock performWriteLockBlock:^{
                [self.needReadResponseArray addObject:message];
            }];
        }
    } else {
        model.readReceiptInfo = [[RCReadReceiptInfo alloc] init];
        model.readReceiptInfo.isReceiptRequestMessage = YES;
        model.isCanSendReadReceipt = NO;
        model.readReceiptCount = 0;
        [self.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_READCOUNT messageId:model.messageId progress:message.readReceiptInfo.userIdList.count];
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
        [self sendGroupReadReceiptResponseForCache];
    }
}

- (void)currentViewFrameChange:(NSNotification *)notification {
    if(!self.isConversationAppear) {
        return;
    }
    if (![RCKitUtility currentDeviceIsIPad]) {
        return;
    }
    [self.chatSessionInputBarControl containerViewSizeChanged];
}

- (void)onMessagesModifiedNotification:(NSNotification *)notification {
    NSArray<RCMessage *> *messages = notification.object;
    NSMutableArray<RCMessageModel *> *models = [NSMutableArray array];
    for (RCMessage *message in messages) {
        if (message.conversationType == self.conversationType && [message.targetId isEqual:self.targetId]) {
            RCMessageModel *model = [RCMessageModel modelWithMessage:message];
            if (model) {
                [models addObject:model];
            }
        }
    }
    [self.dataSource edit_refreshUIMessagesEditedStatus:models];
        
    [self edit_refreshReferenceViewContentIfNeeded:models status:RCReferenceMessageStatusModified];
}

/**
 * 在线状态变化通知处理
 * 
 * @param notification 通知对象，userInfo 中包含 RCUserOnlineStatusChangedUserIdsKey
 */
- (void)onUserOnlineStatusChanged:(NSNotification *)notification {
    if (![self isDisplayOnlineStatus]) {
        return;
    }
    
    NSArray<NSString *> *changedUserIds = notification.userInfo[RCKitUserOnlineStatusChangedUserIdsKey];
    if (!changedUserIds || ![changedUserIds containsObject:self.targetId]) {
        return;
    }
    
    // 更新标题视图的在线状态
    [self updateNavigationTitleOnlineStatus];
}

#pragma mark 语音连续播放
- (void)receiveContinuousPlayNotification:(NSNotification *)notification {
    if (!self.enableContinuousReadUnreadVoice) {
        return;
    }
    RCConversationType conversationType = [notification.userInfo[@"conversationType"] longValue];
    NSString *targetId = notification.userInfo[@"targetId"];
    if (conversationType != self.conversationType || ![targetId isEqualToString:self.targetId]) {
        return;
    }
    if (!self.isContinuousPlaying) {
        return;
    }
    [self performSelector:@selector(playNextVoiceMesage:)
               withObject:notification.object
               afterDelay:0.3f]; //延时0.3秒播放
}

#pragma mark - 已读回执 v5
- (void)didReceiveMessageReadReceiptResponses:(NSArray<RCReadReceiptResponseV5 *> *)responses {
    [self rrs_didReceiveMessageReadReceiptResponses:responses];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.isTouchScrolled = YES;
    if (self.edit_isMessageEditing) {
        [self edit_hideEditBottomPanels];
        return;
    }
    if (self.chatSessionInputBarControl.currentBottomBarStatus != KBottomBarDefaultStatus &&
        self.chatSessionInputBarControl.currentBottomBarStatus != KBottomBarRecordStatus &&
        self.chatSessionInputBarControl.currentBottomBarStatus != KBottomBarDestructStatus) {
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
    [self.dataSource scrollDidEnd];
    /// 请在停止滚动时、滚动动画执行完时更新右下角未读数气泡 或者在collectionview未处于底部时更新
    /// 又或者在撤回未读消息时更新，不要在其他时机更新，或者进行不必要的更新，浪费资源。
    [self updateUnreadMsgCountLabel];
}

/// 停止滚动时调用
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.dataSource scrollDidEnd];
    [self updateUnreadMsgCountLabel];
    self.isTouchScrolled = NO;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        self.isTouchScrolled = NO;
    }
    [self.dataSource scrollDidEnd];
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
    NSInteger count = [self.conversationMessageCollectionView numberOfItemsInSection:0];
    if (count <= 0) {
        return;
    }
    NSUInteger finalRow = count - 1;
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
    // 数据越界保护，开发者可以拿到 conversationDataRepository 并做任何处理
    if (indexPath.row >= self.conversationDataRepository.count) {
        RCMessageBaseCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:rcMessageBaseCellIndentifier forIndexPath:indexPath];
        DebugLog(@"indexPath row out of conversationDataRepository range ");
        return cell;
    }

    RCMessageModel *model = [self.conversationDataRepository objectAtIndex:indexPath.row];

    model = [self.dataSource setModelIsDisplayNickName:model];

    RCMessageContent *messageContent = model.content;
    RCMessageBaseCell *cell = nil;
    NSString *objName = [[messageContent class] getObjectName];
    if ([model isTranslated]||[model translating]) {
        objName = [model translationCellIdentifier];
    }

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
    } else if ((!messageContent || [messageContent isKindOfClass:[RCUnknownMessage class]]) && RCKitConfigCenter.message.showUnkownMessage) {
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
    if ([cell isKindOfClass:RCStreamMessageCell.class]) {
        ((RCStreamMessageCell *)cell).hostView = collectionView;
    }
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
    // 数据越界保护，开发者可以拿到 conversationDataRepository 并做任何处理
    if (indexPath.row >= self.conversationDataRepository.count) {
        return CGSizeZero;
    }

    RCMessageModel *model = [self.conversationDataRepository objectAtIndex:indexPath.row];
    model = [self.dataSource setModelIsDisplayNickName:model];
    // 文本消息
    if (model.cellSize.height > 0 &&
        !(model.conversationType == ConversationType_CUSTOMERSERVICE &&
          [model.content isKindOfClass:[RCTextMessage class]])) {
        if (model.isTranslated) { // 如果是翻译过的消息
            return model.finalSize; // 返回最终大小: 文本size + 翻译size
        } else if (model.translating) { // 如果是翻译中的消息
            return model.translatingSize;
        } else {
            return model.cellSize; // 只返回文本size
        }
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

    if ((!messageContent || [messageContent isKindOfClass:[RCUnknownMessage class]])&& RCKitConfigCenter.message.showUnkownMessage) {
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
        if (self.conversationDataRepository.count < self.defaultMessageCount) {
            height = 1;
        } else {
            height = COLLECTION_VIEW_REFRESH_CONTROL_HEIGHT;
        }
    }
    return (CGSize){width, height};
}

#pragma mark <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.conversationDataRepository.count) {
        return;
    }
    
    RCMessageModel *model = [self.conversationDataRepository objectAtIndex:indexPath.row];
    if ([model rrs_shouldResponseReadReceiptV5] && model.messageUId) {
        // 使用批量管理器处理已读回执 V5 响应
        [self.readReceiptBatchManager addSubmitTask:model.messageUId];
    }
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
    RCBaseNavigationController *nav = [[RCBaseNavigationController alloc] initWithRootViewController:_imagePreviewVC];
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
    RCBaseNavigationController *nav = [[RCBaseNavigationController alloc] initWithRootViewController:_imagePreviewVC];
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
    RCBaseNavigationController *navc = [[RCBaseNavigationController alloc] initWithRootViewController:svc];
    navc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navc animated:YES completion:nil];
}

- (void)presentDestructSightViewPreviewViewController:(RCMessageModel *)model {
    RCDestructSightViewController *svc = [[RCDestructSightViewController alloc] init];
    svc.messageModel = model;
    RCBaseNavigationController *navc = [[RCBaseNavigationController alloc] initWithRootViewController:svc];
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
    Class type = NSClassFromString(@"RCLocationViewController");
    if (type) {
        RCLocationViewController *locationViewController = [[type alloc] initWithLocationMessage:locationMessageContent];
        RCBaseNavigationController *navc = [[RCBaseNavigationController alloc] initWithRootViewController:locationViewController];
        if (self.navigationController) {
            //导航和原有的配色保持一直
            UIImage *image = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
            [navc.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
        }
        navc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:navc animated:YES completion:NULL];
    }
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

- (void)onlySendMessage:(RCMessageContent *)messageContent pushContent:(NSString *)pushContent {
    messageContent = [self willSendMessage:messageContent];
    if (messageContent == nil) {
        return;
    }
    [self.util doOnlySendMessage:messageContent pushContent:pushContent];
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
    [[RCCoreClient sharedCoreClient] sendMediaMessage:conversationType
                                             targetId:targetId
                                              content:messageContent
                                          pushContent:pushContent
                                             pushData:@""
                                             attached:^(RCMessage * _Nullable message) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RCKitSendingMessageNotification"
                                                            object:message
                                                          userInfo:nil];
    }uploadPrepare:^(RCUploadMediaStatusListener *uploadListener) {
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
    //            imageMsg.remoteUrl = @"http://www.rongcloud.cn/images/newVersion/bannerInner.png?0717";
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

- (void)resendMessageWithModel:(RCMessageModel *)model {
    RCMessage *message = [[RCCoreClient sharedCoreClient] getMessage:model.messageId];
    BOOL needUploadMedia = NO;
    if ([message.content isKindOfClass:[RCMediaMessageContent class]]) {
        RCMediaMessageContent *mediaMessage = (RCMediaMessageContent *)message.content;
        if (mediaMessage.remoteUrl.length <= 0) {
            needUploadMedia = YES;
            [[RCIM sharedRCIM] sendMediaMessage:message pushContent:nil pushData:nil progress:nil successBlock:^(RCMessage *successMessage) {
                
            } errorBlock:^(RCErrorCode nErrorCode, RCMessage *errorMessage) {
                
            } cancel:^(RCMessage *cancelMessage) {
                
            }];
        }
    }
    if (!needUploadMedia) {
        [[RCIM sharedRCIM] sendMessage:message pushContent:nil pushData:nil successBlock:^(RCMessage *successMessage) {
            
        } errorBlock:^(RCErrorCode nErrorCode, RCMessage *errorMessage) {
            
        }];
    }
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

- (void)cancelResendMessageIfNeed:(RCMessageModel *)model {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[RCResendManager sharedManager] needResend:model.messageId]) {
            [[RCResendManager sharedManager] removeResendMessage:model.messageId];
        }
    });
}

#pragma mark - 消息编辑




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
        } else if (self.isConversationAppear || self.chatSessionInputBarControl.currentBottomBarStatus == KBottomBarKeyboardStatus) {
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
    [self p_sendTypingStatusIfNeedWithText:text];
    
    //接收 10 条以上消息,进入到聊天页面点击键盘使弹起,再次点击右上角 x 条未读消息,键盘输入文本，页面没有滚动到底部
    if (self.dataSource.isLoadingHistoryMessage || [self isRemainMessageExisted]) {
        [self loadRemainMessageAndScrollToBottom:YES];
    }
}

- (void)inputTextViewDidChange:(UITextView *)textView {
    if (!self.placeholderLabel) {
        return;
    }
    if (textView.text.length > 0) {
        self.placeholderLabel.hidden = YES;
    } else {
        self.placeholderLabel.hidden = NO;
    }
}

- (void)inputTextViewDidChangeOnEndVoiceTransfer:(UITextView *)inputTextView {
    // 讯飞语音输入的文字结束时，也要发送“正在输入”消息
    [self p_sendTypingStatusIfNeedWithText:inputTextView.text];
}

- (void)p_sendTypingStatusIfNeedWithText:(NSString *)text {
    if (RCKitConfigCenter.message.enableTypingStatus && ![text isEqualToString:@"\n"]) {
        [[RCCoreClient sharedCoreClient] sendTypingStatus:self.conversationType
                                               targetId:self.targetId
                                            contentType:[RCTextMessage getObjectName]];
    }
}

- (void)robotSwitchButtonDidTouch{
    [self.csUtil robotSwitchButtonDidTouch];
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
        if ([RCKitUtility isAudioHolding]) {
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

//开关阅后即焚功能
- (void)switchDestructMessageMode {
    if (self.chatSessionInputBarControl.destructMessageMode) {
        [self.chatSessionInputBarControl resetToDefaultStatus];
    } else {
        [self.util alertDestructMessageRemind];
        [self.chatSessionInputBarControl setDefaultInputType:RCChatSessionInputBarInputDestructMode];
    }
}

//打开位置
- (void)openLocationPicker {
    [self.chatSessionInputBarControl openLocationPicker];
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
        [[RCCoreClient sharedCoreClient] sendTypingStatus:self.conversationType
                                               targetId:self.targetId
                                            contentType:[RCTextMessage getObjectName]];
    }
    self.placeholderLabel.hidden = self.chatSessionInputBarControl.inputTextView.text.length > 0;
}

- (void)emojiView:(RCEmojiBoardView *)emojiView didTouchSendButton:(UIButton *)sendButton {
    if ([self sendReferenceMessage:self.chatSessionInputBarControl.inputTextView.text]) {
        return;
    }
    RCTextMessage *rcTextMessage =
        [RCTextMessage messageWithContent:self.chatSessionInputBarControl.inputTextView.text];
    rcTextMessage.mentionedInfo = self.chatSessionInputBarControl.mentionedInfo;

    [self sendMessage:rcTextMessage pushContent:nil];
    
    self.placeholderLabel.hidden = NO;
}

- (BOOL)commonPhrasesButtonDidTouch {
    return [self didTapCommonPhrasesButton];
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
        [[RCCoreClient sharedCoreClient] sendTypingStatus:self.conversationType
                                               targetId:self.targetId
                                            contentType:[RCVoiceMessage getObjectName]];
    }

    [self onBeginRecordEvent];
}

//语音消息录音结束
- (void)recordDidEnd:(NSData *)recordData duration:(long)duration error:(NSError *)error {
    if (error == nil) {
        if (self.conversationType == ConversationType_CUSTOMERSERVICE ||
            [RCCoreClient sharedCoreClient].voiceMsgType == RCVoiceMessageTypeOrdinary) {
            RCVoiceMessage *voiceMessage = [RCVoiceMessage messageWithAudio:recordData duration:duration];
            [self sendMessage:voiceMessage pushContent:nil];
        } else if ([RCCoreClient sharedCoreClient].voiceMsgType == RCVoiceMessageTypeHighQuality) {
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

- (void)sightDidRecordFailedWith:(NSError *)error status:(NSInteger)status {
    NSLog(@"sightDidRecordFailedWith: error %ld status %ld", error.code,status);
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

- (NSDictionary *)getDraftExtraInfo {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.referencingView.referModel) {
        NSString *messageUId = [self.referencingView.referModel.messageUId copy];
        if (messageUId.length) dict[RCKitReferencedMessageUId] = messageUId;
    }
    return dict.copy;
}

- (void)didSetDraft:(NSDictionary *)info {
    NSString *referencedMessageUId = info[RCKitReferencedMessageUId];
    if (referencedMessageUId.length) {
        [RCCoreClient.sharedCoreClient getMessageByUId:referencedMessageUId completion:^(RCMessage * _Nullable message) {
            if (message.messageId == 0 || [message.content isKindOfClass:[RCRecallNotificationMessage class]]) {
                return;
            }
            for (RCMessageModel *model in self.conversationDataRepository) {
                if ([model.messageUId isEqualToString:referencedMessageUId]) {
                    self.currentSelectedModel = model;
                    break;
                }
            }
            if (!self.currentSelectedModel) {
                self.currentSelectedModel = [RCMessageModel modelWithMessage:message];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self onReferenceMessageCellAndEditing:NO];
            });
        }];
    }
}

#pragma mark - RCMessagesLoadProtocol
- (void)noMoreMessageToFetch {}

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
    } else if ([self.currentSelectedModel.content isKindOfClass:RCStreamMessage.class]) {
        RCStreamMessage *stream = (RCStreamMessage *)self.currentSelectedModel.content;
        if (stream.isSync) {
            NSString *content = stream.content;
            if (stream.content.length > RCStreamMessageTextLimit) {
                content = [content substringToIndex:RCStreamMessageTextLimit];
            }
            [pasteboard setString:content];
            return;
        }
        RCStreamSummaryModel *summary = [RCStreamUtilities parserStreamSummary:self.currentSelectedModel];
        [pasteboard setString:summary.summary];
    }
}
//删除消息内容
- (void)onDeleteMessage:(id)sender {
    self.chatSessionInputBarControl.inputTextView.disableActionMenu = NO;
    RCMessageModel *model = self.currentSelectedModel;

    //删除消息时如果是当前播放的消息就停止播放
    if ([RCVoicePlayer defaultPlayer].messageId == model.messageId) {
        [self stopPlayingVoiceMessage];
    }
    RCNetworkStatus currentStatus = [[RCCoreClient sharedCoreClient] getCurrentNetworkStatus];
    if (model.messageUId.length > 0 && currentStatus == RC_NotReachable) {
        [RCAlertView showAlertController:nil message:RCLocalizedString(@"ConnectionDisconnect") cancelTitle:RCLocalizedString(@"Confirm") inViewController:self];
        return;
    }
    [self deleteMessage:model];
}

- (BOOL)isTranslationEnable {
    Class cls = NSClassFromString(@"RCTranslationClient");
    if (!cls
        || ![cls respondsToSelector:@selector(sharedInstance)]) {
        return NO;
    }
    id instance = [[cls class] sharedInstance];
    if ([instance respondsToSelector:@selector(isTextTranslationSupported)]) {
        return [instance isTextTranslationSupported];
    }
    return NO;
}
/// 翻译消息
/// @param sender sender
- (void)onTranslateMessageCell:(id)sender {
    RCMessageModel *model = self.currentSelectedModel;
    Class cls = NSClassFromString(@"RCTranslationClient");
    if (!cls
        || ![model.content isKindOfClass:[RCTextMessage class]]
        || ![cls respondsToSelector:@selector(sharedInstance)]) {
        return;
    }
    NSString *srcLanguage = [RCKitConfig defaultConfig].message.translationConfig.srcLanguage;
    NSString *targetLanguage = [RCKitConfig defaultConfig].message.translationConfig.targetLanguage;
    RCTextMessage *txtMessage = (RCTextMessage *)(model.content);
    model.translating = YES;
    model.translationCategory = RCTranslationCategoryText;
    [self uploadTranslationByModel:model];
    id instance = [[cls class] sharedInstance];
    if ([instance respondsToSelector:@selector(translate:text:srcLanguage:targetLanguage:)]) {
        // 验证是否可以翻译
        [instance translate:model.messageId
                       text:txtMessage.content
                srcLanguage:srcLanguage
             targetLanguage:targetLanguage];
    }
}

- (void)uploadTranslationByModel:(RCMessageModel *)model {
    NSIndexPath *indexPath = [self.util findDataIndexFromMessageList:model];
    if (indexPath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.conversationMessageCollectionView reloadItemsAtIndexPaths:@[indexPath]];
            [self scrollToShowCellAt:indexPath];
        });
    }
}
- (void)scrollToShowCellAt:(NSIndexPath *)indexPath {
   
    [self.conversationMessageCollectionView scrollToItemAtIndexPath:indexPath
                                                   atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                                           animated:YES];
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
    [[RCCoreClient sharedCoreClient] getMessage:messageId completion:^(RCMessage * _Nullable msg) {
        if (msg.messageDirection != MessageDirection_SEND && msg.sentStatus != SentStatus_SENT) {
            NSLog(@"Error，only successfully sent messages can be recalled！！！");
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            __block RCRecallMessageImageView *recallMessageImageView =
                [[RCRecallMessageImageView alloc] initWithFrame:CGRectMake(0, 0, 135, 135)];
            //将 recallMessageImageView 添加到优先级最高的 window 上,避免键盘被遮挡
            [[RCKitUtility getKeyWindow] addSubview:recallMessageImageView];
            [recallMessageImageView setCenter:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2)];
            [recallMessageImageView startAnimating];
            __weak typeof(self) ws = self;
            // 为兼容原有逻辑，此处从原消息配置中读取一次。
            RCRecallMessageOption *option = [[RCRecallMessageOption alloc] init];
            option.disableNotification = msg.messageConfig.disableNotification;
            [[RCCoreClient sharedCoreClient] recallMessage:msg
                                                    option:option
                                               pushContent:nil
                                                   success:^(RCMessage * _Nonnull recalledMessage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([RCVoicePlayer defaultPlayer].messageId == msg.messageId) {
                        [self stopPlayingVoiceMessage];
                    }
                    
                    [ws reloadRecalledMessageWithMessage:recalledMessage];
                    
                    [recallMessageImageView stopAnimating];
                    [recallMessageImageView removeFromSuperview];
                    // private method
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"RCEConversationUpdateNotification"
                                                                        object:nil];
                });
            } error:^(RCErrorCode errorCode) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [recallMessageImageView stopAnimating];
                    [recallMessageImageView removeFromSuperview];
                    [RCAlertView showAlertController:nil message:RCLocalizedString(@"MessageRecallFailed") cancelTitle:RCLocalizedString(@"OK") inViewController:self];
                });
            }];
        });
    }];
}

// 新增传入 message 的刷新方法
- (void)reloadRecalledMessageWithMessage:(RCMessage *)recalledMessage {
    [self reloadRecalledMessageAndReferenceView:recalledMessage.messageId];
    
    if ([self edit_isMessageEditing]) {
        RCMessageModel *model = [RCMessageModel modelWithMessage:recalledMessage];
        if (model) {
            [self edit_refreshEditInputReferenceViewIfNeeded:@[model] status:RCReferenceMessageStatusRecalled];
        }
    }
}

//重新加载撤回消息
- (void)reloadRecalledMessage:(long)recalledMsgId {
    if ([self edit_isMessageEditing]) {
        [[RCCoreClient sharedCoreClient] getMessage:recalledMsgId completion:^(RCMessage * _Nullable message) {
            [self reloadRecalledMessageWithMessage:message];
        }];
    } else {
        [self reloadRecalledMessageAndReferenceView:recalledMsgId];
    }
}

- (void)reloadRecalledMessageAndReferenceView:(long)recalledMsgId {
    [self.dataSource didReloadRecalledMessage:recalledMsgId];
    
    if (self.referencingView && self.referencingView.referModel.messageId == recalledMsgId) {
        [self dismissReferencingView:self.referencingView];
    }
}

//删除消息
- (void)deleteMessage:(RCMessageModel *)model {
    [self deleteMessage:model memoryOnly:NO];
}


/// 删除消息
/// - Parameters:
///   - model: model
///   - memoryOnly: 只删除内存数据(针对阅后即焚)
- (void)deleteMessage:(RCMessageModel *)model memoryOnly:(BOOL)memoryOnly {
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
    
    if ([model.content isKindOfClass:[RCMediaMessageContent class]]) {
        // 多媒体消息此刻要取消上传并停止重发逻辑
        [self cancelUploadMedia:model];
    }else {
        // 普通消息此刻要直接停止重发逻辑
        [self cancelResendMessageIfNeed:model];
    }

    long msgId = model.messageId;
    if(!memoryOnly) { // 已读回执的远端和本地都已清理, 无需重复删除
        if (self.needDeleteRemoteMessage && model.messageUId.length > 0) {
            // 用户设置需要删除远端消息
            RCMessage *delMsg = [[RCCoreClient sharedCoreClient] getMessage:msgId];
            if (delMsg && delMsg.messageUId.length > 0) {
                // 有远端消息可以调用删除远端删除
                [[RCCoreClient sharedCoreClient] deleteRemoteMessage:model.conversationType targetId:model.targetId messages:@[delMsg] success:nil error:nil];
            }else {
                // 未发送成功的，只删除本地消息
                [[RCCoreClient sharedCoreClient] deleteMessages:@[@(msgId)] completion:nil];
            }
        }else {
            // 用户未设置，只删除本地消息
            [[RCCoreClient sharedCoreClient] deleteMessages:@[@(msgId)] completion:nil];
        }
    }
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
    // 消息删除后，清理引用消息
    if (self.referencingView && self.referencingView.referModel.messageId == model.messageId) {
        [self dismissReferencingView:self.referencingView];
    }
    if (model.messageUId) {
        [self.dataSource edit_setUIReferenceMessagesEditStatus:RCReferenceMessageStatusDeleted forMessageUIds:@[model.messageUId]];
        
        [self edit_refreshEditInputReferenceViewIfNeeded:@[model] status:RCReferenceMessageStatusDeleted];
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
            __strong typeof(__weakself) strongSelf = __weakself;
            strongSelf.rightBarButtonItems = strongSelf.navigationItem.rightBarButtonItems;
            strongSelf.leftBarButtonItems = strongSelf.navigationItem.leftBarButtonItems;
            strongSelf.navigationItem.rightBarButtonItems = nil;
            strongSelf.navigationItem.leftBarButtonItems = nil;
            UIBarButtonItem *left =
                [[UIBarButtonItem alloc] initWithTitle:RCLocalizedString(@"Cancel")
                                                 style:UIBarButtonItemStylePlain
                                                target:strongSelf
                                                action:@selector(onCancelMultiSelectEvent:)];

            [left setTintColor:RCKitConfigCenter.ui.globalNavigationBarTintColor];
            strongSelf.navigationItem.leftBarButtonItem = left;
        });
    } else {
        if(!self.displayConversationTypeArray) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(__weakself) strongSelf = __weakself;
                strongSelf.navigationItem.leftBarButtonItems = strongSelf.leftBarButtonItems;
                strongSelf.leftBarButtonItems = nil;
                if (strongSelf.conversationType != ConversationType_Encrypted && strongSelf.rightBarButtonItems) {
                    strongSelf.navigationItem.rightBarButtonItems = strongSelf.rightBarButtonItems;
                    strongSelf.rightBarButtonItems = nil;
                }
            });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationItem setLeftBarButtonItems:[self getLeftBackButton]];
            self.leftBarButtonItems = nil;
            if (self.rightBarButtonItems) {
                self.navigationItem.rightBarButtonItems = self.rightBarButtonItems;
                self.rightBarButtonItems = nil;
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
        void (^configureInputBar)(RCPublicServiceProfile *profile) = ^(RCPublicServiceProfile *profile) {
            if (profile.menu.menuItems) {
                [self.chatSessionInputBarControl
                    setInputBarType:RCChatSessionInputBarControlPubType
                              style:RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION];
                self.chatSessionInputBarControl.publicServiceMenu = profile.menu;
            }
            if (profile.disableInput && profile.disableMenu) {
                self.chatSessionInputBarControl.hidden = YES;
                CGFloat screenHeight = self.view.bounds.size.height;
                CGRect originFrame = self.conversationMessageCollectionView.frame;
                originFrame.size.height =
                    screenHeight - originFrame.origin.y - [self getSafeAreaExtraBottomHeight];
                self.conversationMessageCollectionView.frame = originFrame;
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
        [[RCCoreClient sharedCoreClient] sendMessage:self.conversationType
            targetId:self.targetId
            content:command
            pushContent:nil
            pushData:nil
            attached:^(RCMessage * _Nullable message) {
            
            } success:^(long messageId) {

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
        viewController = [RCKitUtility getPublicServiceWebViewController:url];
        [viewController setValue:RCKitConfigCenter.ui.globalNavigationBarTintColor forKey:@"backButtonTextColor"];
    }
    [self didTapImageTxtMsgCell:url webViewController:viewController];
}
- (void)didLongTouchPublicServiceMessageCell:(RCMessageModel *)model inView:(UIView *)view {
    [self didLongTouchMessageCell:model inView:view];
}

#pragma mark - 点击事件
- (BOOL)p_disableTapCell:(RCMessageModel *)model{
    if (nil == model) {
        return YES;
    }

    if (model.messageDirection == MessageDirection_RECEIVE && model.content.destructDuration > 0) {
        if ([self.util alertDestructMessageRemind]) {
            return YES;
        }
    }
    return NO;
}

//点击cell
- (void)didTapMessageCell:(RCMessageModel *)model {
    DebugLog(@"%s", __FUNCTION__);
    
    if([self p_disableTapCell:model]){
        return;
    }

    RCMessageContent *_messageContent = model.content;

    if ([_messageContent isMemberOfClass:[RCImageMessage class]]) {
        [self p_didTapMessageCellForImageMessage:model];
        return;
    }
    
    if ([_messageContent isMemberOfClass:[RCSightMessage class]]) {
        [self p_didTapMessageCellForSightMessage:model];
        return;
    }
    
    if ([_messageContent isMemberOfClass:[RCGIFMessage class]]) {
        [self p_didTapMessageCellForGIFMessage:model];
        return;
    }
    
    if ([_messageContent isMemberOfClass:[RCCombineMessage class]]) {
        [self p_didTapMessageCellForCombineMessage:model];
        return;
    }
    
    if ([_messageContent isMemberOfClass:[RCVoiceMessage class]] ||
        [_messageContent isMemberOfClass:[RCHQVoiceMessage class]]) {
        [self p_didTapMessageCellForVoiceMessage:model];
        return;
    }
    
    if ([model.objectName isEqualToString:@"RC:LBSMsg"]) {
        [self p_didTapMessageCellForLocationMessage:model];
        return;
    }
    
    if ([_messageContent isMemberOfClass:[RCTextMessage class]]) {
        [self p_didTapMessageCellForTextMessage:model];
        return;
    }
    
    if ([self isExtensionCell:_messageContent]) {
        [[RongIMKitExtensionManager sharedManager] didTapMessageCell:model];
        return;
    }
    
    if ([_messageContent isMemberOfClass:[RCFileMessage class]]) {
        [self presentFilePreviewViewController:model];
        return;
    }
    
    if ([_messageContent isMemberOfClass:[RCCSPullLeaveMessage class]]) {
        [self.csUtil didTapCSPullLeaveMessage:model];
        return;
    }
}

// 长按语音转文本内容
- (void)didLongTouchSTTInfo:(RCMessageModel *)model inView:(UIView *)view {
    [self stt_didLongTouchSTTInfo:model inView:view];
}

- (NSArray<UIMenuItem *> *)getLongTouchSTTInfoMenuList:(RCMessageModel *)model {
    return [self stt_getLongTouchSTTInfoMenuList:model];
}

//长按消息内容
- (void)didLongTouchMessageCell:(RCMessageModel *)model inView:(UIView *)view {
    //长按消息需要停止播放语音消息
    [self.util stopVoiceMessageIfNeed:model];
    self.currentSelectedModel = model;
    
    RCTextView *inputTextView;
    if ([self edit_isMessageEditing]) {
        inputTextView = self.editInputBarControl.editInputContainer.inputTextView;
    } else {
        inputTextView = self.chatSessionInputBarControl.inputTextView;
    }
    inputTextView.disableActionMenu = YES;
    if (![inputTextView isFirstResponder]) {
        //聊天界面不为第一响应者时，长按消息，UIMenuController不能正常显示菜单
        // inputTextView 是第一响应者时，不需要再设置 self 为第一响应者，否则会导致键盘收起
        [self becomeFirstResponder];
    }
    NSArray *menuItems = [self getLongTouchMessageCellMenuList:model];
    CGRect rect = [self.view convertRect:view.frame fromView:view.superview];
    if ([RCKitUtility isTraditionInnerThemes]) {
        UIMenuController *menu = [UIMenuController sharedMenuController];
        [menu setMenuItems:menuItems];
        if (@available(iOS 13.0, *)) {
            [menu showMenuFromView:self.view rect:rect];
        } else {
            [menu setTargetRect:rect inView:self.view];
            [menu setMenuVisible:YES animated:YES];
        }
    } else {
        [[RCMenuController sharedMenuController] showMenuFromView:view
                                                            menuItems:menuItems
                                                        actionHandler:^(RCMenuItem * _Nonnull menuItem, NSInteger index) {
            if ([self respondsToSelector:menuItem.action]) {
                [self performSelector:menuItem.action
                           withObject:[menuItems objectAtIndex:index]];
            }
        }];
    }
}

- (NSArray<UIMenuItem *> *)getLongTouchMessageCellMenuList:(RCMessageModel *)model {
    if ([model.content isKindOfClass:RCStreamMessage.class]) {
        return [self getLongTouchStreamMessageCellMenuList:model];
    }
    UIMenuItem *copyItem = [[RCMenuItem alloc] initWithTitle:RCLocalizedString(@"Copy")
                                                       image:RCDynamicImage(@"conversation_menu_item_copy_img", @"")
                                                      action:@selector(onCopyMessage:)];
    UIMenuItem *deleteItem =
        [[RCMenuItem alloc] initWithTitle:RCLocalizedString(@"Delete")
                                    image:RCDynamicImage(@"conversation_menu_item_delete_img", @"")
                                   action:@selector(onDeleteMessage:)];

    UIMenuItem *recallItem =
        [[RCMenuItem alloc] initWithTitle:RCLocalizedString(@"Recall")
                                    image:RCDynamicImage(@"conversation_menu_item_recall_img", @"")
                                   action:@selector(onRecallMessage:)];
    UIMenuItem *multiSelectItem =
        [[RCMenuItem alloc] initWithTitle:RCLocalizedString(@"MessageTapMore")
                                    image:RCDynamicImage(@"conversation_menu_item_multiple_img", @"")
                                   action:@selector(onMultiSelectMessageCell:)];

    UIMenuItem *referItem =
        [[RCMenuItem alloc] initWithTitle:RCLocalizedString(@"Reference")
                                    image:RCDynamicImage(@"conversation_menu_item_reference_img", @"")
                                   action:@selector(onReferenceMessageCell:)];

    NSMutableArray *items = @[].mutableCopy;
    if (model.content.destructDuration > 0) {
        [items addObject:deleteItem];
        if ([self.util canRecallMessageOfModel:model]) {
            [items addObject:recallItem];
        }
    } else {
        if ([model.content isMemberOfClass:[RCTextMessage class]] ||
            [model.content isMemberOfClass:[RCReferenceMessage class]]) {
            [items addObject:copyItem];
        }
        // 语音转文本
        UIMenuItem *sttItem = [self stt_menuItemForModel:model];
        if (sttItem) {
            [items addObject:sttItem];
        }
        [items addObject:deleteItem];
        if ([self.util canRecallMessageOfModel:model]) {
            [items addObject:recallItem];
        }
        if ([self.util canReferenceMessage:model]) {
            [items addObject:referItem];
        }
        if ([model edit_isMessageEditable]) {
            UIMenuItem *editItem = [[RCMenuItem alloc] initWithTitle:RCLocalizedString(@"Edit")
                                                               image:RCDynamicImage(@"conversation_menu_item_edit_img", @"")
                                                              action:@selector(onEditMessage:)];
            [items addObject:editItem];
        }
    }
    
    BOOL translateEnable = [self isTranslationEnable] && !model.isTranslated && [model.content isKindOfClass:[RCTextMessage class]] && !model.translating;
    if (translateEnable) {
        UIMenuItem *transItem =
        [[RCMenuItem alloc] initWithTitle:RCLocalizedString(@"Translate")
                                    image:RCDynamicImage(@"conversation_menu_item_translation_img", @"")
                                   action:@selector(onTranslateMessageCell:)];
        [items addObject:transItem];
    }
    if (self.conversationType != ConversationType_SYSTEM) {
        [items addObject:multiSelectItem];
    }
    
    return items.copy;
}



- (NSArray<UIMenuItem *> *)getLongTouchStreamMessageCellMenuList:(RCMessageModel *)model {
    
    if (![model.content isKindOfClass:RCStreamMessage.class]) {
        return @[];
    }
    NSMutableArray *items = @[].mutableCopy;
    
    UIMenuItem *copyItem = [[RCMenuItem alloc] initWithTitle:RCLocalizedString(@"Copy")
                                                       image:RCDynamicImage(@"conversation_menu_item_copy_img", @"")
                                                      action:@selector(onCopyMessage:)];
    UIMenuItem *deleteItem =
    [[RCMenuItem alloc] initWithTitle:RCLocalizedString(@"Delete")
                                image:RCDynamicImage(@"conversation_menu_item_delete_img", @"")
                               action:@selector(onDeleteMessage:)];
    [items addObjectsFromArray:@[copyItem, deleteItem]];
    
    RCStreamMessage *stream = (RCStreamMessage *)model.content;
    RCStreamSummaryModel *summary = [RCStreamUtilities parserStreamSummary:model];
    if (stream.isSync || summary.isComplete) {
        UIMenuItem *referItem =
        [[RCMenuItem alloc] initWithTitle:RCLocalizedString(@"Reference")
                                    image:RCDynamicImage(@"conversation_menu_item_reference_img", @"")
                                   action:@selector(onReferenceMessageCell:)];
        [items addObject:referItem];
    }
    UIMenuItem *multiSelectItem =
    [[RCMenuItem alloc] initWithTitle:RCLocalizedString(@"MessageTapMore")
                                image:RCDynamicImage(@"conversation_menu_item_multiple_img", @"")
                               action:@selector(onMultiSelectMessageCell:)];
    [items addObject:multiSelectItem];
    return items;
}

- (void)didTapUrlInMessageCell:(NSString *)url model:(RCMessageModel *)model {
    [RCKitUtility openURLInSafariViewOrWebView:url base:self];
}

- (void)didTapReedit:(RCMessageModel *)model {
    if ([self edit_didTapReedit:model]) {
        return;
    }
    
    [self insertReeditText:model];
}

- (void)didTapReferencedContentView:(RCMessageModel *)model {
    [self previewReferenceView:model];
}

- (void)didTapPhoneNumberInMessageCell:(NSString *)phoneNumber model:(RCMessageModel *)model {
    NSString *phoneStr = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
  if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneStr]
                                           options:@{}
                                 completionHandler:^(BOOL success) {
            
        }];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneStr]];
    }
}

//点击头像
- (void)didTapCellPortrait:(NSString *)userId {
}

- (void)didLongPressCellPortrait:(NSString *)userId {
    if (!self.chatSessionInputBarControl.isMentionedEnabled ||
        [userId isEqualToString:[RCIM sharedRCIM].currentUserInfo.userId]) {
        return;
    }
    [self addMentionedUserToCurrentInput:[self getSelectingUserInfo:userId]];
}

- (BOOL)didTapCommonPhrasesButton {
    return NO;
}

// 插入撤回消息重新编辑的文本到输入框
- (void)insertReeditText:(RCMessageModel *)model {
    // 获取被撤回的文本消息的内容
    RCRecallNotificationMessage *recallMessage = (RCRecallNotificationMessage *)model.content;
    NSString *content = recallMessage.recallContent;
    if (content.length > 0) {
        RCTextView *textView = self.chatSessionInputBarControl.inputTextView;
        [textView becomeFirstResponder];
        NSString *replaceContent = [NSString stringWithFormat:@"%@%@", textView.text, content];
        NSRange range = NSMakeRange(textView.text.length, content.length);
        textView.text = replaceContent;
        [self inputTextView:textView shouldChangeTextInRange:range replacementText:replaceContent];
    }
    self.placeholderLabel.hidden = self.chatSessionInputBarControl.inputTextView.text.length > 0;
}

- (void)didTapReceiptStatusView:(RCMessageModel *)model {
    RCMessageReadDetailViewModel *viewModel = [[RCMessageReadDetailViewModel alloc] initWithMessageModel:model config:nil];
    RCMessageReadDetailViewController *readReceiptDetailVC = [[RCMessageReadDetailViewController alloc] initWithViewModel:viewModel];
    [self.navigationController pushViewController:readReceiptDetailVC animated:YES];
}

#pragma mark 内部点击方法
- (void)tapRightBottomMsgCountIcon:(UIGestureRecognizer *)gesture {
    [self.dataSource tapRightBottomMsgCountIcon:gesture];
}

- (void)tap4ResetDefaultBottomBarStatus:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (self.edit_isMessageEditing) {
            [self edit_hideEditBottomPanels];
            return;
        }
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
    
    NSIndexPath *indexPath = [self.util findDataIndexFromMessageList:model];
    if (!indexPath) {
        return;
    }
    if ([content isMemberOfClass:[RCHQVoiceMessage class]] && model.messageDirection == MessageDirection_RECEIVE) {
        RCMessage *message = [[RCCoreClient sharedCoreClient] getMessage:model.messageId];
        if (!message) {
            return;
        }
        [[RCHQVoiceMsgDownloadManager defaultManager] pushVoiceMsgs:@[ message ] priority:NO];
        [self.conversationMessageCollectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
    } else {
        // 增加判断如果不在此条重发消息不在最底部，需要换到最底部
        if (indexPath.row != self.conversationDataRepository.count - 1) {
            [self.conversationDataRepository removeObject:model];
            [self.conversationDataRepository addObject:model];
            NSIndexPath *targetIndex = [NSIndexPath indexPathForItem:self.conversationDataRepository.count - 1 inSection:0];
            [self.conversationMessageCollectionView moveItemAtIndexPath:indexPath toIndexPath:targetIndex];
        }
        [self resendMessageWithModel:model];
    }
}

- (void)onTypingStatusChanged:(RCConversationType)conversationType
                     targetId:(NSString *)targetId
                       status:(NSArray *)userTypingStatusList {
    if (conversationType == self.conversationType && [targetId isEqualToString:self.targetId] &&
        RCKitConfigCenter.message.enableTypingStatus) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (userTypingStatusList == nil || userTypingStatusList.count == 0) {
                // 恢复标题
                [self updateNavigationTitle:self.navigationTitle];
            } else {
                self.navigationTitle = [self currentNavigationTitle];
                // 显示输入状态
                RCUserTypingStatus *typingStatus = (RCUserTypingStatus *)userTypingStatusList[0];
                NSString *statusText = nil;
                if ([typingStatus.contentType isEqualToString:[RCTextMessage getObjectName]]) {
                    statusText = RCLocalizedString(@"typing");
                } else if ([typingStatus.contentType isEqualToString:[RCVoiceMessage getObjectName]]||[typingStatus.contentType isEqualToString:[RCHQVoiceMessage getObjectName]]) {
                    statusText = RCLocalizedString(@"Speaking");
                }
                
                if (statusText) {
                    [self updateNavigationTitle:statusText];
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
    if ([self edit_updateConversationMessageCollectionView]) {
        return;
    }
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
    
    // Xcode13、iOS15 下需要刷新不可视范围的 Cell，否则会出现 禅道 44945 这个问题
    // reloadItemsAtIndexPaths 和 reloadData 同时调用会有某些 cell 没有 reload 的情况
    // 网上也有人遇到类似的问题，提到如果间隔 0.3 秒以上就不会有问题
    [self.conversationMessageCollectionView reloadData];
    [self.conversationMessageCollectionView setNeedsLayout];
    [self.conversationMessageCollectionView layoutIfNeeded];
}

- (void)showToolBar:(BOOL)show {
    if (show) {
        [self.view addSubview:self.messageSelectionToolbar];
        [self dismissReferencingViewAndCommonPhrasesView:self.referencingView];
    } else {
        [self.messageSelectionToolbar removeFromSuperview];
        [self showCommonPhrasesViewIfNeeded];
    }
}

- (NSArray<RCMessageModel *> *)selectedMessages {
    return [[RCMessageSelectionUtility sharedManager] selectedMessages];
}

- (void)deleteMessages {
    NSArray *tempArray = [self.selectedMessages mutableCopy];
    self.allowsMessageCellSelection = NO;
    
    __block BOOL isAllLocalMessage = YES;
    [tempArray enumerateObjectsUsingBlock:^(RCMessageModel *msg, NSUInteger idx, BOOL * _Nonnull stop) {
        if (msg.messageUId.length > 0) {
            isAllLocalMessage = NO;
            *stop = YES;
        }
    }];
    RCNetworkStatus currentStatus = [[RCCoreClient sharedCoreClient] getCurrentNetworkStatus];
    if ((!isAllLocalMessage) && currentStatus == RC_NotReachable) {
        [RCAlertView showAlertController:nil message:RCLocalizedString(@"ConnectionDisconnect") cancelTitle:RCLocalizedString(@"Confirm") inViewController:self];
        return;
    }
    
    for (int i = 0; i < tempArray.count; i++) {
        [self deleteMessage:tempArray[i]];
    }
    // 批量删除后，缺少重置collectionViewNewContentSize 导致 IMSDK-8250
   RCConversationViewLayout *currentLayout = (RCConversationViewLayout *)self.conversationMessageCollectionView.collectionViewLayout;
    currentLayout.collectionViewNewContentSize = CGSizeZero;
    
    // 删除后，没有消息了会空屏，要自动触发拉取下一页
    if (self.conversationDataRepository.count == 0) {
        [self.collectionViewHeader startAnimating];
        [self.dataSource scrollToLoadMoreHistoryMessage];
    }
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

- (void)updateForMessageSendSuccess:(RCMessage *)message {
    long messageId = message.messageId;
    RCMessageContent *content = message.content;
    DebugLog(@"message<%ld> send succeeded ", messageId);
    [self.csUtil startNotSendMessageAlertTimer];

    dispatch_async(dispatch_get_main_queue(), ^{
        RCMessage *message = [[RCCoreClient sharedCoreClient] getMessage:messageId];
 		if ([message.content isKindOfClass:[RCReferenceMessage class]]) {
            RCReferenceMessage *refMessage = (RCReferenceMessage *)message.content;
            RCMessageModel *uiMessageModel = [self.util modelByMessageUId:refMessage.referMsgUid];
            if (uiMessageModel && uiMessageModel.hasChanged) {
                refMessage.referMsgStatus = RCReferenceMessageStatusModified;
            }
        }
        NSArray *conversationDataRepository = self.conversationDataRepository.copy;
        for (RCMessageModel *model in conversationDataRepository) {
            if (model.messageId == messageId) {
                model.sentStatus = SentStatus_SENT;
                if (model.messageId > 0) {
                    if (message) {
                        model.sentTime = message.sentTime;
                        model.messageUId = message.messageUId;
                        model.content = message.content;
                    }
                }
                break;
            }
        }
        for(RCMessageModel *model in self.dataSource.cachedReloadMessages){
            if (model.messageId == messageId) {
                model.sentStatus = SentStatus_SENT;
                if (model.messageId > 0) {
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
        if (messageId == self.dataSource.showUnreadViewMessageId && ![self isSupportReadReceiptV5]) {
            [self updateLastMessageReadReceiptStatus:messageId content:content];
        }
    });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self didSendMessage:0 content:content];
#pragma clang diagnostic pop
    [self didSendMessageModel:0 model:[RCMessageModel modelWithMessage:message]];

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
    RCMessage *message = [[RCCoreClient sharedCoreClient] getMessage:messageId];
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
                          message:(RCMessage *)message
             ifResendNotification:(bool)ifResendNotification{
    long messageId = message.messageId;
    RCMessageContent *content = message.content;
    DebugLog(@"message<%ld> send failed error code %d", messageId, (int)nErrorCode);


    __weak typeof(self) __weakself = self;
    dispatch_after(
        // 发送失败0.3s之后再刷新，防止没有Cell绘制太慢
        dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.3f), dispatch_get_main_queue(), ^{
            __strong typeof(__weakself) strongSelf = __weakself;
            for (RCMessageModel *model in strongSelf.conversationDataRepository) {
                if (model.messageId == messageId) {
                    model.sentStatus = SentStatus_FAILED;
                    break;
                }
            }
            for (RCMessageModel *model in strongSelf.dataSource.cachedReloadMessages) {
                if (model.messageId == messageId) {
                    model.sentStatus = SentStatus_FAILED;
                    break;
                }
            }
            [strongSelf.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_FAILED messageId:messageId progress:0];
        });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self didSendMessage:nErrorCode content:content];
#pragma clang diagnostic pop

    [self didSendMessageModel:nErrorCode model:[RCMessageModel modelWithMessage:message]];

    RCInformationNotificationMessage *informationNotifiMsg = [self.util getInfoNotificationMessageByErrorCode:nErrorCode];
    if (nil != informationNotifiMsg && !ifResendNotification) {
        [[RCCoreClient sharedCoreClient] insertOutgoingMessage:self.conversationType
                                                      targetId:self.targetId
                                                    sentStatus:SentStatus_SENT
                                                       content:informationNotifiMsg
                                                      sentTime:(message.sentTime + 1)
                                                    completion:^(RCMessage * _Nullable message) {
            __block RCMessage *tempMessage = message;
            dispatch_async(dispatch_get_main_queue(), ^{
                tempMessage = [self willAppendAndDisplayMessage:tempMessage];
                if (tempMessage) {
                    [self appendAndDisplayMessage:tempMessage];
                }
            });
        }];
    }
    if (nErrorCode == RC_MEDIA_EXCEPTION) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *alertMessage = RCLocalizedString(@"CannotUploadFiles");
            [RCAlertView showAlertController:nil message:alertMessage hiddenAfterDelay:1 inViewController:self];
        });
    }
}

- (void)updateForMessageSendCanceled:(long)messageId content:(RCMessageContent *)content {
    DebugLog(@"message<%ld> canceled", messageId);

    __weak typeof(self) __weakself = self;
    dispatch_after(
        // 发送失败0.3s之后再刷新，防止没有Cell绘制太慢
        dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.3f), dispatch_get_main_queue(), ^{
            __strong typeof(__weakself) strongSelf = __weakself;
            for (RCMessageModel *model in strongSelf.conversationDataRepository) {
                if (model.messageId == messageId) {
                    model.sentStatus = SentStatus_CANCELED;
                    break;
                }
            }

            [strongSelf.util sendMessageStatusNotification:CONVERSATION_CELL_STATUS_SEND_CANCELED messageId:messageId progress:0];
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
                if (self.isContinuousPlaying && model.messageId == [RCVoicePlayer defaultPlayer].messageId) {
                    [self startPlayAudio:model];
                }
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
 @discussion 如果您使用IMLib请参考 RCCoreClient 的RCMessageDestructDelegate
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
            /*
             * 焚毁消息在倒计时会缓存一份 RCMessage 未结束前，消息被删除， 再次拉取远端消息后， cell 持有的 RCMessageModel.messageId 会变更
             * 后续的删除消息是依据 messageId 的，此时需要使用正确的 messageId，执行焚毁逻辑
             */
            
            RCMessageModel *delModel = [RCMessageModel modelWithMessage:message];
            for (RCMessageModel *msgModel in self.conversationDataRepository) {
                if ([msgModel.messageUId isEqualToString:message.messageUId]) {
                    delModel.messageId = msgModel.messageId;
                    break;
                }
            }
            [self deleteMessage:delModel memoryOnly:YES];
            UIMenuController *menu = [UIMenuController sharedMenuController];
            menu.menuVisible = NO;
            [[RCMenuController sharedMenuController] hideMenuAnimated:NO];
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
    NSMutableArray *titleArray = [[NSMutableArray alloc]
        initWithObjects:RCLocalizedString(@"OneByOneForward"), nil];
    if (RCKitConfigCenter.message.enableSendCombineMessage &&
        (self.conversationType == ConversationType_PRIVATE || self.conversationType == ConversationType_GROUP)) {
        [titleArray addObject:RCLocalizedString(@"CombineAndForward")];
    }
    [RCActionSheetView showActionSheetView:nil
                                 cellArray:titleArray
                               cancelTitle:RCLocalizedString(@"Cancel")
                             selectedBlock:^(NSInteger index) {
        if (index == 0) {
            if ([RCCombineMessageUtility allSelectedOneByOneForwordMessagesAreLegal:self.selectedMessages]) {
                //逐条转发
                [self forwardMessage:0
                           completed:^(NSArray<RCConversation *> *conversationList) {
                    NSArray *selectedMessage = [NSArray arrayWithArray:self.selectedMessages];
                    if (conversationList && selectedMessage.count > 0) {
                        [[RCForwardManager sharedInstance] doForwardMessageList:selectedMessage
                                                               conversationList:conversationList
                                                                      isCombine:NO
                                                        forwardConversationType:self.conversationType
                                                                      completed:^(BOOL success){
                        }];
                        [self forwardMessageEnd];
                    }
                }];
            } else {
                [RCAlertView showAlertController:nil message:RCLocalizedString(@"OneByOneForwardingNotSupported") cancelTitle:RCLocalizedString(@"OK") inViewController:self];
            }
            
        } else if (index == 1) {
            if ([RCCombineMessageUtility allSelectedCombineForwordMessagesAreLegal:self.selectedMessages]) {
                [self forwardMessage:1
                           completed:^(NSArray<RCConversation *> *conversationList) {
                    NSArray *selectedMessage = [NSArray arrayWithArray:self.selectedMessages];
                    if (conversationList && selectedMessage.count > 0) {
                        [[RCForwardManager sharedInstance] doForwardMessageList:selectedMessage
                                                               conversationList:conversationList
                                                                      isCombine:YES
                                                        forwardConversationType:self.conversationType
                                                                      completed:^(BOOL success){
                        }];
                        [self forwardMessageEnd];
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
#pragma mark -- RCTranslationClientDelegate

/// 翻译结束
/// @param translation model
/// @param code 返回码
- (void)onTranslation:(RCTranslation *)translation
         finishedWith:(NSInteger)code {
    Class cls = NSClassFromString(@"RCTranslation");
    if (cls) {
        RCMessageModel *model = [self.util modelByMessageID:translation.messageId];
        if (!model) {
            return;
        }
            model.translating = NO;
        if (code == 26200) {
            model.translationString = translation.translationString;
        } else {
            [RCAlertView showAlertController:RCLocalizedString(@"TranslateFailed")
                                     message:nil
                            hiddenAfterDelay:1
                            inViewController:self];
        }
        [self uploadTranslationByModel:model];

    }
}

#pragma mark -- Emoji

/*!
 禁用系统表情

 @discussion 禁用后只显示自定义表情。
 */
- (void)disableSystemDefaultEmoji {
    [self.chatSessionInputBarControl.emojiBoardView disableSystemDefaultEmoji];
}
/*!
 系统表情是否禁用

 @discussion 禁用状态。
 */
- (BOOL)isSystemEmojiDisable {
    return self.chatSessionInputBarControl.emojiBoardView.isSystemEmojiDisable;
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
            [self.unReadButton setBackgroundImage:RCDynamicImage(@"conversation_unread_button_bg_img", @"up") forState:UIControlStateNormal];
        }
        if (self.unReadMentionedButton) {
            [self.unReadMentionedButton setBackgroundImage:RCDynamicImage(@"conversation_unread_button_bg_img", @"up") forState:UIControlStateNormal];
        }
        [self.conversationMessageCollectionView reloadData];
    }
}

#pragma mark - Reference
- (void)onReferenceMessageCell:(id)sender {
    if ([self edit_onReferenceMessageCell:sender])  {
        return;
    }
    // 进入普通输入引用消息模式
    [self onReferenceMessageCellAndEditing:YES];
}

- (void)onReferenceMessageCellAndEditing:(BOOL)editing {
    [self removeReferencingView];
    self.referencingView = [[RCReferencingView alloc] initWithModel:self.currentSelectedModel inView:self.view];
    self.referencingView.delegate = self;
    [self.view addSubview:self.referencingView];
    [self.referencingView
        setOffsetY:CGRectGetMinY(self.chatSessionInputBarControl.frame) - self.referencingView.frame.size.height];
    if (editing) {
        [self.chatSessionInputBarControl.inputTextView becomeFirstResponder];
    }
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

- (void)dismissReferencingViewAndCommonPhrasesView:(RCReferencingView *)referencingView {
    [self removeReferencingView];
    __block CGRect messageCollectionView = self.conversationMessageCollectionView.frame;
    [UIView animateWithDuration:0.25
                     animations:^{
        if (self.chatSessionInputBarControl) {
            NSInteger diff = [self.chatSessionInputBarControl currentCommonPhrasesViewHeight];
            messageCollectionView.size.height =
            CGRectGetMinY(self.chatSessionInputBarControl.frame) - messageCollectionView.origin.y + diff;
            self.conversationMessageCollectionView.frame = messageCollectionView;
        }
    }];
}

- (void)showCommonPhrasesViewIfNeeded {
    __block CGRect messageCollectionView = self.conversationMessageCollectionView.frame;
    [UIView animateWithDuration:0.25
                     animations:^{
        NSInteger diff = [self.chatSessionInputBarControl currentCommonPhrasesViewHeight];
        if (self.chatSessionInputBarControl) {
            messageCollectionView.size.height = messageCollectionView.size.height - diff;
            self.conversationMessageCollectionView.frame = messageCollectionView;
        }
    }];
}

- (void)previewReferenceView:(RCMessageModel *)messageModel {
    if ([self disableReferencedPreview:messageModel]) {
        return;
    }
    
    RCMessageContent *msgContent = messageModel.content;
    if ([messageModel.content isKindOfClass:[RCReferenceMessage class]]) {
        RCReferenceMessage *refer = (RCReferenceMessage *)messageModel.content;
        msgContent = refer.referMsg;
    }

    if ([msgContent isKindOfClass:[RCImageMessage class]]) {
        RCMessage *referencedMsg = [[RCMessage alloc] initWithType:self.conversationType
                                                          targetId:self.targetId
                                                         direction:MessageDirection_SEND
                                                           content:msgContent];
        referencedMsg.messageId = messageModel.messageId;
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
    } else if ([msgContent isKindOfClass:[RCTextMessage class]]|| [msgContent isKindOfClass:[RCReferenceMessage class]]){
        if ([self.chatSessionInputBarControl.inputTextView isFirstResponder]) {
            [self.chatSessionInputBarControl.inputTextView resignFirstResponder];
        }
        BOOL isEdited = NO;
        if ([messageModel.content isKindOfClass:[RCReferenceMessage class]]) {
            isEdited = ((RCReferenceMessage *)messageModel.content).referMsgStatus == RCReferenceMessageStatusModified;
        }
        NSString *showText = [RCKitUtility formatMessage:msgContent targetId:self.targetId conversationType:self.conversationType isAllMessage:YES];
        [RCTextPreviewView edit_showText:showText messageId:messageModel.messageId edited:isEdited delegate:self];
    } else if ([msgContent isKindOfClass:[RCStreamMessage class]]){
         if ([self.chatSessionInputBarControl.inputTextView isFirstResponder]) {
             [self.chatSessionInputBarControl.inputTextView resignFirstResponder];
         }
        RCStreamMessage *stream = (RCStreamMessage *)msgContent;
        [RCTextPreviewView showText:stream.content messageId:messageModel.messageId  delegate:self];
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
        reference.referMsgUid = self.referencingView.referModel.messageUId;
        if (self.referencingView.referModel.hasChanged) {
            [reference setValue:@(RCReferenceMessageStatusModified) forKey:@"referMsgStatus"];
        }
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

- (void)setDefaultLocalHistoryMessageCount:(int)count {
    self.defaultMessageCount = count;
}

- (void)setDefaultRemoteHistoryMessageCount:(int)count {
    self.defaultMessageCount = count;
}

- (void)setDefaultMessageCount:(int)count {
    if (count > 100) {
        _defaultMessageCount = 100;
    }else if(count < 2){
        _defaultMessageCount = 10;
    } else {
        _defaultMessageCount = count;
    }
}

- (int)defaultMessageCount {
    return _defaultMessageCount;
}

- (int)defaultLocalHistoryMessageCount {
    return self.defaultMessageCount;
}

- (int)defaultRemoteHistoryMessageCount {
    return self.defaultMessageCount;
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
        RCMessageModel *nextVoiceMessage;
        long long currentVoiceSentTime = 0;
        for (int i = 0; i < self.conversationDataRepository.count; i++) {
            rcMsg = [self.conversationDataRepository objectAtIndex:i];
            // 先找到当前音频
            if(currentVoiceSentTime == 0){
                if(messageId == rcMsg.messageId) {
                    currentVoiceSentTime = rcMsg.sentTime; // 记录发送时间
                }
                continue;
            }
            // 找到距离发送时间最近的一个音频消息
            if (currentVoiceSentTime < rcMsg.sentTime && ([rcMsg.content isMemberOfClass:[RCVoiceMessage class]] ||
                                                [rcMsg.content isMemberOfClass:[RCHQVoiceMessage class]]) &&
                NO == rcMsg.receivedStatusInfo.isListened && rcMsg.messageDirection == MessageDirection_RECEIVE &&
                rcMsg.content.destructDuration == 0) {
                nextVoiceMessage = rcMsg;
                break;
            }
        }
        
        if (!nextVoiceMessage) {
            self.isContinuousPlaying = NO;
            return;
        }
        [self startPlayAudio:nextVoiceMessage];
    });
}

- (void)startPlayAudio:(RCMessageModel *)model {
    [self markMessageListened:model];
    [[RCVoicePlayer defaultPlayer] playAudio:model];
}

- (void)markMessageListened:(RCMessageModel *)model {
    if (model.receivedStatusInfo.isListened) {
        return;
    }
    [model.receivedStatusInfo markAsListened];
    [[RCCoreClient sharedCoreClient] setMessageReceivedStatus:model.messageId
                                           receivedStatusInfo:model.receivedStatusInfo
                                                   completion:nil];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return [super canPerformAction:action withSender:sender];
}

- (BOOL)resignFirstResponder {
    // 🎯 当RCConversationViewController丧失第一响应者身份时，清空UIMenuController的菜单项
    // 这样可以避免消息cell的菜单项残留，影响输入框的菜单显示
    UIMenuController *menu = [UIMenuController sharedMenuController];
    
    // 只有当菜单项不为空时才进行清空操作，避免不必要的UI更新
    if (menu.menuItems.count > 0) {
        // iOS 13+ 和之前版本的兼容性处理
        if (@available(iOS 13.0, *)) {
            // iOS 13+ 使用新的API，需要同时隐藏菜单和清空菜单项
            [menu hideMenuFromView:self.view];
            [menu setMenuItems:nil];
        } else {
            // iOS 13以下使用传统方式
            [menu setMenuItems:nil];
            [menu setMenuVisible:NO animated:NO];
        }
    }
    [[RCMenuController sharedMenuController] hideMenuAnimated:NO];

    return [super resignFirstResponder];
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
    
    // 清理批量提交管理器
    [self.readReceiptBatchManager invalidate];

}

- (BOOL)isRemainMessageExisted {
    return self.locatedMessageSentTime != 0;
}

- (void)addMentionedUserToCurrentInput:(RCUserInfo *)userInfo {
    if ([self edit_addMentionedUserToCurrentInput:userInfo]) {
        return;
    }
    // 普通模式
    if (self.chatSessionInputBarControl.isMentionedEnabled) {
        [self.chatSessionInputBarControl addMentionedUser:userInfo];
        [self.chatSessionInputBarControl.inputTextView becomeFirstResponder];
    }
}

- (BOOL)isSupportReadReceiptV5 {
    return [[RCCoreClient sharedCoreClient] getAppSettings].readReceiptVersion == RCMessageReadReceiptVersion5;
}

- (BOOL)isDisplayOnlineStatus {
    NSString *userId = [RCCoreClient sharedCoreClient].currentUserInfo.userId;
    // 只处理单聊且有自定义标题视图的情况
    return self.conversationType == ConversationType_PRIVATE
            && [RCUserOnlineStatusUtil shouldDisplayOnlineStatus]
            && !([userId isEqualToString:self.targetId]);
}

#pragma mark - Title Management
/**
 * 重写 setTitle: 方法，支持外部通过 self.title 设置标题
 * 
 * @param title 标题文本
 * 
 * @discussion
 *   - 当使用自定义标题视图时，将标题更新到自定义视图
 *   - 否则使用系统默认的标题设置方式
 */
- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    
    // 如果有自定义标题视图，同步更新到自定义视图
    if (self.conversationTitleView) {
        [self.conversationTitleView setTitle:title];
    }
}

/**
 * 获取当前导航栏标题
 * 
 * @return 当前标题文本
 */
- (NSString *)currentNavigationTitle {
    if (self.conversationTitleView) {
        return self.conversationTitleView.titleLabel.text;
    } else {
        return self.navigationItem.title;
    }
}

/// 更新导航栏标题的在线状态显示
- (void)updateNavigationTitleOnlineStatus {
    // 如果子类自定义了 titleView 那就不用处理了。
    if (![self isDisplayOnlineStatus]
        || !self.conversationTitleView
        || ![self.navigationItem.titleView isKindOfClass:[self.conversationTitleView class]]) {
        return;
    }
    
    RCSubscribeUserOnlineStatus *onlineStatus = [[RCUserOnlineStatusManager sharedManager] getCachedOnlineStatus:self.targetId];
    // 无论是否在线，都需要显示图标
    [self.conversationTitleView updateOnlineStatus:onlineStatus.isOnline];
    if (!onlineStatus) {
        [[RCUserOnlineStatusManager sharedManager] fetchOnlineStatus:self.targetId processSubscribeLimit:NO];
    }
}

- (void)updateNavigationTitle:(NSString *)title {
    if (self.conversationTitleView) {
        self.conversationTitleView.titleLabel.text = title;
    } else {
        self.navigationItem.title = title;
    }
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

- (void)didSendMessageModel:(NSInteger)status model:(RCMessageModel *)messageModel {
    DebugLog(@"super %s, %@", __FUNCTION__, messageModel);
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
- (RCBaseImageView *)unreadRightBottomIcon {
    if (!_unreadRightBottomIcon) {
        UIImage *msgCountIcon = RCDynamicImage(@"conversation_unread_button_bubble_img", @"bubble");
        CGRect frame = CGRectMake(self.view.frame.size.width - 5.5 - 35, self.chatSessionInputBarControl.frame.origin.y - 12 - 35, 35, 35);
        if ([RCKitUtility isRTL]) {
            frame.origin.x = 5.5;
        }
        _unreadRightBottomIcon = [[RCBaseImageView alloc] initWithFrame:frame];
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
        _unReadNewMessageLabel.textColor = RCDynamicColor(@"control_title_white_color", @"0xffffff", @"0x111111");
        _unReadNewMessageLabel.center = CGPointMake(_unReadNewMessageLabel.frame.size.width / 2,
                                                    _unReadNewMessageLabel.frame.size.height / 2 - 2.5);
        [self.unreadRightBottomIcon addSubview:_unReadNewMessageLabel];
    }
    return _unReadNewMessageLabel;
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


- (RCBaseButton *)unReadButton {
    if (!_unReadButton) {
        _unReadButton = [RCBaseButton new];
        CGFloat extraHeight = 0;
        if ([self getSafeAreaExtraBottomHeight] > 0) {
            extraHeight = 24; // 齐刘海屏的导航由20变成了44，需要额外加24
        }
        CGFloat height = 48;
        if (![RCKitUtility isTraditionInnerThemes]) {
            height = 32;
            // 设置阴影
            _unReadButton.layer.shadowColor = HEXCOLOR(0x1d1d1d).CGColor; // 阴影颜色（注意用 CGColor）
            _unReadButton.layer.shadowOpacity = 1; // 透明度（0~1）
            _unReadButton.layer.shadowRadius = 4; // 模糊半径
            _unReadButton.layer.shadowOffset = CGSizeMake(0, 4); // 偏移（x:0 向右偏移0，y:4 向下偏移4）
        }
        _unReadButton.frame = CGRectMake(0, [RCKitUtility getWindowSafeAreaInsets].top + self.navigationController.navigationBar.frame.size.height + 14, 0, height);
        [_unReadButton setBackgroundImage:RCDynamicImage(@"conversation_unread_button_bg_img", @"up") forState:UIControlStateNormal];
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
        _unReadMessageLabel.textColor = RCDynamicColor(@"primary_color", @"0x111f2c", @"0x0099ff");
        _unReadMessageLabel.textAlignment = NSTextAlignmentCenter;
        _unReadMessageLabel.tag = 1001;
    }
    return _unReadMessageLabel;
}

- (RCBaseButton *)unReadMentionedButton {
    if (_unReadMentionedButton == nil) {
        _unReadMentionedButton = [RCBaseButton new];
        CGFloat height = 48;
        if (![RCKitUtility isTraditionInnerThemes]) {
            height = 32;
            // 设置阴影
            _unReadMentionedButton.layer.shadowColor = HEXCOLOR(0x1d1d1d).CGColor;
            _unReadMentionedButton.layer.shadowOpacity = 1; // 透明度（0~1）
            _unReadMentionedButton.layer.shadowRadius = 4; // 模糊半径
            _unReadMentionedButton.layer.shadowOffset = CGSizeMake(0, 4); // 偏移（x:0 向右偏移0，y:4 向下偏移4）
        }
        _unReadMentionedButton.frame = CGRectMake(0, CGRectGetMaxY(self.unReadButton.frame) + 15, 0, height);
        [_unReadMentionedButton setBackgroundImage:RCDynamicImage(@"conversation_unread_button_bg_img", @"up") forState:UIControlStateNormal];
        [_unReadMentionedButton addTarget:self action:@selector(tapRightTopUnReadMentionedButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_unReadMentionedButton];
        [_unReadMentionedButton addSubview:self.unReadMentionedLabel];
        [_unReadMentionedButton bringSubviewToFront:self.conversationMessageCollectionView];
    }
    return _unReadMentionedButton;
}

- (UILabel *)unReadMentionedLabel {
    if (!_unReadMentionedLabel) {
        _unReadMentionedLabel = [[UILabel alloc] initWithFrame:CGRectMake(17 + 9 + 6, 0, 0, 48)];
        _unReadMentionedLabel.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
        _unReadMentionedLabel.textColor = RCDynamicColor(@"hint_color", @"0x111f2c", @"0x0099ff");
        _unReadMentionedLabel.textAlignment = NSTextAlignmentCenter;
        _unReadMentionedLabel.tag = 1002;
    }
    return _unReadMentionedLabel;
}

- (UIToolbar *)messageSelectionToolbar {
    if (!_messageSelectionToolbar) {
        _messageSelectionToolbar = [[UIToolbar alloc] init];
        [_messageSelectionToolbar setShadowImage:[UIImage new] forToolbarPosition:UIBarPositionAny];
        _messageSelectionToolbar.backgroundColor =  RCDynamicColor(@"common_background_color", @"0xf5f6f9", @"0x090909");
        _messageSelectionToolbar.barTintColor = RCDynamicColor(@"common_background_color", @"0xf5f6f9", @"0x1c1c1c");

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

        NSArray *items = @[ spaceItem, forwardBarButtonItem, spaceItem, deleteBarButtonItem, spaceItem ];
        
        if ([RCKitUtility isRTL]){
            _messageSelectionToolbar.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        }else{
            _messageSelectionToolbar.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }

        [_messageSelectionToolbar setItems:items animated:YES];
        _messageSelectionToolbar.translucent = NO;

    }
    return _messageSelectionToolbar;
}

- (NSArray *)getLeftBackButton {
    int count = [[RCCoreClient sharedCoreClient] getUnreadCount:self.displayConversationTypeArray];
    
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
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    imgMirror = [RCSemanticContext imageflippedForRTL:imgMirror];
    if (self.conversationType == ConversationType_CUSTOMERSERVICE) {
        items = [RCKitUtility getLeftNavigationItems:imgMirror title:backString target:self action:@selector(customerServiceLeftCurrentViewController)];
    } else {
        items = [RCKitUtility getLeftNavigationItems:imgMirror title:backString target:self action:@selector(leftBarButtonItemPressed:)];
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

- (void)setIsTouchScrolled:(BOOL)isTouchScrolled {
    if (isTouchScrolled != self.isTouchScrolled) {
        _isTouchScrolled = isTouchScrolled;
        [[NSNotificationCenter defaultCenter] postNotificationName:RCConversationViewScrollNotification object:@(isTouchScrolled)];
    }
}

#pragma -mark private method
- (void)p_didTapMessageCellForImageMessage:(RCMessageModel *)model {
    RCMessageContent *_messageContent = model.content;
    RCImageMessage *imageMsg = (RCImageMessage *)_messageContent;
    if (imageMsg.destructDuration > 0) {
        [self presentDestructImagePreviewController:model];
    } else {
        [self presentImagePreviewController:model];
    }
}

- (void)p_didTapMessageCellForSightMessage:(RCMessageModel *)model {
    RCMessageContent *_messageContent = model.content;
    if ([RCKitUtility isCameraHolding]) {
        NSString *alertMessage = RCLocalizedString(@"VoIPVideoCallExistedWarning");
        [RCAlertView showAlertController:nil message:alertMessage hiddenAfterDelay:1 inViewController:self];
        return;
    }
    if ([RCKitUtility isAudioHolding]) {
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
}

- (void)p_didTapMessageCellForGIFMessage:(RCMessageModel *)model {
    RCMessageContent *_messageContent = model.content;
    RCGIFMessage *gifMsg = (RCGIFMessage *)_messageContent;
    if (gifMsg.destructDuration > 0) {
        [self pushDestructGIFPreviewViewController:model];
    } else {
        [self pushGIFPreviewViewController:model];
    }
}

- (void)p_didTapMessageCellForCombineMessage:(RCMessageModel *)model {
    RCMessageContent *_messageContent = model.content;
    RCCombineMessage *combineMsg = (RCCombineMessage *)_messageContent;
    if (combineMsg.destructDuration > 0) {
    } else {
        [self pushCombinePreviewViewController:model];
    }
}

- (void)p_didTapMessageCellForVoiceMessage:(RCMessageModel *)model {
    if ([RCKitUtility isAudioHolding]) {
        NSString *alertMessage = RCLocalizedString(@"AudioHoldingWarning");
        [RCAlertView showAlertController:nil message:alertMessage hiddenAfterDelay:1 inViewController:self];
        return;
    }
    if (model.messageDirection == MessageDirection_RECEIVE && NO == model.receivedStatusInfo.isListened) {
        self.isContinuousPlaying = YES;
    } else {
        self.isContinuousPlaying = NO;
    }
    if ([RCVoicePlayer defaultPlayer].isPlaying && model.messageId == [RCVoicePlayer defaultPlayer].messageId) {
        [[RCVoicePlayer defaultPlayer] stopPlayVoice];
    } else {
        [self startPlayAudio:model];
    }
}

- (void)p_didTapMessageCellForLocationMessage:(RCMessageModel *)model {
    RCMessageContent *_messageContent = model.content;
    // Show the location view controller
    RCLocationMessage *locationMessage = (RCLocationMessage *)(_messageContent);
    [self presentLocationViewController:locationMessage];
}

- (void)p_didTapMessageCellForTextMessage:(RCMessageModel *)model {
    RCMessageContent *_messageContent = model.content;
    // link
    RCTextMessage *textMsg = (RCTextMessage *)(_messageContent);
    if (model.messageDirection == MessageDirection_RECEIVE && textMsg.destructDuration > 0) {
        NSUInteger row = [self.conversationDataRepository indexOfObject:model];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [[RCCoreClient sharedCoreClient] getMessage:model.messageId completion:^(RCMessage * _Nullable message) {
            [[RCCoreClient sharedCoreClient] messageBeginDestruct:message];
            dispatch_async(dispatch_get_main_queue(), ^{
                model.cellSize = CGSizeZero;
                //更新UI
                [self.conversationMessageCollectionView reloadItemsAtIndexPaths:@[ indexPath ]];
                
                [self.conversationMessageCollectionView scrollToItemAtIndexPath:indexPath
                                                               atScrollPosition:UICollectionViewScrollPositionNone
                                                                       animated:YES];
            });
        }];
    }
    // phoneNumber
}

#pragma mark - Edit Message

- (BOOL)disableReferencedPreview:(RCMessageModel *)messageModel {
    if ([messageModel.content isKindOfClass:[RCReferenceMessage class]]) {
        RCReferenceMessage *refMsg = (RCReferenceMessage *)messageModel.content;
        if (refMsg.referMsgStatus == RCReferenceMessageStatusDeleted
            || refMsg.referMsgStatus == RCReferenceMessageStatusRecalled) {
            return YES;
        }
    }
    return NO;
}

- (void)onEditMessage:(id)sender {
    [self edit_onEditMessage:sender];
}

- (void)didTapEditRetryButton:(RCMessageModel *)model {
    [self edit_didTapEditRetryButton:model];
}

#pragma mark RCEditBarControlDelegate

- (void)editInputBarControl:(RCEditInputBarControl *)editInputBarControl didConfirmWithText:(NSString *)text {
    [self edit_editInputBarControl:editInputBarControl didConfirmWithText:text];
}

- (void)editInputBarControlDidCancel:(RCEditInputBarControl *)editInputBarControl {
    [self edit_editInputBarControlDidCancel:editInputBarControl];
}

- (void)editInputBarControl:(RCEditInputBarControl *)editInputBarControl shouldChangeFrame:(CGRect)frame {
    [self edit_editInputBarControl:editInputBarControl shouldChangeFrame:frame];
}

- (void)editInputBarControl:(RCEditInputBarControl *)editInputBarControl
           showUserSelector:(void (^)(RCUserInfo *selectedUser))selectedBlock
                     cancel:(void (^)(void))cancelBlock {
    [self edit_editInputBarControl:editInputBarControl showUserSelector:selectedBlock cancel:cancelBlock];
}

- (void)editInputBarControlRequestFullScreenEdit:(RCEditInputBarControl *)editInputBarControl {
    [self edit_editInputBarControlRequestFullScreenEdit:editInputBarControl];
}

#pragma mark FullScreenEditViewDelegate

- (void)fullScreenEditViewCollapse:(RCFullScreenEditView *)fullScreenEditView {
    [self edit_fullScreenEditViewCollapse:fullScreenEditView];
}

- (void)fullScreenEditViewCancel:(RCFullScreenEditView *)fullScreenEditView {
    [self edit_fullScreenEditViewCancel:fullScreenEditView];
}

- (void)fullScreenEditView:(RCFullScreenEditView *)fullScreenEditView didConfirmWithText:(NSString *)text {
    [self edit_fullScreenEditView:fullScreenEditView didConfirmWithText:text];
}

- (void)fullScreenEditView:(RCFullScreenEditView *)fullScreenEditView showUserSelector:(void (^)(RCUserInfo * _Nonnull))selectedBlock cancel:(void (^)(void))cancelBlock {
    [self edit_fullScreenEditView:fullScreenEditView showUserSelector:selectedBlock cancel:cancelBlock];
}

#pragma mark RCEditBarControlDataSource

- (nullable RCUserInfo *)editInputBarControl:(RCEditInputBarControl *)editInputBarControl
                            getUserInfo:(NSString *)userId {
    return [self edit_editInputBarControl:editInputBarControl getUserInfo:userId];
}

#pragma mark RCSelectingUserDataSource

- (void)getSelectingUserIdList:(void (^)(NSArray<NSString *> *userIdList))completion {
    [self getSelectingUserIdList:completion functionTag:INPUT_MENTIONED_SELECT_TAG];
}

@end
