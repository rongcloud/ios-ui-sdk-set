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
#import "RCMessageEditUtil.h"

static CGFloat RC_KIT_UNREAD_BOTTOM_ICON_WIDTH = 35;
static CGFloat RC_KIT_UNREAD_BOTTOM_ICON_HEIGHT = 35;

@interface RCConversationViewController ()

@property (nonatomic, strong) RCConversationDataSource *dataSource;
@property (nonatomic, assign) BOOL isConversationAppear;
@property (nonatomic, strong) RCConversationVCUtil *util;
@property (nonatomic, strong) RCMessageModel *currentSelectedModel;
// 正在编辑中的配置
@property (nonatomic, strong) RCEditInputBarConfig *editingInputBarConfig;
// 输入框底部最后的状态，主要用来在界面恢复显示时，处理底部键盘的弹出
@property (nonatomic, assign) KBottomBarStatus latestInputBottomBarStatus;

- (void)removeReferencingView;

- (BOOL)isRemainMessageExisted;

- (float)getSafeAreaExtraBottomHeight;

- (void)loadRemainMessageAndScrollToBottom:(BOOL)animated;

- (RCUserInfo *)getSelectingUserInfo:(NSString *)userId;

- (void)getSelectingUserIdList:(void (^)(NSArray<NSString *> *userIdList))completion
                   functionTag:(NSInteger)functionTag;

- (void)insertReeditText:(RCMessageModel *)model;

- (void)onReferenceMessageCellAndEditing:(BOOL)editing;

@end

@implementation RCConversationViewController (Edit)

- (void)edit_viewWillAppear:(BOOL)animated {
    if ([self edit_isMessageEditing]) {
        if (!self.fullScreenEditView) {
            self.editInputBarControl.isVisible = YES;
        }
        return;
    }
}

- (void)edit_viewDidAppear:(BOOL)animated {
    if ([self edit_isMessageEditing]
        && !self.fullScreenEditView
        && self.latestInputBottomBarStatus == KBottomBarKeyboardStatus) {
        [self.editInputBarControl restoreFocus];
    }
}

- (void)edit_viewWillDisappear:(BOOL)animated {
    if (![self edit_isMessageEditing]) {
        return;
    }
    if (self.fullScreenEditView) {
        return;
    }
    self.latestInputBottomBarStatus = self.editInputBarControl.currentBottomBarStatus;
    self.editInputBarControl.isVisible = NO;
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

- (void)edit_hideEditBottomPanels {
    [self.editInputBarControl hideBottomPanelsWithAnimation:YES completion:nil];
}

- (BOOL)edit_markEditIsExpired:(RCEditInputBarControl *)inputBar {
    if (!self.editingInputBarConfig
        || ![RCMessageEditUtil isEditTimeValid:self.editingInputBarConfig.sentTime]) {

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
    [self edit_exitEditModeAndRestoreNormalWithAnimation:NO activateNormal:NO completion:^{
        // 插入撤回消息重新编辑的文本
        [self insertReeditText:model];
    }];
    return [self edit_isMessageEditing];
}

- (BOOL)edit_onReferenceMessageCell:(id)sender {
    [self edit_exitEditModeAndRestoreNormalWithAnimation:NO activateNormal:NO completion:^{
        // 进入普通输入引用消息模式
        [self onReferenceMessageCellAndEditing:YES];
    }];
    return [self edit_isMessageEditing];
}

// 处理编辑消息的响应
- (void)edit_onEditMessage:(id)sender {
    // 同一条消息，长按再次编辑直接忽略
    if ([self.editingInputBarConfig.messageUId isEqualToString:self.currentSelectedModel.messageUId]) {
        return;
    }
    
    if (self.editingInputBarConfig) {
        [RCAlertView showAlertController:RCLocalizedString(@"Tip") message:RCLocalizedString(@"MessageEditingAlert") actionTitles:nil cancelTitle:RCLocalizedString(@"Cancel") confirmTitle:RCLocalizedString(@"Confirm") preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:^{
            self.editingInputBarConfig = nil;
            [self edit_enterEditWithModel:self.currentSelectedModel];
        } inViewController:self];
        return;
    }
    
    // 保存草稿
    [self.util saveDraftIfNeed];
    
    // 进入编辑模式
    [self edit_enterEditWithModel:self.currentSelectedModel];
}

- (void)edit_syncGetReferenceMessageContent:(RCMessageModel *)model
                                 completion:(void(^)(NSString *referMsgUserName, NSString *referContent))completion {
    
    void (^safeCompletion)(NSString *, NSString *) = ^(NSString *referMsgUserName, NSString *referContent){
        if (completion) {
            completion(referMsgUserName, referContent);
        }
    };
    
    if (!model || ![model.content isKindOfClass:[RCReferenceMessage class]]) {
        safeCompletion(nil, nil);
        return;
    }
    
    NSString *referMsgUserName;
    NSString *referContent;
    
    RCReferenceMessage *referenceMessage = (RCReferenceMessage *)model.content;
    
    if (referenceMessage.referMsgUserId) {
        RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:referenceMessage.referMsgUserId];
        referMsgUserName = userInfo.name ?: @"";
    }
    if (referenceMessage.referMsgStatus == RCReferenceMessageStatusRecalled) {
        referContent = RCLocalizedString(@"ReferencedMessageRecalled");
    } else if (referenceMessage.referMsgStatus == RCReferenceMessageStatusDeleted) {
        referContent = RCLocalizedString(@"ReferencedMessageDeleted");
    } else if (referenceMessage.referMsg) {
        if ([referenceMessage.referMsg isKindOfClass:[RCTextMessage class]]) {
            RCTextMessage *refTextMsg = (RCTextMessage *)referenceMessage.referMsg;
            referContent = refTextMsg.content ?: @"";
        } else {
            NSString *content = [RCKitUtility formatMessage:referenceMessage.referMsg
                                                   targetId:model.targetId
                                           conversationType:model.conversationType
                                               isAllMessage:YES];
            referContent = content ?: @"";
        }
    }
    safeCompletion(referMsgUserName, referContent);
}

- (void)edit_enterEditWithModel:(RCMessageModel *)model {
    // 获取原始消息内容
    NSString *originalText = @"";
    
    __block NSString *referencedSenderName = nil;
    __block NSString *referencedContent = nil;
    RCReferenceMessageStatus referencedMsgStatus = RCReferenceMessageStatusDefault;
    
    if ([model.content isKindOfClass:[RCTextMessage class]]) {
        RCTextMessage *textMessage = (RCTextMessage *)model.content;
        originalText = textMessage.content ?: @"";
    } else if ([model.content isKindOfClass:[RCReferenceMessage class]]) {
        RCReferenceMessage *referenceMessage = (RCReferenceMessage *)model.content;
        originalText = referenceMessage.content ?: @"";
        [self edit_syncGetReferenceMessageContent:model completion:^(NSString *referMsgUserName, NSString *referContent) {
            referencedSenderName = referMsgUserName;
            referencedContent = referContent;
        }];
        referencedMsgStatus = referenceMessage.referMsgStatus;
    }
    
    RCEditInputBarConfig *config = [[RCEditInputBarConfig alloc] init];
    config.messageUId = model.messageUId;
    config.sentTime = model.sentTime;
    config.textContent = originalText;
    config.referencedSenderName = referencedSenderName;
    config.referencedContent = referencedContent;
    config.referencedMsgStatus = referencedMsgStatus;
    config.mentionedRangeInfo = [self edit_toMentionedRangeInfo:model.content.mentionedInfo inText:originalText];
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
    
    if (!self.chatSessionInputBarControl.hidden) {
        if (self.chatSessionInputBarControl.currentBottomBarStatus != KBottomBarDefaultStatus) {
            [self.chatSessionInputBarControl updateStatus:KBottomBarDefaultStatus animated:NO];
        }
        self.chatSessionInputBarControl.hidden = YES;
    }
    if (self.referencingView) {
        [self removeReferencingView];
    }
    [self.editInputBarControl showWithConfig:config];
    [self edit_markEditIsExpired:self.editInputBarControl];
    if (becomeFirstResponder) {
        [self.editInputBarControl restoreFocus];
    }
}

- (void)edit_checkConfirmData:(RCEditInputBarControl *)editInputBarControl
                         text:(NSString *)text
                   completion:(void (^)(RCMessageModel * _Nullable message))completion {
    
    void (^safeCompletion)(RCMessageModel * _Nullable model) = ^(RCMessageModel * _Nullable model){
        if (completion) {
            [self performOnMainThread:^{
                completion(model);
            }];
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
    if (text.length == 0 || !messageModel) {
        return;
    }
    // 先更新消息为编辑中的状态
    RCMessageModifyInfo *modifyInfo = [[RCMessageModifyInfo alloc] init];
    modifyInfo.status = RCMessageModifyStatusUpdating;
    messageModel.modifyInfo = modifyInfo;
    [self.dataSource edit_refreshUIMessagesEditedStatus:@[messageModel]];
    
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
    RCModifyMessageParams *modifyParams = [[RCModifyMessageParams alloc] init];
    modifyParams.messageUId = model.messageUId;
    modifyParams.messageContent = newContent;
    
    void (^completeBlock)(RCMessage *, RCErrorCode) = ^(RCMessage * _Nonnull editedMessage, RCErrorCode code){
        [self edit_showEditErrorAlert:code isRetry:isRetry];
        
        if (!editedMessage) {
            if (model.modifyInfo) {
                model.modifyInfo.status = RCMessageModifyStatusSuccess;
            }
            if (model) {
                [self.dataSource edit_refreshUIMessagesEditedStatus:@[model]];
            }
            return;
        }
        RCMessageModel *editedModel = [RCMessageModel modelWithMessage:editedMessage];
        if (editedModel) {
            [self.dataSource edit_refreshUIMessagesEditedStatus:@[editedModel]];
        }
    };
    
    [[RCCoreClient sharedCoreClient] modifyMessageWithParams:modifyParams completionHandler:^(RCMessage * _Nonnull message, RCErrorCode code) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            completeBlock(message, code);
        });
    }];
}

- (void)edit_showAlert:(NSString *)alertMessage {
    [RCAlertView showAlertController:RCLocalizedString(@"Tip") message:alertMessage actionTitles:nil cancelTitle:nil confirmTitle:RCLocalizedString(@"Confirm") preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:^{
        
    } inViewController:self];
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
        [self.editInputBarControl addMentionedUser:userInfo symbolRequest:YES];
        [self.editInputBarControl restoreFocus];
        return YES;
    }
    return NO;
}

- (NSArray <RCMentionedStringRangeInfo *> *)edit_toMentionedRangeInfo:(RCMentionedInfo *)mentionedInfo
                                                               inText:(NSString *)text {
    if (!mentionedInfo || mentionedInfo.userIdList.count == 0) {
        return nil;
    }
    if (!text || text.length == 0) {
        return nil;
    }
    
    NSMutableArray<RCMentionedStringRangeInfo *> *rangeInfoList = [NSMutableArray array];
    
    // 预处理：获取所有用户信息
    NSMutableDictionary *userDisplayNames = [NSMutableDictionary dictionary];
    for (NSString *userId in mentionedInfo.userIdList) {
        RCUserInfo *userInfo = [self getSelectingUserInfo:userId];
        if (userInfo) {
            userDisplayNames[userId] = userInfo.name ?: userId;
        }
    }
    
    // 扫描文本找到所有 @ 匹配位置
    NSRange searchRange = NSMakeRange(0, text.length);
    
    while (searchRange.location < text.length) {
        NSRange atRange = [text rangeOfString:@"@" options:0 range:searchRange];
        if (atRange.location == NSNotFound) {
            break; // 没有更多 @ 符号
        }
        // 检查这个 @ 位置是否匹配任何用户名
        for (NSString *userId in mentionedInfo.userIdList) {
            NSString *displayName = userDisplayNames[userId];
            if (!displayName) continue;
            
            NSString *pattern = [NSString stringWithFormat:@"@%@ ", displayName];
            if ([self text:text hasPrefix:pattern atIndex:atRange.location]) {
                NSRange matchRange = NSMakeRange(atRange.location, pattern.length);
                // 检查这个位置是否已经被记录（避免重复）
                if (![self isRangeAlreadyInMatches:matchRange matches:rangeInfoList]) {
                    // 直接创建并添加 RCMentionedStringRangeInfo 对象
                    RCMentionedStringRangeInfo *rangeInfo = [[RCMentionedStringRangeInfo alloc] init];
                    rangeInfo.range = matchRange;
                    rangeInfo.userId = userId;
                    rangeInfo.content = pattern;
                    [rangeInfoList addObject:rangeInfo];
                    break; // 找到匹配就跳出内层循环
                }
            }
        }
        // 移动到下一个字符位置继续搜索
        searchRange.location = atRange.location + 1;
        searchRange.length = text.length - searchRange.location;
    }
    return [rangeInfoList copy];
}

#pragma mark - 引用消息处理

- (void)edit_refreshReferenceViewContentIfNeeded:(NSArray<RCMessageModel *> *)messageModels
                                          status:(RCReferenceMessageStatus)status {
    if (messageModels.count == 0) {
        return;
    }
    [self edit_refreshNormalInputReferenceViewIfNeeded:messageModels];
    [self edit_refreshEditInputReferenceViewIfNeeded:messageModels status:status];
}

// 处理正常输入框上方的引用消息显示
- (void)edit_refreshNormalInputReferenceViewIfNeeded:(NSArray<RCMessageModel *> *)messageModels {
    NSMutableDictionary<NSString *, RCMessageModel *> *messageModelDict = [NSMutableDictionary dictionary];
    for (RCMessageModel *model in messageModels) {
        if (model.messageUId.length > 0) {
            messageModelDict[model.messageUId] = model;
        }
    }
    if (messageModelDict.count == 0 || !self.referencingView || !self.referencingView.referModel) {
        return;
    }
    NSString *referencedMessageUId = self.referencingView.referModel.messageUId;
    if (referencedMessageUId.length == 0) {
        return;
    }
    if (![messageModelDict.allKeys containsObject:referencedMessageUId]) {
        return;
    }
    RCMessageModel *model = messageModelDict[referencedMessageUId];
    if (!model) {
        return;
    }
    if (!self.currentSelectedModel) {
        self.currentSelectedModel = model;
    }
    [self performOnMainThread: ^{
        self.referencingView.referModel = model;
        self.referencingView.textLabel.text = [RCKitUtility formatMessage:model.content
                                                                 targetId:model.targetId
                                                         conversationType:model.conversationType
                                                             isAllMessage:YES];
    }];
}

// 处理编辑输入框上方的引用消息显示
- (void)edit_refreshEditInputReferenceViewIfNeeded:(NSArray<RCMessageModel *> *)messageModels
                                            status:(RCReferenceMessageStatus)status {
    if (![self edit_isMessageEditing]) {
        return;
    }
    NSMutableDictionary<NSString *, RCMessageModel *> *messageModelDict = [NSMutableDictionary dictionary];
    for (RCMessageModel *model in messageModels) {
        if (model.messageUId.length > 0) {
            messageModelDict[model.messageUId] = model;
        }
    }
    if (messageModelDict.count == 0) {
        return;
    }
    [[RCCoreClient sharedCoreClient] getMessageByUId:self.editingInputBarConfig.messageUId completion:^(RCMessage * _Nullable editingMessage) {
        if (![editingMessage.content isKindOfClass:[RCReferenceMessage class]]) {
            return;
        }
        RCReferenceMessage *refMessageContent = (RCReferenceMessage *)editingMessage.content;
        
        // 被引用消息的 model
        RCMessageModel *referMessageModel = messageModelDict[refMessageContent.referMsgUid];
        if (!referMessageModel) {
            return;
        }
        
        RCEditInputBarControl *editInputBarControl = [self edit_currentActiveEditInputBarControl];
        if (editInputBarControl) {
            // 只有状态为有修改时，才需要更新 content。删除和撤回时，引用消息会显示为已删除或已撤回。
            if (status == RCReferenceMessageStatusModified) {
                refMessageContent.referMsg = referMessageModel.content;
            }
            refMessageContent.referMsgStatus = status;
            
            RCMessageModel *messageModel = [RCMessageModel modelWithMessage:editingMessage];
            [self edit_syncGetReferenceMessageContent:messageModel completion:^(NSString *referMsgUserName, NSString *referContent) {
                self.editingInputBarConfig.referencedSenderName = referMsgUserName;
                self.editingInputBarConfig.referencedContent = referContent;
                
                [self performOnMainThread:^{
                    [editInputBarControl setReferenceInfo:referMsgUserName content:referContent];
                }];
            }];
            if ([messageModel.content isKindOfClass:[RCReferenceMessage class]]) {
                self.editingInputBarConfig.referencedMsgStatus = ((RCReferenceMessage *)messageModel.content).referMsgStatus;
            }
        }
    }];
}

#pragma mark - 编辑状态保存和恢复

- (void)edit_showEditingMessage:(RCEditedMessageDraft *)draft {
    if (!RCKitConfigCenter.message.enableEditMessage) {
        return;
    }
    if (!draft || draft.content.length == 0) {
        return;
    }
    // 如果当前已经在编辑模式，不要重复加载
    if ([self edit_isMessageEditing]) {
        return;
    }
    RCEditInputBarConfig *editConfig = [[RCEditInputBarConfig alloc] initWithData:draft.content];
    
    void (^showBlock)(RCEditInputBarConfig *) = ^(RCEditInputBarConfig *config){
        [self performOnMainThread:^{
            [self edit_showEditBarWithConfig:editConfig becomeFirstResponder:NO];
            // 强制设置 KBottomBarKeyboardStatus， 进入页面加载缓存后需要在 viewDidAppear 时弹出键盘
            self.latestInputBottomBarStatus = KBottomBarKeyboardStatus;
        }];
    };
    
    // 刷新引用消息的被引用内容
    if (editConfig.messageUId.length > 0
        && editConfig.referencedContent.length > 0
        && editConfig.referencedMsgStatus != RCReferenceMessageStatusDeleted
        && editConfig.referencedMsgStatus != RCReferenceMessageStatusRecalled) {
        
        RCRefreshReferenceMessageParams *params = [[RCRefreshReferenceMessageParams alloc] init];
        RCConversationIdentifier *identifier = [[RCConversationIdentifier alloc] init];
        identifier.type = self.conversationType;
        identifier.targetId = self.targetId;
        identifier.channelId = self.channelId;
        params.conversationIdentifier = identifier;
        params.messageUIds = @[editConfig.messageUId];
        
        void (^resultsBlock)(NSArray<RCMessageResult *> *)  = ^(NSArray<RCMessageResult *> *results){
            if (results.count == 1) {
                RCMessage *message = results[0].message;
                if (message) {
                    RCMessageModel *model = [[RCMessageModel alloc] initWithMessage:message];
                    [self edit_syncGetReferenceMessageContent:model completion:^(NSString *referMsgUserName, NSString *referContent) {
                        editConfig.referencedSenderName = referMsgUserName;
                        editConfig.referencedContent = referContent;
                    }];
                    
                    if ([message.content isKindOfClass:[RCReferenceMessage class]]) {
                        editConfig.referencedMsgStatus = ((RCReferenceMessage *)message.content).referMsgStatus;
                    }
                    showBlock(editConfig);
                }
            }
        };
        
        [[RCCoreClient sharedCoreClient] refreshReferenceMessageWithParams:params
                                                         localMessageBlock:resultsBlock
                                                        remoteMessageBlock:resultsBlock
                                                                errorBlock:^(RCErrorCode code) {
            showBlock(editConfig);
        }];
    } else {
        showBlock(editConfig);
    }
}

- (void)edit_saveCurrentEditStateIfNeeded {
    if (![self edit_isMessageEditing]) {
        return;
    }
    
    RCEditInputBarControl *editInputBar = [self edit_currentActiveEditInputBarControl];
    if (![editInputBar hasContent]) {
        return;
    }
    RCEditedMessageDraft *draft = [[RCEditedMessageDraft alloc] init];
    draft.messageUId = editInputBar.inputBarConfig.messageUId;
    draft.content = [editInputBar.inputBarConfig encode];
    
    RCConversationIdentifier *identifier = [[RCConversationIdentifier alloc] init];
    identifier.type = self.conversationType;
    identifier.targetId = self.targetId;
    identifier.channelId = self.channelId;
    
    [[RCCoreClient sharedCoreClient] saveEditedMessageDraft:draft identifier:identifier completion:^(RCErrorCode code) {
        
    }];
}

- (void)edit_clearSavedEditState {
    RCConversationIdentifier *identifier = [[RCConversationIdentifier alloc] init];
    identifier.type = self.conversationType;
    identifier.targetId = self.targetId;
    identifier.channelId = self.channelId;
    [[RCCoreClient sharedCoreClient] clearEditedMessageDraft:identifier completion:^(RCErrorCode code) {
        
    }];
}

/// 退出编辑并还原普通输入框
- (void)edit_exitEditModeAndRestoreNormalWithAnimation:(BOOL)animated
                                        activateNormal:(BOOL)activate
                                            completion:(void (^ _Nullable)())completion {
    if (![self edit_isMessageEditing]) {
        return;
    }
    [self performOnMainThread:^{
         [self edit_exitEditModeWithAnimation:animated completion:^{
             [self edit_restoreNormalInputWithActivate:activate completion:completion];
        }];
    }];
}

/// 退出编辑模式
- (void)edit_exitEditModeWithAnimation:(BOOL)animated completion:(void (^ _Nullable)())completion {
    [self.editInputBarControl exitWithAnimation:animated completion:^{
        self.editingInputBarConfig = nil;
        [self.editInputBarControl resetEditInputBar];
        [self edit_clearSavedEditState];
        if (completion) {
            completion();
        }
    }];
}

/// 恢复普通输入框
- (void)edit_restoreNormalInputWithActivate:(BOOL)activate completion:(void (^ _Nullable)())completion {
    self.chatSessionInputBarControl.hidden = NO;
    // 恢复草稿, 主要为了恢复草稿中保存的引用消息
    [[RCChannelClient sharedChannelManager] getConversation:self.conversationType
                                                   targetId:self.targetId
                                                  channelId:self.channelId
                                                 completion:^(RCConversation * _Nullable conversation) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.chatSessionInputBarControl.draft = conversation.draft;
            if (activate) {
                [self.chatSessionInputBarControl.inputTextView becomeFirstResponder];
            }
            if (completion) {
                completion();
            }
        });
    }];
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
                [self edit_exitEditModeAndRestoreNormalWithAnimation:YES activateNormal:YES completion:nil];
            }
        }];
    }
}

- (void)edit_editInputBarControlDidCancel:(RCEditInputBarControl *)editInputBarControl {
    [self edit_exitEditModeAndRestoreNormalWithAnimation:YES activateNormal:YES completion:nil];
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
    
    CGFloat width = RC_KIT_UNREAD_BOTTOM_ICON_WIDTH;
    CGFloat height = RC_KIT_UNREAD_BOTTOM_ICON_HEIGHT;
    CGFloat rightOrLeftPadding = 5.5;
    CGFloat bottom = 12;
    CGFloat editInputBarControlY = editInputBarControl.frame.origin.y;
    CGFloat x = self.view.frame.size.width - rightOrLeftPadding - width;
    CGFloat y = editInputBarControlY - bottom - height;
    
    if ([RCKitUtility isRTL]) {
        x = rightOrLeftPadding;
    }
    [self.unreadRightBottomIcon setFrame:CGRectMake(x, y, width, height)];
    
    if (self.locatedMessageSentTime == 0) {
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
    // 获取当前光标位置
    NSRange currentCursorPosition = [editInputBarControl getCurrentCursorPosition];
    
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
        
        [self.fullScreenEditView showWithConfig:editInputBarControl.inputBarConfig animation:YES];
        
        // 恢复光标位置到全屏编辑器
        if (currentCursorPosition.location != NSNotFound) {
            [self.fullScreenEditView.editInputBarControl setCursorPosition:currentCursorPosition];
        }
        
        [self edit_markEditIsExpired:self.fullScreenEditView.editInputBarControl];
    }];
}

#pragma mark - 全屏编辑

- (void)edit_fullScreenEditViewCollapse:(RCFullScreenEditView *)fullScreenEditView {
    // 获取全屏编辑器的光标位置
    NSRange currentCursorPosition = [fullScreenEditView.editInputBarControl getCurrentCursorPosition];
    
    // 获取状态数据
    RCEditInputBarConfig *config = fullScreenEditView.editInputBarControl.inputBarConfig;
    
    // 恢复到普通编辑模式
    [self edit_showEditBarWithConfig:config becomeFirstResponder:NO];
    
    [self edit_exitFullScreenEditView:^{
        // 恢复光标位置到普通编辑器
        if (currentCursorPosition.location != NSNotFound) {
            [self.editInputBarControl setCursorPosition:currentCursorPosition];
        }
        
        // 延迟恢复焦点，确保状态已经完全恢复
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.editInputBarControl restoreFocus];
        });
    }];
}

- (void)edit_fullScreenEditViewCancel:(RCFullScreenEditView *)fullScreenEditView {
    [self edit_exitFullScreenEditView:^{
        // 退出普通编辑模式
        [self edit_exitEditModeAndRestoreNormalWithAnimation:YES activateNormal:YES completion:nil];
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
                [self edit_exitEditModeAndRestoreNormalWithAnimation:YES activateNormal:YES completion:nil];
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

// 线程安全执行 block
- (void)performOnMainThread:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

/// 检查文本在指定位置是否以某个字符串开头
/// @param text 源文本
/// @param prefix 要检查的前缀字符串
/// @param index 检查的起始位置
/// @return YES 表示匹配，NO 表示不匹配
- (BOOL)text:(NSString *)text hasPrefix:(NSString *)prefix atIndex:(NSInteger)index {
    if (!text || !prefix || index < 0 || index >= text.length) {
        return NO;
    }
    
    NSInteger remainingLength = text.length - index;
    if (remainingLength < prefix.length) {
        return NO; // 剩余长度不足
    }
    
    NSRange checkRange = NSMakeRange(index, prefix.length);
    NSString *substring = [text substringWithRange:checkRange];
    return [substring isEqualToString:prefix];
}

/// 检查指定范围是否已经在匹配列表中
/// @param range 要检查的范围
/// @param matches 匹配列表
/// @return YES 表示已存在，NO 表示不存在
- (BOOL)isRangeAlreadyInMatches:(NSRange)range matches:(NSArray<RCMentionedStringRangeInfo *> *)matches {
    for (RCMentionedStringRangeInfo *match in matches) {
        if (NSEqualRanges(range, match.range)) {
            return YES;
        }
    }
    return NO;
}

@end
