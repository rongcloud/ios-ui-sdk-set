//
//  RCVoiceMessageCell.h
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCMessageCell.h"

#define kAudioBubbleMinWidth 70
#define kAudioBubbleMaxWidth 180
#define kMessageContentViewHeight 36

/*!
 *  \~chinese
 开始语音播放的Notification
 
 *  \~english
 Notification that starts voice playback 
 */
UIKIT_EXTERN NSString *const kNotificationPlayVoice;

/*!
 *  \~chinese
 语音消息播放停止的Notification
 
 *  \~english
 Notification where voice message playback stops
 */
UIKIT_EXTERN NSString *const kNotificationStopVoicePlayer;

/*!
 *  \~chinese
 语音消息Cell
 
 *  \~english
 Voice message Cell
 */
@interface RCVoiceMessageCell : RCMessageCell

/*!
 *  \~chinese
 语音播放的View
 
 *  \~english
 View for voice playback
 */
@property (nonatomic, strong) UIImageView *playVoiceView;

/*!
 *  \~chinese
 显示是否已播放的View
 
 *  \~english
 Display whether the View has been played
 */
@property (nonatomic, strong) UIImageView *voiceUnreadTagView;

/*!
 *  \~chinese
 显示语音时长的Label
 
 *  \~english
 Label that displays the duration of the voice
 */
@property (nonatomic, strong) UILabel *voiceDurationLabel;

/*!
 *  \~chinese
 播放语音
 
 *  \~english
 Play voice
 */
- (void)playVoice;

/*!
 *  \~chinese
 停止播放语音
 
 *  \~english
 Stop playing voice
 */
- (void)stopPlayingVoice;

@end
