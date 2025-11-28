//
//  RCConversationDetailContentView.m
//  RongIMKit
//
//  Created by 岑裕 on 16/9/15.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCConversationDetailContentView.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCKitConfig.h"
#import "RCResendManager.h"
#import "RCEditInputBarConfig.h"
#import "RCConversationModel+RRS.h"
#import "RCRRSUtil.h"

@interface RCConversationDetailContentView ()
@property (nonatomic, strong) NSArray *constraints;
@property (nonatomic, copy) NSString *prefixName;
@end

@implementation RCConversationDetailContentView
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

    [self addSubview:self.messageContentLabel];
    [self addSubview:self.hightlineLabel];
    [self addSubview:self.sentStatusView];

    [self addSubviewConstraint];
}

- (void)updateContent:(RCConversationModel *)model prefixName:(NSString *)prefixName {
    self.prefixName = prefixName;
    [self updateContent:model];
}

/// 是否在左侧显示已读状态
/// - Parameter model: model
- (BOOL)shouldShowReadStatusAtLeading:(RCConversationModel *)model {
    if ([RCKitUtility isTraditionInnerThemes]) {// 传统模式不显示在左侧, 仍然在右侧
        return NO;
    }
    if (model.draft.length == 0
        && model.editedMessageDraft.content.length == 0
        && model.lastestMessageId > 0
        && model.lastestMessageDirection == MessageDirection_SEND
        && ((model.conversationType == ConversationType_PRIVATE
             && [RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(model.conversationType)])
            || model.conversationType == ConversationType_Encrypted)
        && model.latestMessageUId
        && model.latestMessageUId.length > 0
        && ![model.objectName isEqualToString:RCRecallNotificationMessageIdentifier]) {
        return YES;
    }
    return NO;
}

- (void)updateContent:(RCConversationModel *)model {
    if ([self isShowDraft:model]) {
        self.sentStatusView.hidden = YES;
        self.hightlineLabel.text = RCLocalizedString(@"Draft");
        self.hightlineLabel.textColor = RCDynamicColor(@"hint_color", @"0xcc3333", @"0xcc3333");
    } else if (model.lastestMessageDirection == MessageDirection_SEND && model.sentStatus == SentStatus_FAILED) {
        self.sentStatusView.hidden = NO;
        self.hightlineLabel.text = nil;
        if ([[RCResendManager sharedManager] needResend:model.lastestMessageId]) {
            self.sentStatusView.image = RCDynamicImage(@"conversation-list_cell_msg_sending_img", @"rc_conversation_list_msg_sending");
        } else {
            self.sentStatusView.image = RCDynamicImage(@"conversation-list_cell_msg_fail_img", @"message_fail");
        }
    } else if (model.lastestMessageDirection == MessageDirection_SEND && model.sentStatus == SentStatus_SENDING) {
        self.sentStatusView.hidden = NO;
        self.sentStatusView.image = RCDynamicImage(@"conversation-list_cell_msg_sending_img", @"rc_conversation_list_msg_sending");
        self.hightlineLabel.text = nil;
    } else if (model.hasUnreadMentioned) {
        self.sentStatusView.hidden = YES;
        self.hightlineLabel.text = RCLocalizedString(@"HaveMentioned");
        self.hightlineLabel.textColor = RCDynamicColor(@"hint_color", @"0xcc3333", @"0xcc3333");
    } else if([self shouldShowReadStatusAtLeading:model]) { // 欢快主题显示已读状态
        // 默认未读图标
        UIImage *image = RCDynamicImage(@"conversation_msg_rrs_v5_unread_gray_img",@"msg_rrs_v5_unread_gray");;
        if ([RCRRSUtil isSupportReadReceiptV5]
            && [model rrs_shouldFetchConversationReadReceipt]) {
            if (model.readReceiptInfoV5.readCount > 0 && model.readReceiptInfoV5.unreadCount == 0) {
                // 已读
                image = RCDynamicImage(@"conversation_msg_rrs_v5_read_img",@"msg_rrs_v5_read");
            }
        } else if (model.sentStatus == SentStatus_READ) {
            image = RCDynamicImage(@"conversation-list_cell_msg_read_img",@"message_read_status");
        }
        self.sentStatusView.hidden = NO;
        self.sentStatusView.image = image;
        self.hightlineLabel.text = nil;
    } else {
        self.sentStatusView.hidden = YES;
        self.hightlineLabel.text = nil;
    }

    NSString *messageContent = nil;
    if ([self isShowDraft:model]) {
        NSString *editedDraftContent = model.editedMessageDraft.content;
        if (editedDraftContent.length) {
            RCEditInputBarConfig *config = [[RCEditInputBarConfig alloc] initWithData:editedDraftContent];
            messageContent = config.textContent;
        } else {
            messageContent = model.draft;
        }
    } else if (model.lastestMessageId > 0) {
        if (self.prefixName.length == 0 || model.lastestMessageDirection == MessageDirection_SEND ||
            [model.lastestMessage isMemberOfClass:[RCRecallNotificationMessage class]] ||
            [model.lastestMessage isKindOfClass:[RCInformationNotificationMessage class]] ||
            [model.lastestMessage isKindOfClass:[RCGroupNotificationMessage class]] ||
            [model.lastestMessage isKindOfClass:[RCUnknownMessage class]]) {
            messageContent = [self formatMessageContent:model];
        } else {
            messageContent = [NSString stringWithFormat:@"%@: %@", self.prefixName, [self formatMessageContent:model]];
        }
    }
    if (messageContent == nil) {
        messageContent = @"";
    } else {
        messageContent = [self getOneLineString:messageContent];
    }
    BOOL isVoiceMessage = [model.lastestMessage isKindOfClass:[RCVoiceMessage class]] || [model.lastestMessage isKindOfClass:[RCHQVoiceMessage class]];
    NSMutableAttributedString *attibuteText = [[NSMutableAttributedString alloc] initWithString:messageContent];
    if (model.draft.length == 0 && model.lastestMessageId > 0 && isVoiceMessage
         &&
        (NO == model.receivedStatusInfo.isListened) && model.lastestMessageDirection == MessageDirection_RECEIVE) {
        NSRange range;
        if (self.prefixName.length == 0 || messageContent.length == 0) {
            range = NSMakeRange(0, messageContent.length);
        } else {
            range = [messageContent rangeOfString:[self formatMessageContent:model]];
        }
        UIColor *attributeColor = RCDynamicColor(@"hint_color", @"0xcc3333", @"0xcc3333");
        if (attributeColor) {
            [attibuteText addAttribute:NSForegroundColorAttributeName value:attributeColor range:range];
        }
     
    }
    self.messageContentLabel.attributedText = attibuteText;
    [self updateLayout];
}

- (void)updateLayout {
    if (self.constraints) {
        [self removeConstraints:self.constraints];
    }

    NSString *layoutFormat = nil;
    if (!self.sentStatusView.hidden) {
        layoutFormat = @"H:|-0-[_sentStatusView(width)]-3.5-[_messageContentLabel]-0-|";
    } else if (self.hightlineLabel.text.length > 0) {
        layoutFormat = @"H:|-0-[_hightlineLabel(width)]-3.5-[_messageContentLabel]-0-|";
    } else {
        layoutFormat = @"H:|-0-[_messageContentLabel]-0-|";
    }

    self.constraints =
        [NSLayoutConstraint constraintsWithVisualFormat:layoutFormat
                                                options:0
                                                metrics:@{
                                                    @"width" : @([self getLeftViewWidth])
                                                }
                                                  views:NSDictionaryOfVariableBindings(_sentStatusView, _hightlineLabel,
                                                                                       _messageContentLabel)];
    [self addConstraints:self.constraints];

    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    [self layoutIfNeeded];
}

- (NSString *)formatMessageContent:(RCConversationModel *)model {
    NSString *objectName = model.objectName;
    if (model.conversationType == ConversationType_Encrypted &&
        ([objectName isEqualToString:RCTextMessageTypeIdentifier] ||
         [objectName isEqualToString:RCVoiceMessageTypeIdentifier] ||
         [objectName isEqualToString:RCImageMessageTypeIdentifier] || [objectName isEqualToString:@"RC:SightMsg"] ||
         [objectName isEqualToString:@"RC:LBSMsg"] || [objectName isEqualToString:@"RC:CardMsg"])) {
        return RCLocalizedString(@"Message");
    }
    if ([RCKitUtility isUnkownMessage:model.lastestMessageId content:model.lastestMessage] &&
        RCKitConfigCenter.message.showUnkownMessage) {
        return RCLocalizedString(@"unknown_message_cell_tip");
    } else if ([model.lastestMessage isKindOfClass:[RCStreamMessage class]]) {
        return [RCKitUtility formatStreamDigest:[[RCCoreClient sharedCoreClient] getMessage:model.lastestMessageId]];
    }  else {
        return [RCKitUtility formatMessage:model.lastestMessage
                                  targetId:model.targetId
                          conversationType:model.conversationType];
    }
}

- (NSString *)getOneLineString:(NSString *)oldString {
    NSString *newString = [oldString stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "];
    newString = [newString stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    newString = [newString stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
    return newString;
}

- (void)resetDefaultLayout:(RCConversationModel *)reuseModel {
    self.hightlineLabel.text = nil;
    self.messageContentLabel.attributedText = nil;
    self.sentStatusView.hidden = YES;
}

- (CGFloat)getLeftViewWidth {
    if (!self.sentStatusView.hidden) {
        return self.sentStatusView.frame.size.width;
    } else if (self.hightlineLabel.text.length > 0) {
        CGSize size = [RCKitUtility getTextDrawingSize:self.hightlineLabel.text
                                                  font:self.hightlineLabel.font
                                       constrainedSize:CGSizeMake(MAXFLOAT, self.bounds.size.height)];
        return ceilf(size.width);
    } else {
        return 0;
    }
}

// 是否显示草稿
- (BOOL)isShowDraft:(RCConversationModel *)model {
    return (model.editedMessageDraft.content.length > 0 || model.draft.length > 0) && !model.hasUnreadMentioned;
}

#pragma mark - Constraint
- (void)addSubviewConstraint {
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.messageContentLabel
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.hightlineLabel
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.sentStatusView
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
}

#pragma mark - Getter & Setter
- (UILabel *)messageContentLabel {
    if(!_messageContentLabel) {
        _messageContentLabel = [[UILabel alloc] init];
        _messageContentLabel.backgroundColor = [UIColor clearColor];
        _messageContentLabel.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
        _messageContentLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xA0A5AB", @"0x5D5D5D");
        _messageContentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _messageContentLabel;
}

- (UILabel *)hightlineLabel {
    if(!_hightlineLabel) {
        _hightlineLabel = [[UILabel alloc] init];
        _hightlineLabel.backgroundColor = [UIColor clearColor];
        _hightlineLabel.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
        _hightlineLabel.textColor = RCDynamicColor(@"hint_color", @"0xA0A5AB", @"0x5D5D5D");
        _hightlineLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _hightlineLabel.accessibilityLabel = @"_hightlineLabel";
    }
    return _hightlineLabel;
}

- (RCBaseImageView *)sentStatusView {
    if(!_sentStatusView) {
        _sentStatusView = [[RCBaseImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        _sentStatusView.image = RCDynamicImage(@"conversation-list_cell_msg_fail_img", @"message_fail");
    }
    return _sentStatusView;
}
@end
