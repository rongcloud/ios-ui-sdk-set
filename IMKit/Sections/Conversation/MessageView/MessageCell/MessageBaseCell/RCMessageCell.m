//
//  RCMessageCell.m
//  RongIMKit
//
//  Created by xugang on 15/1/28.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCMessageCell.h"
#import "RCMessageCell+Edit.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCUserInfoCacheManager.h"
#import "RCloudImageView.h"
#import "RCAlertView.h"
#import "RCKitConfig.h"
#import "RCMessageCellTool.h"
#import "RCResendManager.h"
#import "RCCoreClient+Destructing.h"
#import <RongPublicService/RongPublicService.h>
#import "RCIM.h"
#import "RCMessageModel+StreamCellVM.h"
#import "RCMessageModel+RRS.h"
#import "RCRRSUtil.h"

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
//当前 cell 正在展示的用户信息，消息携带用户信息且频发发送，会导致 cell 频发刷新
//cell 复用的时候，检测如果是即将刷新的是同一个用户信息，那么就跳过刷新
//IMSDK-2705
@property (nonatomic, strong) RCUserInfo *currentDisplayedUserInfo;

@property (nonatomic, weak, readwrite) UICollectionView *hostCollectionView;

/// 消息编辑状态
@property (nonatomic, assign) RCMessageModifyStatus editStatus;

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
    [self p_showBubbleBackgroundView];
    self.messageFailedStatusView.hidden = YES;
    [self p_setReadStatus];
    [self p_setUserInfo];
    [self setCellAutoLayout];
    [self messageDestructing];
    [self edit_showEditStatusIfNeeded];
    [self updateReadReceiptViewV5];
}

- (UICollectionView *)hostCollectionView {
    if (!_hostCollectionView) {
        _hostCollectionView = [self parentCollectionView];
    }
    return _hostCollectionView;
}
- (UICollectionView *)parentCollectionView {
    UIView *view = self.superview;
    while (view) {
        if ([view isKindOfClass:[UICollectionView class]]) {
            return (UICollectionView *)view;
        }
        view = view.superview;
    }
    return nil;
}
#pragma mark - Public Methods

- (void)updateStatusContentView:(RCMessageModel *)model {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.messageActivityIndicatorView.hidden = YES;
        if (model.messageDirection == MessageDirection_RECEIVE) {
            return;
        }
        switch (model.sentStatus) {
            case SentStatus_SENDING:
                [self updateStatusContentViewForSending:model];
                break;
            case SentStatus_FAILED:
                [self updateStatusContentViewForFailed:model];
                break;
            case SentStatus_CANCELED:
                [self updateStatusContentViewForCanceled:model];
                break;
            case SentStatus_SENT:
                [self updateStatusContentViewForSent:model];
                break;
            case SentStatus_READ:
                [self updateStatusContentViewForRead:model];
                break;
            default:
                break;
        }
    });
}

- (void)updateStatusContentViewForSending:(RCMessageModel *)model {
    self.messageFailedStatusView.hidden = YES;
    if (self.messageActivityIndicatorView) {
        self.messageActivityIndicatorView.hidden = NO;
        if (self.messageActivityIndicatorView.isAnimating == NO) {
            [self.messageActivityIndicatorView startAnimating];
        }
    }
}

- (void)updateStatusContentViewForFailed:(RCMessageModel *)model {
    self.receiptView.hidden = YES;
    self.receiptStatusLabel.hidden = YES;
    self.messageFailedStatusView.hidden = YES;
    if ([[RCResendManager sharedManager] needResend:model.messageId]) {
        if (self.messageActivityIndicatorView) {
            self.messageActivityIndicatorView.hidden = NO;
            if (self.messageActivityIndicatorView.isAnimating == NO) {
                [self.messageActivityIndicatorView startAnimating];
            }
        }
    } else {
        self.messageFailedStatusView.hidden = NO;
        if (self.messageActivityIndicatorView) {
            self.messageActivityIndicatorView.hidden = YES;
            if (self.messageActivityIndicatorView.isAnimating == YES) {
                [self.messageActivityIndicatorView stopAnimating];
            }
        }
    }
}

- (void)updateStatusContentViewForCanceled:(RCMessageModel *)model {
    self.messageFailedStatusView.hidden = YES;
    if (self.messageActivityIndicatorView) {
        self.messageActivityIndicatorView.hidden = YES;
        if (self.messageActivityIndicatorView.isAnimating == YES) {
            [self.messageActivityIndicatorView stopAnimating];
        }
    }
}

- (void)updateStatusContentViewForSent:(RCMessageModel *)model {
    self.messageFailedStatusView.hidden = YES;
    if (self.messageActivityIndicatorView) {
        self.messageActivityIndicatorView.hidden = YES;
        if (self.messageActivityIndicatorView.isAnimating == YES) {
            [self.messageActivityIndicatorView stopAnimating];
        }
    }
    // 已读 v5 处理逻辑
    if ([RCRRSUtil isSupportReadReceiptV5]) {
        [self updateReadReceiptViewV5];
    } else if (model.isCanSendReadReceipt) {
        self.receiptView.hidden = NO;
        self.receiptView.userInteractionEnabled = YES;
        self.receiptStatusLabel.hidden = YES;
    } else {
        self.receiptView.hidden = YES;
        self.receiptStatusLabel.hidden = NO;
    }
}

- (void)updateStatusContentViewForRead:(RCMessageModel *)model {
    if ([RCRRSUtil isSupportReadReceiptV5]) {
        return;
    }
    BOOL isDisplayReadStatus = self.isDisplayReadStatus;
    BOOL isReadStatusType = model.conversationType == ConversationType_PRIVATE ||
    model.conversationType == ConversationType_Encrypted;
    if (!isDisplayReadStatus || !isReadStatusType) {
        return;
    }
    if (model.messageUId.length > 0) {
        self.receiptStatusLabel.hidden = YES;
        self.receiptStatusLabel.userInteractionEnabled = NO;
        self.receiptView.hidden = NO;
    }
    self.messageFailedStatusView.hidden = YES;
    if (self.messageActivityIndicatorView) {
        self.messageActivityIndicatorView.hidden = YES;
        if (self.messageActivityIndicatorView.isAnimating == YES) {
            [self.messageActivityIndicatorView stopAnimating];
        }
    }
}

- (void)updateReadReceiptViewV5 {
    if (![self.model rrs_shouldFetchReadReceiptV5]) {
        return;
    }
    
    RCReadReceiptInfoV5 *readReceiptInfoV5 = self.model.readReceiptInfoV5;
    
    if (readReceiptInfoV5.readCount == 0) {
        self.receiptView.hidden = NO;
        self.receiptProgressView.hidden = YES;
        self.receiptView.userInteractionEnabled = YES;
        
        // 未读状态，显示未读图标
        UIImage *image = RCDynamicImage(@"conversation_msg_rrs_v5_unread_gray_img", @"msg_rrs_v5_unread_gray");
        [self.receiptView setImage:image forState:UIControlStateNormal];
    } else if (readReceiptInfoV5.readCount > 0 && readReceiptInfoV5.unreadCount == 0) {
        // 100% 全部已读，显示已读图标
        self.receiptView.hidden = NO;
        self.receiptProgressView.hidden = YES;
        self.receiptView.userInteractionEnabled = YES;
        
        UIImage *image = RCDynamicImage(@"conversation_msg_rrs_v5_read_img", @"msg_rrs_v5_read");
        [self.receiptView setImage:image forState:UIControlStateNormal];
    } else {
        // 部分已读，显示进度视图
        self.receiptView.hidden = YES;
        self.receiptProgressView.hidden = NO;
        NSInteger totalCount = readReceiptInfoV5.readCount + readReceiptInfoV5.unreadCount;
        CGFloat progress = totalCount > 0 ? (CGFloat)readReceiptInfoV5.readCount / (CGFloat)totalCount : 0;
        self.receiptProgressView.progress = progress;
    }
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
    [self.statusContentView addSubview:self.receiptProgressView];
    
    [self.baseContentView addSubview:self.editStatusContentView];
    [self.editStatusContentView addSubview:self.editStatusLabel];
    [self.editStatusContentView addSubview:self.editRetryButton];
    [self.editStatusContentView addSubview:self.editCircularLoadingView];
    
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
    
    [self registerFrameUpdateLayoutIfNeed];
    [self registerSizeUpdateLayoutIfNeed];
    
}

- (void)registerFrameUpdateLayoutIfNeed{
    __weak typeof(self) weakSelf = self;
    [self.messageContentView registerFrameChangedEvent:^(CGRect frame) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.model) {
            if ([RCKitUtility isRTL]) {
                if (strongSelf.model.messageDirection == MessageDirection_SEND) {
                    CGRect statusFrame = CGRectMake(CGRectGetMaxX(frame)+StatusViewAndContentViewSpace, frame.origin.y, StatusContentViewWidth, frame.size.height);
                    strongSelf.statusContentView.frame = statusFrame;
                    strongSelf.receiptStatusLabel.frame = CGRectMake(0 , statusFrame.size.height - 12,statusFrame.size.width, 12);
                    
                    [strongSelf setupReceiptViewFrame:statusFrame];
                    
                    strongSelf.messageFailedStatusView.frame = CGRectMake(0, (statusFrame.size.height-16)/2, 16, 16);
                } else {
                    CGRect statusFrame = CGRectMake(frame.origin.x - StatusContentViewWidth-StatusViewAndContentViewSpace, frame.origin.y, StatusContentViewWidth, frame.size.height);
                    strongSelf.statusContentView.frame = statusFrame;
                    strongSelf.messageFailedStatusView.frame = CGRectMake(statusFrame.size.width-16, (statusFrame.size.height-16)/2, 16, 16);
                }
                strongSelf.messageActivityIndicatorView.frame = strongSelf.messageFailedStatusView.frame;
            } else {
                if (strongSelf.model.messageDirection == MessageDirection_SEND) {
                    CGRect statusFrame = CGRectMake(frame.origin.x - StatusContentViewWidth-StatusViewAndContentViewSpace, frame.origin.y, StatusContentViewWidth, frame.size.height);
                    strongSelf.statusContentView.frame = statusFrame;
                    strongSelf.receiptStatusLabel.frame = CGRectMake(0 , statusFrame.size.height - 12,statusFrame.size.width, 12);
                    
                    [strongSelf setupReceiptViewFrame:statusFrame];
                    
                    strongSelf.messageFailedStatusView.frame = CGRectMake(statusFrame.size.width-16, (statusFrame.size.height-16)/2, 16, 16);
                    strongSelf.messageActivityIndicatorView.frame = strongSelf.messageFailedStatusView.frame;
                } else {
                    CGRect statusFrame = CGRectMake(CGRectGetMaxX(frame)+StatusViewAndContentViewSpace, frame.origin.y, StatusContentViewWidth, frame.size.height);
                    strongSelf.statusContentView.frame = statusFrame;
                    strongSelf.messageFailedStatusView.frame = CGRectMake(0, (statusFrame.size.height-16)/2, 16, 16);
                    strongSelf.messageActivityIndicatorView.frame = strongSelf.messageFailedStatusView.frame;
                }
            }
            
            if (strongSelf.showBubbleBackgroundView) {
                strongSelf.bubbleBackgroundView.frame = strongSelf.messageContentView.bounds;
            }
        }
    }];
}

- (void)registerSizeUpdateLayoutIfNeed{
    __weak typeof(self) weakSelf = self;
    [self.messageContentView registerSizeChangedEvent:^(CGSize size) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.model){
            CGRect rect = CGRectMake(0, 0, size.width, size.height);
            CGFloat protraitWidth = RCKitConfigCenter.ui.globalMessagePortraitSize.width;

            if ([RCKitUtility isRTL]) {
                if(strongSelf.model.messageDirection == MessageDirection_RECEIVE) {
                    if (strongSelf.showPortrait) {
                        rect.origin.x = strongSelf.baseContentView.bounds.size.width - (size.width + HeadAndContentSpacing + protraitWidth + PortraitViewEdgeSpace);
                    } else {
                        rect.origin.x = strongSelf.baseContentView.bounds.size.width - (size.width + PortraitViewEdgeSpace);
                    }
                    rect.origin.y = PortraitImageViewTop;
                    if (strongSelf.model.isDisplayNickname) {
                        rect.origin.y = PortraitImageViewTop + NameHeight + NameAndContentSpace;
                    }
                } else {
                    if (strongSelf.showPortrait) {
                        rect.origin.x = PortraitViewEdgeSpace + protraitWidth + HeadAndContentSpacing;
                    } else {
                        rect.origin.x = PortraitViewEdgeSpace;
                    }
                    rect.origin.y = PortraitImageViewTop;
                }
            } else {
                if(strongSelf.model.messageDirection == MessageDirection_RECEIVE) {
                    if (strongSelf.showPortrait) {
                        rect.origin.x = PortraitViewEdgeSpace + protraitWidth + HeadAndContentSpacing;
                    } else {
                        rect.origin.x = PortraitViewEdgeSpace;
                    }
                    CGFloat messageContentViewY = PortraitImageViewTop;
                    if (strongSelf.model.isDisplayNickname) {
                        messageContentViewY = PortraitImageViewTop + NameHeight + NameAndContentSpace;
                    }
                    rect.origin.y = messageContentViewY;
                } else {
                    if (strongSelf.showPortrait) {
                        rect.origin.x = strongSelf.baseContentView.bounds.size.width - (size.width + HeadAndContentSpacing + protraitWidth + PortraitViewEdgeSpace);
                    } else {
                        rect.origin.x = strongSelf.baseContentView.bounds.size.width - (size.width + PortraitViewEdgeSpace);
                    }
                    
                    rect.origin.y = PortraitImageViewTop;
                }
            }
            strongSelf.messageContentView.frame = rect;
            [strongSelf setDestructViewLayout];
        }
    }];
}

- (void)setupReceiptViewFrame:(CGRect)statusFrame {
    // 判断是否为私聊或加密会话
    BOOL isPrivateOrEncrypted = (self.model.conversationType == ConversationType_PRIVATE || 
                                  self.model.conversationType == ConversationType_Encrypted);
    
    // 根据会话类型确定尺寸和图片
    CGFloat size = isPrivateOrEncrypted ? 16 : 14;
    UIImage *receiptImage = isPrivateOrEncrypted ? 
        RCDynamicImage(@"conversation_msg_cell_msg_read_img", @"message_read_status") :
        RCDynamicImage(@"conversation_msg_cell_receipt_img", @"receipt");

    if ([RCRRSUtil isSupportReadReceiptV5]) {
        size = 12;
        receiptImage = RCDynamicImage(@"conversation_msg_rrs_v5_unread_gray_img", @"msg_rrs_v5_unread_gray");
    }
    // 计算位置
    CGFloat y = statusFrame.size.height - size;
    CGFloat x = [RCKitUtility isRTL] ? 0 : (StatusContentViewWidth - size);
    
    // 设置 frame 和图片
    self.receiptView.frame = CGRectMake(x, y, size, size);
    [self.receiptView setImage:receiptImage forState:UIControlStateNormal];
    
    if ([RCRRSUtil isSupportReadReceiptV5]) {
        // 已读回执 V5 需要设置已读进度视图的 frame
        self.receiptProgressView.frame = CGRectMake(x, y, size, size);
    }
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
    
    CGRect nicknameFrame = self.nicknameLabel.frame;
    CGRect contentFrame = self.messageContentView.frame;
    CGSize size = contentFrame.size;
    if ([RCKitUtility isRTL]) {
        // receiver
        if (MessageDirection_RECEIVE == self.model.messageDirection) {
            CGFloat nameOffset_X = 0;
            if (self.showPortrait) {
                contentFrame.origin.x = self.baseContentView.bounds.size.width - (size.width + HeadAndContentSpacing + protraitWidth + PortraitViewEdgeSpace);
                nameOffset_X = self.portraitImageView.frame.origin.x - DefaultMessageContentViewWidth - HeadAndContentSpacing;
            } else {
                nameOffset_X = self.baseContentView.bounds.size.width - (DefaultMessageContentViewWidth + PortraitViewEdgeSpace);
                contentFrame.origin.x = self.baseContentView.bounds.size.width - (size.width + PortraitViewEdgeSpace);
            }
            nicknameFrame.origin.x = nameOffset_X;
        } else { // owner
            if (self.showPortrait) {
                contentFrame.origin.x = PortraitViewEdgeSpace + protraitWidth + HeadAndContentSpacing;
            } else {
                contentFrame.origin.x = PortraitViewEdgeSpace;
            }
            
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
            [self.nicknameLabel setTextAlignment:NSTextAlignmentRight];
            self.nicknameLabel.hidden = !self.model.isDisplayNickname;
            CGFloat portraitImageX = self.baseContentView.bounds.size.width - (protraitWidth + PortraitViewEdgeSpace);
            self.portraitImageView.frame = CGRectMake(portraitImageX, PortraitImageViewTop, protraitWidth, protraitHeight);
            if (self.showPortrait) {
                self.nicknameLabel.frame = CGRectMake(portraitImageX - DefaultMessageContentViewWidth - HeadAndContentSpacing, PortraitImageViewTop, DefaultMessageContentViewWidth, NameHeight);
            } else {
                self.nicknameLabel.frame = CGRectMake(self.baseContentView.bounds.size.width - (DefaultMessageContentViewWidth + PortraitViewEdgeSpace), PortraitImageViewTop, DefaultMessageContentViewWidth, NameHeight);
            }
        } else { // owner
            self.nicknameLabel.hidden = YES;
            CGFloat portraitImageX = PortraitViewEdgeSpace;
            self.portraitImageView.frame = CGRectMake(portraitImageX, PortraitImageViewTop, protraitWidth, protraitHeight);
        }
        self.messageContentView.contentSize = CGSizeMake(DefaultMessageContentViewWidth,self.baseContentView.bounds.size.height - ContentViewBottom);
    } else {
        // receiver
           if (MessageDirection_RECEIVE == self.model.messageDirection) {
               [self.nicknameLabel setTextAlignment:NSTextAlignmentLeft];
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
        [[RCCoreClient sharedCoreClient] getDestructMessageRemainDuration:self.model.messageUId];
    if (whisperMsgDuration == nil) {
        [self.destructBtn setTitle:@"" forState:UIControlStateNormal];
        [self.destructBtn setImage:RCDynamicImage(@"conversation_msg_cell_fire_identify_img",@"fire_identify") forState:UIControlStateNormal];
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
        self.destructBtn.backgroundColor = RCDynamicColor(@"common_background_color", @"0xf4b50b", @"0xf4b50b");
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
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_READ_RECEIPT_INFO_V5]) {
            self.model.readReceiptInfoV5 = notifyModel.readReceiptInfoV5;
            [self updateReadReceiptViewV5];
        }
    }
}

- (void)sendMessageReadReceiptRequest:(NSString *)messageUId {
    RCMessage *message = [[RCCoreClient sharedCoreClient] getMessage:self.model.messageId];
    if (message) {
        if (!messageUId || [messageUId isEqualToString:@""]) {
            return;
        }
        [[RCCoreClient sharedCoreClient] sendReadReceiptRequest:message success:^{
            self.model.isCanSendReadReceipt = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.receiptView.hidden = YES;
                self.receiptView.userInteractionEnabled = NO;
                self.receiptStatusLabel.hidden = NO;
                self.receiptStatusLabel.userInteractionEnabled = YES;
                self.receiptStatusLabel.text =
                [NSString stringWithFormat:RCLocalizedString(@"readNum"), 0];
                if (!self.model.readReceiptInfo) {
                    self.model.readReceiptInfo = [[RCReadReceiptInfo alloc] init];
                }
                self.model.readReceiptInfo.isReceiptRequestMessage = YES;
                if ([self.delegate respondsToSelector:@selector(didTapNeedReceiptView:)]) {
                    [self.delegate didTapNeedReceiptView:self.model];
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

- (void)p_showBubbleBackgroundView{
    if (self.showBubbleBackgroundView) {
        self.bubbleBackgroundView.image = [self getDefaultMessageCellBackgroundImage];
    }
}

- (UIImage *)getDefaultMessageCellBackgroundImage {
    UIImage *bubbleImage;
    
    // 根据消息方向选择对应的气泡背景图片
    if (MessageDirection_RECEIVE == self.model.messageDirection) {
        bubbleImage = RCDynamicImage(@"conversation_msg_cell_bg_from_img", @"chat_from_bg_normal");
    } else {
        // 根据消息类型判断是否使用白色气泡
        NSArray *whiteBackgroundMessageTypes = @[@"RC:FileMsg", @"RC:CardMsg", @"RC:LBSMsg", @"RC:CombineMsg"];
        if ([RCKitUtility isTraditionInnerThemes]) { // 传统模式不包含合并转发消息
            whiteBackgroundMessageTypes = @[@"RC:FileMsg", @"RC:CardMsg", @"RC:LBSMsg"];
        }
        if ([whiteBackgroundMessageTypes containsObject:self.model.objectName]) {
            bubbleImage = RCDynamicImage(@"conversation_msg_cell_bg_white_img", @"chat_to_bg_white");
        } else {
            bubbleImage = RCDynamicImage(@"conversation_msg_cell_bg_to_img", @"chat_to_bg_normal");
        }
    }
    
    // 处理RTL布局
    if ([RCKitUtility isRTL]) {
        bubbleImage = [bubbleImage imageFlippedForRightToLeftLayoutDirection];
    }
    
    // 处理动态图片的resizable操作
    if (bubbleImage.imageAsset) {
        // 对于动态图片，需要先获取当前trait对应的图片再应用resizable
        UIImage *currentTraitImage = [bubbleImage.imageAsset imageWithTraitCollection:self.traitCollection];
        bubbleImage = [self applyResizableCapInsets:currentTraitImage];
    } else {
        // 对于静态图片，直接应用resizable
        bubbleImage = [self applyResizableCapInsets:bubbleImage];
    }
    
    return bubbleImage;
}

#pragma mark - Private Helper Methods

- (UIImage *)applyResizableCapInsets:(UIImage *)image {
    if (!image) return nil;
    
    CGFloat halfWidth = image.size.width * 0.5;
    CGFloat halfHeight = image.size.height * 0.5;
    UIEdgeInsets capInsets = UIEdgeInsetsMake(halfHeight, halfWidth, halfHeight, halfWidth);
    
    return [image resizableImageWithCapInsets:capInsets];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    // iOS 13+ 深色模式支持
    if (@available(iOS 13.0, *)) {
        if (previousTraitCollection && 
            [previousTraitCollection hasDifferentColorAppearanceComparedToTraitCollection:self.traitCollection]) {
            // 当系统外观模式发生变化时，更新气泡背景图片
            [self p_showBubbleBackgroundView];
        }
    }
}

- (void)p_setReadStatus{
    if ([RCRRSUtil isSupportReadReceiptV5]) {
        self.receiptView.hidden = YES;
        self.receiptView.userInteractionEnabled = NO;
        self.receiptProgressView.hidden = YES;
        self.receiptStatusLabel.hidden = YES;
        self.receiptStatusLabel = nil;
        return;
    }
    if (self.model.readReceiptInfo.isReceiptRequestMessage && self.model.messageDirection == MessageDirection_SEND && [RCKitConfigCenter.message.enabledReadReceiptConversationTypeList containsObject:@(self.model.conversationType)]) {
        self.receiptStatusLabel.hidden = NO;
        self.receiptStatusLabel.userInteractionEnabled = YES;
        self.receiptStatusLabel.text = [NSString
            stringWithFormat:RCLocalizedString(@"readNum"), self.model.readReceiptCount];
    } else {
        self.receiptStatusLabel.hidden = YES;
        self.receiptStatusLabel.userInteractionEnabled = NO;
        self.receiptStatusLabel.text = nil;
    }

    if (self.model.messageDirection == MessageDirection_SEND && self.model.sentStatus == SentStatus_SENT) {
        if (self.model.isCanSendReadReceipt) {
            self.receiptView.hidden = NO;
            self.receiptView.userInteractionEnabled = YES;
            self.receiptStatusLabel.hidden = YES;
        } else {
            self.receiptView.hidden = YES;
            self.receiptStatusLabel.hidden = NO;
        }
    }else{
        self.receiptView.hidden = YES;
    }
}

- (void)p_setUserInfo{
    RCMessageModel *model = self.model;
    // DebugLog(@"%s", __FUNCTION__);
    //如果是客服，更换默认头像
    if (ConversationType_CUSTOMERSERVICE == model.conversationType) {
        [self p_setCustomerServiceInfo:model];
    } else if (ConversationType_APPSERVICE == model.conversationType ||
               ConversationType_PUBLICSERVICE == model.conversationType) {
        [self p_setPublicServiceInfo:model];
    } else if (ConversationType_GROUP == model.conversationType) {
        [self p_setGroupInfo:model];
    } else {
        //优先使用 RCMessage.senderUserId 确定用户，控制头像的显示
        //否则使用 RCMessage.content.senderUserInfo.userId 确定用户，控制头像的显示
        NSString *userId = model.senderUserId;
        if (userId.length <= 0) {
            userId = model.content.senderUserInfo.userId;
        }
        
        if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement && [model.content.senderUserInfo.userId isEqualToString:model.senderUserId]) {
            if (model.conversationType != ConversationType_Encrypted) {
                [self.portraitImageView setImageURL:[NSURL URLWithString:model.content.senderUserInfo.portraitUri]];
            }
            [self.nicknameLabel setText:[RCKitUtility getDisplayName:model.content.senderUserInfo]];

        } else {
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
    }
}

- (void)p_setCustomerServiceInfo:(RCMessageModel *)model{
    if (model.messageDirection == MessageDirection_RECEIVE) {
        UIImage *image = RCDynamicImage(@"conversation-list_cell_portrait_kefu_img",@"portrait_kefu");
        [self.portraitImageView setPlaceholderImage:image];

        model.userInfo = model.content.senderUserInfo;
        if (model.content.senderUserInfo != nil) {
            [self.portraitImageView setImageURL:[NSURL URLWithString:model.content.senderUserInfo.portraitUri]];
            [self.nicknameLabel setText:[RCKitUtility getDisplayName:model.content.senderUserInfo]];
        } else {
            UIImage *image = RCDynamicImage(@"conversation-list_cell_portrait_kefu_img",@"portrait_kefu");
            [self.portraitImageView setImage:image];
            [self.nicknameLabel setText:nil];
        }
    } else {
        RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId];
        model.userInfo = userInfo;
        [self.portraitImageView setPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
        if (userInfo) {
            [self.portraitImageView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
            [self.nicknameLabel setText:[RCKitUtility getDisplayName:userInfo]];
        } else {
            [self.portraitImageView setImageURL:nil];
            [self.nicknameLabel setText:nil];
        }
    }
}

- (void)p_setPublicServiceInfo:(RCMessageModel *)model{
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
}

- (void)p_setGroupInfo:(RCMessageModel *)model{
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement && [model.content.senderUserInfo.userId isEqualToString:model.senderUserId]) {
        if (model.conversationType != ConversationType_Encrypted) {
            [self.portraitImageView setImageURL:[NSURL URLWithString:model.content.senderUserInfo.portraitUri]];
        }
        [self.nicknameLabel setText:[RCKitUtility getDisplayName:model.content.senderUserInfo]];
        return;
    }
    RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId inGroupId:self.model.targetId];
    RCUserInfo *tempUserInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:model.senderUserId];
    if (userInfo) {
        userInfo.alias = tempUserInfo.alias.length > 0 ? tempUserInfo.alias : userInfo.alias;
        model.userInfo = userInfo;
    } else {
        model.userInfo = tempUserInfo;
    }
    if (model.userInfo) {
        [self.portraitImageView setImageURL:[NSURL URLWithString:model.userInfo.portraitUri]];
        [self.nicknameLabel setText:[RCKitUtility getDisplayName:model.userInfo]];
    } else {
        [self.portraitImageView setImageURL:nil];
        [self.nicknameLabel setText:nil];
    }
}

#pragma mark - UserInfo Update
- (void)onUserInfoUpdate:(NSNotification *)notification {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement && [self.model.content.senderUserInfo.userId isEqualToString:self.model.senderUserId]) {
        return;
    }
    NSDictionary *userInfoDic = notification.object;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.model.senderUserId isEqualToString:userInfoDic[@"userId"]]) {
            if (self.model.conversationType == ConversationType_GROUP) {
                //重新取一下混合的用户信息
                RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:self.model.senderUserId inGroupId:self.model.targetId];
                RCUserInfo *tempUserInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:self.model.senderUserId];
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
    });
}

- (void)onGroupUserInfoUpdate:(NSNotification *)notification {
    if ([RCIM sharedRCIM].currentDataSourceType == RCDataSourceTypeInfoManagement && [self.model.content.senderUserInfo.userId isEqualToString:self.model.senderUserId]) {
        return;
    }
    if (self.model.conversationType == ConversationType_GROUP) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *groupUserInfoDic = (NSDictionary *)notification.object;
            if ([self.model.targetId isEqualToString:groupUserInfoDic[@"inGroupId"]] &&
                [self.model.senderUserId isEqualToString:groupUserInfoDic[@"userId"]]) {
                //重新取一下混合的用户信息
                RCUserInfo *userInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:self.model.senderUserId inGroupId:self.model.targetId];
                RCUserInfo *tempUserInfo = [[RCUserInfoCacheManager sharedManager] getUserInfo:self.model.senderUserId];
                userInfo.alias = tempUserInfo.alias;
                [self updateUserInfoUI:userInfo];
            }
        });
    }
}

- (void)updateUserInfoUI:(RCUserInfo *)userInfo {
    if ([self isSameUserInfo:self.currentDisplayedUserInfo other:userInfo]) {
        return;
    }
    self.currentDisplayedUserInfo = userInfo;
    
    self.model.userInfo = userInfo;
    if (userInfo.portraitUri.length > 0) {
        [self.portraitImageView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
    }
    [self.nicknameLabel setText:[RCKitUtility getDisplayName:userInfo]];
}

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
    if ([RCRRSUtil isSupportReadReceiptV5]) {
        [self didTapReceiptStatusView:sender];
        return;
    }
    if (!self.model.messageUId) {
        RCMessage *message = [[RCCoreClient sharedCoreClient] getMessage:self.model.messageId];
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

- (void)didTapReceiptStatusView:(id)sender {
    if (self.model.conversationType != ConversationType_GROUP) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(didTapReceiptStatusView:)]) {
        [self.delegate didTapReceiptStatusView:self.model];
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
- (RCBaseButton *)receiptView {
    if (!_receiptView) {
        _receiptView = [[RCBaseButton alloc] init];
        [_receiptView setImage:RCDynamicImage(@"conversation_msg_cell_msg_read_img", @"message_read_status")
                      forState:UIControlStateNormal];
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
        _receiptStatusLabel.textColor = RCDynamicColor(@"primary_color", @"0x0099ff", @"0x595959");
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

- (RCBaseButton *)destructBtn {
    if (_destructBtn == nil) {
        _destructBtn = [[RCBaseButton alloc] initWithFrame:CGRectZero];
        [_destructBtn setTitleColor:RCDynamicColor(@"hint_color", @"0xffffff", @"0x111111") forState:UIControlStateNormal];
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
        [_messageFailedStatusView setImage:RCDynamicImage(@"conversation_msg_cell_msg_fail_img",@"sendMsg_failed_tip")
                                  forState:UIControlStateNormal];
        _messageFailedStatusView.hidden = YES;
        [_messageFailedStatusView addTarget:self
                                     action:@selector(didClickMsgFailedView:)
                           forControlEvents:UIControlEventTouchUpInside];
    }
    return _messageFailedStatusView;
}

- (RCloudImageView *)portraitImageView{
    if (!_portraitImageView) {
        _portraitImageView = [[RCloudImageView alloc] initWithPlaceholderImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
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
            setTextColor: RCDynamicColor(@"text_secondary_color", @"0x808080", @"0x707070")];
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

- (RCBaseImageView *)bubbleBackgroundView{
    if (!_bubbleBackgroundView) {
        _bubbleBackgroundView = [[RCBaseImageView alloc] initWithFrame:CGRectZero];
        [self.messageContentView addSubview:self.bubbleBackgroundView];
    }
    return _bubbleBackgroundView;
}

#pragma mark - Edit

- (UIView *)editStatusContentView {
    if (!_editStatusContentView) {
        _editStatusContentView = [[UIView alloc] init];
        _editStatusContentView.hidden = YES;
    }
    return _editStatusContentView;
}

- (RCCircularLoadingView *)editCircularLoadingView {
    if (!_editCircularLoadingView) {
        _editCircularLoadingView = [[RCCircularLoadingView alloc] init];
        _editCircularLoadingView.hidden = YES;
    }
    return _editCircularLoadingView;
}

- (UILabel *)editStatusLabel {
    if (!_editStatusLabel) {
        _editStatusLabel = [[UILabel alloc] init];
        _editStatusLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        _editStatusLabel.textColor = RCDynamicColor(@"primary_color", @"0x007AFF", @"0x007AFF");
        _editStatusLabel.textAlignment = NSTextAlignmentRight;
        _editStatusLabel.hidden = YES;
        _editStatusLabel.numberOfLines = 1;
        _editStatusLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _editStatusLabel;
}

- (UIButton *)editRetryButton {
    if (!_editRetryButton) {
        NSString *title = [NSString stringWithFormat:@" %@", RCLocalizedString(@"MessageEditFailed")];
        _editRetryButton = [[UIButton alloc] init];
        [_editRetryButton setImage:RCDynamicImage(@"conversation_msg_edit_retry_img", @"edit_retry") forState:UIControlStateNormal];
        [_editRetryButton setTitle:title forState:UIControlStateNormal];
        [_editRetryButton setTitleColor:RCDynamicColor(@"hint_color", @"0xFF5A50", @"0xFF5A50") forState:UIControlStateNormal];
        _editRetryButton.titleLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        [_editRetryButton addTarget:self action:@selector(edit_didTapEditRetryButton:) forControlEvents:UIControlEventTouchUpInside];
        _editRetryButton.hidden = YES;
    }
    return _editRetryButton;
}

- (RCReadReceiptProgressView *)receiptProgressView {
    if (!_receiptProgressView) {
        _receiptProgressView = [[RCReadReceiptProgressView alloc] init];
        _receiptProgressView.hidden = YES;
        _receiptProgressView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapReceiptStatusView:)];
        [_receiptProgressView addGestureRecognizer:tapGesture];
    }
    return _receiptProgressView;
}

@end
