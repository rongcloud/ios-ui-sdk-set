//
//  RCVoiceMessageCell.m
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCVoiceMessageCell.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCMessageCellTool.h"
#import "RCVoicePlayer.h"
#import "RCKitConfig.h"
#import "RCSTTContentView.h"
#import "RCMessageModel+STT.h"
#import "RCReferencedContentView.h"


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

static CGFloat RCVoiceMessageQuoteContentOffset(RCMessageModel *model, CGFloat bubbleWidth) {
    CGFloat cardWidth = MAX(bubbleWidth - QUOTE_CARD_HORIZONTAL_INSET * 2, 0);
    CGFloat cardHeight = [RCReferencedContentView quoteCardHeightForMessageModel:model maxWidth:cardWidth];
    return RCQuoteCardTopMargin + cardHeight;
}

static CGFloat RCVoiceMessageQuoteBubbleWidth(RCMessageModel *model, CGFloat audioBubbleWidth) {
    CGFloat maxBubbleWidth = [RCMessageCellTool getMessageContentViewMaxWidth];
    CGFloat maxCardWidth = MAX(maxBubbleWidth - QUOTE_CARD_HORIZONTAL_INSET * 2, 0);
    CGSize quoteCardSize = [RCReferencedContentView quoteCardContentSizeForMessageModel:model maxWidth:maxCardWidth];
    CGFloat quoteWidth = quoteCardSize.width + QUOTE_CARD_HORIZONTAL_INSET * 2;
    return MIN(MAX(audioBubbleWidth, quoteWidth), maxBubbleWidth);
}

static CGFloat RCVoiceMessageQuoteBodyTopSpacing(void) {
    return QUOTE_DIVIDER_TOP_SPACING + QUOTE_DIVIDER_HEIGHT + QUOTE_DIVIDER_BOTTOM_SPACING;
}

static CGFloat RCVoiceMessageQuoteVoiceRowHeight(void) {
    return ceilf([[RCKitConfig defaultConfig].font fontOfSecondLevel].lineHeight);
}

static CGFloat RCVoiceMessageQuoteBodyHeight(void) {
    return RCVoiceMessageQuoteBodyTopSpacing() + RCVoiceMessageQuoteVoiceRowHeight() + QUOTE_BODY_BOTTOM_PADDING;
}

static UIImage *RCVoiceMessageVoiceImage(BOOL showsQuoteCard, RCMessageDirection direction, NSInteger index) {
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

static NSTimer *s_previousAnimationTimer = nil;
static UIImageView *s_previousPlayVoiceImageView = nil;
static RCMessageDirection s_previousMessageDirection;
static BOOL s_previousShowsQuoteCard;

@interface RCVoiceMessageCell () <RCVoicePlayerObserver>

@property (nonatomic) long duration;

@property (nonatomic) CGSize voiceViewSize;

@property (nonatomic) int animationIndex;

@property (nonatomic, strong) NSTimer *animationTimer;

@property (nonatomic, strong) RCVoicePlayer *voicePlayer;
@property (nonatomic, strong) RCSTTContentView *sttContentView;
@property (nonatomic, strong) UIView *quoteDividerView;

@end

@implementation RCVoiceMessageCell
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

#pragma mark - Public Methods

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

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:model];
    CGFloat __messagecontentview_height = showsQuoteCard ? RCVoiceMessageQuoteBodyHeight() : Voice_Height;
    [RCSTTContentViewModel configureSTTIfNeeded:model];

    if (__messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        __messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }
    
    __messagecontentview_height += extraHeight;
    __messagecontentview_height += [self sstInfoHeight:model];
    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
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
- (void)setMessageInfo:(RCVoiceMessage *)voiceMessage{
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

- (void)updateSubViewsLayout:(RCVoiceMessage *)voiceMessage{
    CGFloat audioBubbleWidth = [self getBubbleWidth:voiceMessage.duration];
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    CGFloat contentWidth = audioBubbleWidth;
    if (showsQuoteCard) {
        contentWidth = RCVoiceMessageQuoteBubbleWidth(self.model, audioBubbleWidth);
    }
    CGFloat quoteOffset = showsQuoteCard ? RCVoiceMessageQuoteContentOffset(self.model, contentWidth) : 0;
    CGFloat bodyTopSpacing = showsQuoteCard ? RCVoiceMessageQuoteBodyTopSpacing() : 0;
    CGFloat voiceRowHeight = showsQuoteCard ? RCVoiceMessageQuoteVoiceRowHeight() : Voice_Height;
    CGFloat contentHeight = showsQuoteCard ? quoteOffset + RCVoiceMessageQuoteBodyHeight() : Voice_Height;
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
        self.playVoiceView.image = RCVoiceMessageVoiceImage(YES, self.model.messageDirection, 3);
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
    } else if (self.model.messageDirection == MessageDirection_SEND) {
        self.voiceDurationLabel.textAlignment = NSTextAlignmentRight;
        self.playVoiceView.frame = CGRectMake(contentWidth - 12 - Play_Voice_View_Width, voiceRowY + (Voice_Height - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
        self.voiceDurationLabel.frame = CGRectMake(12, voiceRowY, CGRectGetMinX(self.playVoiceView.frame) - 20, Voice_Height);
        [self.voiceDurationLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x040A0F")];
        self.playVoiceView.image = RCVoiceMessageVoiceImage(NO, self.model.messageDirection, 3);
    }else{
        self.playVoiceView.image = RCVoiceMessageVoiceImage(NO, self.model.messageDirection, 3);
        [self.voiceDurationLabel setTextColor: RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc")];
        self.voiceDurationLabel.textAlignment = NSTextAlignmentLeft;
        self.playVoiceView.frame = CGRectMake(12, voiceRowY + (Voice_Height - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
        self.voiceDurationLabel.frame = CGRectMake(CGRectGetMaxX(self.playVoiceView.frame) + 8, voiceRowY, contentWidth - (CGRectGetMaxX(self.playVoiceView.frame) + 8), Voice_Height);
    }
    
    [self addVoiceUnreadTagView];
}

- (void)addVoiceUnreadTagView{
    [self.voiceUnreadTagView removeFromSuperview];
    self.voiceUnreadTagView.image = nil;
    [self.voiceUnreadTagView setHidden:YES];
    if (MessageDirection_RECEIVE == self.model.messageDirection) {
        CGFloat x = CGRectGetMaxX(self.messageContentView.frame) + 8;
        BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
        CGFloat voiceAreaCenterY = self.messageContentView.contentSize.height - Voice_Height / 2.0;
        if (showsQuoteCard) {
            CGFloat quoteOffset = RCVoiceMessageQuoteContentOffset(self.model, self.messageContentView.contentSize.width);
            voiceAreaCenterY = quoteOffset + RCVoiceMessageQuoteBodyTopSpacing() + RCVoiceMessageQuoteVoiceRowHeight() / 2.0;
        }
        if (NO == self.model.receivedStatusInfo.isListened) {
            self.voiceUnreadTagView = [[RCBaseImageView alloc] initWithFrame:CGRectMake(x, self.messageContentView.frame.origin.y + voiceAreaCenterY - voice_Unread_View_Width / 2.0, voice_Unread_View_Width, voice_Unread_View_Width)];
            [self.voiceUnreadTagView setHidden:NO];
            [self.baseContentView addSubview:self.voiceUnreadTagView];
            self.voiceUnreadTagView.image = RCDynamicImage(@"conversation_msg_cell_voice_unread_img",@"voice_unread");
        }
    }
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    [self resetAnimationTimer];
    
    RCVoiceMessage *voiceMessage = (RCVoiceMessage *)model.content;
    
    [self setMessageInfo:voiceMessage];
    [self updateSubViewsLayout:voiceMessage];
    [self configureSTTContentViewIfNeed];

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
    RCVoiceMessage *voiceMessage = (RCVoiceMessage *)self.model.content;
    if (self.model.messageDirection == MessageDirection_RECEIVE && voiceMessage.destructDuration > 0) {
        [[RCCoreClient sharedCoreClient]
         messageBeginDestruct:[[RCCoreClient sharedCoreClient] getMessage:self.model.messageId]];
    }
}

- (void)stopDestruct {
    RCVoiceMessage *voiceMessage = (RCVoiceMessage *)self.model.content;
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
}

// todo cyenux
- (void)resetByExtensionModelEvents {
    [self stopPlayingVoiceData];
    [self disableCurrentAnimationTimer];
}

// stop and disable timer during background mode.
- (void)resetActiveEventInBackgroundMode {
    [self stopPlayingVoiceData];
    [self disableCurrentAnimationTimer];
}

#pragma mark - Private Methods

- (void)initialize {
    [self showBubbleBackgroundView:YES];
    [self.messageContentView addSubview:self.playVoiceView];
    [self.messageContentView addSubview:self.voiceDurationLabel];
    [self.messageContentView addSubview:self.quoteDividerView];
    
    self.voicePlayer = [RCVoicePlayer defaultPlayer];
    [self registerNotification];
}

- (BOOL)usesTopQuoteCardLayout {
    return YES;
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

- (void)stopPlayingVoiceDataIfNeed:(NSNotification *)notification {
    long messageId = [notification.object longValue];
    if (messageId == self.model.messageId) {
        [self disableCurrentAnimationTimer];
        [self startDestruct];
    }
}

- (void)startPlayingVoiceData {
    RCVoiceMessage *_voiceMessage = (RCVoiceMessage *)self.model.content;

    if (_voiceMessage.wavAudioData) {
        /**
         *  if the previous voice message is playing, then
         *  stop it and reset the prevoius animation timer indicator
         */
        BOOL bPlay = [self.voicePlayer playVoice:self.model.conversationType
                                        targetId:self.model.targetId
                                       messageId:self.model.messageId
                                       voiceData:_voiceMessage.wavAudioData
                                        observer:self];
        // if failed to play the voice message, reset all indicator.
        if (!bPlay) {
            [self stopPlayingVoiceData];
            [self disableCurrentAnimationTimer];
        } else {
            [self enableCurrentAnimationTimer];
        }
    } else {
        DebugLog(@"[RongIMKit]: RCVoiceMessage.voiceData is NULL");
    }
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
    [self.animationTimer fire];

    s_previousAnimationTimer = self.animationTimer;
    s_previousPlayVoiceImageView = self.playVoiceView;
    s_previousMessageDirection = self.model.messageDirection;
    s_previousShowsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
}

/**
 *  Implement the animation operation
 */
- (void)scheduleAnimationOperation {
    DebugLog(@"%s", __FUNCTION__);

    self.animationIndex++;
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    UIImage *image = RCVoiceMessageVoiceImage(showsQuoteCard, self.model.messageDirection, self.animationIndex % 4);
    self.playVoiceView.image = image;
}

- (void)disableCurrentAnimationTimer {
    if (self.animationTimer && [self.animationTimer isValid]) {
        [self.animationTimer invalidate];
        self.animationTimer = nil;
        self.animationIndex = 0;
    }
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    self.playVoiceView.image = RCVoiceMessageVoiceImage(showsQuoteCard, self.model.messageDirection, 3);
}

- (void)disablePreviousAnimationTimer {
    if (s_previousAnimationTimer && [s_previousAnimationTimer isValid]) {
        [s_previousAnimationTimer invalidate];
        s_previousAnimationTimer = nil;

        /**
         *  reset the previous playVoiceView indicator image
         */
        if (s_previousPlayVoiceImageView) {
            s_previousPlayVoiceImageView.image = RCVoiceMessageVoiceImage(s_previousShowsQuoteCard,
                                                                          s_previousMessageDirection,
                                                                          3);
            s_previousPlayVoiceImageView = nil;
            s_previousMessageDirection = 0;
            s_previousShowsQuoteCard = NO;
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

#pragma mark - STT
- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.sttContentView) {
        [self.sttContentView layoutContentView];
        [self.sttContentView bindCollectionView:self.hostCollectionView];
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
