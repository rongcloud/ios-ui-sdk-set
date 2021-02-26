//
//  RCiFlyInputView.m
//  RongiFlyKit
//
//  Created by Sin on 16/11/10.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#pragma clang diagnostic ignored "-Wincomplete-umbrella"
#import "RCiFlyInputView.h"
#import <iflyMSC/iflyMSC.h>
#import "RCISRDataHelper.h"
#import "RongIMKitHeader.h"
@interface RCVoicePlayer : NSObject
+ (RCVoicePlayer *)defaultPlayer;
- (void)stopPlayVoice;
@property (nonatomic, readonly) BOOL isPlaying;
@end

//本app语音输入使用科大讯飞语音输入法
@interface RCiFlyInputView () <IFlySpeechRecognizerDelegate>
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *backImageView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, assign) BOOL firstHasText;

@property (nonatomic, strong) IFlySpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) NSMutableString *result; //当前session的结果
@end

@implementation RCiFlyInputView
+ (instancetype)iFlyInputViewWithFrame:(CGRect)frame {
    return [[[self class] alloc] initWithFrame:frame];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self configUIWithFrame:frame];
        self.result = [NSMutableString new];
        self.firstHasText = NO;
    }
    return self;
}

- (void)configUIWithFrame:(CGRect)frame {
    self.backgroundColor = [UIColor colorWithRed:244.0 / 255 green:244.0 / 255 blue:246.0 / 255 alpha:1];
    CGSize size = frame.size;

    self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, size.height - 40, size.width, size.height)];
    self.backgroundColor = [UIColor colorWithRed:254 / 255.0 green:254 / 255.0 blue:254 / 255.0 alpha:1];

    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, 1)];
    topLine.backgroundColor = [UIColor colorWithRed:231.0 / 255 green:231.0 / 255 blue:231.0 / 255 alpha:1];

    UIView *middleLine = [[UIView alloc] initWithFrame:CGRectMake(size.width / 2.0 - 0.5, 8, 1, 40 - 16)];
    middleLine.backgroundColor = [UIColor colorWithRed:231.0 / 255 green:231.0 / 255 blue:231.0 / 255 alpha:1];

    UIButton *clearButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, size.width / 2.0, 40)];
    [clearButton setTitle:RCLocalizedString(@"Clear") forState:UIControlStateNormal];
    clearButton.titleLabel.font = [UIFont systemFontOfSize:16.f];
    [clearButton setTitleColor:[UIColor colorWithRed:130.0 / 255 green:130.0 / 255 blue:130.0 / 255 alpha:1]
                      forState:UIControlStateNormal];
    [clearButton addTarget:self action:@selector(clearEvent) forControlEvents:UIControlEventTouchUpInside];
    clearButton.backgroundColor = [UIColor clearColor];
    self.clearButton = clearButton;

    UIButton *sendButton = [[UIButton alloc] initWithFrame:CGRectMake(size.width / 2.0, 0, size.width / 2.0, 40)];
    [sendButton setTitle:RCLocalizedString(@"Send") forState:UIControlStateNormal];
    sendButton.titleLabel.font = [UIFont systemFontOfSize:16.f];
    [sendButton addTarget:self action:@selector(sendEvent) forControlEvents:UIControlEventTouchUpInside];
    [sendButton setTitleColor:[UIColor colorWithRed:130.0 / 255 green:130.0 / 255 blue:130.0 / 255 alpha:1]
                     forState:UIControlStateNormal];
    sendButton.backgroundColor = [UIColor clearColor];
    self.sendButton = sendButton;
    
    if ([RCKitUtility isRTL]) {
        self.clearButton.frame = CGRectMake(size.width / 2.0, 0, size.width / 2.0, 40);
        self.sendButton.frame = CGRectMake(0, 0, size.width / 2.0, 40);
    }

    CGFloat backImgViewX = self.frame.size.width / 2.0 - 104 / 2.0;
    UIImageView *backImgView = [[UIImageView alloc] initWithFrame:CGRectMake(backImgViewX, 43, 104, 90)];
    UITapGestureRecognizer *imgViewTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTap)];
    [backImgView addGestureRecognizer:imgViewTap];
    backImgView.userInteractionEnabled = YES;
    self.backImageView = backImgView;
    backImgView.image = [self imageFromiFlyBundle:@"voice_input_back"];

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(38, 22, 28, 47)];
    imageView.userInteractionEnabled = YES;
    self.imageView = imageView;

    [self resetMicroPhoneStatus];

    [backImgView addSubview:imageView];
    [self.bottomView addSubview:topLine];
    [self.bottomView addSubview:middleLine];
    [self.bottomView addSubview:sendButton];
    [self.bottomView addSubview:clearButton];
    [self addSubview:self.bottomView];
    [self addSubview:backImgView];
    [self showBottom:NO];
}

- (void)imageViewTap {
    if ([self.speechRecognizer isListening]) {
        [self stopListening];
    } else {
        [self stopVoicePlayerIfNeed];
        [self.speechRecognizer startListening];
    }
}

- (void)show:(BOOL)isShow inputBarWidth:(CGFloat)inputBarWidth {
    self.hidden = !isShow;
    if (isShow) {
        CGRect frame = self.frame;
        if (frame.size.width != inputBarWidth) {
            frame.size.width = inputBarWidth;
            self.frame = frame;
            self.backImageView.center = CGPointMake(inputBarWidth / 2, self.backImageView.center.y);
        }
        [self showBottom:NO];
        [self stopVoicePlayerIfNeed];
        [self.speechRecognizer startListening];
    }
}

- (void)showBottom:(BOOL)isShow {
    self.bottomView.hidden = !isShow;
}

- (void)stopListening {
    if (self.speechRecognizer && [self.speechRecognizer isListening]) {
        [self.speechRecognizer stopListening];
        self.imageView.image = [self imageFromiFlyBundle:@"voice_input_grey"];
    }
}

- (void)stopVoicePlayerIfNeed {
    if ([RCVoicePlayer defaultPlayer].isPlaying) {
        [[RCVoicePlayer defaultPlayer] stopPlayVoice];
    }
}

- (IFlySpeechRecognizer *)speechRecognizer {
    if (!_speechRecognizer) {
        _speechRecognizer = [IFlySpeechRecognizer sharedInstance];
        [_speechRecognizer setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        _speechRecognizer.delegate = self;
    }
    return _speechRecognizer;
}

#pragma mark - IFlySpeechRecognizerDelegate
- (void)onError:(IFlySpeechError *)errorCode {
    if (self.delegate && [self.delegate respondsToSelector:@selector(onError:)]) {
        [self.delegate onError:errorCode.errorDesc];
    }
}

- (void)onResults:(NSArray *)results isLast:(BOOL)isLast {
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@", key];
    }
    NSString *resultFromJson = [RCISRDataHelper stringFromJson:resultString];

    NSLog(@"_result=%@", self.result);
    NSLog(@"resultFromJson=%@", resultFromJson);
    [_result appendString:resultFromJson];
    if (isLast) {
        NSLog(@"Dictation results(json)：%@", self.result);
        if ([self.result isEqualToString:@"。"]) {
            self.result = [NSMutableString new];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(voiceTransferToText:)]) {
            [self.delegate voiceTransferToText:self.result];
        }
        if (self.result && self.result.length > 0) {
            NSLog(@"result string %@", self.result);
            [self showBottom:YES];
        }
        self.result = [NSMutableString new];
        self.imageView.image = [self imageFromiFlyBundle:@"voice_input_grey"];
    }
}

- (void)onVolumeChanged:(int)volume {
    int index = volume;
    if (index > 14) {
        index = 14;
    }
    __weak typeof(self) ws = self;
    [UIView animateWithDuration:.003
                     animations:^{
                         NSString *imageName = [NSString stringWithFormat:@"voice_input_%d", index];
                         ws.imageView.image = [ws imageFromiFlyBundle:imageName];
                     }];
}

- (void)resetMicroPhoneStatus {
    self.imageView.image = [self imageFromiFlyBundle:@"voice_input_grey"];
    __weak typeof(self) ws = self;
    [UIView animateWithDuration:.3
                     animations:^{
                         ws.imageView.image = [ws imageFromiFlyBundle:@"voice_input_blue"];
                     }];
}

- (UIImage *)imageFromiFlyBundle:(NSString *)imageName {
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"RongCloudiFly" ofType:@"bundle"];
    NSString *imagePath = [bundlePath stringByAppendingPathComponent:imageName];

    UIImage *bundleImage = [UIImage imageWithContentsOfFile:imagePath];
    return bundleImage;
}

#pragma mark RCDVoiceInputViewDelegate

- (void)clearEvent {
    if (self.delegate && [self.delegate respondsToSelector:@selector(clearText)]) {
        [self.delegate clearText];
    }
}

- (void)sendEvent {
    if (self.delegate && [self.delegate respondsToSelector:@selector(sendText)]) {
        [self.delegate sendText];
    }
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end
