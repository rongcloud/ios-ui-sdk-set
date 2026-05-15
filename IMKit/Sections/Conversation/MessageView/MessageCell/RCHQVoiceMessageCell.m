//
//  RCHQVoiceMessageCell.m
//  RongIMKit
//
//  Created by Zhaoqianyu on 2019/5/20.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCHQVoiceMessageCell.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCVoicePlayer.h"
#import "RCHQVoiceMsgDownloadManager.h"
#import "RCHQVoiceMsgDownloadInfo.h"
#import "RCMessageCellTool.h"
#import "RCSTTContentView.h"
#import "RCMessageModel+STT.h"
#import "RCReferencedContentView.h"

static NSTimer *hq_previousAnimationTimer = nil;
static UIImageView *hq_previousPlayVoiceImageView = nil;
static RCMessageDirection hq_previousMessageDirection;
static BOOL hq_previousShowsQuoteCard;

#define Voice_Height 40
#define voice_Unread_View_Width 8
#define Play_Voice_View_Width 16
#define QUOTE_CARD_HORIZONTAL_INSET 12
#define QUOTE_DIVIDER_HORIZONTAL_INSET 12
#define QUOTE_DIVIDER_TOP_SPACING 6
#define QUOTE_DIVIDER_HEIGHT 1
#define QUOTE_DIVIDER_BOTTOM_SPACING 10
#define QUOTE_BODY_BOTTOM_PADDING 10
#define QUOTE_VOICE_HORIZONTAL_INSET 12
#define QUOTE_VOICE_ICON_TEXT_SPACING 8

static CGFloat RCHQVoiceMessageQuoteContentOffset(RCMessageModel *model, CGFloat bubbleWidth) {
    CGFloat cardWidth = MAX(bubbleWidth - QUOTE_CARD_HORIZONTAL_INSET * 2, 0);
    CGFloat cardHeight = [RCReferencedContentView quoteCardHeightForMessageModel:model maxWidth:cardWidth];
    return RCQuoteCardTopMargin + cardHeight;
}

static CGFloat RCHQVoiceMessageQuoteBubbleWidth(RCMessageModel *model, CGFloat audioBubbleWidth) {
    CGFloat maxBubbleWidth = [RCMessageCellTool getMessageContentViewMaxWidth];
    CGFloat maxCardWidth = MAX(maxBubbleWidth - QUOTE_CARD_HORIZONTAL_INSET * 2, 0);
    CGSize quoteCardSize = [RCReferencedContentView quoteCardContentSizeForMessageModel:model maxWidth:maxCardWidth];
    CGFloat quoteWidth = quoteCardSize.width + QUOTE_CARD_HORIZONTAL_INSET * 2;
    return MIN(MAX(audioBubbleWidth, quoteWidth), maxBubbleWidth);
}

static CGFloat RCHQVoiceMessageQuoteBodyTopSpacing(void) {
    return QUOTE_DIVIDER_TOP_SPACING + QUOTE_DIVIDER_HEIGHT + QUOTE_DIVIDER_BOTTOM_SPACING;
}

static CGFloat RCHQVoiceMessageQuoteVoiceRowHeight(void) {
    return ceilf([[RCKitConfig defaultConfig].font fontOfSecondLevel].lineHeight);
}

static CGFloat RCHQVoiceMessageQuoteBodyHeight(void) {
    return RCHQVoiceMessageQuoteBodyTopSpacing() + RCHQVoiceMessageQuoteVoiceRowHeight() + QUOTE_BODY_BOTTOM_PADDING;
}

static UIImage *RCHQVoiceMessageVoiceImage(BOOL showsQuoteCard, RCMessageDirection direction, NSInteger index) {
    BOOL usesReceiveStyleImage = showsQuoteCard || direction == MessageDirection_RECEIVE;
    NSString *imageName = usesReceiveStyleImage ? [NSString stringWithFormat:@"from_voice_%ld", (long)index]
                                                : [NSString stringWithFormat:@"to_voice_%ld", (long)index];
    NSString *imageKey = usesReceiveStyleImage
        ? [NSString stringWithFormat:@"conversation_msg_cell_receive_voice_%ld_img", (long)index]
        : [NSString stringWithFormat:@"conversation_msg_cell_send_voice_%ld_img", (long)index];
    UIImage *image = RCDynamicImage(imageKey, imageName);
    if ([RCKitUtility isRTL]) {
        image = [image imageFlippedForRightToLeftLayoutDirection];
    }
    return image;
}

@interface RCMessageCell()
- (void)messageContentViewFrameDidChanged;
@end

@interface RCHQVoiceMessageCell () <RCVoicePlayerObserver>
@property (nonatomic) CGSize voiceViewSize;
@property (nonatomic, strong) NSTimer *animationTimer;
@property (nonatomic) int animationIndex;
@property (nonatomic, strong) RCVoicePlayer *voicePlayer;
@property (nonatomic, strong) RCSTTContentView *sttContentView;
@property (nonatomic, strong) UIView *quoteDividerView;


@end

@implementation RCHQVoiceMessageCell
#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)dealloc {
    [self disableCurrentAnimationTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    [RCSTTContentViewModel configureSTTIfNeeded:model];
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:model];
    CGFloat __messagecontentview_height = showsQuoteCard ? RCHQVoiceMessageQuoteBodyHeight() : Voice_Height;

    if (__messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        __messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }

    __messagecontentview_height += extraHeight;
    __messagecontentview_height += [self sstInfoHeight:model];
    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    RCSTTLog(@" model changed %p to %p  on %p ", self.model, model, self);
    [super setDataModel:model];
    [self resetAnimationTimer];

    RCHQVoiceMessage *voiceMessage = (RCHQVoiceMessage *)model.content;
    
    [self setMessageInfo:voiceMessage];
    [self updateSubViewsLayout:voiceMessage];
    [self updateVoiceDownloadStatusView:voiceMessage];
    [self configureSTTContentViewIfNeed];
}

#pragma mark - Public API
- (void)playVoice {
    [self removeUnreadTagView];
    [self disablePreviousAnimationTimer];

    if (self.model.messageId == self.voicePlayer.messageId) {
        if (self.voicePlayer.isPlaying) {
            [self.voicePlayer stopPlayVoice];
            [self startDestruct];
        } else {
            [self startPlayingVoiceData];
            [self stopDestruct];
        }
    } else {
        [self startPlayingVoiceData];
        [self stopDestruct];
    }
}

- (void)stopPlayingVoice {
    if (self.model.messageId == self.voicePlayer.messageId) {
        if (self.voicePlayer.isPlaying) {
            [self stopPlayingVoiceData];
            [self disableCurrentAnimationTimer];
        }
    }
}

#pragma mark - RCVoicePlayerObserver
- (void)PlayerDidFinishPlaying:(BOOL)isFinish {
    if (isFinish) {
        [self disableCurrentAnimationTimer];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(NSError *)error {
    [self disableCurrentAnimationTimer];
}

#pragma mark - 阅后即焚

- (void)startDestruct {
    RCHQVoiceMessage *voiceMessage = (RCHQVoiceMessage *)self.model.content;
    if (self.model.messageDirection == MessageDirection_RECEIVE && voiceMessage.destructDuration > 0) {
        [[RCCoreClient sharedCoreClient]
            messageBeginDestruct:[[RCCoreClient sharedCoreClient] getMessage:self.model.messageId]];
    }
}

- (void)stopDestruct {
    RCHQVoiceMessage *voiceMessage = (RCHQVoiceMessage *)self.model.content;
    if (self.model.messageDirection == MessageDirection_RECEIVE && voiceMessage.destructDuration > 0) {
        [[RCCoreClient sharedCoreClient]
            messageStopDestruct:[[RCCoreClient sharedCoreClient] getMessage:self.model.messageId]];
        if ([self respondsToSelector:@selector(messageDestructing)]) {
            [self performSelector:@selector(messageDestructing) withObject:nil afterDelay:NO];
        }
    }
}

#pragma mark - Notification

- (void)registerNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetActiveEventInBackgroundMode)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetByExtensionModelEvents)
                                                 name:@"RCKitExtensionModelResetVoicePlayingNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(voiceWillPlay:)
                                                 name:kNotificationVoiceWillPlayNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(voiceDidPlay:)
                                                 name:kNotificationPlayVoice
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopPlayingVoiceDataIfNeed:)
                                                 name:kNotificationStopVoicePlayer
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadStatus:)
                                                 name:RCHQDownloadStatusChangeNotify
                                               object:nil];
}

- (void)updateDownloadStatus:(NSNotification *)noti {
    RCHQVoiceMsgDownloadInfo *info = noti.object;
    if (info.hqVoiceMsg.messageId == self.model.messageId) {
        RCHQDownloadStatus status = info.status;
        if (status == RCHQDownloadStatusDownloading || status == RCHQDownloadStatusWaiting) {
            [self.voiceUnreadTagView setHidden:YES];
            [self indicatorAnimating];
            [self hideFailedStatusView];
        } else if (status == RCHQDownloadStatusFailed) {
            [self.voiceUnreadTagView setHidden:YES];
            [self indicatorHiding];
            [self showFailedStatusView];
        } else if (status == RCHQDownloadStatusSuccess) {
            ((RCHQVoiceMessage *)self.model.content).localPath =
                ((RCHQVoiceMessage *)info.hqVoiceMsg.content).localPath;
            [self indicatorHiding];
            [self hideFailedStatusView];
            if (MessageDirection_RECEIVE == self.model.messageDirection) {
                [self.voiceUnreadTagView setHidden:NO];
            }
        }
    }
}

- (void)voiceWillPlay:(NSNotification *)notification {
    NSNumber *msgIdNum = notification.object;
    if (msgIdNum && [msgIdNum longLongValue] == self.model.messageId) {
        [self removeUnreadTagView];
    }
}

- (void)voiceDidPlay:(NSNotification *)notification {
    long messageId = [notification.object longValue];
    if (messageId == self.model.messageId) {
        [self disableCurrentAnimationTimer];
        [self enableCurrentAnimationTimer];
    }
}


#pragma mark - Private Methods

- (void)initialize {
    [self showBubbleBackgroundView:YES];
    self.messageContentView.accessibilityLabel = @"messageContentView";
    [self.messageContentView addSubview:self.playVoiceView];
    [self.messageContentView addSubview:self.voiceDurationLabel];
    [self.messageContentView addSubview:self.quoteDividerView];
    
    [self registerNotification];
}

- (RCMessage *)converetMsgModelToMsg:(RCMessageModel *)msgModel {
    RCMessage *msg = RCMessage.new;
    msg.targetId = msgModel.targetId;
    msg.messageId = msgModel.messageId;
    msg.messageUId = msgModel.messageUId;
    msg.content = msgModel.content;
    msg.conversationType = msgModel.conversationType;
    msg.messageDirection = msgModel.messageDirection;
    msg.sentTime = msgModel.sentTime;
    msg.sentStatus = msgModel.sentStatus;
    msg.objectName = msgModel.objectName;
    msg.readReceiptInfo = msgModel.readReceiptInfo;
    msg.receivedTime = msgModel.receivedTime;
    msg.extra = msgModel.extra;
    msg.senderUserId = msgModel.senderUserId;
    return msg;
}

- (void)resetAnimationTimer{
    if (self.voicePlayer.messageId == self.model.messageId) {
        if ((self.voicePlayer.isPlaying)) {
            [self disableCurrentAnimationTimer];
            [self enableCurrentAnimationTimer];
        }
    } else {
        [self disableCurrentAnimationTimer];
    }
}

- (void)setMessageInfo:(RCHQVoiceMessage *)voiceMessage{
    if (voiceMessage) {
        self.voiceDurationLabel.text = [NSString stringWithFormat:@"%ld''", voiceMessage.duration];
    } else {
        DebugLog(@"[RongIMKit]: RCMessageModel.content is NOT RCHQVoiceMessage object");
    }
}

- (CGFloat)getBubbleWidth:(long)duration{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGFloat audioBubbleWidth =
        kAudioBubbleMinWidth +
        (kAudioBubbleMaxWidth - kAudioBubbleMinWidth) * duration / RCKitConfigCenter.message.maxVoiceDuration;
#pragma clang diagnostic pop
    audioBubbleWidth = audioBubbleWidth > kAudioBubbleMaxWidth ? kAudioBubbleMaxWidth : audioBubbleWidth;
    return audioBubbleWidth;
}

- (void)updateSubViewsLayout:(RCHQVoiceMessage *)voiceMessage{
    CGFloat audioBubbleWidth = [self getBubbleWidth:voiceMessage.duration];
    CGFloat voiceHeight = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    CGFloat contentWidth = audioBubbleWidth;
    if (showsQuoteCard) {
        contentWidth = RCHQVoiceMessageQuoteBubbleWidth(self.model, audioBubbleWidth);
    }
    CGFloat quoteOffset = showsQuoteCard ? RCHQVoiceMessageQuoteContentOffset(self.model, contentWidth) : 0;
    CGFloat bodyTopSpacing = showsQuoteCard ? RCHQVoiceMessageQuoteBodyTopSpacing() : 0;
    CGFloat voiceRowHeight = showsQuoteCard ? RCHQVoiceMessageQuoteVoiceRowHeight() : voiceHeight;
    CGFloat contentHeight = showsQuoteCard ? quoteOffset + RCHQVoiceMessageQuoteBodyHeight() : voiceHeight;
    self.messageContentView.contentSize = CGSizeMake(contentWidth, contentHeight);
    self.quoteDividerView.hidden = !showsQuoteCard;
    if (showsQuoteCard) {
        CGFloat dividerWidth = MAX(contentWidth - QUOTE_DIVIDER_HORIZONTAL_INSET * 2, 0);
        self.quoteDividerView.frame = CGRectMake(QUOTE_DIVIDER_HORIZONTAL_INSET,
                                                 quoteOffset + QUOTE_DIVIDER_TOP_SPACING,
                                                 dividerWidth,
                                                 QUOTE_DIVIDER_HEIGHT);
        [self.messageContentView bringSubviewToFront:self.quoteDividerView];
    } else {
        self.quoteDividerView.frame = CGRectZero;
    }
    CGFloat voiceRowY = quoteOffset + bodyTopSpacing;
    if (showsQuoteCard) {
        self.playVoiceView.image = RCHQVoiceMessageVoiceImage(YES, self.model.messageDirection, 3);
        [self.voiceDurationLabel setTextColor:self.model.messageDirection == MessageDirection_SEND
                                           ? RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x040A0F")
                                           : RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc")];
        self.voiceDurationLabel.textAlignment = NSTextAlignmentLeft;
        self.playVoiceView.frame = CGRectMake(QUOTE_VOICE_HORIZONTAL_INSET,
                                              voiceRowY + (voiceRowHeight - Play_Voice_View_Width) / 2,
                                              Play_Voice_View_Width,
                                              Play_Voice_View_Width);
        CGFloat labelX = CGRectGetMaxX(self.playVoiceView.frame) + QUOTE_VOICE_ICON_TEXT_SPACING;
        self.voiceDurationLabel.frame = CGRectMake(labelX,
                                                   voiceRowY,
                                                   MAX(contentWidth - labelX - QUOTE_VOICE_HORIZONTAL_INSET, 0),
                                                   voiceRowHeight);
    } else if ([RCKitUtility isRTL]) {
        if (self.model.messageDirection == MessageDirection_SEND) {
            self.playVoiceView.image = RCHQVoiceMessageVoiceImage(NO, MessageDirection_RECEIVE, 3);
            [self.voiceDurationLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc")];
            self.voiceDurationLabel.textAlignment = NSTextAlignmentLeft;
            self.playVoiceView.frame = CGRectMake(12, voiceRowY + (voiceHeight - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
            self.voiceDurationLabel.frame = CGRectMake(CGRectGetMaxX(self.playVoiceView.frame) + 8, voiceRowY, contentWidth - (CGRectGetMaxX(self.playVoiceView.frame) + 8), voiceHeight);
        } else {
            self.voiceDurationLabel.textAlignment = NSTextAlignmentRight;
            self.playVoiceView.frame = CGRectMake(contentWidth - 12 - Play_Voice_View_Width, voiceRowY + (voiceHeight - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
            self.voiceDurationLabel.frame = CGRectMake(12, voiceRowY, CGRectGetMinX(self.playVoiceView.frame) - 20, voiceHeight);
            [self.voiceDurationLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x040A0F")];
            self.playVoiceView.image = RCHQVoiceMessageVoiceImage(NO, MessageDirection_SEND, 3);
        }
    } else {
        
        if (self.model.messageDirection == MessageDirection_SEND) {
            self.voiceDurationLabel.textAlignment = NSTextAlignmentRight;
            self.playVoiceView.frame = CGRectMake(contentWidth - 12 - Play_Voice_View_Width, voiceRowY + (voiceHeight - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
            self.voiceDurationLabel.frame = CGRectMake(12, voiceRowY, CGRectGetMinX(self.playVoiceView.frame) - 20, voiceHeight);
            [self.voiceDurationLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x040A0F")];
            self.playVoiceView.image = RCHQVoiceMessageVoiceImage(NO, self.model.messageDirection, 3);
        }else{
            self.playVoiceView.image = RCHQVoiceMessageVoiceImage(NO, self.model.messageDirection, 3);
            [self.voiceDurationLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc")];
            self.voiceDurationLabel.textAlignment = NSTextAlignmentLeft;
            self.playVoiceView.frame = CGRectMake(12, voiceRowY + (voiceHeight - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
            self.voiceDurationLabel.frame = CGRectMake(CGRectGetMaxX(self.playVoiceView.frame) + 8, voiceRowY, contentWidth - (CGRectGetMaxX(self.playVoiceView.frame) + 8), voiceHeight);
        }
    }
    
    [self addVoiceUnreadTagView];
}

- (void)updateVoiceDownloadStatusView:(RCHQVoiceMessage *)voiceMessage{
    if (self.model.messageDirection == MessageDirection_SEND && self.model.sentStatus != SentStatus_SENT) {
        return;
    }
    if (voiceMessage.localPath.length <= 0) {
        RCMessage *msg = [self converetMsgModelToMsg:self.model];
        [[RCHQVoiceMsgDownloadManager defaultManager] pushVoiceMsgs:@[ msg ] priority:YES];
        if ([[RCCoreClient sharedCoreClient] getCurrentNetworkStatus] == RC_NotReachable) {
            [self indicatorHiding];
            [self showFailedStatusView];
        } else {
            [self indicatorAnimating];
        }
    } else {
        [self indicatorHiding];
        [self hideFailedStatusView];
    }
}

// todo cyenux
- (void)resetByExtensionModelEvents {
    [self stopPlayingVoiceData];
    [self disableCurrentAnimationTimer];
}

- (void)addVoiceUnreadTagView{
    RCHQVoiceMessage *voiceMessage = (RCHQVoiceMessage *)self.model.content;
    [self.voiceUnreadTagView removeFromSuperview];
    self.voiceUnreadTagView.image = nil;
    [self.voiceUnreadTagView setHidden:YES];
    CGSize size = self.messageContentView.contentSize;
    if (MessageDirection_RECEIVE == self.model.messageDirection) {
        CGFloat x = CGRectGetMaxX(self.messageContentView.frame) + 8;
        if ([RCKitUtility isRTL]) {
            x = CGRectGetMinX(self.messageContentView.frame) - 8 - voice_Unread_View_Width;
        }
        if (NO == self.model.receivedStatusInfo.isListened) {
            // 红点应对齐语音条的垂直中心，而非整个 contentSize（含引用卡片区域）
            BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
            CGFloat quoteOffset = showsQuoteCard ? RCHQVoiceMessageQuoteContentOffset(self.model, size.width) : 0;
            CGFloat bodyTopSpacing = showsQuoteCard ? RCHQVoiceMessageQuoteBodyTopSpacing() : 0;
            CGFloat voiceRowHeight = showsQuoteCard ? RCHQVoiceMessageQuoteVoiceRowHeight() : Voice_Height;
            CGFloat voiceBarCenterY = quoteOffset + bodyTopSpacing + voiceRowHeight / 2.0;
            self.voiceUnreadTagView = [[RCBaseImageView alloc] initWithFrame:CGRectMake(x, self.messageContentView.frame.origin.y + voiceBarCenterY - voice_Unread_View_Width / 2.0, voice_Unread_View_Width, voice_Unread_View_Width)];
            self.voiceUnreadTagView.accessibilityLabel = @"voiceUnreadTagView";
            if (voiceMessage.localPath.length > 0) {
                [self.voiceUnreadTagView setHidden:NO];
            } else {
                [self.voiceUnreadTagView setHidden:YES];
            }
            [self.baseContentView addSubview:self.voiceUnreadTagView];
            self.voiceUnreadTagView.image = RCDynamicImage(@"conversation_msg_cell_voice_unread_img",@"voice_unread");
        }
    }
}

- (void)removeUnreadTagView {
    if (self.voiceUnreadTagView) {
        self.voiceUnreadTagView.hidden = YES;
        [self.voiceUnreadTagView removeFromSuperview];
        self.voiceUnreadTagView = nil;
    }
}

- (BOOL)usesTopQuoteCardLayout {
    return YES;
}

#pragma mark - Overwrite
- (void)messageContentViewFrameDidChanged {
    [super messageContentViewFrameDidChanged];
    if (MessageDirection_RECEIVE == self.model.messageDirection) {
        CGSize size = self.messageContentView.contentSize;
        if (MessageDirection_RECEIVE == self.model.messageDirection) {
            CGFloat x = CGRectGetMaxX(self.messageContentView.frame) + 8;
            if ([RCKitUtility isRTL]) {
                x = CGRectGetMinX(self.messageContentView.frame) - 8 - voice_Unread_View_Width;
            }
            if (NO == self.model.receivedStatusInfo.isListened) {
                // 红点对齐语音条垂直中心
                BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
                CGFloat quoteOffset = showsQuoteCard ? RCHQVoiceMessageQuoteContentOffset(self.model, size.width) : 0;
                CGFloat bodyTopSpacing = showsQuoteCard ? RCHQVoiceMessageQuoteBodyTopSpacing() : 0;
                CGFloat voiceRowHeight = showsQuoteCard ? RCHQVoiceMessageQuoteVoiceRowHeight() : Voice_Height;
                CGFloat voiceBarCenterY = quoteOffset + bodyTopSpacing + voiceRowHeight / 2.0;
                self.voiceUnreadTagView.frame = CGRectMake(x, self.messageContentView.frame.origin.y + voiceBarCenterY - voice_Unread_View_Width / 2.0, voice_Unread_View_Width, voice_Unread_View_Width);
            }
        }
    }
}

#pragma mark - STT
- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.sttContentView) {
        [self.sttContentView bindCollectionView:self.hostCollectionView];
        [self.sttContentView layoutContentView];
    }
}

+ (CGFloat)sstInfoHeight:(RCMessageModel *)model {
    RCSTTContentViewModel *vm =  [model stt_sttViewModel];
    return [vm speedToTextContentHeight]+4;
}

- (void)configureSTTContentViewIfNeed {
    RCSTTContentViewModel *vm = [self.model stt_sttViewModel];
    if (vm) {
        if (!self.sttContentView) {
            self.sttContentView = [RCSTTContentView new];
            __weak __typeof(self)weakSelf = self;
            self.sttContentView.sttFinishedBlock = ^(){
                [weakSelf removeUnreadTagView];
            };
            [self.baseContentView addSubview:self.sttContentView];
        }
    }
    [self.sttContentView bindViewModel:vm
                             baseFrame:self.messageContentView.frame];
}

- (void)setDelegate:(id<RCMessageCellDelegate>)delegate {
    [super setDelegate:delegate];
    [self.sttContentView bindGestureDelegate:delegate];
}

#pragma mark - stop and disable timer during background mode.
- (void)resetActiveEventInBackgroundMode {
    [self stopPlayingVoiceData];
    [self disableCurrentAnimationTimer];
}

- (void)stopPlayingVoiceDataIfNeed:(NSNotification *)notification {
    long messageId = [notification.object longValue];
    if (messageId == self.model.messageId) {
        [self disableCurrentAnimationTimer];
        [self startDestruct];
    }
}

- (NSString *)getCorrectedPath:(NSString *)localPath {
    if (localPath.length > 0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
            return localPath;
        } else {
            NSUInteger location = [localPath rangeOfString:@"Library/Caches/RongCloud"].location;
            if (location != NSNotFound) {
                NSString *relativePath = [localPath substringFromIndex:location];
                NSString *path = NSHomeDirectory();
                path = [path stringByAppendingPathComponent:relativePath];
                return path;
            } else {
                return localPath;
            }
        }
    } else {
        return nil;
    }
}

- (void)startPlayingVoiceData {
    RCMessageContent *voiceContent = [[RCCoreClient sharedCoreClient] getMessage:self.model.messageId].content;
    if (![voiceContent isKindOfClass:[RCHQVoiceMessage class]]) {
        return;
    }
    RCHQVoiceMessage *_voiceMessage =
        (RCHQVoiceMessage *)voiceContent;
    NSString *localPath = [self getCorrectedPath:_voiceMessage.localPath];
    if (localPath.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:localPath]) {

        /**
         *  if the previous voice message is playing, then
         *  stop it and reset the prevoius animation timer indicator
         */
        //        [self stopPlayingVoiceData];

        //        BOOL bPlay = [self.voicePlayer playVoice:[@(self.model.messageId) stringValue]
        //                                       voiceData:_voiceMessage.wavAudioData
        //                                        observer:self];
        NSError *error;
        NSData *wavAudioData =
            [[NSData alloc] initWithContentsOfFile:localPath options:NSDataReadingMappedAlways error:&error];
        //        NSData *wavAudioData = [NSData dataWithContentsOfFile:_voiceMessage.localPath];
        BOOL bPlay = [self.voicePlayer playVoice:self.model.conversationType
                                        targetId:self.model.targetId
                                       messageId:self.model.messageId
                                       voiceData:wavAudioData
                                        observer:self];
        // if failed to play the voice message, reset all indicator.
        if (!bPlay) {
            [self stopPlayingVoiceData];
        } else {
            [self enableCurrentAnimationTimer];
        }
    } else {
        self.model.receivedStatusInfo = [[RCReceivedStatusInfo alloc] initWithReceivedStatus:0];
        self.statusContentView.hidden = NO;
        [self indicatorAnimating];
        [[RCIM sharedRCIM] downloadMediaMessage:self.model.messageId
            progress:^(int progress) {

            }
            success:^(NSString *mediaPath) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    ((RCHQVoiceMessage *)self.model.content).localPath = mediaPath;
                    [self indicatorHiding];
                    [self hideFailedStatusView];
                    if (MessageDirection_RECEIVE == self.model.messageDirection) {
                        [self.voiceUnreadTagView setHidden:NO];
                    }
                    [self startPlayingVoiceData];
                });
            }
            error:^(RCErrorCode errorCode) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self indicatorHiding];
                    [self showFailedStatusView];
                });
            }
            cancel:^{
                [self indicatorHiding];
            }];
    }
}

- (void)showFailedStatusView {
    // 无需对发送方的语音消息进行操作，发送方本地一定有音频文件
//    if (self.model.messageDirection == MessageDirection_RECEIVE) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.messageFailedStatusView) {
                self.statusContentView.hidden = NO;
                self.messageFailedStatusView.hidden = NO;
            }
        });
//    }
}

- (void)hideFailedStatusView {
    // 无需对发送方的语音消息进行操作，发送方本地一定有音频文件
//    if (self.model.messageDirection == MessageDirection_RECEIVE) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.messageFailedStatusView) {
                self.messageFailedStatusView.hidden = YES;
            }
        });
//    }
}

- (void)indicatorAnimating {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.messageActivityIndicatorView && MessageDirection_RECEIVE == self.model.messageDirection) {
            self.statusContentView.hidden = NO;
            self.messageActivityIndicatorView.hidden = NO;
            [self.messageActivityIndicatorView startAnimating];
        }
    });
}

- (void)indicatorHiding {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.messageActivityIndicatorView) {
            self.messageActivityIndicatorView.hidden = YES;
            [self.messageActivityIndicatorView stopAnimating];
        }
    });
}

- (void)stopPlayingVoiceData {
    if (self.voicePlayer.isPlaying) {
        [self.voicePlayer stopPlayVoice];
    }
}

- (void)enableCurrentAnimationTimer {
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                           target:self
                                                         selector:@selector(scheduleAnimationOperation)
                                                         userInfo:nil
                                                          repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.animationTimer forMode:NSRunLoopCommonModes];
    [self.animationTimer fire];

    hq_previousAnimationTimer = self.animationTimer;
    hq_previousPlayVoiceImageView = self.playVoiceView;
    hq_previousMessageDirection = self.model.messageDirection;
    hq_previousShowsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
}


/**
 *  Implement the animation operation
 */
- (void)scheduleAnimationOperation {
    DebugLog(@"%s", __FUNCTION__);

    self.animationIndex++;
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    UIImage *image = RCHQVoiceMessageVoiceImage(showsQuoteCard, self.model.messageDirection, self.animationIndex % 4);
    self.playVoiceView.image = image;
}

- (void)disableCurrentAnimationTimer {
    if (self.animationTimer && [self.animationTimer isValid]) {
        [self.animationTimer invalidate];
        self.animationTimer = nil;
        self.animationIndex = 0;
    }
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    self.playVoiceView.image = RCHQVoiceMessageVoiceImage(showsQuoteCard, self.model.messageDirection, 3);
}

- (void)disablePreviousAnimationTimer {
    if (hq_previousAnimationTimer && [hq_previousAnimationTimer isValid]) {
        [hq_previousAnimationTimer invalidate];
        hq_previousAnimationTimer = nil;

        /**
         *  reset the previous playVoiceView indicator image
         */
        if (hq_previousPlayVoiceImageView) {
            hq_previousPlayVoiceImageView.image = RCHQVoiceMessageVoiceImage(hq_previousShowsQuoteCard,
                                                                             hq_previousMessageDirection,
                                                                             3);
            hq_previousPlayVoiceImageView = nil;
            hq_previousMessageDirection = 0;
            hq_previousShowsQuoteCard = NO;
        }
    }
}

#pragma mark - Getter

- (RCVoicePlayer *)voicePlayer{
    if (!_voicePlayer) {
        _voicePlayer = [RCVoicePlayer defaultPlayer];
    }
    return _voicePlayer;
}

- (RCBaseImageView *)playVoiceView{
    if (!_playVoiceView) {
        _playVoiceView = [[RCBaseImageView alloc] initWithFrame:CGRectZero];
    }
    return _playVoiceView;
}

- (UILabel *)voiceDurationLabel{
    if (!_voiceDurationLabel) {
        _voiceDurationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _voiceDurationLabel.textAlignment = NSTextAlignmentLeft;
        _voiceDurationLabel.font = [[RCKitConfig defaultConfig].font fontOfGuideLevel];
    }
    return _voiceDurationLabel;
}

- (UIView *)quoteDividerView {
    if (!_quoteDividerView) {
        _quoteDividerView = [[UIView alloc] initWithFrame:CGRectZero];
        _quoteDividerView.backgroundColor = RCDynamicColor(@"line_background_color", @"0xE2E4E5", @"0xE2E4E5");
        _quoteDividerView.hidden = YES;
    }
    return _quoteDividerView;
}
@end
