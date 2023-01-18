//
//  RCVoiceCaptureControl.m
//  RongExtensionKit
//
//  Created by xugang on 7/4/14.
//  Copyright (c) 2014 Heq.Shinoda. All rights reserved.
//

#import "RCVoiceCaptureControl.h"
#import "RCKitCommonDefine.h"
#import "RCExtensionService.h"
#import "RCVoiceRecorder.h"
#import "RCKitConfig.h"

@interface RCVoiceCaptureControl () <RCVoiceRecorderDelegate>

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *recordStatusView;
@property (nonatomic, strong) UILabel *escapeTimeLabel;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) RCVoiceRecorder *myRecorder;
@property (nonatomic, strong) NSData *wavAudioData;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) double escapeTime;
@property (nonatomic, assign) double seconds;
@property (nonatomic, assign) BOOL isStopped;
/*!
 当前的会话类型
 */
@property (nonatomic, assign) RCConversationType conversationType;
@end
@implementation RCVoiceCaptureControl
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame conversationType:(RCConversationType)type {
    self = [super initWithFrame:frame];
    if (self) {
        self.conversationType = type;
        [self initSubviews];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
}

#pragma mark - Public Methods

- (void)startRecord {
    //显示UI
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow addSubview:self];

    [self stopTimer];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.02
                                                  target:self
                                                selector:@selector(scheduleOperarion)
                                                userInfo:nil
                                                 repeats:YES];
    [self.myRecorder startRecordWithObserver:self];
    self.seconds = 0;
    [self.timer fire];
}

- (void)cancelRecord {
    [self.myRecorder cancelRecord];
    [self stopTimer];
    [self removeFromSuperview];
}

- (void)showViewWithErrorMsg:(NSString *)errorMsg {
    self.recordStatusView.image = RCResourceImage(@"audio_press_short");
    self.textLabel.text = errorMsg ?: RCLocalizedString(@"message_too_short");
    [self.textLabel setBackgroundColor:[UIColor clearColor]];
    self.textLabel.textColor = HEXCOLOR(0xffffff);
    self.textLabel.frame = CGRectMake(0, 127, self.contentView.frame.size.width, 22);
}

- (void)showCancelView {
    self.recordStatusView.image = RCResourceImage(@"return");
    self.textLabel.text = RCLocalizedString(@"release_to_cancel_title");
    [self.textLabel setBackgroundColor:RCDYCOLOR(0xff4141, 0x7d2c2c)];
    self.textLabel.textColor = RCDYCOLOR(0xffffff, 0xc1a0a0);
    self.textLabel.frame = CGRectMake((self.contentView.frame.size.width-136)/2, 126, 136, 20);

}

- (void)hideCancelView {
    self.recordStatusView.image = RCResourceImage(@"voice_volume0");
    self.textLabel.text = RCLocalizedString(@"slide_up_to_cancel_title");
    [self.textLabel setBackgroundColor:[UIColor clearColor]];
    self.textLabel.textColor = HEXCOLOR(0xffffff);
    self.textLabel.frame = CGRectMake(0, 127, self.contentView.frame.size.width, 22);
}

#pragma mark - RCVoiceRecorderDelegate
- (void)RCVoiceAudioRecorderDidFinishRecording:(BOOL)success {
    DebugLog(@"%s: %d", __FUNCTION__, success);
}

- (void)RCVoiceAudioRecorderEncodeErrorDidOccur:(NSError *)error {
    DebugLog(@"%s", __FUNCTION__);
}

#pragma mark - Private Methods
- (void)initSubviews {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cancelRecord)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.recordStatusView];
    [self.contentView addSubview:self.escapeTimeLabel];
    [self.contentView addSubview:self.textLabel];


    if (self.conversationType == ConversationType_CUSTOMERSERVICE ||
        [RCIMClient sharedRCIMClient].voiceMsgType == RCVoiceMessageTypeOrdinary) {
        _myRecorder = [RCVoiceRecorder defaultVoiceRecorder];
    } else if ([RCIMClient sharedRCIMClient].voiceMsgType == RCVoiceMessageTypeHighQuality) {
        _myRecorder = [RCVoiceRecorder hqVoiceRecorder];
    }
    self.escapeTime = RCKitConfigCenter.message.maxVoiceDuration;
    self.seconds = 0;
    self.isStopped = NO;
}

- (void)setSeconds:(double)seconds {
    _seconds = seconds;
    int leftTime = ceil(self.escapeTime - self.seconds);
    if (leftTime <= 11) {
        if (leftTime > 1) {
            [self.escapeTimeLabel setText:[NSString stringWithFormat:@"%d", leftTime - 1]];
        } else {
            self.escapeTimeLabel.text = @"!";
            self.textLabel.text = RCLocalizedString(@"message_too_long");
        }
        self.escapeTimeLabel.hidden = NO;
        self.recordStatusView.hidden = YES;
    } else {
        self.escapeTimeLabel.hidden = YES;
    }

    if (self.escapeTime < self.seconds) {
        if ([self.delegate respondsToSelector:@selector(RCVoiceCaptureControlTimeout:)]) {
            [self.delegate RCVoiceCaptureControlTimeout:self.escapeTime];
        }
    }
    if ([self.delegate respondsToSelector:@selector(RCVoiceCaptureControlTimeUpdate:)]) {
        [self.delegate RCVoiceCaptureControlTimeUpdate:_seconds];
    }
}

- (NSData *)stopRecord {
    [self stopTimer];
    if (self.isStopped) {
        return nil;
    } else {
        __block NSData *_wavData = nil;
        __block NSTimeInterval ses = 0.0f;
        [self.myRecorder stopRecord:^(NSData *wavData, NSTimeInterval secs) {
            _wavData = wavData;
            ses = secs;
        }];
        if (self.escapeTime < self.seconds) {
            _duration = self.escapeTime;
        } else {
            _duration = ses;
        }
        _wavAudioData = _wavData;
        self.isStopped = YES;
        return _wavData;
    }
}

- (void)scheduleOperarion {
    self.seconds += 0.02;
    float volume = [_myRecorder updateMeters];
    if ([self.textLabel.text isEqualToString:RCLocalizedString(@"release_to_cancel_title")]) {
        return;
    }
    UIImage *image = nil;
    if (volume > 0.0f && volume < 0.85f) {
        image = RCResourceImage(@"voice_1");
    } else if (volume >= 0.85f && volume < 0.87f) {
        image = RCResourceImage(@"voice_2");
    } else if (volume >= 0.87f && volume < 0.88f) {
        image = RCResourceImage(@"voice_3");
    } else if (volume >= 0.88f && volume < 0.90f) {
        image = RCResourceImage(@"voice_4");
    } else if (volume >= 0.90f && volume < 0.92f) {
        image = RCResourceImage(@"voice_5");
    } else if (volume >= 0.92f && volume < 0.94f) {
        image = RCResourceImage(@"voice_6");
    } else if (volume >= 0.94f && volume < 0.96f) {
        image = RCResourceImage(@"voice_7");
    } else if (volume >= 0.96f && volume <= 1.0f) {
        image = RCResourceImage(@"voice_8");
    }
    if (image) {
        [self.recordStatusView setImage:image];
    }
}

- (void)stopTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark - Getter
- (UILabel *)textLabel{
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 127, self.contentView.frame.size.width, 22)];
        [_textLabel setTextAlignment:NSTextAlignmentCenter];
        [_textLabel setFont:[[RCKitConfig defaultConfig].font fontOfGuideLevel]];
        [_textLabel setText:RCLocalizedString(@"slide_up_to_cancel_title")];
        _textLabel.textColor = HEXCOLOR(0xffffff);
        _textLabel.layer.cornerRadius = 2;
        _textLabel.layer.masksToBounds = YES;

    }
    return _textLabel;
}

- (UILabel *)escapeTimeLabel{
    if (!_escapeTimeLabel) {
        _escapeTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.contentView.frame.size.width-100)/2, 21.0f, 100, 90)];
        _escapeTimeLabel.tag = 444;
        _escapeTimeLabel.font = [[RCKitConfig defaultConfig].font fontOfSize:80];
        _escapeTimeLabel.textAlignment = NSTextAlignmentCenter;
        [_escapeTimeLabel setTextColor:[UIColor whiteColor]];
        [_escapeTimeLabel setTextAlignment:NSTextAlignmentCenter];
    }
    return _escapeTimeLabel;
}

- (UIImageView *)recordStatusView{
    if (!_recordStatusView) {
        _recordStatusView = [[UIImageView alloc] initWithFrame:CGRectMake(29.0f, 20.0f, 102, 102)];
        [_recordStatusView setImage:RCResourceImage(@"voice_volume0")];
    }
    return _recordStatusView;
}

- (UIView *)contentView{
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 160, 160)];
        [_contentView setCenter:CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2 - 34)];
        _contentView.backgroundColor = [RCKitUtility generateDynamicColor:RCMASKCOLOR(0x000000, 0.6) darkColor:RCMASKCOLOR(0x000000, 0.8)];;
        _contentView.layer.cornerRadius = 6;
        _contentView.layer.masksToBounds = YES;
    }
    return _contentView;
}
@end
