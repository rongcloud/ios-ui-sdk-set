//
//  RCHQVoiceMessageCell.h
//  RongIMKit
//
//  Created by Zhaoqianyu on 2019/5/20.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RongIMKit.h"

/*!
 *  \~chinese
 语音消息Cell
 
 *  \~english
 Voice message Cell 
 */
@interface RCHQVoiceMessageCell : RCMessageCell

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
