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

static NSTimer *hq_previousAnimationTimer = nil;
static UIImageView *hq_previousPlayVoiceImageView = nil;
static RCMessageDirection hq_previousMessageDirection;

#define Voice_Height 40
#define voice_Unread_View_Width 8
#define Play_Voice_View_Width 16
@interface RCMessageCell()
- (void)messageContentViewFrameDidChanged;
@end

@interface RCHQVoiceMessageCell () <RCVoicePlayerObserver>
@property (nonatomic) CGSize voiceViewSize;
@property (nonatomic, strong) NSTimer *animationTimer;
@property (nonatomic) int animationIndex;
@property (nonatomic, strong) RCVoicePlayer *voicePlayer;
@property (nonatomic, strong) RCSTTContentView *sttContentView;


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
    CGFloat __messagecontentview_height = Voice_Height;

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
    self.messageContentView.contentSize = CGSizeMake(audioBubbleWidth, voiceHeight);
    if ([RCKitUtility isRTL]) {
        if (self.model.messageDirection == MessageDirection_SEND) {
            self.playVoiceView.image = RCDynamicImage(@"conversation_msg_cell_receive_voice_3_img",@"from_voice_3");
            [self.voiceDurationLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc")];
            self.voiceDurationLabel.textAlignment = NSTextAlignmentLeft;
            self.playVoiceView.frame = CGRectMake(12, (voiceHeight - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
            self.voiceDurationLabel.frame = CGRectMake(CGRectGetMaxX(self.playVoiceView.frame) + 8, 0, audioBubbleWidth - (CGRectGetMaxX(self.playVoiceView.frame) + 8), voiceHeight);
        } else {
            self.voiceDurationLabel.textAlignment = NSTextAlignmentRight;
            self.playVoiceView.frame = CGRectMake(self.messageContentView.frame.size.width-12-Play_Voice_View_Width, (voiceHeight - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
            self.voiceDurationLabel.frame = CGRectMake(12, 0, CGRectGetMinX(self.playVoiceView.frame) - 20, voiceHeight);
            [self.voiceDurationLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x040A0F")];
            self.playVoiceView.image = RCDynamicImage(@"conversation_msg_cell_send_voice_3_img",@"to_voice_3");
        }
    } else {
        
        if (self.model.messageDirection == MessageDirection_SEND) {
            self.voiceDurationLabel.textAlignment = NSTextAlignmentRight;
            self.playVoiceView.frame = CGRectMake(self.messageContentView.frame.size.width-12-Play_Voice_View_Width, (voiceHeight - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
            self.voiceDurationLabel.frame = CGRectMake(12, 0, CGRectGetMinX(self.playVoiceView.frame) - 20, voiceHeight);
            [self.voiceDurationLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x040A0F")];
            self.playVoiceView.image = RCDynamicImage(@"conversation_msg_cell_send_voice_3_img",@"to_voice_3");
        }else{
            self.playVoiceView.image = RCDynamicImage(@"conversation_msg_cell_receive_voice_3_img",@"from_voice_3");
            [self.voiceDurationLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc")];
            self.voiceDurationLabel.textAlignment = NSTextAlignmentLeft;
            self.playVoiceView.frame = CGRectMake(12, (voiceHeight - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
            self.voiceDurationLabel.frame = CGRectMake(CGRectGetMaxX(self.playVoiceView.frame) + 8, 0, audioBubbleWidth - (CGRectGetMaxX(self.playVoiceView.frame) + 8), voiceHeight);
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
    CGFloat voiceHeight = size.height;
    if (MessageDirection_RECEIVE == self.model.messageDirection) {
        CGFloat x = CGRectGetMaxX(self.messageContentView.frame) + 8;
        if ([RCKitUtility isRTL]) {
            x = CGRectGetMinX(self.messageContentView.frame) - 8 - voice_Unread_View_Width;
        }
        if (NO == self.model.receivedStatusInfo.isListened) {
            self.voiceUnreadTagView = [[RCBaseImageView alloc] initWithFrame:CGRectMake(x, self.messageContentView.frame.origin.y + (voiceHeight-voice_Unread_View_Width)/2, voice_Unread_View_Width, voice_Unread_View_Width)];
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

#pragma mark - Overwrite
- (void)messageContentViewFrameDidChanged {
    [super messageContentViewFrameDidChanged];
    if (MessageDirection_RECEIVE == self.model.messageDirection) {
        CGSize size = self.messageContentView.contentSize;
        CGFloat voiceHeight = size.height;
        if (MessageDirection_RECEIVE == self.model.messageDirection) {
            CGFloat x = CGRectGetMaxX(self.messageContentView.frame) + 8;
            if ([RCKitUtility isRTL]) {
                x = CGRectGetMinX(self.messageContentView.frame) - 8 - voice_Unread_View_Width;
            }
            if (NO == self.model.receivedStatusInfo.isListened) {
                self.voiceUnreadTagView.frame = CGRectMake(x, self.messageContentView.frame.origin.y + (voiceHeight-voice_Unread_View_Width)/2, voice_Unread_View_Width, voice_Unread_View_Width);
                
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
    UIImage *image;
    if (MessageDirection_SEND == self.model.messageDirection) {
        image = RCDynamicImage(@"conversation_msg_cell_send_voice_3_img",@"to_voice_3");
    } else {
        image = RCDynamicImage(@"conversation_msg_cell_receive_voice_3_img",@"from_voice_3");
    }
    if ([RCKitUtility isRTL]) {
        self.playVoiceView.image = [image imageFlippedForRightToLeftLayoutDirection];
    } else {
        self.playVoiceView.image = image;
    }
}

- (void)disablePreviousAnimationTimer {
    if (hq_previousAnimationTimer && [hq_previousAnimationTimer isValid]) {
        [hq_previousAnimationTimer invalidate];
        hq_previousAnimationTimer = nil;

        /**
         *  reset the previous playVoiceView indicator image
         */
        if (hq_previousPlayVoiceImageView) {
            if (MessageDirection_SEND == self.model.messageDirection) {
                hq_previousPlayVoiceImageView.image = RCDynamicImage(@"conversation_msg_cell_send_voice_3_img",@"to_voice_3");
            } else {
                hq_previousPlayVoiceImageView.image = RCDynamicImage(@"conversation_msg_cell_receive_voice_3_img",@"from_voice_3");
            }
            hq_previousPlayVoiceImageView = nil;
            hq_previousMessageDirection = 0;
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
@end
