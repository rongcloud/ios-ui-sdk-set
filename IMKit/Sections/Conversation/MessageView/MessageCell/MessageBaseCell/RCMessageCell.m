//
//  RCMessageCell.m
//  RongIMKit
//
//  Created by xugang on 15/1/28.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCMessageCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCUserInfoCacheManager.h"
#import "RCloudImageView.h"
#import "RCAlertView.h"
#import "RCKitConfig.h"
#import "RCMessageCellTool.h"
#import "RCResendManager.h"
#import <RCIMClient+Destructing.h>
#import <RongPublicService/RongPublicService.h>
// 头像
#define PortraitImageViewTop 0
// 气泡
#define ContentViewBottom 14
#define DefaultMessageContentViewWidth 200
#define StatusContentViewWidth 100
#define DestructBtnWidth 20
#define StatusViewAndContentViewSpace 8

NSString *const KNotificationMessageBaseCellUpdateCanReceiptStatus =
    @"KNotificationMessageBaseCellUpdateCanReceiptStatus";
@interface RCMessageCell() {
    BOOL _showPortrait;
}
@property (nonatomic, assign) BOOL showBubbleBackgroundView;
@end
@implementation RCMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self rcinit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self rcinit];
    }
    return self;
}

- (void)rcinit{
    _showPortrait = YES;
    [self setupMessageCellView];
    [self registerMessageCellNotification];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setShowPortrait:(BOOL)showPortrait {
    if (showPortrait != _showPortrait) {
        _showPortrait = showPortrait;
        [self relayoutViewBy:_showPortrait];
    }
    self.portraitImageView.hidden = !_showPortrait;
}

- (BOOL)showPortrait {
    return _showPortrait;
}
#pragma mark - Super Methods

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    if (self.showBubbleBackgroundView) {
        self.bubbleBackgroundView.image = [RCMessageCellTool getDefaultMessageCellBackgroundImage:self.model];
    }
    self.receiptView.hidden = YES;
    self.receiptStatusLabel.hidden = YES;
    self.messageFailedStatusView.hidden = YES;
    if (model.readReceiptInfo.isReceiptRequestMessage && model.messageDirection == MessageDirection_SEND && [RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(model.conversationType)]) {
        self.receiptStatusLabel.hidden = NO;
        self.receiptStatusLabel.userInteractionEnabled = YES;
        self.receiptStatusLabel.text = [NSString
            stringWithFormat:RCLocalizedString(@"readNum"), self.model.readReceiptCount];
    } else {
        self.receiptStatusLabel.hidden = YES;
        self.receiptStatusLabel.userInteractionEnabled = NO;
        self.receiptStatusLabel.text = nil;
    }

    if (model.messageDirection == MessageDirection_SEND && model.sentStatus == SentStatus_SENT) {
        if (model.isCanSendReadReceipt) {
            self.receiptView.hidden = NO;
            self.receiptView.userInteractionEnabled = YES;
            self.receiptStatusLabel.hidden = YES;
        } else {
            self.receiptView.hidden = YES;
            self.receiptStatusLabel.hidden = NO;
        }
    }

    // DebugLog(@"%s", __FUNCTION__);
    //如果是客服，更换默认头像
    if (ConversationType_CUSTOMERSERVICE == model.conversationType) {
        if (model.messageDirection == MessageDirection_RECEIVE) {
            [self.portraitImageView setPlaceholderImage:RCResourceImage(@"portrait_kefu")];

            model.userInfo = model.content.senderUserInfo;
            if (model.content.senderUserInfo != nil) {
                [self.portraitImageView setImageURL:[NSURL URLWithString:model.content.senderUserInfo.portraitUri]];
                [self.nicknameLabel setText:[RCKitUtility getDisplayName:model.content.senderUserInfo]];
            } else {
                [self.portraitImageView setImage:RCResourceImage(@"portrait_kefu")];
                [self.nicknameLabel setText:nil];
            }
        } else {
            RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId];
            model.userInfo = userInfo;
            [self.portraitImageView setPlaceholderImage:RCResourceImage(@"default_portrait_msg")];
            if (userInfo) {
                [self.portraitImageView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
                [self.nicknameLabel setText:[RCKitUtility getDisplayName:userInfo]];
            } else {
                [self.portraitImageView setImageURL:nil];
                [self.nicknameLabel setText:nil];
            }
        }
    } else if (ConversationType_APPSERVICE == model.conversationType ||
               ConversationType_PUBLICSERVICE == model.conversationType) {
        if (model.messageDirection == MessageDirection_RECEIVE) {
            RCPublicServiceProfile *serviceProfile = nil;
            if ([RCIM sharedRCIM].publicServiceInfoDataSource) {
                serviceProfile = [[RCUserInfoCacheManager sharedManager] getPublicServiceProfile:model.targetId];
            } else {
                serviceProfile =
                    [[RCPublicServiceClient sharedPublicServiceClient] getPublicServiceProfile:(RCPublicServiceType)model.conversationType
                                                           publicServiceId:model.targetId];
            }
            model.userInfo = model.content.senderUserInfo;
            if (serviceProfile) {
                [self.portraitImageView setImageURL:[NSURL URLWithString:serviceProfile.portraitUrl]];
                [self.nicknameLabel setText:serviceProfile.name];
            }
        } else {
            RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId];
            model.userInfo = userInfo;
            if (userInfo) {
                [self.portraitImageView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
                [self.nicknameLabel setText:[RCKitUtility getDisplayName:userInfo]];
            } else {
                [self.portraitImageView setImageURL:nil];
                [self.nicknameLabel setText:nil];
            }
        }
    } else if (ConversationType_GROUP == model.conversationType) {
        RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId inGroupId:self.model.targetId];
        RCUserInfo *tempUserInfo = [[RCUserInfoCache sharedCache] getUserInfo:model.senderUserId];
        userInfo.alias = tempUserInfo.alias;
        model.userInfo = userInfo;
        if (userInfo) {
            [self.portraitImageView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
            [self.nicknameLabel setText:[RCKitUtility getDisplayName:userInfo]];
        } else {
            [self.portraitImageView setImageURL:nil];
            [self.nicknameLabel setText:nil];
        }
    } else {
        //优先使用 RCMessage.senderUserId 确定用户，控制头像的显示
        //否则使用 RCMessage.content.senderUserInfo.userId 确定用户，控制头像的显示
        NSString *userId = model.senderUserId;
        if (userId.length <= 0) {
            userId = model.content.senderUserInfo.userId;
        }
        RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:userId];
        model.userInfo = userInfo;
        if (userInfo) {
            if (model.conversationType != ConversationType_Encrypted) {
                [self.portraitImageView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
            }
            [self.nicknameLabel setText:[RCKitUtility getDisplayName:userInfo]];
        } else {
            [self.portraitImageView setImageURL:nil];
            [self.nicknameLabel setText:nil];
        }
    }

    [self setCellAutoLayout];
    [self messageDestructing];
}

#pragma mark - Public Methods

- (void)updateStatusContentView:(RCMessageModel *)model {
    self.messageActivityIndicatorView.hidden = YES;
    if (model.messageDirection == MessageDirection_RECEIVE) {
        return;
    }
    __weak typeof(self) __blockSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^{

        if (__blockSelf.model.sentStatus == SentStatus_SENDING) {
            __blockSelf.messageFailedStatusView.hidden = YES;
            if (__blockSelf.messageActivityIndicatorView) {
                __blockSelf.messageActivityIndicatorView.hidden = NO;
                if (__blockSelf.messageActivityIndicatorView.isAnimating == NO) {
                    [__blockSelf.messageActivityIndicatorView startAnimating];
                }
            }
        } else if (__blockSelf.model.sentStatus == SentStatus_FAILED) {
            __blockSelf.receiptView.hidden = YES;
            __blockSelf.receiptStatusLabel.hidden = YES;
            __blockSelf.messageFailedStatusView.hidden = YES;
            if ([[RCResendManager sharedManager] needResend:model.messageId]) {
                if (__blockSelf.messageActivityIndicatorView) {
                    __blockSelf.messageActivityIndicatorView.hidden = NO;
                    if (__blockSelf.messageActivityIndicatorView.isAnimating == NO) {
                        [__blockSelf.messageActivityIndicatorView startAnimating];
                    }
                }
            } else {
                __blockSelf.messageFailedStatusView.hidden = NO;
                if (__blockSelf.messageActivityIndicatorView) {
                    __blockSelf.messageActivityIndicatorView.hidden = YES;
                    if (__blockSelf.messageActivityIndicatorView.isAnimating == YES) {
                        [__blockSelf.messageActivityIndicatorView stopAnimating];
                    }
                }
            }
        } else if (__blockSelf.model.sentStatus == SentStatus_CANCELED) {
            __blockSelf.messageFailedStatusView.hidden = YES;
            if (__blockSelf.messageActivityIndicatorView) {
                __blockSelf.messageActivityIndicatorView.hidden = YES;
                if (__blockSelf.messageActivityIndicatorView.isAnimating == YES) {
                    [__blockSelf.messageActivityIndicatorView stopAnimating];
                }
            }
        } else if (__blockSelf.model.sentStatus == SentStatus_SENT) {
            __blockSelf.messageFailedStatusView.hidden = YES;
            if (__blockSelf.messageActivityIndicatorView) {
                __blockSelf.messageActivityIndicatorView.hidden = YES;
                if (__blockSelf.messageActivityIndicatorView.isAnimating == YES) {
                    [__blockSelf.messageActivityIndicatorView stopAnimating];
                }
            }

            if (model.isCanSendReadReceipt) {
                __blockSelf.receiptView.hidden = NO;
                __blockSelf.receiptView.userInteractionEnabled = YES;
                __blockSelf.receiptStatusLabel.hidden = YES;
            } else {
                __blockSelf.receiptView.hidden = YES;
                __blockSelf.receiptStatusLabel.hidden = NO;
            }

        } //更新成已读状态
        else if (__blockSelf.model.sentStatus == SentStatus_READ && __blockSelf.isDisplayReadStatus &&
                 (__blockSelf.model.conversationType == ConversationType_PRIVATE ||
                  __blockSelf.model.conversationType == ConversationType_Encrypted)) {
            if (__blockSelf.model && __blockSelf.model.messageUId && __blockSelf.model.messageUId.length > 0) {
                __blockSelf.receiptStatusLabel.hidden = YES;
                __blockSelf.receiptStatusLabel.userInteractionEnabled = NO;
                __blockSelf.receiptView.hidden = NO;
            }

            __blockSelf.messageFailedStatusView.hidden = YES;
            if (__blockSelf.messageActivityIndicatorView) {
                __blockSelf.messageActivityIndicatorView.hidden = YES;
                if (__blockSelf.messageActivityIndicatorView.isAnimating == YES) {
                    [__blockSelf.messageActivityIndicatorView stopAnimating];
                }
            }
        }
    });
}

- (void)showBubbleBackgroundView:(BOOL)show{
    self.showBubbleBackgroundView = show;
    self.bubbleBackgroundView.userInteractionEnabled = show;
    if (show){
        [self.messageContentView sendSubviewToBack:self.bubbleBackgroundView];
    }else{
        self.bubbleBackgroundView = nil;
    }
}

#pragma mark - Private Methods

- (void)setupMessageCellView {
    self.allowsSelection = YES;
    self.delegate = nil;

    [self.baseContentView addSubview:self.portraitImageView];
    [self.baseContentView addSubview:self.nicknameLabel];
    [self.baseContentView addSubview:self.messageContentView];
    [self.baseContentView addSubview:self.statusContentView];
    
    [self.messageContentView addSubview:self.destructView];
    
    [self.destructView addSubview:self.destructBtn];
    
    [self.statusContentView addSubview:self.messageFailedStatusView];
    [self.statusContentView addSubview:self.messageActivityIndicatorView];
    self.messageActivityIndicatorView.hidden = YES;
    [self.statusContentView addSubview:self.receiptStatusLabel];
    [self.statusContentView addSubview:self.receiptView];


    [self setPortraitStyle:RCKitConfigCenter.ui.globalMessageAvatarStyle];
}

- (void)registerMessageCellNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUserInfoUpdate:)
                                                 name:RCKitDispatchUserInfoUpdateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onGroupUserInfoUpdate:)
                                                 name:RCKitDispatchGroupUserInfoUpdateNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onReceiptStatusUpdate:)
                                                 name:KNotificationMessageBaseCellUpdateCanReceiptStatus
                                               object:nil];
    
    [self registerUpdateLayoutIfNeed];
    
}

- (void)registerUpdateLayoutIfNeed{
    __weak typeof(self) weakSelf = self;
    [self.messageContentView registerFrameChangedEvent:^(CGRect frame) {
        if (weakSelf.model) {
            if ([RCKitUtility isRTL]) {
                if (weakSelf.model.messageDirection == MessageDirection_SEND) {
                    CGRect statusFrame = CGRectMake(CGRectGetMaxX(frame)+StatusViewAndContentViewSpace, frame.origin.y, StatusContentViewWidth, frame.size.height);
                    weakSelf.statusContentView.frame = statusFrame;
                    weakSelf.receiptStatusLabel.frame = CGRectMake(0 , statusFrame.size.height - 12,statusFrame.size.width, 12);
                    if (weakSelf.model.conversationType == ConversationType_PRIVATE || weakSelf.model.conversationType == ConversationType_Encrypted) {
                        weakSelf.receiptView.frame = CGRectMake(0, statusFrame.size.height - 16, 16, 16);
                        [weakSelf.receiptView setImage:RCResourceImage(@"message_read_status") forState:UIControlStateNormal];
                    } else {
                        weakSelf.receiptView.frame = CGRectMake(0, statusFrame.size.height - 16, 14, 14);
                        [weakSelf.receiptView setImage:RCResourceImage(@"receipt") forState:UIControlStateNormal];
                    }
                    weakSelf.messageFailedStatusView.frame = CGRectMake(0, (statusFrame.size.height-16)/2, 16, 16);
                } else {
                    CGRect statusFrame = CGRectMake(frame.origin.x - StatusContentViewWidth-StatusViewAndContentViewSpace, frame.origin.y, StatusContentViewWidth, frame.size.height);
                    weakSelf.statusContentView.frame = statusFrame;
                    weakSelf.messageFailedStatusView.frame = CGRectMake(statusFrame.size.width-16, (statusFrame.size.height-16)/2, 16, 16);
                }
                weakSelf.messageActivityIndicatorView.frame = weakSelf.messageFailedStatusView.frame;
            } else {
                if (weakSelf.model.messageDirection == MessageDirection_SEND) {
                    CGRect statusFrame = CGRectMake(frame.origin.x - StatusContentViewWidth-StatusViewAndContentViewSpace, frame.origin.y, StatusContentViewWidth, frame.size.height);
                    weakSelf.statusContentView.frame = statusFrame;
                    weakSelf.receiptStatusLabel.frame = CGRectMake(0 , statusFrame.size.height - 12,statusFrame.size.width, 12);
                    if (weakSelf.model.conversationType == ConversationType_PRIVATE || weakSelf.model.conversationType == ConversationType_Encrypted) {
                        weakSelf.receiptView.frame = CGRectMake(StatusContentViewWidth - 16, statusFrame.size.height - 16, 16, 16);
                        [weakSelf.receiptView setImage:RCResourceImage(@"message_read_status") forState:UIControlStateNormal];
                    } else {
                        weakSelf.receiptView.frame = CGRectMake(StatusContentViewWidth - 14, statusFrame.size.height - 16, 14, 14);
                        [weakSelf.receiptView setImage:RCResourceImage(@"receipt") forState:UIControlStateNormal];
                    }
                    weakSelf.messageFailedStatusView.frame = CGRectMake(statusFrame.size.width-16, (statusFrame.size.height-16)/2, 16, 16);
                    weakSelf.messageActivityIndicatorView.frame = weakSelf.messageFailedStatusView.frame;
                } else {
                    CGRect statusFrame = CGRectMake(CGRectGetMaxX(frame)+StatusViewAndContentViewSpace, frame.origin.y, StatusContentViewWidth, frame.size.height);
                    weakSelf.statusContentView.frame = statusFrame;
                    weakSelf.messageFailedStatusView.frame = CGRectMake(0, (statusFrame.size.height-16)/2, 16, 16);
                    weakSelf.messageActivityIndicatorView.frame = weakSelf.messageFailedStatusView.frame;
                }
            }
            if (weakSelf.showBubbleBackgroundView) {
                weakSelf.bubbleBackgroundView.frame = weakSelf.messageContentView.bounds;
            }
        }
    }];
    
    [self.messageContentView registerSizeChangedEvent:^(CGSize size) {
        if (weakSelf.model){
            CGRect rect = CGRectMake(0, 0, size.width, size.height);
            CGFloat protraitWidth = RCKitConfigCenter.ui.globalMessagePortraitSize.width;

            if ([RCKitUtility isRTL]) {
                if(weakSelf.model.messageDirection == MessageDirection_RECEIVE) {
                    if (self.showPortrait) {
                        rect.origin.x = weakSelf.baseContentView.bounds.size.width - (size.width + HeadAndContentSpacing + protraitWidth + PortraitViewEdgeSpace);
                    } else {
                        rect.origin.x = weakSelf.baseContentView.bounds.size.width - (size.width + PortraitViewEdgeSpace);
                    }
                    rect.origin.y = PortraitImageViewTop;
                    if (weakSelf.model.isDisplayNickname) {
                        rect.origin.y = PortraitImageViewTop + NameHeight + NameAndContentSpace;
                    }
                } else {
                    if (self.showPortrait) {
                        rect.origin.x = PortraitViewEdgeSpace + protraitWidth + HeadAndContentSpacing;
                    } else {
                        rect.origin.x = PortraitViewEdgeSpace;
                    }
                    rect.origin.y = PortraitImageViewTop;
                }
            } else {
                if(weakSelf.model.messageDirection == MessageDirection_RECEIVE) {
                    if (self.showPortrait) {
                        rect.origin.x = PortraitViewEdgeSpace + protraitWidth + HeadAndContentSpacing;
                    } else {
                        rect.origin.x = PortraitViewEdgeSpace;
                    }
                    CGFloat messageContentViewY = PortraitImageViewTop;
                    if (weakSelf.model.isDisplayNickname) {
                        messageContentViewY = PortraitImageViewTop + NameHeight + NameAndContentSpace;
                    }
                    rect.origin.y = messageContentViewY;
                } else {
                    if (self.showPortrait) {
                        rect.origin.x = weakSelf.baseContentView.bounds.size.width - (size.width + HeadAndContentSpacing + protraitWidth + PortraitViewEdgeSpace);
                    } else {
                        rect.origin.x = weakSelf.baseContentView.bounds.size.width - (size.width + PortraitViewEdgeSpace);
                    }
                
                    rect.origin.y = PortraitImageViewTop;
                }
            }
            weakSelf.messageContentView.frame = rect;
            [weakSelf setDestructViewLayout];
        }
    }];
}

- (void)messageContentViewFrameDidChanged {
    
}

- (void)setPortraitStyle:(RCUserAvatarStyle)portraitStyle {
    _portraitStyle = portraitStyle;
    if (_portraitStyle == RC_USER_AVATAR_RECTANGLE) {
        self.portraitImageView.layer.cornerRadius = RCKitConfigCenter.ui.portraitImageViewCornerRadius;
    }
    if (_portraitStyle == RC_USER_AVATAR_CYCLE) {
        self.portraitImageView.layer.cornerRadius = [RCKitConfigCenter.ui globalMessagePortraitSize].height / 2;
    }
    self.portraitImageView.layer.masksToBounds = YES;
}

- (void)relayoutViewBy:(BOOL)show {
    CGFloat protraitWidth = RCKitConfigCenter.ui.globalMessagePortraitSize.width;
    CGFloat protraitHeight = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    
    CGRect nicknameFrame = self.nicknameLabel.frame;
    CGRect contentFrame = self.messageContentView.frame;
    CGSize size = contentFrame.size;
    if ([RCKitUtility isRTL]) {
        // receiver
        if (MessageDirection_RECEIVE == self.model.messageDirection) {
          
            if (self.showPortrait) {
                contentFrame.origin.x = self.baseContentView.bounds.size.width - (size.width + HeadAndContentSpacing + protraitWidth + PortraitViewEdgeSpace);
            } else {
                contentFrame.origin.x = self.baseContentView.bounds.size.width - (size.width + PortraitViewEdgeSpace);
            }
        } else { // owner
            CGFloat nameOffset_X = 0;
            if (self.showPortrait) {
                contentFrame.origin.x = PortraitViewEdgeSpace + protraitWidth + HeadAndContentSpacing;
                nameOffset_X = self.portraitImageView.frame.origin.x + self.portraitImageView.bounds.size.width + HeadAndContentSpacing;
            } else {
                contentFrame.origin.x = PortraitViewEdgeSpace;
                nameOffset_X = self.portraitImageView.frame.origin.x;
            }
            
            nicknameFrame.origin.x = nameOffset_X;
        }

    } else {
        // receiver
           if (MessageDirection_RECEIVE == self.model.messageDirection) {
               CGFloat nameOffset_X = 0;
               if (self.showPortrait) {
                   contentFrame.origin.x = PortraitViewEdgeSpace + protraitWidth + HeadAndContentSpacing;
                   nameOffset_X = self.portraitImageView.frame.origin.x + self.portraitImageView.bounds.size.width + HeadAndContentSpacing;
               } else {
                   contentFrame.origin.x = PortraitViewEdgeSpace;
                   nameOffset_X = self.portraitImageView.frame.origin.x;
               }
               nicknameFrame.origin = CGPointMake(nameOffset_X, PortraitImageViewTop);
               self.nicknameLabel.frame = nicknameFrame;
           } else { // owner
               if (self.showPortrait) {
                   contentFrame.origin.x = self.baseContentView.bounds.size.width - (size.width + HeadAndContentSpacing + protraitWidth + PortraitViewEdgeSpace);
               } else {
                   contentFrame.origin.x = self.baseContentView.bounds.size.width - (size.width + PortraitViewEdgeSpace);
               }
           }
    }
    self.nicknameLabel.frame = nicknameFrame;
    self.messageContentView.frame = contentFrame;
    [self messageContentViewFrameDidChanged];

}

- (void)setCellAutoLayout {
    CGFloat protraitWidth = RCKitConfigCenter.ui.globalMessagePortraitSize.width;
    CGFloat protraitHeight = RCKitConfigCenter.ui.globalMessagePortraitSize.height;

    if ([RCKitUtility isRTL]) {
        // receiver
        if (MessageDirection_RECEIVE == self.model.messageDirection) {
            self.nicknameLabel.hidden = YES;
            CGFloat portraitImageX = self.baseContentView.bounds.size.width - (protraitWidth + PortraitViewEdgeSpace);
            self.portraitImageView.frame = CGRectMake(portraitImageX, PortraitImageViewTop, protraitWidth, protraitHeight);
        } else { // owner
            self.nicknameLabel.hidden = !self.model.isDisplayNickname;
            CGFloat portraitImageX = PortraitViewEdgeSpace;
            self.portraitImageView.frame = CGRectMake(portraitImageX, PortraitImageViewTop, protraitWidth, protraitHeight);
            if (self.showPortrait) {
                self.nicknameLabel.frame = CGRectMake(portraitImageX + self.portraitImageView.bounds.size.width + HeadAndContentSpacing, PortraitImageViewTop, DefaultMessageContentViewWidth, NameHeight);
            } else {
                self.nicknameLabel.frame = CGRectMake(portraitImageX, PortraitImageViewTop, DefaultMessageContentViewWidth, NameHeight);
            }
          
        }
        self.messageContentView.contentSize = CGSizeMake(DefaultMessageContentViewWidth,self.baseContentView.bounds.size.height - ContentViewBottom);
    } else {
        // receiver
           if (MessageDirection_RECEIVE == self.model.messageDirection) {
               self.nicknameLabel.hidden = !self.model.isDisplayNickname;
               CGFloat portraitImageX = PortraitViewEdgeSpace;
               self.portraitImageView.frame =
               CGRectMake(portraitImageX, PortraitImageViewTop, protraitWidth,
                          protraitHeight);
            if (self.showPortrait) {
                   self.nicknameLabel.frame =
                   CGRectMake(portraitImageX + self.portraitImageView.bounds.size.width + HeadAndContentSpacing, PortraitImageViewTop, DefaultMessageContentViewWidth, NameHeight);
               } else {
                   self.nicknameLabel.frame =
                   CGRectMake(portraitImageX , PortraitImageViewTop, DefaultMessageContentViewWidth, NameHeight);               }
           } else { // owner
               self.nicknameLabel.hidden = YES;
               CGFloat portraitImageX =
               self.baseContentView.bounds.size.width - (protraitWidth + PortraitViewEdgeSpace);
               self.portraitImageView.frame =
               CGRectMake(portraitImageX, PortraitImageViewTop, protraitWidth,
                          protraitHeight);
           }
           self.messageContentView.contentSize = CGSizeMake(DefaultMessageContentViewWidth,self.baseContentView.bounds.size.height - ContentViewBottom);
    }
    [self updateStatusContentView:self.model];
}

- (void)setDestructViewLayout {
    self.destructBtn.frame = CGRectMake(0, 0, DestructBtnWidth, DestructBtnWidth);
    if (self.model.content.destructDuration > 0) {
        self.destructView.hidden = NO;
        [self.messageContentView bringSubviewToFront:self.destructView];
        CGRect frame = self.destructBtn.frame;
        if (self.destructBtn.titleLabel.text > 0) {
            CGFloat textWidth = [RCKitUtility getTextDrawingSize:self.destructBtn.titleLabel.text font:self.destructBtn.titleLabel.font constrainedSize:CGSizeMake(MAXFLOAT, DestructBtnWidth)].width + 6;
            textWidth = textWidth < DestructBtnWidth ? DestructBtnWidth : textWidth;
            frame.size.width = textWidth;
            self.destructBtn.frame = frame;
        }
        if ([RCKitUtility isRTL]) {
            if (self.messageDirection == MessageDirection_RECEIVE) {
                self.destructView.frame = CGRectMake(- frame.size.width/2, - frame.size.height/2, frame.size.width, frame.size.height);
            } else {
                self.destructView.frame = CGRectMake(self.messageContentView.frame.size.width - frame.size.width/2, - frame.size.height/2, frame.size.width, frame.size.height);
            }
        } else {
            if (self.messageDirection == MessageDirection_RECEIVE) {
                self.destructView.frame = CGRectMake(self.messageContentView.frame.size.width - frame.size.width/2, - frame.size.height/2, frame.size.width, frame.size.height);
            } else {
                self.destructView.frame = CGRectMake( - frame.size.width/2, - frame.size.height/2, frame.size.width, frame.size.height);
            }
        }
    } else {
        self.destructView.hidden = YES;
        self.destructView.frame = CGRectZero;
    }
}

- (void)messageDestructing {
    NSNumber *whisperMsgDuration =
        [[RCIMClient sharedRCIMClient] getDestructMessageRemainDuration:self.model.messageUId];
    if (whisperMsgDuration == nil) {
        [self.destructBtn setTitle:@"" forState:UIControlStateNormal];
        [self.destructBtn setImage:RCResourceImage(@"fire_identify") forState:UIControlStateNormal];
        self.destructBtn.backgroundColor = [UIColor clearColor];
    } else {
        NSDecimalNumber *subTime =
            [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", whisperMsgDuration]];
        NSDecimalNumber *divTime = [NSDecimalNumber decimalNumberWithString:@"1"];
        NSDecimalNumberHandler *handel = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundBankers
                                                                                                scale:0
                                                                                     raiseOnExactness:NO
                                                                                      raiseOnOverflow:NO
                                                                                     raiseOnUnderflow:NO
                                                                                  raiseOnDivideByZero:NO];
        NSDecimalNumber *showTime = [subTime decimalNumberByDividingBy:divTime withBehavior:handel];
        [self.destructBtn setImage:nil forState:UIControlStateNormal];
        [self.destructBtn setTitle:[NSString stringWithFormat:@"%@", showTime] forState:UIControlStateNormal];
        self.destructBtn.backgroundColor = HEXCOLOR(0xf4b50b);
        [self setDestructViewLayout];
    }
}

- (void)onReceiptStatusUpdate:(NSNotification *)notification {
    // 更新消息状态
    NSDictionary *statusDic = notification.object;
    NSUInteger conversationType = [statusDic[@"conversationType"] integerValue];
    NSString *targetId = statusDic[@"targetId"];
    long messageId = [statusDic[@"messageId"] longValue];
    if (self.model.conversationType == conversationType && [self.model.targetId isEqualToString:targetId]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (messageId == self.model.messageId) {
                self.receiptView.hidden = NO;
                self.receiptView.userInteractionEnabled = YES;
                self.receiptStatusLabel.hidden = YES;
                self.model.isCanSendReadReceipt = YES;
            } else {
                self.receiptView.hidden = YES;
                self.receiptStatusLabel.hidden = NO;
                self.model.isCanSendReadReceipt = NO;
            }
        });
    }
}

- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification {
    RCMessageCellNotificationModel *notifyModel = notification.object;
    if (self.model.messageId == notifyModel.messageId) {
        DebugLog(@"messageCellUpdateSendingStatusEvent >%@ ", notifyModel.actionName);
        if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_BEGIN]) {
            self.model.sentStatus = SentStatus_SENDING;
            [self updateStatusContentView:self.model];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_FAILED]) {
            if ([[RCResendManager sharedManager] needResend:self.model.messageId]) {
                self.model.sentStatus = SentStatus_SENDING;
            } else {
                self.model.sentStatus = SentStatus_FAILED;
            }
            [self updateStatusContentView:self.model];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_CANCELED]) {
            self.model.sentStatus = SentStatus_CANCELED;
            [self updateStatusContentView:self.model];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_SUCCESS]) {
            if (self.model.sentStatus != SentStatus_READ) {
                self.model.sentStatus = SentStatus_SENT;
                [self updateStatusContentView:self.model];
            }
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_PROGRESS]) {
            self.model.sentStatus = SentStatus_SENDING;
            self.messageFailedStatusView.hidden = YES;
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_HASREAD] &&
                   [RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.model.conversationType)] &&
                   (self.model.conversationType == ConversationType_PRIVATE ||
                    self.model.conversationType == ConversationType_Encrypted)) {
            self.model.sentStatus = SentStatus_READ;
            [self updateStatusContentView:self.model];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_READCOUNT] &&
                   [RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.model.conversationType)] &&
                   (self.model.conversationType == ConversationType_GROUP ||
                    self.model.conversationType == ConversationType_DISCUSSION)) {
            self.receiptView.hidden = YES;
            self.receiptStatusLabel.hidden = NO;
            self.receiptStatusLabel.userInteractionEnabled = YES;
            self.receiptStatusLabel.text = [NSString
                stringWithFormat:RCLocalizedString(@"readNum"), notifyModel.progress];
            [self updateStatusContentView:self.model];
        }
    }
}

- (void)sendMessageReadReceiptRequest:(NSString *)messageUId {
    RCMessage *message = [[RCIMClient sharedRCIMClient] getMessage:self.model.messageId];
    if (message) {
        if (!messageUId || [messageUId isEqualToString:@""]) {
            return;
        }
        __weak typeof(self) weakSelf = self;
        [[RCIMClient sharedRCIMClient] sendReadReceiptRequest:message success:^{
            weakSelf.model.isCanSendReadReceipt = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.receiptView.hidden = YES;
                weakSelf.receiptView.userInteractionEnabled = NO;
                weakSelf.receiptStatusLabel.hidden = NO;
                weakSelf.receiptStatusLabel.userInteractionEnabled = YES;
                weakSelf.receiptStatusLabel.text =
                [NSString stringWithFormat:RCLocalizedString(@"readNum"), 0];
                if (!weakSelf.model.readReceiptInfo) {
                    weakSelf.model.readReceiptInfo = [[RCReadReceiptInfo alloc] init];
                }
                weakSelf.model.readReceiptInfo.isReceiptRequestMessage = YES;
                if ([weakSelf.delegate respondsToSelector:@selector(didTapNeedReceiptView:)]) {
                    [weakSelf.delegate didTapNeedReceiptView:weakSelf.model];
                }
            });
        }error:^(RCErrorCode nErrorCode) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *tip = RCLocalizedString(@"SendReadReceiptRequestFailed");
                if (tip.length > 0 && ![tip isEqualToString:@"SendReadReceiptRequestFailed"]) {
                    [RCAlertView showAlertController:nil message:RCLocalizedString(@"SendReadReceiptRequestFailed") hiddenAfterDelay:1];
                }
            });
        }];
    }
}

#pragma mark - UserInfo Update
- (void)onUserInfoUpdate:(NSNotification *)notification {
    NSDictionary *userInfoDic = notification.object;
    if ([self.model.senderUserId isEqualToString:userInfoDic[@"userId"]]) {
        if (self.model.conversationType == ConversationType_GROUP) {
            //重新取一下混合的用户信息
            RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:self.model.senderUserId inGroupId:self.model.targetId];
            RCUserInfo *tempUserInfo = [[RCUserInfoCache sharedCache] getUserInfo:self.model.senderUserId];
            userInfo.alias = tempUserInfo.alias;
            [self updateUserInfoUI:userInfo];
        } else if (self.model.messageDirection == MessageDirection_SEND) {
            [self updateUserInfoUI:userInfoDic[@"userInfo"]];
        } else if (self.model.conversationType != ConversationType_APPSERVICE &&
                   self.model.conversationType != ConversationType_PUBLICSERVICE) {
            if (self.model.conversationType == ConversationType_CUSTOMERSERVICE && self.model.content.senderUserInfo) {
                return;
            }
            [self updateUserInfoUI:userInfoDic[@"userInfo"]];
        }
    }
}

- (void)onGroupUserInfoUpdate:(NSNotification *)notification {
    if (self.model.conversationType == ConversationType_GROUP) {
        NSDictionary *groupUserInfoDic = (NSDictionary *)notification.object;
        if ([self.model.targetId isEqualToString:groupUserInfoDic[@"inGroupId"]] &&
            [self.model.senderUserId isEqualToString:groupUserInfoDic[@"userId"]]) {
            //重新取一下混合的用户信息
            RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:self.model.senderUserId inGroupId:self.model.targetId];
            RCUserInfo *tempUserInfo = [[RCUserInfoCache sharedCache] getUserInfo:self.model.senderUserId];
            userInfo.alias = tempUserInfo.alias;
            [self updateUserInfoUI:userInfo];
        }
    }
}

- (void)updateUserInfoUI:(RCUserInfo *)userInfo {
    self.model.userInfo = userInfo;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (userInfo.portraitUri.length > 0) {
            [weakSelf.portraitImageView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
        }
        [weakSelf.nicknameLabel setText:[RCKitUtility getDisplayName:userInfo]];
    });
}

#pragma mark - Target Action
- (void)didClickMsgFailedView:(UIButton *)button {
    self.messageFailedStatusView.hidden = YES;
    self.model.sentStatus = SentStatus_SENDING;
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(didTapmessageFailedStatusViewForResend:)]) {
            [self.delegate didTapmessageFailedStatusViewForResend:self.model];
        }
    }
}

- (void)enableShowReceiptView:(UIButton *)sender {
    if (!self.model.messageUId) {
        RCMessage *message = [[RCIMClient sharedRCIMClient] getMessage:self.model.messageId];
        if (message) {
            [self sendMessageReadReceiptRequest:message.messageUId];
        }
    } else {
        [self sendMessageReadReceiptRequest:self.model.messageUId];
    }
}

- (void)clickReceiptCountView:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didTapReceiptCountView:)]) {
        if (self.receiptStatusLabel.text != nil) {
            [self.delegate didTapReceiptCountView:self.model];
        }
        return;
    }
}

- (void)tapUserPortaitEvent:(UIGestureRecognizer *)gestureRecognizer {
    __weak typeof(self) weakSelf = self;
    if ([self.delegate respondsToSelector:@selector(didTapCellPortrait:)]) {
        [self.delegate didTapCellPortrait:weakSelf.model.senderUserId];
    }
}

- (void)longPressUserPortaitEvent:(UIGestureRecognizer *)gestureRecognizer {
    __weak typeof(self) weakSelf = self;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if ([self.delegate respondsToSelector:@selector(didLongPressCellPortrait:)]) {
            [self.delegate didLongPressCellPortrait:weakSelf.model.senderUserId];
        }
    }
}

- (void)longPressedMessageContentView:(id)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        [self.delegate didLongTouchMessageCell:self.model inView:self.messageContentView];
    }
}

- (void)didTapMessageContentView{
    DebugLog(@"%s", __FUNCTION__);
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
        [self.delegate didTapMessageCell:self.model];
    }
}

#pragma mark - Getter && Setter
- (UIButton *)receiptView {
    if (!_receiptView) {
        _receiptView = [[UIButton alloc] init];
        [_receiptView setImage:RCResourceImage(@"message_read_status") forState:UIControlStateNormal];
        [_receiptView addTarget:self
                         action:@selector(enableShowReceiptView:)
               forControlEvents:UIControlEventTouchUpInside];
        _receiptView.userInteractionEnabled = NO;
        _receiptView.hidden = YES;
    }
    return _receiptView;
}

- (UILabel *)receiptStatusLabel {
    if (!_receiptStatusLabel) {
        _receiptStatusLabel = [[UILabel alloc] init];
        _receiptStatusLabel.textAlignment = [RCKitUtility isRTL] ? NSTextAlignmentLeft : NSTextAlignmentRight;
        _receiptStatusLabel.font = [[RCKitConfig defaultConfig].font fontOfAssistantLevel];
        _receiptStatusLabel.textColor = RCDYCOLOR(0x0099ff, 0x595959);
        _receiptStatusLabel.hidden = YES;
        UITapGestureRecognizer *clickReceiptCountView =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickReceiptCountView:)];
        [_receiptStatusLabel addGestureRecognizer:clickReceiptCountView];
    }
    return _receiptStatusLabel;
}

- (UIView *)destructView {
    if (!_destructView) {
        _destructView = [[UIView alloc] init];
        _destructView.backgroundColor = [UIColor clearColor];
        _destructView.hidden = YES;
    }
    return _destructView;
}

- (UIButton *)destructBtn {
    if (_destructBtn == nil) {
        _destructBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_destructBtn setTitleColor:RCDYCOLOR(0xffffff, 0x11111) forState:UIControlStateNormal];
        _destructBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        _destructBtn.layer.cornerRadius = 10.f;
        _destructBtn.layer.masksToBounds = YES;
        _destructBtn.userInteractionEnabled = NO;
        _destructBtn.titleLabel.font = [[RCKitConfig defaultConfig].font fontOfAssistantLevel];
    }
    return _destructBtn;
}

- (UIActivityIndicatorView *)messageActivityIndicatorView {
    if (!_messageActivityIndicatorView) {
        if (@available(iOS 13.0, *)) {
            _messageActivityIndicatorView =
                [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        } else {
            _messageActivityIndicatorView =
                [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        }
         _messageActivityIndicatorView.hidden = YES;
    }
    return _messageActivityIndicatorView;
}

- (RCButton *)messageFailedStatusView{
    if (!_messageFailedStatusView) {
        _messageFailedStatusView = [[RCButton alloc] init];
        [_messageFailedStatusView setImage:RCResourceImage(@"sendMsg_failed_tip") forState:UIControlStateNormal];
        _messageFailedStatusView.hidden = YES;
        [_messageFailedStatusView addTarget:self
                                     action:@selector(didClickMsgFailedView:)
                           forControlEvents:UIControlEventTouchUpInside];
    }
    return _messageFailedStatusView;
}

- (RCloudImageView *)portraitImageView{
    if (!_portraitImageView) {
        _portraitImageView = [[RCloudImageView alloc] initWithPlaceholderImage:RCResourceImage(@"default_portrait_msg")];
        //点击头像
        UITapGestureRecognizer *portraitTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapUserPortaitEvent:)];
        portraitTap.numberOfTapsRequired = 1;
        portraitTap.numberOfTouchesRequired = 1;
        [_portraitImageView addGestureRecognizer:portraitTap];

        UILongPressGestureRecognizer *portraitLongPress =
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressUserPortaitEvent:)];
        [_portraitImageView addGestureRecognizer:portraitLongPress];

        _portraitImageView.userInteractionEnabled = YES;
    }
    return _portraitImageView;
}

- (UILabel *)nicknameLabel{
    if (!_nicknameLabel) {
        _nicknameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _nicknameLabel.backgroundColor = [UIColor clearColor];
        [_nicknameLabel setFont:[[RCKitConfig defaultConfig].font fontOfAnnotationLevel]];
        [_nicknameLabel
            setTextColor:[RCKitUtility generateDynamicColor:[UIColor grayColor] darkColor:HEXCOLOR(0x707070)]];
    }
    return _nicknameLabel;
}

- (UIView *)statusContentView{
    if (!_statusContentView) {
        _statusContentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, StatusContentViewWidth, StatusContentViewWidth)];
        _statusContentView.backgroundColor = [UIColor clearColor];
    }
    return _statusContentView;
}

- (RCContentView *)messageContentView{
    if (!_messageContentView) {
        _messageContentView = [[RCContentView alloc] init];
        UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressedMessageContentView:)];
        [_messageContentView addGestureRecognizer:longPress];

        UITapGestureRecognizer *tap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapMessageContentView)];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        [_messageContentView addGestureRecognizer:tap];
        _messageContentView.userInteractionEnabled = YES;
    }
    return _messageContentView;
}

- (UIImageView *)bubbleBackgroundView{
    if (!_bubbleBackgroundView) {
        _bubbleBackgroundView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.messageContentView addSubview:self.bubbleBackgroundView];
    }
    return _bubbleBackgroundView;
}

@end
