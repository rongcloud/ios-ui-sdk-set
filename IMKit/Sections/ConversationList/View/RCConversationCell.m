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
@interface RCConversationCell ()

@property (nonatomic, strong) RCConversationHeaderView *headerView;

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
        [RCKitUtility generateDynamicColor:HEXCOLOR(0xf5f5f5)
                                 darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.8]];

    [self.contentView addSubview:self.headerView];
    [self.contentView addSubview:self.conversationTitle];
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
        NSDictionaryOfVariableBindings(_headerView, _conversationTitle, _messageCreatedTimeLabel, _detailContentView,
                                       _statusView, _conversationTagView);
    [self.contentView
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"H:|-12-[_headerView(width)]-12-"
                                                       @"[_conversationTitle]-5-[_conversationTagView(50)]-5-"
                                                       @"[_messageCreatedTimeLabel(>=80)]-12-|"
                                               options:0
                                               metrics:@{
                                                   @"width" : @(RCKitConfigCenter.ui.globalConversationPortraitSize.width)
                                               }
                                                 views:cellSubViews]];
    [self.contentView
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:[_headerView(height)]"
                                               options:0
                                               metrics:@{
                                                   @"height" :
                                                       @(RCKitConfigCenter.ui.globalConversationPortraitSize.height)
                                               }
                                                 views:cellSubViews]];
    
    [self.contentView
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:[_conversationTitle(21)]"
                                               options:0
                                               metrics:nil
                                                 views:cellSubViews]];

    [self.contentView
        addConstraints:[NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:[_conversationTagView(21)]"
                                               options:0
                                               metrics:nil
                                                 views:cellSubViews]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-16-[_messageCreatedTimeLabel]"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:cellSubViews]];
    [self.contentView
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
                                               @"H:[_headerView]-12-[_detailContentView]-(>=0)-[_statusView(55)]-5-|"
                                                               options:0
                                                               metrics:nil
                                                                 views:cellSubViews]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.statusView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.detailContentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1
                                                                  constant:0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.conversationTagView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.conversationTitle
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1
                                                                  constant:0]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.headerView
                                                                 attribute:NSLayoutAttributeBottom
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.detailContentView
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1
                                                                  constant:0]];

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.conversationTitle
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.messageCreatedTimeLabel
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1
                                                                  constant:0]];

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

    if (self.model.isTop) {
        self.backgroundColor = self.topCellBackgroundColor;
    } else {
        self.backgroundColor = self.cellBackgroundColor;
    }

    if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL) {
        if (model.conversationType == ConversationType_PRIVATE ||
            model.conversationType == ConversationType_CUSTOMERSERVICE ||
            model.conversationType == ConversationType_SYSTEM || model.conversationType == ConversationType_Encrypted) {
            NSString *targetId = model.targetId;
            if (model.conversationType == ConversationType_Encrypted) {
                targetId = [[model.targetId componentsSeparatedByString:@";;;"] lastObject];
            }
            RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:targetId];
            if (userInfo) {
                if (model.conversationType != ConversationType_Encrypted) {
                    self.headerView.headerImageView.imageURL = [NSURL URLWithString:userInfo.portraitUri];
                }
                [self updateConversationTitle:[RCKitUtility getDisplayName:userInfo]];
            }
            [self.detailContentView updateContent:model prefixName:nil];
        } else if (model.conversationType == ConversationType_GROUP) {
            RCGroup *groupInfo = [[RCUserInfoCacheManager sharedManager] getGroupInfo:model.targetId];
            if (groupInfo) {
                self.headerView.headerImageView.imageURL = [NSURL URLWithString:groupInfo.portraitUri];
                [self updateConversationTitle:groupInfo.groupName];
            }

            if (self.hideSenderName) {
                [self.detailContentView updateContent:model prefixName:nil];
            } else {
                RCUserInfo *memberInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId inGroupId:model.targetId];
                RCUserInfo *userInfo = [[RCUserInfoCache sharedCache] getUserInfo:model.senderUserId];
                NSString *displayName = userInfo.name;
                if (userInfo.alias.length > 0) {
                    displayName = userInfo.alias;
                } else if (memberInfo.name.length > 0) {
                    displayName = memberInfo.name;
                }
                [self.detailContentView updateContent:model prefixName:displayName];
            }
        } else if (model.conversationType == ConversationType_DISCUSSION) {
            [self updateConversationTitle:RCLocalizedString(@"DISCUSSION")];
            __weak __typeof(self) ws = self;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [[RCDiscussionClient sharedDiscussionClient] getDiscussion:model.targetId
                                                 success:^(RCDiscussion *discussion) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         if ([model isEqual:ws.model] && discussion) {
                                                             [ws updateConversationTitle:discussion.discussionName];
                                                         }
                                                     });
                                                 }
                                                   error:nil];
            
#pragma clang diagnostic pop
            if (self.hideSenderName) {
                [self.detailContentView updateContent:model prefixName:nil];
            } else {
                RCUserInfo *userInfo =
                    [[RCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId inGroupId:model.targetId];
                [self.detailContentView updateContent:model prefixName:[RCKitUtility getDisplayName:userInfo]];
            }
        } else {
            [self.detailContentView updateContent:model prefixName:nil];
            [self updateConversationTitle:[NSString stringWithFormat:@"name<%@>", model.targetId]];
        }
    } else if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
        // 聚合类型优先使用全局配置，再次使用默认标题
        NSString *conversationCollectionTitle = @"";
        NSDictionary<NSNumber *, NSString *> *glConversationCollectionTitleDic = RCKitConfigCenter.ui.globalConversationCollectionTitleDic;
        NSString *collectionTitle = glConversationCollectionTitleDic[@(model.conversationType)];
        if (collectionTitle && [collectionTitle isKindOfClass:[NSString class]]) {
            conversationCollectionTitle = collectionTitle;
        }else {
            conversationCollectionTitle = [RCKitUtility defaultTitleForCollectionConversation:model.conversationType];
        }
        [self updateConversationTitle:conversationCollectionTitle];

        //聚合会话优先查看是否有全局配置，再使用默认头像
        NSDictionary<NSNumber *, NSString *> *glCollectionAvatarDic = RCKitConfigCenter.ui.globalConversationCollectionAvatarDic;
        NSString *dicAvatarUrl = glCollectionAvatarDic[@(model.conversationType)];
        if (dicAvatarUrl && [dicAvatarUrl isKindOfClass:[NSString class]]) {
            self.headerView.headerImageView.imageURL = [NSURL URLWithString:dicAvatarUrl];
        }
        
        if (model.conversationType == ConversationType_PRIVATE ||
            model.conversationType == ConversationType_CUSTOMERSERVICE ||
            model.conversationType == ConversationType_SYSTEM) {
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
                              if ([model isEqual:ws.model] && discussion) {
                                  [ws.detailContentView updateContent:model prefixName:discussion.discussionName];
                              }
                          });
                      }
                        error:nil];
#pragma clang diagnostic pop
        }
    } else if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE) {
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

    [self.headerView updateBubbleUnreadNumber:(int)model.unreadMessageCount];

    self.messageCreatedTimeLabel.text = [RCKitUtility convertConversationTime:model.sentTime / 1000];

    [self.statusView updateNotificationStatus:model];
    [self.statusView updateReadStatus:model];
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
}

- (void)updateConversationTitle:(NSString *)text {
    self.model.conversationTitle = text;
    self.conversationTitle.text = self.model.conversationTitle;
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
    BOOL updateSenderName = (hideSenderName != _hideSenderName);
    _hideSenderName = hideSenderName;

    if (updateSenderName) {
        if (_hideSenderName) {
            [self.detailContentView updateContent:self.model prefixName:nil];
        } else if (self.model.conversationType == ConversationType_GROUP || self.model.conversationType == ConversationType_DISCUSSION) {
            RCUserInfo *memberInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:self.model.senderUserId inGroupId:self.model.targetId];
            RCUserInfo *userInfo = [[RCUserInfoCache sharedCache] getUserInfo:self.model.senderUserId];
            NSString *displayName = userInfo.name;
            if (userInfo.alias.length > 0) {
                displayName = userInfo.alias;
            } else if (memberInfo.name.length > 0) {
                displayName = memberInfo.name;
            }
            [self.detailContentView updateContent:self.model prefixName:displayName];
        }
    }
}

#pragma mark - Notification selector
- (void)onUserInfoUpdate:(NSNotification *)notification {
    NSDictionary *userInfoDic = notification.object;
    RCUserInfo *updateUserInfo = userInfoDic[@"userInfo"];
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
                    [self.detailContentView updateContent:self.model prefixName:displayName];
                }
            }
        } else if (self.model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
            if ([updateUserId isEqualToString:self.model.targetId] &&
                (self.model.conversationType == ConversationType_PRIVATE ||
                 self.model.conversationType == ConversationType_CUSTOMERSERVICE ||
                 self.model.conversationType == ConversationType_SYSTEM)) {
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
            if (!self.hideSenderName) {
                RCUserInfo *memberInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:self.model.senderUserId inGroupId:self.model.targetId];
                RCUserInfo *userInfo = [[RCUserInfoCache sharedCache] getUserInfo:self.model.senderUserId];
                NSString *displayName = userInfo.name;
                if (userInfo.alias.length > 0) {
                    displayName = userInfo.alias;
                } else if (memberInfo.name.length > 0) {
                    displayName = memberInfo.name;
                }
                [self.detailContentView updateContent:self.model prefixName:displayName];
            }
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
            } else if (updateInfo.updateType == RCConversationCell_SentStatus_Update) {
                [self.statusView updateReadStatus:self.model];
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

- (UILabel *)conversationTitle {
    if(!_conversationTitle) {
        _conversationTitle = [[UILabel alloc] init];
        _conversationTitle.translatesAutoresizingMaskIntoConstraints = NO;
        _conversationTitle.backgroundColor = [UIColor clearColor];
        _conversationTitle.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
        _conversationTitle.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0x111f2c) darkColor:[HEXCOLOR(0xffffff) colorWithAlphaComponent:0.9]];
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
        _messageCreatedTimeLabel.textColor = RCDYCOLOR(0xC7CbCe, 0x3c3c3c);
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
