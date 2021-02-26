//
//  RCConversationStatusView.m
//  RongIMKit
//
//  Created by 岑裕 on 16/9/15.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCConversationStatusView.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCIM.h"
#import "RCKitConfig.h"


@interface RCConversationStatusView ()

@property (nonatomic, strong) NSArray *constraints;
@property (nonatomic, strong) RCConversationModel *backupModel;

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

    [self addSubview:self.conversationNotificationStatusView];
    [self addSubview:self.messageReadStatusView];

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
    [self updateLayout];
}

- (void)updateReadStatus:(RCConversationModel *)model {
    if (model.draft.length == 0 && model.lastestMessageId > 0 &&
        model.lastestMessageDirection == MessageDirection_SEND && model.sentStatus == SentStatus_READ &&
        ((model.conversationType == ConversationType_PRIVATE &&
          [RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(model.conversationType)]) ||
         model.conversationType == ConversationType_Encrypted)) {
        RCMessage *msg = [[RCIMClient sharedRCIMClient] getMessage:model.lastestMessageId];
        if (msg && msg.messageUId && msg.messageUId.length > 0 &&
            ![msg.objectName isEqualToString:RCRecallNotificationMessageIdentifier]) {
            self.messageReadStatusView.hidden = NO;
        }
    }
}

- (void)updateLayout {
    if (self.constraints) {
        [self removeConstraints:self.constraints];
    }

    NSString *layoutFormat = nil;
    if (self.conversationNotificationStatusView.hidden) {
        layoutFormat = @"H:[_messageReadStatusView(16)]-5-|";
    } else {
        layoutFormat = @"H:[_messageReadStatusView(16)]-6.5-[_conversationNotificationStatusView(16)]-5-|";
    }
    self.constraints = [NSLayoutConstraint
        constraintsWithVisualFormat:layoutFormat
                            options:0
                            metrics:nil
                              views:NSDictionaryOfVariableBindings(_messageReadStatusView,
                                                                   _conversationNotificationStatusView)];
    [self addConstraints:self.constraints];

    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    [self layoutIfNeeded];
}

- (void)resetDefaultLayout:(RCConversationModel *)reuseModel {
    self.conversationNotificationStatusView.hidden = YES;
    self.messageReadStatusView.hidden = YES;
}

#pragma mark - Constraint
- (void)addSubviewConstraint {
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.conversationNotificationStatusView
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.messageReadStatusView
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
}

#pragma mark - Getter & Setter
- (UIImageView *)conversationNotificationStatusView {
    if(!_conversationNotificationStatusView) {
        _conversationNotificationStatusView = [[UIImageView alloc] initWithFrame:CGRectMake(38, 3, 16, 16)];
        _conversationNotificationStatusView.backgroundColor = [UIColor clearColor];
        _conversationNotificationStatusView.image = RCResourceImage(@"block_notification");
        _conversationNotificationStatusView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _conversationNotificationStatusView;
}

- (UIImageView *)messageReadStatusView {
    if (!_messageReadStatusView) {
        _messageReadStatusView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        _messageReadStatusView.backgroundColor = [UIColor clearColor];
        _messageReadStatusView.image = RCResourceImage(@"message_read_status");
        _messageReadStatusView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _messageReadStatusView;
}
@end
