//
//  RCConversationViewController+Edit.m
//  RongIMKit
//
//  Created by RongCloud on 2025/1/16.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCConversationViewController+Edit.h"
#import "RCEditInputBarControl.h"
#import "RCUserListViewController.h"
#import "RCBaseNavigationController.h"
#import "RCAlertView.h"
#import "RCKitUtility.h"
#import "RCKitConfig.h"
#import "RCUserInfoCacheManager.h"
#import "RCMessageModel.h"
#import "RCConversationVCUtil.h"
#import "RCKitCommonDefine.h"
#import "RCConversationDataSource.h"
#import "RCConversationDataSource+Edit.h"
#import "RCMessageModel+Edit.h"
#import "RCMessageSelectionUtility.h"

@interface RCConversationViewController ()

@property (nonatomic, strong) RCConversationDataSource *dataSource;
@property (nonatomic, assign) BOOL isConversationAppear;
@property (nonatomic, strong) RCConversationVCUtil *util;
@property (nonatomic, strong) RCMessageModel *currentSelectedModel;
// 正在编辑中的配置
@property (nonatomic, strong) RCEditInputBarConfig *editingInputBarConfig;

- (void)removeReferencingView;

- (BOOL)isRemainMessageExisted;

- (float)getSafeAreaExtraBottomHeight;

- (void)loadRemainMessageAndScrollToBottom:(BOOL)animated;

- (RCUserInfo *)getSelectingUserInfo:(NSString *)userId;

- (void)getSelectingUserIdList:(void (^)(NSArray<NSString *> *userIdList))completion
                   functionTag:(NSInteger)functionTag;

@end

@implementation RCConversationViewController (Edit)

- (void)edit_viewWillAppear:(BOOL)animated {
    if ([self edit_isMessageEditing]) {
        [self.editInputBarControl restoreFocusIfNeeded];
    }
}

- (BOOL)edit_isMessageEditing {
    return self.editInputBarControl && self.editingInputBarConfig;
}

#pragma mark - 编辑控件管理

- (void)edit_createEditBarControl {
    if (!RCKitConfigCenter.message.enableEditMessage) {
        return;
    }
    if (!self.editInputBarControl) {
        CGRect frame = CGRectMake(0, self.view.bounds.size.height - RC_ChatSessionInputBar_Height - [self getSafeAreaExtraBottomHeight], self.view.bounds.size.width, RC_ChatSessionInputBar_Height);
        self.editInputBarControl = [[RCEditInputBarControl alloc] initWithFrame:frame];
        self.editInputBarControl.delegate = self;
        self.editInputBarControl.dataSource = self;
        self.editInputBarControl.conversationType = self.conversationType;
        self.editInputBarControl.targetId = self.targetId;
        self.editInputBarControl.isMentionedEnabled = YES;
        self.editInputBarControl.hidden = YES;
        [self.view addSubview:self.editInputBarControl];
    }
}

- (void)edit_dismissEditBottomPanels {
    [self.editInputBarControl hideBottomPanels];
}

- (BOOL)edit_markEditIsExpired:(RCEditInputBarControl *)inputBar {
    if (!self.editingInputBarConfig
        || ![self.util isEditTimeValid:self.editingInputBarConfig.sentTime]) {

        [inputBar markEditAsExpired];
        return YES;
    }
    return NO;
}

#pragma mark - 编辑逻辑

// 点击更多按钮会触发的逻辑
- (BOOL)edit_updateConversationMessageCollectionView {
    if (![self edit_isMessageEditing]) {
        return NO;
    }
    // 更新导航栏
    [self notifyUpdateUnreadMessageCount];
    
    BOOL multiSelect = [RCMessageSelectionUtility sharedManager].multiSelect;
    if (multiSelect) {
        [[RCMessageSelectionUtility sharedManager] addMessageModel:self.currentSelectedModel];
        [self.view addSubview:self.messageSelectionToolbar];
    } else {
        self.currentSelectedModel = nil;
        [self.messageSelectionToolbar removeFromSuperview];
    }
    [self.editInputBarControl hideEditInputBar:multiSelect];
    
    [self.conversationMessageCollectionView reloadData];
    [self.conversationMessageCollectionView setNeedsLayout];
    [self.conversationMessageCollectionView layoutIfNeeded];
    return YES;
}

- (BOOL)edit_didTapReedit:(RCMessageModel *)model {
    [self edit_exitEditModeWithActivateNormal:NO];
    return NO;
}

- (BOOL)edit_onReferenceMessageCell:(id)sender {
    [self edit_exitEditModeWithActivateNormal:NO];
    return NO;
}

// 处理编辑消息的响应
- (void)edit_onEditMessage:(id)sender {
    // 保存草稿
    [self edit_saveNormalInputDraftIfNeed];
    // 如果普通输入框有引用消息，先删除，编辑退出后会判断是否需要恢复
    [self removeReferencingView];

    if (self.editingInputBarConfig && [self.editingInputBarConfig.messageUId isEqualToString:self.currentSelectedModel.messageUId]) {
        return;
    }
    
    if (self.editingInputBarConfig) {
        [RCAlertView showAlertController:RCLocalizedString(@"Tip") message:RCLocalizedString(@"MessageEditingAlert") actionTitles:nil cancelTitle:RCLocalizedString(@"Cancel") confirmTitle:RCLocalizedString(@"Confirm") preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:^{
            self.editingInputBarConfig = nil;
            [self edit_enterEditWithModel:self.currentSelectedModel];
        } inViewController:self];
        return;
    }
    
   [self edit_enterEditWithModel:self.currentSelectedModel];
}

- (void)edit_enterEditWithModel:(RCMessageModel *)model {
    // 获取原始消息内容
    NSString *originalText = @"";
    NSString *referencedSenderName = nil;
    NSString *referencedContent = nil;
    
    RCMentionedInfo *mentionedInfo = model.content.mentionedInfo;
    if ([model.content isMemberOfClass:[RCTextMessage class]]) {
        RCTextMessage *textMessage = (RCTextMessage *)model.content;
        originalText = textMessage.content ?: @"";
    } else if ([model.content isMemberOfClass:[RCReferenceMessage class]]) {
        RCReferenceMessage *referenceMessage = (RCReferenceMessage *)model.content;
        originalText = referenceMessage.content ?: @"";
        
        // 获取引用消息的信息
        if (referenceMessage.referMsg) {
            // 使用 referMsgUserId 获取用户信息
            if (referenceMessage.referMsgUserId) {
                RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:referenceMessage.referMsgUserId];
                referencedSenderName = userInfo.name ?: @"";
            }
            if (referenceMessage.referMsgStatus == RCReferenceMessageStatusRecalled) {
                referencedContent = RCLocalizedString(@"ReferencedMessageRecalled");
            } else if (referenceMessage.referMsgStatus == RCReferenceMessageStatusDeleted) {
                referencedContent = RCLocalizedString(@"ReferencedMessageDeleted");
            } else {
                if ([referenceMessage.referMsg isKindOfClass:[RCTextMessage class]]) {
                    RCTextMessage *refTextMsg = (RCTextMessage *)referenceMessage.referMsg;
                    referencedContent = refTextMsg.content ?: @"";
                } else {
                    NSString *content = [RCKitUtility formatMessage:referenceMessage.referMsg
                                                           targetId:model.targetId
                                                   conversationType:model.conversationType
                                                       isAllMessage:YES];
                    referencedContent = content;
                }
            }
        }
    }
    
    RCEditInputBarConfig *config = [[RCEditInputBarConfig alloc] init];
    config.messageUId = model.messageUId;
    config.sentTime = model.sentTime;
    config.textContent = originalText;
    config.referencedSenderName = referencedSenderName;
    config.referencedContent = referencedContent;
    config.mentionedInfo = mentionedInfo;
    // 进入编辑
    [self edit_showEditBarWithConfig:config becomeFirstResponder:YES];
}

- (void)edit_showEditBarWithConfig:(RCEditInputBarConfig *)config
              becomeFirstResponder:(BOOL)becomeFirstResponder {
    // 进入编辑时清除已有缓存
    [self edit_clearSavedEditState];
    
    // 只有退出编辑或第一次编辑时，才需重新保存 editingInputBarConfig，避免从全屏页面返回时被重置
    if (!self.editingInputBarConfig) {
        self.editingInputBarConfig = config;
    }
    
    void (^showEditBlock)(void) = ^{
        if ([self.chatSessionInputBarControl.inputTextView isFirstResponder]) {
            [self.chatSessionInputBarControl.inputTextView resignFirstResponder];
        }
        if (!self.chatSessionInputBarControl.hidden) {
            self.chatSessionInputBarControl.hidden = YES;
        }
        [self.editInputBarControl showWithConfig:config];
        [self edit_markEditIsExpired:self.editInputBarControl];
        if (becomeFirstResponder) {
            [self.editInputBarControl restoreFocus];
        }
    };
    
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), showEditBlock);
    } else {
        showEditBlock();
    }
}

- (void)edit_showAlert:(NSString *)alertMessage {
    [RCAlertView showAlertController:RCLocalizedString(@"Tip") message:alertMessage actionTitles:nil cancelTitle:nil confirmTitle:RCLocalizedString(@"Confirm") preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:^{
        
    } inViewController:self];
}

- (void)edit_checkConfirmData:(RCEditInputBarControl *)editInputBarControl
                         text:(NSString *)text
                   completion:(void (^)(RCMessageModel * _Nullable message))completion {
    
    void (^safeCompletion)(RCMessageModel * _Nullable model) = ^(RCMessageModel * _Nullable model){
        if (completion) {
            if ([NSThread isMainThread]) {
                completion(model);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(model);
                });
            }
        }
    };
    
    if (text.length == 0) {
        safeCompletion(nil);
        return;
    }
    if ([self edit_markEditIsExpired:editInputBarControl]) {
        safeCompletion(nil);
        return;
    }
    [[RCCoreClient sharedCoreClient] getMessageByUId:self.editingInputBarConfig.messageUId completion:^(RCMessage * _Nullable message) {
        if (!message) {
            [self edit_showAlert:RCLocalizedString(@"MessageEditDeletedAlert")];
            safeCompletion(nil);
            return;
        }
        if ([message.content isKindOfClass:[RCRecallNotificationMessage class]]) {
            [self edit_showAlert:RCLocalizedString(@"MessageEditRecalledAlert")];
            safeCompletion(nil);
            return;
        }
        RCMessageModel *model = [RCMessageModel modelWithMessage:message];
        safeCompletion(model);
    }];
}

- (void)edit_didUpdateMessageWithText:(NSString *)text
                        mentionedInfo:(nullable RCMentionedInfo *)mentionedInfo
                         messageModel:(RCMessageModel *)messageModel {
    // 如果编辑的文本为空，则不进行更新
    if (text.length == 0) {
        return;
    }
    
    RCMessageContent *newContent = messageModel.content;
    newContent.mentionedInfo = mentionedInfo;
    if ([newContent isMemberOfClass:[RCTextMessage class]]) {
        // 更新文本消息
        RCTextMessage *textMessage = (RCTextMessage *)newContent;
        textMessage.content = text;
    } else if ([newContent isMemberOfClass:[RCReferenceMessage class]]) {
        RCReferenceMessage *refMessage = (RCReferenceMessage *)newContent;
        refMessage.content = text;
    }
    [self edit_modifyMessage:messageModel newContent:newContent isRetry:NO];
}

- (void)edit_modifyMessage:(RCMessageModel *)model
           newContent:(RCMessageContent *)newContent 
              isRetry:(BOOL)isRetry {
    // 1. 先更新消息为编辑中的状态
    RCMessageModifyInfo *modifyInfo = [[RCMessageModifyInfo alloc] init];
    modifyInfo.status = RCMessageModifyStatusUpdating;
    model.modifyInfo = modifyInfo;
    [self edit_refreshEditedMessageByMessageModel:model];
    
    // 2. 真正开始修改
    RCModifyMessageParams *modifyParams = [[RCModifyMessageParams alloc] init];
    modifyParams.messageUId = model.messageUId;
    modifyParams.messageContent = newContent;
    
    void (^completeBlock)(RCMessage *, RCErrorCode) = ^(RCMessage * _Nonnull editedMessage, RCErrorCode code){
        [self edit_showEditErrorAlert:code isRetry:isRetry];
        
        if (!editedMessage) {
            if (model.modifyInfo) {
                model.modifyInfo.status = RCMessageModifyStatusSuccess;
            }
            [self edit_refreshEditedMessageByMessageModel:model];
            return;
        }
        RCMessageModel *editedModel = [RCMessageModel modelWithMessage:editedMessage];
        [self edit_refreshEditedMessageByMessageModel:editedModel];
    };
    
    [[RCCoreClient sharedCoreClient] modifyMessageWithParams:modifyParams completionHandler:^(RCMessage * _Nonnull message, RCErrorCode code) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            completeBlock(message, code);
        });
    }];
}
     
- (void)edit_showEditErrorAlert:(RCErrorCode)code isRetry:(BOOL)isRetry {
    if (code == RC_SUCCESS) {
        return;
    }
    NSString *alertContent = @"";
    switch (code) {
        case RC_ORIGINAL_MESSAGE_NOT_EXIST:
            alertContent = RCLocalizedString(@"MessageEditNotExist");
            break;
        case RC_DANGEROUS_CONTENT:
        case RC_CONTENT_REVIEW_REJECTED:
            alertContent = RCLocalizedString(@"MessageEditContentSensitive");
            break;
        case MESSAGE_OVER_MODIFY_TIME_FAIL:
        case RC_MODIFIED_MESSAGE_TIMEOUT:
            alertContent = RCLocalizedString(@"MessageEditExpiredToast");
            break;
        default:
        {
            if (isRetry) {
                alertContent = RCLocalizedString(@"MessageEditRetryFailed");
            } else {
                alertContent = RCLocalizedString(@"MessageEditFailed");
            }
        }
            break;
    }
    if (alertContent.length > 0) {
        [RCAlertView showAlertController:nil message:alertContent hiddenAfterDelay:2];
    }
}

- (void)edit_refreshEditedMessageByMessageModel:(RCMessageModel *)messageModel {
    if (!messageModel) {
        return;
    }
    [self.dataSource edit_refreshUIMessagesEditedStatus:@[messageModel]];
}

#pragma mark - @ 信息处理

- (BOOL)edit_addMentionedUserToCurrentInput:(RCUserInfo *)userInfo {
    // 检查是否在编辑模式
    if (![self edit_isMessageEditing]) {
        return NO;
    }
    
    if (!self.editInputBarControl.isMentionedEnabled) {
        return NO;
    }
    
    if (userInfo) {
        [self.editInputBarControl addMentionedUser:userInfo];
        [self.editInputBarControl restoreFocus];
        return YES;
    }
    return NO;
}

#pragma mark - 普通输入框的逻辑处理

- (void)edit_saveNormalInputDraftIfNeed {
    [self.util saveDraftIfNeed];
}

- (void)edit_restoreNoramlInputDarftIfNeed {
    [[RCChannelClient sharedChannelManager] getConversation:self.conversationType targetId:self.targetId channelId:self.channelId completion:^(RCConversation * _Nullable conversation) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.chatSessionInputBarControl.draft = conversation.draft;
        });
    }];
}

#pragma mark - 编辑状态保存和恢复

- (void)edit_loadEditingMessageIfNeeded {
    if (!RCKitConfigCenter.message.enableEditMessage) {
        return;
    }
    // 如果当前已经在编辑模式，不要重复加载
    if ([self edit_isMessageEditing]) {
        return;
    }
    RCEditInputBarConfig *editConfig = [self.util getCacheEditConfig];
    if (!editConfig || editConfig.cachedStateData.count == 0) {
        return;
    }
    [self edit_showEditBarWithConfig:editConfig becomeFirstResponder:YES];

    return;
}

- (void)edit_saveCurrentEditStateIfNeeded {
    if (![self edit_isMessageEditing]) {
        return;
    }
    RCEditInputBarControl *editInputBar = [self edit_currentActiveEditInputBarControl];
    if ([editInputBar hasContent]) {
        self.editingInputBarConfig.cachedStateData = editInputBar.stateData;
        [self.util saveEditingStateWithEditConfig:self.editingInputBarConfig];
    } else {
        // 如果编辑输入框没有内容，需要清空缓存的数据
        [self.util clearEditingState];
    }
}

- (void)edit_clearSavedEditState {
    [self.util clearEditingState];
}

- (void)edit_exitEditModeWithActivateNormal:(BOOL)activate {
    if (![self edit_isMessageEditing]) {
        return;
    }
    void (^safeBlock)() = ^{
        [self edit_exitEditModeWithAnimation:YES completion:^{
            [self edit_restoreNormalInputWithActivate:activate];
        }];
    };
    if ([NSThread isMainThread]) {
        safeBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            safeBlock();
        });
    }
}

- (void)edit_exitEditModeWithAnimation:(BOOL)animated completion:(void (^ _Nullable)())completion {
    // 退出并清空编辑状态
    [self.editInputBarControl exitWithAnimation:animated completion:^{
        self.editingInputBarConfig = nil;
        [self.editInputBarControl resetEditInputBar];
        [self edit_clearSavedEditState];
        if (completion) {
            completion();
        }
    }];
}

- (void)edit_restoreNormalInputWithActivate:(BOOL)activate {
    self.chatSessionInputBarControl.hidden = NO;
    // 原有的隐藏逻辑
    [self edit_restoreNoramlInputDarftIfNeed];
    if (activate) {
        [self.chatSessionInputBarControl.inputTextView becomeFirstResponder];
    }
}

- (RCEditInputBarControl *)edit_currentActiveEditInputBarControl {
    // 全屏编辑因为在界面上会覆盖普通编辑，所以优先返回全屏编辑
    return self.fullScreenEditView ?
    self.fullScreenEditView.editInputBarControl :
    self.editInputBarControl;
}

#pragma mark - 编辑 Delegate 实现方法

- (void)edit_editInputBarControl:(RCEditInputBarControl *)editInputBarControl didConfirmWithText:(NSString *)text {
    if (self.editingInputBarConfig) {
        [self edit_checkConfirmData:editInputBarControl text:text completion:^(RCMessageModel *model) {
            if (model) {
                [self edit_didUpdateMessageWithText:text mentionedInfo:editInputBarControl.mentionedInfo messageModel:model];
                // 退出编辑模式
                [self edit_exitEditModeWithActivateNormal:YES];
            }
        }];
    }
}

- (void)edit_editInputBarControlDidCancel:(RCEditInputBarControl *)editInputBarControl {
    [self edit_exitEditModeWithActivateNormal:YES];
}

- (void)edit_editInputBarControl:(RCEditInputBarControl *)editInputBarControl shouldChangeFrame:(CGRect)frame {
    if (![self edit_isMessageEditing]) {
        return;
    }
    // 是否显示多选，显示多选时编辑输入框是被隐藏的，所以需要减去多选工具栏的高度。
    BOOL multiSelect = [RCMessageSelectionUtility sharedManager].multiSelect;
    CGFloat extraHeight = multiSelect ? self.messageSelectionToolbar.bounds.size.height : 0;
    
    CGRect collectionViewRect = self.conversationMessageCollectionView.frame;
    collectionViewRect.size.height = CGRectGetMinY(frame) - collectionViewRect.origin.y - extraHeight;
    [self.conversationMessageCollectionView setFrame:collectionViewRect];
    if ([RCKitUtility isRTL]) {
        [self.unreadRightBottomIcon setFrame:CGRectMake(5.5, editInputBarControl.frame.origin.y - 12 - 35, 35, 35)];
    } else {
        [self.unreadRightBottomIcon setFrame:CGRectMake(self.view.frame.size.width - 5.5 - 35, editInputBarControl.frame.origin.y - 12 - 35, 35, 35)];
    }
    if (self.locatedMessageSentTime == 0 || self.isConversationAppear) {
        //在viewwillapear和viewdidload之前，如果强制定位，则不滑动到底部
        if (self.dataSource.isLoadingHistoryMessage || [self isRemainMessageExisted]) {
            [self loadRemainMessageAndScrollToBottom:YES];
        } else if (self.isConversationAppear) {
            [self scrollToBottomAnimated:NO];
        }
    }
}

- (void)edit_editInputBarControl:(RCEditInputBarControl *)editInputBarControl
           showUserSelector:(void (^)(RCUserInfo *selectedUser))selectedBlock
                     cancel:(void (^)(void))cancelBlock {
    void (^restoreFocus)(void) = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [editInputBarControl restoreFocus];
        });
    };
    // 包装回调，添加焦点恢复逻辑
    void (^wrappedCompletion)(RCUserInfo *) = ^(RCUserInfo *selectedUser) {
        if (selectedBlock) {
            selectedBlock(selectedUser);
        }
        restoreFocus();
    };
    
    void (^wrappedCancelBlock)(void) = ^{
        if (cancelBlock) {
            cancelBlock();
        }
        restoreFocus();
    };
    
    if ([self respondsToSelector:@selector(showChooseUserViewController:cancel:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showChooseUserViewController:wrappedCompletion cancel:wrappedCancelBlock];
        });
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 创建用户选择控制器
        RCUserListViewController *userListVC = [[RCUserListViewController alloc] init];
        userListVC.selectedBlock = wrappedCompletion;
        userListVC.cancelBlock = wrappedCancelBlock;
        userListVC.dataSource = self;
        userListVC.navigationTitle = RCLocalizedString(@"SelectMentionedUser");
        userListVC.maxSelectedUserNumber = 1;
        
        // 创建导航控制器并展示
        RCBaseNavigationController *rootVC = [[RCBaseNavigationController alloc] initWithRootViewController:userListVC];
        rootVC.modalPresentationStyle = UIModalPresentationFullScreen;
        UIViewController *presentedVC = self.navigationController.presentedViewController;
        if (presentedVC) {
            [presentedVC presentViewController:rootVC animated:YES completion:nil];
        } else {
            [self.navigationController presentViewController:rootVC animated:YES completion:nil];
        }
    });
}

- (nullable RCUserInfo *)edit_editInputBarControl:(RCEditInputBarControl *)editInputBarControl getUserInfo:(NSString *)userId {
    // 复用聊天输入栏的用户信息获取逻辑
    return [self getSelectingUserInfo:userId];
}

- (void)edit_editInputBarControlRequestFullScreenEdit:(RCEditInputBarControl *)editInputBarControl {
    
    [editInputBarControl hideBottomPanelsWithAnimation:YES completion:^{
        // 设为不可见
        editInputBarControl.isVisible = NO;
        
        [self edit_setupFullScreenEditView];
        
        if (self.navigationController) {
            [self.navigationController.view addSubview:self.fullScreenEditView];
        } else {
            // 降级方案：如果找不到导航控制器，仍然使用keyWindow
            UIWindow *keyWindow = [self edit_keyWindow];
            [keyWindow addSubview:self.fullScreenEditView];
        }
        RCEditInputBarConfig *config = [[RCEditInputBarConfig alloc] init];
        config.cachedStateData = self.editInputBarControl.stateData;
        
        [self.fullScreenEditView showWithConfig:config animation:YES];
        
        [self edit_markEditIsExpired:self.fullScreenEditView.editInputBarControl];
    }];
}

#pragma mark - 全屏编辑

- (void)edit_fullScreenEditViewCollapse:(RCFullScreenEditView *)fullScreenEditView {
    RCEditInputBarConfig *config = [[RCEditInputBarConfig alloc] init];
    config.cachedStateData = fullScreenEditView.editInputBarControl.stateData;
    [self edit_showEditBarWithConfig:config becomeFirstResponder:NO];
    
    [self edit_exitFullScreenEditView:^{
        [self.editInputBarControl restoreFocus];
    }];
}

- (void)edit_fullScreenEditViewCancel:(RCFullScreenEditView *)fullScreenEditView {
    // 退出普通编辑模式
    [self edit_exitEditModeWithAnimation:NO completion:nil];
    [self edit_exitFullScreenEditView:^{
        // 恢复正常的输入框
        [self edit_restoreNormalInputWithActivate:YES];
    }];
}

- (void)edit_fullScreenEditView:(RCFullScreenEditView *)fullScreenEditView
               showUserSelector:(void (^)(RCUserInfo * _Nonnull))selectedBlock
                         cancel:(void (^)(void))cancelBlock {
    [self edit_editInputBarControl:fullScreenEditView.editInputBarControl showUserSelector:selectedBlock cancel:cancelBlock];
}

- (void)edit_fullScreenEditView:(RCFullScreenEditView *)fullScreenEditView didConfirmWithText:(NSString *)text {
    [self edit_checkConfirmData:fullScreenEditView.editInputBarControl text:text completion:^(RCMessageModel *model) {
        if (model) {
            [self edit_exitFullScreenEditView:^{
                [self edit_didUpdateMessageWithText:text
                                      mentionedInfo:fullScreenEditView.editInputBarControl.mentionedInfo
                                       messageModel:model];
                [self edit_exitEditModeWithActivateNormal:YES];
            }];
        }
    }];
    
}

- (void)edit_exitFullScreenEditView:(void(^)(void))completion {
    [self.fullScreenEditView hideWithAnimation:YES completion:^{
        if (completion) {
            completion();
        }
        self.fullScreenEditView = nil;
    }];
}

- (void)edit_didTapEditRetryButton:(RCMessageModel *)model {
    if (!model) {
        return;
    }
    if (!model.modifyInfo || !model.modifyInfo.content) {
        return;
    }
    [self edit_modifyMessage:model newContent:model.modifyInfo.content isRetry:YES];
}

- (void)edit_setupFullScreenEditView {
    if (!self.fullScreenEditView) {
        self.fullScreenEditView = [[RCFullScreenEditView alloc] initWithFrame:self.view.bounds];
        self.fullScreenEditView.conversationType = self.conversationType;
        self.fullScreenEditView.targetId = self.targetId;
        self.fullScreenEditView.delegate = self;
        self.fullScreenEditView.isMentionedEnabled = self.dataSource.isMentionedEnabled;
    }
}

- (UIWindow *)edit_keyWindow {
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
            }
        }
    }
    return [UIApplication sharedApplication].keyWindow;
}

@end
