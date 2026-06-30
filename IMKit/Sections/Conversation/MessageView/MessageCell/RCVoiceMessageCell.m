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
#import "RCMessageCell+Internal.h"
#import "RCMessageModel+MessageReaction.h"


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
#define REACTION_VOICE_BUBBLE_HORIZONTAL_INSET 12
#define REACTION_VOICE_BUBBLE_VERTICAL_INSET 12
#define REACTION_VOICE_UNREAD_TAG_SPACING 8
#define REACTION_VOICE_UNREAD_TAG_EDGE_INSET REACTION_VOICE_BUBBLE_HORIZONTAL_INSET

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
    return Voice_Height;
}

static CGFloat RCVoiceMessageQuoteBodyHeight(void) {
    return RCVoiceMessageQuoteBodyTopSpacing() + RCVoiceMessageQuoteVoiceRowHeight() + QUOTE_BODY_BOTTOM_PADDING;
}

static UIImage *RCVoiceMessageVoiceImage(BOOL showsQuoteCard, RCMessageDirection direction, NSInteger index) {
    BOOL usesReceiveStyleImage = direction == MessageDirection_RECEIVE;
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
static BOOL s_previousUsesQuoteCardStyle;

@interface RCVoiceMessageCell () <RCVoicePlayerObserver>

@property (nonatomic) long duration;

@property (nonatomic) CGSize voiceViewSize;

@property (nonatomic) int animationIndex;

@property (nonatomic, strong) NSTimer *animationTimer;

@property (nonatomic, strong) RCVoicePlayer *voicePlayer;
@property (nonatomic, strong) RCSTTContentView *sttContentView;
@property (nonatomic, strong) UIView *quoteDividerView;
@property (nonatomic, strong) RCBaseImageView *reactionVoiceBubbleView;

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
    if (!showsQuoteCard && [model rc_hasVisibleReactions]) {
        __messagecontentview_height += REACTION_VOICE_BUBBLE_VERTICAL_INSET * 2;
    }
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
    BOOL hasVisibleReactions = [self.model rc_hasVisibleReactions];
    BOOL usesQuoteCardStyle = showsQuoteCard;
    CGFloat reactionLeadingInset = (!showsQuoteCard && hasVisibleReactions) ? REACTION_VOICE_BUBBLE_HORIZONTAL_INSET : 0;
    CGFloat reactionTrailingInset = reactionLeadingInset;
    CGFloat reactionVerticalInset = (!showsQuoteCard && hasVisibleReactions) ? REACTION_VOICE_BUBBLE_VERTICAL_INSET : 0;
    BOOL reservesUnreadTagSpace = !showsQuoteCard && hasVisibleReactions &&
                                  self.model.messageDirection == MessageDirection_RECEIVE &&
                                  !self.model.receivedStatusInfo.isListened;
    if (reservesUnreadTagSpace) {
        CGFloat unreadTagInset = REACTION_VOICE_UNREAD_TAG_SPACING + voice_Unread_View_Width +
                                 REACTION_VOICE_UNREAD_TAG_EDGE_INSET;
        if ([RCKitUtility isRTL]) {
            reactionLeadingInset = MAX(reactionLeadingInset, unreadTagInset);
        } else {
            reactionTrailingInset = MAX(reactionTrailingInset, unreadTagInset);
        }
    }
    CGFloat voiceBubbleWidth = audioBubbleWidth;
    CGFloat contentWidth = audioBubbleWidth;
    if (showsQuoteCard) {
        CGFloat quoteVoiceRequiredWidth = QUOTE_VOICE_HORIZONTAL_INSET + audioBubbleWidth + QUOTE_VOICE_HORIZONTAL_INSET;
        if (self.model.messageDirection == MessageDirection_RECEIVE && !self.model.receivedStatusInfo.isListened) {
            quoteVoiceRequiredWidth = QUOTE_VOICE_HORIZONTAL_INSET + audioBubbleWidth +
                                      REACTION_VOICE_UNREAD_TAG_SPACING + voice_Unread_View_Width +
                                      REACTION_VOICE_UNREAD_TAG_EDGE_INSET;
        }
        contentWidth = RCVoiceMessageQuoteBubbleWidth(self.model, quoteVoiceRequiredWidth);
    } else if (hasVisibleReactions) {
        contentWidth = MIN(audioBubbleWidth + reactionLeadingInset + reactionTrailingInset,
                           [RCMessageCellTool getMessageContentViewMaxWidth]);
        voiceBubbleWidth = MAX(contentWidth - reactionLeadingInset - reactionTrailingInset, 0);
    }
    CGFloat quoteOffset = showsQuoteCard ? RCVoiceMessageQuoteContentOffset(self.model, contentWidth) : 0;
    CGFloat bodyTopSpacing = showsQuoteCard ? RCVoiceMessageQuoteBodyTopSpacing() : 0;
    CGFloat voiceRowHeight = showsQuoteCard ? RCVoiceMessageQuoteVoiceRowHeight() : Voice_Height;
    CGFloat contentHeight = showsQuoteCard ? quoteOffset + RCVoiceMessageQuoteBodyHeight() : Voice_Height + reactionVerticalInset * 2;
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
    [self updateQuoteDividerLayoutIfNeeded];
    CGFloat voiceRowX = showsQuoteCard ? QUOTE_VOICE_HORIZONTAL_INSET : reactionLeadingInset;
    CGFloat voiceRowY = quoteOffset + bodyTopSpacing + reactionVerticalInset;
    if (self.model.messageDirection == MessageDirection_SEND) {
        self.voiceDurationLabel.textAlignment = NSTextAlignmentRight;
        self.playVoiceView.frame = CGRectMake(voiceRowX + voiceBubbleWidth - 12 - Play_Voice_View_Width, voiceRowY + (Voice_Height - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
        self.voiceDurationLabel.frame = CGRectMake(voiceRowX + 12, voiceRowY, MAX(CGRectGetMinX(self.playVoiceView.frame) - voiceRowX - 20, 0), Voice_Height);
        [self.voiceDurationLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x040A0F")];
        self.playVoiceView.image = RCVoiceMessageVoiceImage(usesQuoteCardStyle, self.model.messageDirection, 3);
    }else{
        self.playVoiceView.image = RCVoiceMessageVoiceImage(usesQuoteCardStyle, self.model.messageDirection, 3);
        [self.voiceDurationLabel setTextColor: RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc")];
        self.voiceDurationLabel.textAlignment = NSTextAlignmentLeft;
        self.playVoiceView.frame = CGRectMake(voiceRowX + 12, voiceRowY + (Voice_Height - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
        self.voiceDurationLabel.frame = CGRectMake(CGRectGetMaxX(self.playVoiceView.frame) + 8, voiceRowY, MAX(voiceRowX + voiceBubbleWidth - (CGRectGetMaxX(self.playVoiceView.frame) + 8), 0), Voice_Height);
    }
    [self updateReactionVoiceBubbleFrame:CGRectMake(voiceRowX, voiceRowY, voiceBubbleWidth, voiceRowHeight)];
    
    [self addVoiceUnreadTagView];
}

- (void)addVoiceUnreadTagView{
    [self.voiceUnreadTagView removeFromSuperview];
    self.voiceUnreadTagView.image = nil;
    [self.voiceUnreadTagView setHidden:YES];
    if (MessageDirection_RECEIVE == self.model.messageDirection) {
        BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
        if (NO == self.model.receivedStatusInfo.isListened) {
            CGFloat x = [self voiceUnreadTagXWithShowsQuoteCard:showsQuoteCard];
            CGFloat voiceAreaCenterY = [self voiceUnreadTagCenterYWithShowsQuoteCard:showsQuoteCard];
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

- (void)messageContentViewFrameDidChange {
    [super messageContentViewFrameDidChange];
    [self updateQuoteDividerLayoutIfNeeded];
    [self configureSTTContentViewIfNeed];
    [self updateVoiceUnreadTagFrameIfNeeded];
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

+ (UIImage *)reactionBubbleBackgroundImageForDirection:(RCMessageDirection)direction {
    UIColor *color = direction == MessageDirection_SEND
        ? RCDynamicColor(@"message_reaction_voice_sent_bg_color", @"0xFFFFFF", @"0xFFFFFF")
        : RCDynamicColor(@"message_reaction_voice_received_bg_color", @"0xD2E1FE", @"0xD2E1FE");
    CGSize size = CGSizeMake(20, 20);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:10];
    [color setFill];
    [path fill];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
}

- (void)initialize {
    [self showBubbleBackgroundView:YES];
    [self.messageContentView addSubview:self.reactionVoiceBubbleView];
    [self.messageContentView addSubview:self.playVoiceView];
    [self.messageContentView addSubview:self.voiceDurationLabel];
    [self.messageContentView addSubview:self.quoteDividerView];
    
    self.voicePlayer = [RCVoicePlayer defaultPlayer];
    [self registerNotification];
}

- (BOOL)usesTopQuoteCardLayout {
    return YES;
}

- (void)updateReactionVoiceBubbleFrame:(CGRect)frame {
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    if (!showsQuoteCard && ![self.model rc_hasVisibleReactions]) {
        self.reactionVoiceBubbleView.hidden = YES;
        self.reactionVoiceBubbleView.frame = CGRectZero;
        return;
    }
    self.reactionVoiceBubbleView.hidden = NO;
    self.reactionVoiceBubbleView.image = [RCVoiceMessageCell reactionBubbleBackgroundImageForDirection:self.model.messageDirection];
    self.reactionVoiceBubbleView.frame = frame;
}

- (void)updateVoiceUnreadTagFrameIfNeeded {
    if (MessageDirection_RECEIVE != self.model.messageDirection || self.voiceUnreadTagView.hidden) {
        return;
    }
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    CGFloat x = [self voiceUnreadTagXWithShowsQuoteCard:showsQuoteCard];
    CGFloat centerY = [self voiceUnreadTagCenterYWithShowsQuoteCard:showsQuoteCard];
    self.voiceUnreadTagView.frame = CGRectMake(x,
                                               CGRectGetMinY(self.messageContentView.frame) + centerY - voice_Unread_View_Width / 2.0,
                                               voice_Unread_View_Width,
                                               voice_Unread_View_Width);
}

- (CGFloat)voiceUnreadTagXWithShowsQuoteCard:(BOOL)showsQuoteCard {
    if (!self.reactionVoiceBubbleView.hidden && !CGRectIsEmpty(self.reactionVoiceBubbleView.frame)) {
        CGFloat contentMinX = CGRectGetMinX(self.messageContentView.frame);
        CGFloat bubbleMinX = contentMinX + CGRectGetMinX(self.reactionVoiceBubbleView.frame);
        CGFloat bubbleMaxX = contentMinX + CGRectGetMaxX(self.reactionVoiceBubbleView.frame);
        if ([RCKitUtility isRTL]) {
            return bubbleMinX - REACTION_VOICE_UNREAD_TAG_SPACING - voice_Unread_View_Width;
        }
        return bubbleMaxX + REACTION_VOICE_UNREAD_TAG_SPACING;
    }
    if ([RCKitUtility isRTL]) {
        return CGRectGetMinX(self.messageContentView.frame) - 8 - voice_Unread_View_Width;
    }
    return CGRectGetMaxX(self.messageContentView.frame) + 8;
}

- (CGFloat)voiceUnreadTagCenterYWithShowsQuoteCard:(BOOL)showsQuoteCard {
    if (!self.reactionVoiceBubbleView.hidden && !CGRectIsEmpty(self.reactionVoiceBubbleView.frame)) {
        return CGRectGetMidY(self.reactionVoiceBubbleView.frame);
    }
    if (showsQuoteCard) {
        CGFloat quoteOffset = RCVoiceMessageQuoteContentOffset(self.model, self.messageContentView.contentSize.width);
        return quoteOffset + RCVoiceMessageQuoteBodyTopSpacing() + RCVoiceMessageQuoteVoiceRowHeight() / 2.0;
    }
    return self.messageContentView.contentSize.height - Voice_Height / 2.0;
}

- (void)updateQuoteDividerLayoutIfNeeded {
    if (![RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model]) {
        return;
    }
    if (self.quoteDividerView.hidden || CGRectGetWidth(self.quoteDividerView.frame) <= 0) {
        return;
    }
    CGFloat bubbleWidth = CGRectGetWidth(self.messageContentView.bounds);
    if (bubbleWidth <= 0) {
        return;
    }
    CGRect frame = self.quoteDividerView.frame;
    frame.size.width = MAX(bubbleWidth - QUOTE_DIVIDER_HORIZONTAL_INSET * 2, 0);
    self.quoteDividerView.frame = frame;
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
    s_previousUsesQuoteCardStyle = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
}

/**
 *  Implement the animation operation
 */
- (void)scheduleAnimationOperation {
    DebugLog(@"%s", __FUNCTION__);

    self.animationIndex++;
    BOOL usesQuoteCardStyle = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    UIImage *image = RCVoiceMessageVoiceImage(usesQuoteCardStyle, self.model.messageDirection, self.animationIndex % 4);
    self.playVoiceView.image = image;
}

- (void)disableCurrentAnimationTimer {
    if (self.animationTimer && [self.animationTimer isValid]) {
        [self.animationTimer invalidate];
        self.animationTimer = nil;
        self.animationIndex = 0;
    }
    BOOL usesQuoteCardStyle = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    self.playVoiceView.image = RCVoiceMessageVoiceImage(usesQuoteCardStyle, self.model.messageDirection, 3);
}

- (void)disablePreviousAnimationTimer {
    if (s_previousAnimationTimer && [s_previousAnimationTimer isValid]) {
        [s_previousAnimationTimer invalidate];
        s_previousAnimationTimer = nil;

        /**
         *  reset the previous playVoiceView indicator image
         */
        if (s_previousPlayVoiceImageView) {
            s_previousPlayVoiceImageView.image = RCVoiceMessageVoiceImage(s_previousUsesQuoteCardStyle,
                                                                          s_previousMessageDirection,
                                                                          3);
            s_previousPlayVoiceImageView = nil;
            s_previousMessageDirection = 0;
            s_previousUsesQuoteCardStyle = NO;
        }
    }
}

- (void)removeUnreadTagView {
    if (self.voiceUnreadTagView) {
        self.voiceUnreadTagView.hidden = YES;
        [self.voiceUnreadTagView removeFromSuperview];
        self.voiceUnreadTagView = nil;
    }
    [self updateLayoutAfterUnreadTagRemovedIfNeeded];
}

- (void)updateLayoutAfterUnreadTagRemovedIfNeeded {
    BOOL showsQuoteCard = [RCReferencedContentView shouldShowQuoteCardForMessageModel:self.model];
    if ((!showsQuoteCard && ![self.model rc_hasVisibleReactions]) || !self.model.receivedStatusInfo.isListened) {
        return;
    }
    RCVoiceMessage *voiceMessage = (RCVoiceMessage *)self.model.content;
    [self updateSubViewsLayout:voiceMessage];
    [self setNeedsLayout];
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

- (RCBaseImageView *)reactionVoiceBubbleView {
    if (!_reactionVoiceBubbleView) {
        _reactionVoiceBubbleView = [[RCBaseImageView alloc] initWithFrame:CGRectZero];
        _reactionVoiceBubbleView.hidden = YES;
    }
    return _reactionVoiceBubbleView;
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
