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
#import "RCVoicePlayer.h"
#import "RCKitConfig.h"
#import "RCSTTContentView.h"
#import "RCMessageModel+STT.h"

#define Voice_Height 40
#define voice_Unread_View_Width 8
#define Play_Voice_View_Width 16

static NSTimer *s_previousAnimationTimer = nil;
static UIImageView *s_previousPlayVoiceImageView = nil;
static RCMessageDirection s_previousMessageDirection;

@interface RCVoiceMessageCell () <RCVoicePlayerObserver>

@property (nonatomic) long duration;

@property (nonatomic) CGSize voiceViewSize;

@property (nonatomic) int animationIndex;

@property (nonatomic, strong) NSTimer *animationTimer;

@property (nonatomic, strong) RCVoicePlayer *voicePlayer;
@property (nonatomic, strong) RCSTTContentView *sttContentView;

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
    CGFloat __messagecontentview_height = Voice_Height;
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
    self.messageContentView.contentSize = CGSizeMake(audioBubbleWidth, Voice_Height);
    if (self.model.messageDirection == MessageDirection_SEND) {
        self.voiceDurationLabel.textAlignment = NSTextAlignmentRight;
        self.playVoiceView.frame = CGRectMake(self.messageContentView.frame.size.width-12-Play_Voice_View_Width, (Voice_Height - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
        self.voiceDurationLabel.frame = CGRectMake(12, 0, CGRectGetMinX(self.playVoiceView.frame) - 20, Voice_Height);
        [self.voiceDurationLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x040A0F")];
        self.playVoiceView.image = RCDynamicImage(@"conversation_msg_cell_send_voice_3_img",@"to_voice_3");
    }else{
        self.playVoiceView.image = RCDynamicImage(@"conversation_msg_cell_receive_voice_3_img",@"from_voice_3");
        [self.voiceDurationLabel setTextColor: RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc")];
        self.voiceDurationLabel.textAlignment = NSTextAlignmentLeft;
        self.playVoiceView.frame = CGRectMake(12, (Voice_Height - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
        self.voiceDurationLabel.frame = CGRectMake(CGRectGetMaxX(self.playVoiceView.frame) + 8, 0, audioBubbleWidth - (CGRectGetMaxX(self.playVoiceView.frame) + 8), Voice_Height);
    }
    
    [self addVoiceUnreadTagView];
}

- (void)addVoiceUnreadTagView{
    [self.voiceUnreadTagView removeFromSuperview];
    self.voiceUnreadTagView.image = nil;
    [self.voiceUnreadTagView setHidden:YES];
    if (MessageDirection_RECEIVE == self.model.messageDirection) {
        CGFloat x = CGRectGetMaxX(self.messageContentView.frame) + 8;
        if (NO == self.model.receivedStatusInfo.isListened) {
            self.voiceUnreadTagView = [[RCBaseImageView alloc] initWithFrame:CGRectMake(x, self.messageContentView.frame.origin.y + (Voice_Height-voice_Unread_View_Width)/2, voice_Unread_View_Width, voice_Unread_View_Width)];
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
    
    self.voicePlayer = [RCVoicePlayer defaultPlayer];
    [self registerNotification];
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
}

/**
 *  Implement the animation operation
 */
- (void)scheduleAnimationOperation {
    DebugLog(@"%s", __FUNCTION__);

    self.animationIndex++;
    NSString *playingIndicatorIndex;
    NSString *playingIndicatorIndexKey;

    if (MessageDirection_SEND == self.model.messageDirection) {
        playingIndicatorIndex = [NSString stringWithFormat:@"to_voice_%d", (self.animationIndex % 4)];
        playingIndicatorIndexKey = [NSString stringWithFormat:@"conversation_msg_cell_send_voice_%d_img", (self.animationIndex % 4)];
    } else {
        playingIndicatorIndex = [NSString stringWithFormat:@"from_voice_%d", (self.animationIndex % 4)];
        playingIndicatorIndexKey = [NSString stringWithFormat:@"conversation_msg_cell_receive_voice_%d_img", (self.animationIndex % 4)];

    }
    DebugLog(@"playingIndicatorIndex > %@", playingIndicatorIndex);
    UIImage *image = RCDynamicImage(playingIndicatorIndexKey, playingIndicatorIndex);
    if ([RCKitUtility isRTL]) {
        image = [image imageFlippedForRightToLeftLayoutDirection];
    }
    self.playVoiceView.image = image;
}

- (void)disableCurrentAnimationTimer {
    if (self.animationTimer && [self.animationTimer isValid]) {
        [self.animationTimer invalidate];
        self.animationTimer = nil;
        self.animationIndex = 0;
    }
    if (MessageDirection_SEND == self.model.messageDirection) {
        self.playVoiceView.image = RCDynamicImage(@"conversation_msg_cell_send_voice_3_img",@"to_voice_3");
    } else {
        self.playVoiceView.image = RCDynamicImage(@"conversation_msg_cell_receive_voice_3_img",@"from_voice_3");
    }
}

- (void)disablePreviousAnimationTimer {
    if (s_previousAnimationTimer && [s_previousAnimationTimer isValid]) {
        [s_previousAnimationTimer invalidate];
        s_previousAnimationTimer = nil;

        /**
         *  reset the previous playVoiceView indicator image
         */
        if (s_previousPlayVoiceImageView) {
            if (MessageDirection_SEND == self.model.messageDirection) {
                s_previousPlayVoiceImageView.image = RCDynamicImage(@"conversation_msg_cell_send_voice_3_img",@"to_voice_3");
            } else {
                s_previousPlayVoiceImageView.image = RCDynamicImage(@"conversation_msg_cell_receive_voice_3_img",@"from_voice_3");
            }
            s_previousPlayVoiceImageView = nil;
            s_previousMessageDirection = 0;
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
@end
