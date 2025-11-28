//
//  RCConversationCell.m
//  RongIMKit
//
//  Created by xugang on 15/1/24.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCConversationCell.h"
#import "RCConversationCellUpdateInfo.h"
#import "RCConversationHeaderView.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCUserInfoCacheManager.h"
#import "RCKitConfig.h"
#import <RongPublicService/RongPublicService.h>
#import <RongDiscussion/RongDiscussion.h>
#import "RCSemanticContext.h"
#import "RCOnlineStatusView.h"
#import "RCUserOnlineStatusUtil.h"

@interface RCConversationCell ()

@property (nonatomic, strong) RCConversationHeaderView *headerView;
//当前 cell 正在展示的用户信息，消息携带用户信息且频发发送，会导致 cell 频发刷新
//cell 复用的时候，检测如果是即将刷新的是同一个用户信息，那么就跳过刷新
//IMSDK-2705
@property (nonatomic, strong) RCUserInfo *currentDisplayedUserInfo;

// 包含在线状态图标和标题的 StackView（用于自动管理显示/隐藏时的布局）
@property (nonatomic, strong) UIStackView *titleStackView;

@end

@implementation RCConversationCell

#pragma mark - 初始化
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initCellLayout];
        [self registerObserver];
    }
    return self;
}

- (void)initCellLayout {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.frame];
    self.selectedBackgroundView.backgroundColor =
    RCDynamicColor(@"highlight_color", @"0xf5f5f5", @"0x1c1c1eCC");

    [self.contentView addSubview:self.headerView];
    [self.contentView addSubview:self.titleStackView]; // 使用 StackView 包含在线状态和标题
    [self.contentView addSubview:self.conversationTagView];
    [self.contentView addSubview:self.messageCreatedTimeLabel];
    [self.contentView addSubview:self.detailContentView];
    [self.contentView addSubview:self.statusView];
    self.statusView.conversationNotificationStatusView.hidden = YES;
    [self addSubViewConstraints];
}

- (void)registerObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUserInfoUpdate:)
                                                 name:RCKitDispatchUserInfoUpdateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onGroupUserInfoUpdate:)
                                                 name:RCKitDispatchGroupUserInfoUpdateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onGroupInfoUpdate:)
                                                 name:RCKitDispatchGroupInfoUpdateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateCellIfNeed:)
                                                 name:RCKitConversationCellUpdateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePublicServiceIfNeed:)
                                                 name:RCKitDispatchPublicServiceInfoNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUserOnlineStatusChanged:)
                                                 name:RCKitConversationCellOnlineStatusUpdateNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addSubViewConstraints {
    [self.conversationTitle setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                            forAxis:UILayoutConstraintAxisHorizontal];
    [self.conversationTitle setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    // fix: rce "部门"标签视图与时间视图重叠
    NSDictionary *cellSubViews =
        NSDictionaryOfVariableBindings(_headerView, _titleStackView, _messageCreatedTimeLabel, _detailContentView,
                                       _statusView, _conversationTagView);
    
    // 水平布局：头像 - StackView(在线状态+标题) - 标签 - 时间
    // StackView 会自动管理在线状态图标的显示/隐藏，隐藏时不占用空间
    [self.contentView
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"H:|-12-[_headerView(width)]-12-"
                                                       @"[_titleStackView]-5-[_conversationTagView(50)]-5-"
                                                       @"[_messageCreatedTimeLabel(>=80)]-12-|"
                                               options:0
                                               metrics:@{
                                                   @"width" : @(RCKitConfigCenter.ui.globalConversationPortraitSize.width)
                                               }
                                                 views:cellSubViews]];
    
    // 头像高度
    [self.contentView
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:[_headerView(height)]"
                                               options:0
                                               metrics:@{
                                                   @"height" :
                                                       @(RCKitConfigCenter.ui.globalConversationPortraitSize.height)
                                               }
                                                 views:cellSubViews]];
    
    // StackView 高度（与标题高度一致）
    [self.contentView
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:[_titleStackView(21)]"
                                               options:0
                                               metrics:nil
                                                 views:cellSubViews]];

    // 标签高度
    [self.contentView
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:[_conversationTagView(21)]"
                                               options:0
                                               metrics:nil
                                                 views:cellSubViews]];
    
    // 时间标签位置
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-16-[_messageCreatedTimeLabel]"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:cellSubViews]];
    
    // 详细内容和状态视图水平布局
    [self.contentView
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
                                               @"H:[_headerView]-12-[_detailContentView]-(>=0)-[_statusView(55)]-5-|"
                                                               options:0
                                                               metrics:nil
                                                                 views:cellSubViews]];
    
    // 状态视图垂直居中于详细内容
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.statusView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.detailContentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1
                                                                  constant:0]];
    
    // 标签垂直居中于 StackView
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.conversationTagView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.titleStackView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1
                                                                  constant:0]];
    
    // 头像底部对齐详细内容
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.headerView
                                                                 attribute:NSLayoutAttributeBottom
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.detailContentView
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1
                                                                  constant:0]];

    // StackView 顶部对齐时间
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.titleStackView
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.messageCreatedTimeLabel
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1
                                                                  constant:0]];

    // 头像垂直居中
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_headerView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1
                                                                  constant:0]];

    [self setNeedsUpdateConstraints];
}

#pragma mark - Model处理&显示
- (void)setDataModel:(RCConversationModel *)model {
    [self resetDefaultLayout:model];
    [super setDataModel:model];
    self.backgroundColor = self.model.isTop ? self.topCellBackgroundColor : self.cellBackgroundColor;

    if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL) {
        [self p_displayNormal:model];
    } else if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
        [self p_displayCollection:model];
    } else if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE) {
        [self p_displayPublicService:model];
    }

    [self.headerView updateBubbleUnreadNumber:(int)model.unreadMessageCount];
    if (model.sentTime > 0) {
        self.messageCreatedTimeLabel.text = [RCKitUtility convertConversationTime:model.sentTime / 1000];
    } else if (model.operationTime > 0) {
        self.messageCreatedTimeLabel.text = [RCKitUtility convertConversationTime:model.operationTime / 1000];
    }
    [self.statusView updateReadStatus:model];
    [self.statusView updateNotificationStatus:model];
    
    // 更新在线状态显示
    [self updateOnlineStatusDisplay];
}

- (void)p_displaySimaple:(RCConversationModel *)model {
    BOOL isEncrypted = model.conversationType == ConversationType_Encrypted;
    NSString *targetId = isEncrypted ? [[model.targetId componentsSeparatedByString:@";;;"] lastObject] : model.targetId;
   
    RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:targetId];
    if (userInfo) {
        if (!isEncrypted) {
            self.headerView.headerImageView.imageURL = [NSURL URLWithString:userInfo.portraitUri];
        }
    }
    [self updateConversationTitle:[RCKitUtility getDisplayName:userInfo]];
    [self.detailContentView updateContent:model prefixName:nil];
}

- (void)p_displayGroup:(RCConversationModel *)model {
    RCGroup *groupInfo = [[RCUserInfoCacheManager sharedManager] getGroupInfo:model.targetId];
    if (groupInfo) {
        self.headerView.headerImageView.imageURL = [NSURL URLWithString:groupInfo.portraitUri];
    }
    [self updateConversationTitle:groupInfo.groupName];

    if (self.hideSenderName) {
        [self.detailContentView updateContent:model prefixName:nil];
        return;
    }
    if ([self updateMessagePrefixNameWithSenderUser]) {
        return;
    }
    
    RCUserInfo *memberInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId inGroupId:model.targetId];
    RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId];
    NSString *displayName = userInfo.name;
    if (userInfo.alias.length > 0) {
        displayName = userInfo.alias;
    } else if (memberInfo.name.length > 0) {
        displayName = memberInfo.name;
    }
    [self.detailContentView updateContent:model prefixName:displayName];
}

- (void)p_displayDiscussion:(RCConversationModel *)model {
    [self updateConversationTitle:RCLocalizedString(@"DISCUSSION")];
    __weak __typeof(self) ws = self;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[RCDiscussionClient sharedDiscussionClient] getDiscussion:model.targetId
                                                       success:^(RCDiscussion *discussion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL isSuitable = [model isEqual:ws.model] && discussion;
            if (isSuitable) {
                [ws updateConversationTitle:discussion.discussionName];
            }
        });
    }
                                                         error:nil];
    
#pragma clang diagnostic pop
    if (self.hideSenderName) {
        [self.detailContentView updateContent:model prefixName:nil];
        return;
    }
    if ([self updateMessagePrefixNameWithSenderUser]) {
        return;
    }
    RCUserInfo *userInfo =
    [[RCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId inGroupId:model.targetId];
    [self.detailContentView updateContent:model prefixName:[RCKitUtility getDisplayName:userInfo]];
}

- (void)p_displayNormal:(RCConversationModel *)model {
    BOOL isSimpleConversation = model.conversationType == ConversationType_PRIVATE ||
    model.conversationType == ConversationType_CUSTOMERSERVICE ||
    model.conversationType == ConversationType_SYSTEM || model.conversationType == ConversationType_Encrypted;
    if (isSimpleConversation) {
        [self p_displaySimaple:model];
        return;
    } else if (model.conversationType == ConversationType_GROUP) {
        [self p_displayGroup:model];
        return;
    } else if (model.conversationType == ConversationType_DISCUSSION) {
        [self p_displayDiscussion:model];
        return;
    }
    [self.detailContentView updateContent:model prefixName:nil];
    [self updateConversationTitle:model.targetId];
}

- (void)p_displayCollection:(RCConversationModel *)model {
    // 聚合类型优先使用全局配置，再次使用默认标题
    NSString *conversationCollectionTitle = @"";
    NSDictionary<NSNumber *, NSString *> *glConversationCollectionTitleDic = RCKitConfigCenter.ui.globalConversationCollectionTitleDic;
    NSString *collectionTitle = glConversationCollectionTitleDic[@(model.conversationType)];
    BOOL showTitle = collectionTitle && [collectionTitle isKindOfClass:[NSString class]];
    conversationCollectionTitle = showTitle ? collectionTitle : [RCKitUtility defaultTitleForCollectionConversation:model.conversationType];;
    [self updateConversationTitle:conversationCollectionTitle];

    //聚合会话优先查看是否有全局配置，再使用默认头像
    NSDictionary<NSNumber *, NSString *> *glCollectionAvatarDic = RCKitConfigCenter.ui.globalConversationCollectionAvatarDic;
    NSString *dicAvatarUrl = glCollectionAvatarDic[@(model.conversationType)];
    BOOL isAvatarValid = dicAvatarUrl && [dicAvatarUrl isKindOfClass:[NSString class]];
    if (isAvatarValid) {
        self.headerView.headerImageView.imageURL = [NSURL URLWithString:dicAvatarUrl];
    }
    BOOL ret = model.conversationType == ConversationType_PRIVATE ||
    model.conversationType == ConversationType_CUSTOMERSERVICE ||
    model.conversationType == ConversationType_SYSTEM;
    if (ret) {
        RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:model.targetId];
        [self.detailContentView updateContent:model prefixName:[RCKitUtility getDisplayName:userInfo]];
    } else if (model.conversationType == ConversationType_GROUP) {
        RCGroup *group = [[RCUserInfoCacheManager sharedManager] getGroupInfo:model.targetId];
        [self.detailContentView updateContent:model prefixName:group.groupName];
    } else if (model.conversationType == ConversationType_DISCUSSION) {
        [self.detailContentView updateContent:model prefixName:nil];
        __weak __typeof(self) ws = self;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [[RCDiscussionClient sharedDiscussionClient]
            getDiscussion:model.targetId
                  success:^(RCDiscussion *discussion) {
                      dispatch_async(dispatch_get_main_queue(), ^{
                          BOOL isSuitable = [model isEqual:ws.model] && discussion;
                          if (isSuitable) {
                              [ws.detailContentView updateContent:model prefixName:discussion.discussionName];
                          }
                      });
                  }
                    error:nil];
#pragma clang diagnostic pop
    }
}

- (void)p_displayPublicService:(RCConversationModel *)model {
    RCPublicServiceProfile *serviceProfile = nil;
    //// 如果设置了代理，使用新的公众号业务
    if ([RCIM sharedRCIM].publicServiceInfoDataSource) {
        serviceProfile = [[RCUserInfoCacheManager sharedManager] getPublicServiceProfile:model.targetId];
    } else {
        serviceProfile =
            [[RCPublicServiceClient sharedPublicServiceClient] getPublicServiceProfile:(RCPublicServiceType)model.conversationType
                                                   publicServiceId:model.targetId];
    }

    if (serviceProfile) {
        self.headerView.headerImageView.imageURL = [NSURL URLWithString:serviceProfile.portraitUrl];
        [self updateConversationTitle:serviceProfile.name];
    }
    [self.detailContentView updateContent:model prefixName:@""];
}


- (void)resetDefaultLayout:(RCConversationModel *)reuseModel {
    _hideSenderName = [self hideSenderNameForDefault:reuseModel];
    self.topCellBackgroundColor = reuseModel.topCellBackgroundColor;
    self.cellBackgroundColor = reuseModel.cellBackgroundColor;

    [self.headerView resetDefaultLayout:reuseModel];
    self.conversationTitle.text = nil;
    self.messageCreatedTimeLabel.text = nil;
    [self.detailContentView resetDefaultLayout:reuseModel];
    [self.statusView resetDefaultLayout:reuseModel];
    for (UIView *view in [self.conversationTagView subviews]) {
        [view removeFromSuperview];
    }
    
    // 重置在线状态圆点（默认隐藏，StackView 会自动不给它分配空间）
    self.onlineStatusView.hidden = YES;
    self.onlineStatusView.backgroundColor = nil;
}

- (void)updateConversationTitle:(NSString *)text {
    text = (text.length > 0) ? text : self.model.targetId;
    self.model.conversationTitle = text;
    self.conversationTitle.text = self.model.conversationTitle;
}

- (void)updateOnlineStatus:(BOOL)isOnline {
    if (!self.model.displayOnlineStatus) {
        self.onlineStatusView.hidden = YES;
        return;
    }
    // 显示在线状态圆点，根据状态显示不同颜色
    self.onlineStatusView.hidden = NO;
    self.onlineStatusView.online = isOnline;
}

- (void)updateOnlineStatusDisplay {
    [self updateOnlineStatus:self.model.onlineStatus.isOnline];
}

- (BOOL)hideSenderNameForDefault:(RCConversationModel *)model {
    if ([model.objectName isEqualToString:@"RC:RcNtf"] ||
        ([RCKitUtility isUnkownMessage:model.lastestMessageId content:model.lastestMessage] &&
         RCKitConfigCenter.message.showUnkownMessage)) {
        return YES;
    } else {
        return NO;
    }
}

- (void)setHideSenderName:(BOOL)hideSenderName {
    if (hideSenderName == _hideSenderName) {
        return;
    }
    _hideSenderName = hideSenderName;

    if (_hideSenderName) {
        [self.detailContentView updateContent:self.model prefixName:nil];
    } else if (self.model.conversationType == ConversationType_GROUP || self.model.conversationType == ConversationType_DISCUSSION) {
        if ([self updateMessagePrefixNameWithSenderUser]) {
            return;
        }
        RCUserInfo *memberInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:self.model.senderUserId inGroupId:self.model.targetId];
        RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:self.model.senderUserId];
        NSString *displayName = userInfo.name;
        if (userInfo.alias.length > 0) {
            displayName = userInfo.alias;
        } else if (memberInfo.name.length > 0) {
            displayName = memberInfo.name;
        }
        [self.detailContentView updateContent:self.model prefixName:displayName];
    }
}

#pragma mark - Notification selector
- (void)onUserInfoUpdate:(NSNotification *)notification {
    NSDictionary *userInfoDic = notification.object;
    RCUserInfo *updateUserInfo = userInfoDic[@"userInfo"];
    if ([self isSameUserInfo:self.currentDisplayedUserInfo other:updateUserInfo]) {
        return;
    }
    self.currentDisplayedUserInfo = updateUserInfo;
    
    NSString *updateUserId = userInfoDic[@"userId"];
    NSString *displayName = [RCKitUtility getDisplayName:updateUserInfo];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL) {
            if ([updateUserId isEqualToString:self.model.targetId] &&
                (self.model.conversationType == ConversationType_PRIVATE ||
                 self.model.conversationType == ConversationType_CUSTOMERSERVICE ||
                 self.model.conversationType == ConversationType_SYSTEM)) {
                self.headerView.headerImageView.imageURL = [NSURL URLWithString:updateUserInfo.portraitUri];
                [self updateConversationTitle:displayName];
            } else if (self.model.conversationType == ConversationType_Encrypted) {
                NSString *originalTargetId = [self.model.targetId componentsSeparatedByString:@";;;"].lastObject;
                if ([updateUserId isEqualToString:originalTargetId]) {
                    [self updateConversationTitle:displayName];
                }
            } else if ([updateUserId isEqualToString:self.model.senderUserId] &&
                       self.model.conversationType == ConversationType_GROUP) {
                if (!self.hideSenderName ||
                    [self.model.lastestMessage isMemberOfClass:[RCRecallNotificationMessage class]]) {
                    if ([self updateMessagePrefixNameWithSenderUser]) {
                        return;
                    }
                    RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:self.model.senderUserId
                                                                                     inGroupId:self.model.targetId];
                    NSString *name = updateUserInfo.name;
                    if (updateUserInfo.alias.length > 0) {
                        name = updateUserInfo.alias;
                    } else if (userInfo.name.length > 0) {
                        name = userInfo.name;
                    }
                    [self.detailContentView updateContent:self.model prefixName:name];
                }
            } else if ([updateUserId isEqualToString:self.model.senderUserId] &&
                       self.model.conversationType == ConversationType_DISCUSSION) {
                if (!self.hideSenderName ||
                    [self.model.lastestMessage isMemberOfClass:[RCRecallNotificationMessage class]]) {
                    if ([self updateMessagePrefixNameWithSenderUser]) {
                        return;
                    }
                    [self.detailContentView updateContent:self.model prefixName:displayName];
                }
            }
        } else if (self.model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
            if (!self.hideSenderName &&
                [updateUserId isEqualToString:self.model.targetId] &&
                (self.model.conversationType == ConversationType_PRIVATE ||
                 self.model.conversationType == ConversationType_CUSTOMERSERVICE ||
                 self.model.conversationType == ConversationType_SYSTEM)) {
                if ([self updateMessagePrefixNameWithSenderUser]) {
                    return;
                }
                [self.detailContentView updateContent:self.model prefixName:displayName];
            }
        }
    });
}

- (void)onGroupUserInfoUpdate:(NSNotification *)notification {
    NSDictionary *groupUserInfoDic = (NSDictionary *)notification.object;
    NSString *groupId = groupUserInfoDic[@"inGroupId"];
    NSString *userId = groupUserInfoDic[@"userId"];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL &&
            self.model.conversationType == ConversationType_GROUP && [self.model.targetId isEqualToString:groupId] &&
            [self.model.senderUserId isEqualToString:userId]) {
            if (self.hideSenderName) {
                return;
            }
            if ([self updateMessagePrefixNameWithSenderUser]) {
                return;
            }
            RCUserInfo *memberInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:self.model.senderUserId inGroupId:self.model.targetId];
            RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:self.model.senderUserId];
            NSString *displayName = userInfo.name;
            if (userInfo.alias.length > 0) {
                displayName = userInfo.alias;
            } else if (memberInfo.name.length > 0) {
                displayName = memberInfo.name;
            }
            [self.detailContentView updateContent:self.model prefixName:displayName];
        }
    });
}

- (void)onGroupInfoUpdate:(NSNotification *)notification {
    NSDictionary *groupInfoDic = (NSDictionary *)notification.object;
    RCGroup *groupInfo = groupInfoDic[@"groupInfo"];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.model.conversationType == ConversationType_GROUP &&
            [self.model.targetId isEqualToString:groupInfo.groupId]) {
            if (self.model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL) {
                self.headerView.headerImageView.imageURL = [NSURL URLWithString:groupInfo.portraitUri];
                [self updateConversationTitle:groupInfo.groupName];
            } else if (self.model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
                [self.detailContentView updateContent:self.model prefixName:groupInfo.groupName];
            }
        }
    });
}

- (void)updateCellIfNeed:(NSNotification *)notification {
    RCConversationCellUpdateInfo *updateInfo = notification.object;

    if ([updateInfo.model isEqual:self.model]) {
        dispatch_main_async_safe(^{
            if (updateInfo.updateType == RCConversationCell_MessageContent_Update) {
                [self.detailContentView updateContent:self.model];
                [self.statusView updateReadStatus:self.model];
            } else if (updateInfo.updateType == RCConversationCell_SentStatus_Update) {
                [self.statusView updateReadStatus:self.model];
                [self.detailContentView updateContent:self.model];
            } else if (updateInfo.updateType == RCConversationCell_UnreadCount_Update) {
                [self.headerView updateBubbleUnreadNumber:(int)self.model.unreadMessageCount];
            }
        });
    }
}

- (void)updatePublicServiceIfNeed:(NSNotification *)notification {
    NSDictionary *serviceInfoDic = (NSDictionary *)notification.object;
    RCPublicServiceProfile *profile = serviceInfoDic[@"serviceInfo"];
    NSString *serviceId = serviceInfoDic[@"serviceId"];
    if ([self.model.targetId isEqualToString:serviceId]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateConversationTitle:profile.name];
            self.headerView.headerImageView.imageURL = [NSURL URLWithString:profile.portraitUrl];
        });
    }
}

- (void)onUserOnlineStatusChanged:(NSNotification *)notification {
    // 只在单聊类型会话中处理在线状态变化
    if (self.model.conversationType != ConversationType_PRIVATE) {
        return;
    }
    
    // 获取变化的用户ID列表
    NSArray<NSString *> *changedUserIds = notification.userInfo[RCKitUserOnlineStatusChangedUserIdsKey];
    
    // 检查当前会话的用户是否在变化列表中
    if ([changedUserIds containsObject:self.model.targetId]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateOnlineStatusDisplay];
        });
    }
}

#pragma mark - 回调
- (void)headerImageDidTap {
    if ([self.delegate respondsToSelector:@selector(didTapCellPortrait:)]) {
        [self.delegate didTapCellPortrait:self.model];
    }
}

- (void)headerImageDidLongPress {
    if ([self.delegate respondsToSelector:@selector(didLongPressCellPortrait:)]) {
        [self.delegate didLongPressCellPortrait:self.model];
    }
}

#pragma mark - Getter & Setter
- (RCConversationHeaderView *)headerView {
    if(!_headerView) {
        _headerView = [[RCConversationHeaderView alloc]
            initWithFrame:CGRectMake(0, 0, RCKitConfigCenter.ui.globalConversationPortraitSize.width,
                                     RCKitConfigCenter.ui.globalConversationPortraitSize.height)];
        [_headerView
            addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(headerImageDidLongPress)]];
        [_headerView
            addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerImageDidTap)]];
    }
    return _headerView;
}

- (UIStackView *)titleStackView {
    if (!_titleStackView) {
        _titleStackView = [[UIStackView alloc] init];
        _titleStackView.translatesAutoresizingMaskIntoConstraints = NO;
        _titleStackView.axis = UILayoutConstraintAxisHorizontal;
        _titleStackView.alignment = UIStackViewAlignmentCenter;
        _titleStackView.spacing = 4; // 在线状态圆点和标题之间的间距
        
        // 添加在线状态圆点和标题到 StackView
        [_titleStackView addArrangedSubview:self.onlineStatusView];
        [_titleStackView addArrangedSubview:self.conversationTitle];
    }
    return _titleStackView;
}

- (RCOnlineStatusView *)onlineStatusView {
    if (!_onlineStatusView) {
        _onlineStatusView = [[RCOnlineStatusView alloc] init];
    }
    return _onlineStatusView;
}

- (UILabel *)conversationTitle {
    if(!_conversationTitle) {
        _conversationTitle = [[UILabel alloc] init];
        _conversationTitle.translatesAutoresizingMaskIntoConstraints = NO;
        _conversationTitle.backgroundColor = [UIColor clearColor];
        _conversationTitle.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
        _conversationTitle.textColor = RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffE5");
    }
    return _conversationTitle;
}

- (UIView *)conversationTagView {
    if(!_conversationTagView) {
        _conversationTagView = [[UIView alloc] init];
        _conversationTagView.translatesAutoresizingMaskIntoConstraints = NO;
        _conversationTagView.clipsToBounds = YES;
    }
    return _conversationTagView;
}

- (UILabel *)messageCreatedTimeLabel {
    if(!_messageCreatedTimeLabel) {
        _messageCreatedTimeLabel = [[UILabel alloc] init];
        _messageCreatedTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _messageCreatedTimeLabel.backgroundColor = [UIColor clearColor];
        _messageCreatedTimeLabel.font = [[RCKitConfig defaultConfig].font fontOfGuideLevel];
        _messageCreatedTimeLabel.textColor = RCDynamicColor(@"text_secondary_color",@"0xC7CbCe", @"0x3c3c3c");
        BOOL isRTL = [RCSemanticContext isRTL];
        _messageCreatedTimeLabel.textAlignment = isRTL ? NSTextAlignmentLeft : NSTextAlignmentRight;
        _messageCreatedTimeLabel.accessibilityLabel = @"messageCreatedTimeLabel";
    }
    return _messageCreatedTimeLabel;
}

- (RCConversationDetailContentView *)detailContentView {
    if(!_detailContentView) {
        _detailContentView = [[RCConversationDetailContentView alloc] init];
    }
    return _detailContentView;
}

- (RCConversationStatusView *)statusView {
    if(!_statusView) {
        _statusView = [[RCConversationStatusView alloc] init];
    }
    return _statusView;
}
#pragma mark - private method
- (BOOL)isSameUserInfo:(RCUserInfo *)currentUserInfo other:(RCUserInfo *)other {
    if (!currentUserInfo || !other) {
        return NO;
    }
    if (currentUserInfo.userId && ![currentUserInfo.userId isEqualToString:other.userId]) {
        return NO;
    }
    if (currentUserInfo.name && ![currentUserInfo.name isEqualToString:other.name]) {
        return NO;
    }
    if (currentUserInfo.portraitUri && ![currentUserInfo.portraitUri isEqualToString:other.portraitUri]) {
        return NO;
    }
    if (currentUserInfo.alias && ![currentUserInfo.alias isEqualToString:other.alias]) {
        return NO;
    }
    return YES;
}

- (BOOL)updateMessagePrefixNameWithSenderUser {
    if (!self.hideSenderName &&
        [RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement &&
        [self.model.lastestMessage.senderUserInfo.userId isEqualToString:self.model.senderUserId]) {
        [self.detailContentView updateContent:self.model prefixName:[RCKitUtility getDisplayName:self.model.lastestMessage.senderUserInfo]];
        return YES;
    }
    return NO;
}

#pragma mark - 向后兼容
- (void)setHeaderImageViewBackgroundView:(UIView *)headerImageViewBackgroundView {
    self.headerView.backgroundView = headerImageViewBackgroundView;
}
- (UIView *)headerImageViewBackgroundView {
    return self.headerView.backgroundView;
}
- (void)setHeaderImageView:(RCloudImageView *)headerImageView {
    self.headerView.headerImageView = headerImageView;
}
- (RCloudImageView *)headerImageView {
    return self.headerView.headerImageView;
}
- (void)setBubbleTipView:(RCMessageBubbleTipView *)bubbleTipView {
    self.headerView.bubbleView = bubbleTipView;
}
- (RCMessageBubbleTipView *)bubbleTipView {
    return self.headerView.bubbleView;
}
- (void)setConversationStatusImageView:(UIImageView *)conversationStatusImageView {
    self.statusView.conversationNotificationStatusView = conversationStatusImageView;
}
- (UIImageView *)conversationStatusImageView {
    return self.statusView.conversationNotificationStatusView;
}

- (void)setMessageContentLabel:(UILabel *)messageContentLabel {
    self.detailContentView.messageContentLabel = messageContentLabel;
}
- (UILabel *)messageContentLabel {
    return self.detailContentView.messageContentLabel;
}
- (void)setEnableNotification:(BOOL)enableNotification {
    if([[NSThread currentThread] isMainThread]) {
        self.statusView.conversationNotificationStatusView.hidden = enableNotification;
    }else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.statusView.conversationNotificationStatusView.hidden = enableNotification;
        });
    }
}
- (BOOL)enableNotification {
    return self.statusView.conversationNotificationStatusView.hidden;
}
- (void)setPortraitStyle:(RCUserAvatarStyle)portraitStyle {
    [self setHeaderImagePortraitStyle:portraitStyle];
}
- (void)setHeaderImagePortraitStyle:(RCUserAvatarStyle)portraitStyle {
    _portraitStyle = portraitStyle;
    [self.headerView setHeaderImageStyle:_portraitStyle];
}
- (void)setIsShowNotificationNumber:(BOOL)isShowNotificationNumber {
    self.headerView.bubbleView.isShowNotificationNumber = isShowNotificationNumber;
}
- (BOOL)isShowNotificationNumber {
    return self.headerView.bubbleView.isShowNotificationNumber;
}
@end
