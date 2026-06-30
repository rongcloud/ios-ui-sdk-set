//
//  RCConversationStatusView.m
//  RongIMKit
//
//  Created by 岑裕 on 16/9/15.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCConversationStatusView.h"
#import "RCKitCommonDefine.h"
#import "RCIM.h"
#import "RCKitConfig.h"
#import "RCConversationModel+RRS.h"
#import "RCRRSUtil.h"

@interface RCConversationStatusView ()
@property (nonatomic, strong) RCConversationModel *backupModel;
@property (nonatomic, strong) UIStackView *stackView;
@end

@implementation RCConversationStatusView

#pragma mark - Life Cycle
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initSubviewsLayout];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubviewsLayout];
    }
    return self;
}

- (void)initSubviewsLayout {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.stackView];
    [self addSubviewConstraint];
}

- (void)updateNotificationStatus:(RCConversationModel *)model {
    self.conversationNotificationStatusView.hidden = YES;
    self.backupModel = model;
    if ([model isEqual:self.backupModel]) {
        if (model.blockStatus == DO_NOT_DISTURB) {
            self.conversationNotificationStatusView.hidden = NO;
        } else {
            self.conversationNotificationStatusView.hidden = YES;
        }
    }
    [self updatePinStatus:model];
    [self updateLayout];
}

- (void)updateReadStatus:(RCConversationModel *)model {
    if (model.draft.length == 0
        && model.editedMessageDraft.content.length == 0
        && model.lastestMessageId > 0
        && model.lastestMessageDirection == MessageDirection_SEND
        && model.sentStatus != SentStatus_SENDING
        && model.sentStatus != SentStatus_FAILED
        && ((model.conversationType == ConversationType_PRIVATE
             && [RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(model.conversationType)])
            || model.conversationType == ConversationType_Encrypted)) {
        
        RCMessage *msg = [[RCCoreClient sharedCoreClient] getMessage:model.lastestMessageId];
        if (msg && msg.messageUId && msg.messageUId.length > 0 &&
            ![msg.objectName isEqualToString:RCRecallNotificationMessageIdentifier]) {
            // 默认未读图标
            UIImage *image = RCDynamicImage(@"conversation_msg_rrs_v5_unread_gray_img",@"msg_rrs_v5_unread_gray");
            
            if ([RCRRSUtil isSupportReadReceiptV5]
                && [model rrs_shouldFetchConversationReadReceipt]) {
                if (model.readReceiptInfoV5.readCount > 0 && model.readReceiptInfoV5.unreadCount == 0) {
                    // 已读
                    image = RCDynamicImage(@"conversation_msg_rrs_v5_read_img",@"msg_rrs_v5_read");
                }
            } else if (model.sentStatus == SentStatus_READ) {
                image = RCDynamicImage(@"conversation-list_cell_msg_read_img",@"message_read_status");
            }
            self.messageReadStatusView.hidden = NO;
            self.messageReadStatusView.image = image;
            [self updateLayout];
        }
    }
}

- (void)updatePinStatus:(RCConversationModel *)model {
    self.conversationPinView.hidden = !model.isTop;
}

- (void)updateLayout {
    if (self.messageReadStatusView.hidden &&
        self.conversationNotificationStatusView.hidden &&
        self.conversationPinView.hidden) {
        return;
    }

    for (UIView *view in self.stackView.arrangedSubviews) {
        [self.stackView removeArrangedSubview:view];
    }
    
    if ([RCKitUtility isTraditionInnerThemes]) {
        if (!self.messageReadStatusView.hidden) {
            [self.stackView addArrangedSubview:self.messageReadStatusView];
        }
    }
    
    if (!self.conversationNotificationStatusView.hidden) {
        [self.stackView addArrangedSubview:self.conversationNotificationStatusView];
    }
    
    if ([RCIMKitThemeManager currentInnerThemesType] != RCIMKitInnerThemesTypeTradition) {
        if (!self.conversationPinView.hidden) {
            [self.stackView addArrangedSubview:self.conversationPinView];
        }
    }
}

- (void)resetDefaultLayout:(RCConversationModel *)reuseModel {
    self.conversationNotificationStatusView.hidden = YES;
    self.messageReadStatusView.hidden = YES;
    self.conversationPinView.hidden = YES;
}

#pragma mark - Constraint
- (void)addSubviewConstraint {
    [NSLayoutConstraint activateConstraints:@[
        [self.stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-5],
        [self.stackView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    ]];
}


#pragma mark - Getter & Setter
- (RCBaseImageView *)conversationNotificationStatusView {
    if(!_conversationNotificationStatusView) {
        _conversationNotificationStatusView = [[RCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        _conversationNotificationStatusView.backgroundColor = [UIColor clearColor];
        _conversationNotificationStatusView.image =
        RCDynamicImage(@"conversation-list_cell_block_notification_img", @"block_notification");
        _conversationNotificationStatusView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [_conversationNotificationStatusView.widthAnchor constraintEqualToConstant:16],
            [_conversationNotificationStatusView.heightAnchor constraintEqualToConstant:16]
        ]];
    }
    return _conversationNotificationStatusView;
}

- (RCBaseImageView *)messageReadStatusView {
    if (!_messageReadStatusView) {
        _messageReadStatusView = [[RCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        _messageReadStatusView.backgroundColor = [UIColor clearColor];
        _messageReadStatusView.image = RCDynamicImage(@"conversation-list_cell_msg_read_img",@"message_read_status");
        _messageReadStatusView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [_messageReadStatusView.widthAnchor constraintEqualToConstant:16],
            [_messageReadStatusView.heightAnchor constraintEqualToConstant:16]
        ]];
    }
    return _messageReadStatusView;
}

- (RCBaseImageView *)conversationPinView {
    if (!_conversationPinView) {
        _conversationPinView = [[RCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        _conversationPinView.backgroundColor = [UIColor clearColor];
        _conversationPinView.image = RCDynamicImage(@"conversation-list_cell_pin_img", @"");
        _conversationPinView.accessibilityLabel = @"_conversationPinView";
        _conversationPinView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [_conversationPinView.widthAnchor constraintEqualToConstant:16],
            [_conversationPinView.heightAnchor constraintEqualToConstant:16]
        ]];
    }
    return _conversationPinView;
}
- (UIStackView *)stackView {
    if (!_stackView) {
        // 创建水平StackView来放置statusView和titleLabel
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.axis = UILayoutConstraintAxisHorizontal; // 改为水平布局
        stackView.alignment = UIStackViewAlignmentTrailing;
        stackView.distribution = UIStackViewDistributionEqualSpacing;
        stackView.spacing = 5;
        _stackView = stackView;
    }
    return _stackView;
}

@end
