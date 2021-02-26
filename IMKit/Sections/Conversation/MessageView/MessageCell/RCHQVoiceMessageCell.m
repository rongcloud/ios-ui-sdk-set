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
#import "RCResendManager.h"
static NSTimer *hq_previousAnimationTimer = nil;
static UIImageView *hq_previousPlayVoiceImageView = nil;
static RCMessageDirection hq_previousMessageDirection;
static long hq_messageId = 0;

#define Voice_Height 40
#define voice_Unread_View_Width 8
#define Play_Voice_View_Width 16


@interface RCHQVoiceMessageCell () <RCVoicePlayerObserver>
@property (nonatomic) CGSize voiceViewSize;
@property (nonatomic, strong) NSTimer *animationTimer;
@property (nonatomic) int animationIndex;
@property (nonatomic, strong) RCVoicePlayer *voicePlayer;
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
    CGFloat __messagecontentview_height = Voice_Height;

    if (__messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        __messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }

    __messagecontentview_height += extraHeight;

    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    [self resetAnimationTimer];

    RCHQVoiceMessage *voiceMessage = (RCHQVoiceMessage *)model.content;
    
    [self setMessageInfo:voiceMessage];
    [self updateSubViewsLayout:voiceMessage];
    [self updateStatusView:voiceMessage];
}

#pragma mark - Public API
- (void)playVoice {

    RCHQVoiceMessage *voiceMessage = (RCHQVoiceMessage *)self.model.content;

    if (self.voiceUnreadTagView) {
        self.voiceUnreadTagView.hidden = YES;
        [self.voiceUnreadTagView removeFromSuperview];
        self.voiceUnreadTagView = nil;
    }
    if (voiceMessage.localPath.length > 0) {
        [[RCIMClient sharedRCIMClient] setMessageReceivedStatus:self.model.messageId
                                                 receivedStatus:ReceivedStatus_LISTENED];
        self.model.receivedStatus = ReceivedStatus_LISTENED;
    }
    [self disablePreviousAnimationTimer];

    if (self.model.messageId == hq_messageId) {
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
    if (self.model.messageId == hq_messageId) {
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
        [[RCIMClient sharedRCIMClient]
            messageBeginDestruct:[[RCIMClient sharedRCIMClient] getMessage:self.model.messageId]];
    }
}

- (void)stopDestruct {
    RCHQVoiceMessage *voiceMessage = (RCHQVoiceMessage *)self.model.content;
    if (self.model.messageDirection == MessageDirection_RECEIVE && voiceMessage.destructDuration > 0) {
        [[RCIMClient sharedRCIMClient]
            messageStopDestruct:[[RCIMClient sharedRCIMClient] getMessage:self.model.messageId]];
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
                                             selector:@selector(stopPlayingVoiceDataIfNeed:)
                                                 name:@"kNotificationStopVoicePlayer"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadStatus:)
                                                 name:RCHQDownloadStatusChangeNotify
                                               object:nil];
}

- (void)playVoiceNotification:(NSNotification *)notification {
    long messageId = [notification.object longValue];
    if (messageId == self.model.messageId) {
        [self playVoice];
    }
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

#pragma mark - Private Methods

- (void)initialize {
    [self showBubbleBackgroundView:YES];
    
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
    if (hq_messageId == self.model.messageId) {
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
    CGFloat audioBubbleWidth =
        kAudioBubbleMinWidth +
        (kAudioBubbleMaxWidth - kAudioBubbleMinWidth) * duration / RCKitConfigCenter.message.maxVoiceDuration;
    audioBubbleWidth = audioBubbleWidth > kAudioBubbleMaxWidth ? kAudioBubbleMaxWidth : audioBubbleWidth;
    return audioBubbleWidth;
}

- (void)updateSubViewsLayout:(RCHQVoiceMessage *)voiceMessage{
    CGFloat audioBubbleWidth = [self getBubbleWidth:voiceMessage.duration];
    self.messageContentView.contentSize = CGSizeMake(audioBubbleWidth, Voice_Height);
    if ([RCKitUtility isRTL]) {
        if (self.model.messageDirection == MessageDirection_SEND) {
            self.playVoiceView.image = RCResourceImage(@"from_voice_3");
            [self.voiceDurationLabel setTextColor:[RCKitUtility generateDynamicColor:HEXCOLOR(0x111f2c) darkColor:RCMASKCOLOR(0xffffff, 0.8)]];
            self.voiceDurationLabel.textAlignment = NSTextAlignmentLeft;
            self.playVoiceView.frame = CGRectMake(12, (Voice_Height - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
            self.voiceDurationLabel.frame = CGRectMake(CGRectGetMaxX(self.playVoiceView.frame) + 8, 0, audioBubbleWidth - (CGRectGetMaxX(self.playVoiceView.frame) + 8), Voice_Height);
        } else {
            self.voiceDurationLabel.textAlignment = NSTextAlignmentRight;
            self.playVoiceView.frame = CGRectMake(self.messageContentView.frame.size.width-12-Play_Voice_View_Width, (Voice_Height - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
            self.voiceDurationLabel.frame = CGRectMake(12, 0, CGRectGetMinX(self.playVoiceView.frame) - 20, Voice_Height);
            [self.voiceDurationLabel setTextColor:RCDYCOLOR(0x111f2c, 0x040A0F)];
            self.playVoiceView.image = RCResourceImage(@"to_voice_3");
        }
    } else {
        
        if (self.model.messageDirection == MessageDirection_SEND) {
            self.voiceDurationLabel.textAlignment = NSTextAlignmentRight;
            self.playVoiceView.frame = CGRectMake(self.messageContentView.frame.size.width-12-Play_Voice_View_Width, (Voice_Height - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
            self.voiceDurationLabel.frame = CGRectMake(12, 0, CGRectGetMinX(self.playVoiceView.frame) - 20, Voice_Height);
            [self.voiceDurationLabel setTextColor:RCDYCOLOR(0x111f2c, 0x040A0F)];
            self.playVoiceView.image = RCResourceImage(@"to_voice_3");
        }else{
            self.playVoiceView.image = RCResourceImage(@"from_voice_3");
            [self.voiceDurationLabel setTextColor:[RCKitUtility generateDynamicColor:HEXCOLOR(0x111f2c) darkColor:RCMASKCOLOR(0xffffff, 0.8)]];
            self.voiceDurationLabel.textAlignment = NSTextAlignmentLeft;
            self.playVoiceView.frame = CGRectMake(12, (Voice_Height - Play_Voice_View_Width)/2, Play_Voice_View_Width, Play_Voice_View_Width);
            self.voiceDurationLabel.frame = CGRectMake(CGRectGetMaxX(self.playVoiceView.frame) + 8, 0, audioBubbleWidth - (CGRectGetMaxX(self.playVoiceView.frame) + 8), Voice_Height);
        }
    }
    
    [self addVoiceUnreadTagView];
}

- (void)updateStatusView:(RCHQVoiceMessage *)voiceMessage{
    if (voiceMessage.localPath.length <= 0) {
        RCMessage *msg = [self converetMsgModelToMsg:self.model];
        [[RCHQVoiceMsgDownloadManager defaultManager] pushVoiceMsgs:@[ msg ] priority:YES];
        if ([[RCIMClient sharedRCIMClient] getCurrentNetworkStatus] == RC_NotReachable) {
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
    if (MessageDirection_RECEIVE == self.model.messageDirection) {
        CGFloat x = CGRectGetMaxX(self.messageContentView.frame) + 8;
        if ([RCKitUtility isRTL]) {
            x = CGRectGetMinX(self.messageContentView.frame) - 8 - voice_Unread_View_Width;
        }
        if (ReceivedStatus_LISTENED != self.model.receivedStatus) {
            self.voiceUnreadTagView = [[UIImageView alloc] initWithFrame:CGRectMake(x, self.messageContentView.frame.origin.y + (Voice_Height-voice_Unread_View_Width)/2, voice_Unread_View_Width, voice_Unread_View_Width)];
            if (voiceMessage.localPath.length > 0) {
                [self.voiceUnreadTagView setHidden:NO];
            } else {
                [self.voiceUnreadTagView setHidden:YES];
            }
            [self.baseContentView addSubview:self.voiceUnreadTagView];
            self.voiceUnreadTagView.image = RCResourceImage(@"voice_unread");
        }
    }
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
    RCHQVoiceMessage *_voiceMessage =
        (RCHQVoiceMessage *)[[RCIMClient sharedRCIMClient] getMessage:self.model.messageId].content;
    NSString *localPath = [self getCorrectedPath:_voiceMessage.localPath];
    if (localPath.length > 0) {

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
                                       direction:self.model.messageDirection
                                       voiceData:wavAudioData
                                        observer:self];
        // if failed to play the voice message, reset all indicator.
        if (!bPlay) {
            [self stopPlayingVoiceData];
        } else {
            [self enableCurrentAnimationTimer];
        }
        hq_messageId = self.model.messageId;
    } else {
        self.model.receivedStatus = ReceivedStatus_UNREAD;
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
    if (MessageDirection_SEND == self.model.messageDirection) {
        playingIndicatorIndex = [NSString stringWithFormat:@"to_voice_%d", (self.animationIndex % 4)];
    } else {
        playingIndicatorIndex = [NSString stringWithFormat:@"from_voice_%d", (self.animationIndex % 4)];
    }
    DebugLog(@"playingIndicatorIndex > %@", playingIndicatorIndex);
    self.playVoiceView.image = RCResourceImage(playingIndicatorIndex);
}

- (void)disableCurrentAnimationTimer {
    if (self.animationTimer && [self.animationTimer isValid]) {
        [self.animationTimer invalidate];
        self.animationTimer = nil;
        self.animationIndex = 0;
    }
    UIImage *image;
    if (MessageDirection_SEND == self.model.messageDirection) {
        image = RCResourceImage(@"to_voice_3");
    } else {
        image = RCResourceImage(@"from_voice_3");
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
                hq_previousPlayVoiceImageView.image = RCResourceImage(@"to_voice_3");
            } else {
                hq_previousPlayVoiceImageView.image = RCResourceImage(@"from_voice_3");
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

- (UIImageView *)playVoiceView{
    if (!_playVoiceView) {
        _playVoiceView = [[UIImageView alloc] initWithFrame:CGRectZero];
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
