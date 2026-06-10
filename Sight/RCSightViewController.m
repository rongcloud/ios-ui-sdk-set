//
//  RCSightViewController.m
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/4/24.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightViewController.h"
#import "RCSightActionButton.h"
#import "RCSightCapturer.h"
#import "RCSightPlayerController.h"
#import "RCSightPreviewView.h"
#import "RCSightRecorder.h"
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreMotion/CoreMotion.h>
#import <Photos/Photos.h>
#import "RongSightAdaptiveHeader.h"
#import "RCSightExtensionModule.h"
#import "RCToastView.h"
#import "RCSightPlayerOverlay.h"
#define ActionBtnSize 120
#define BottomSpace 10
#define OKBtnSize 74
#define AnimateDuration 0.2
#define CommonBtnSize 44
#define Marging 8
#define YOffset ISX ? 28 : 8

AVCaptureVideoOrientation orientationBaseOnAcceleration(CMAcceleration acceleration) {
    AVCaptureVideoOrientation result;
    if (acceleration.x >= 0.75) { /// UIDeviceOrientationLandscapeRight
        result = AVCaptureVideoOrientationLandscapeLeft;
    } else if (acceleration.x <= -0.75) { /// UIDeviceOrientationLandscapeLeft
        result = AVCaptureVideoOrientationLandscapeRight;
    } else if (acceleration.y <= -0.75) { /// UIDeviceOrientationPortrait
        result = AVCaptureVideoOrientationPortrait;
    } else if (acceleration.y >= 0.75) { /// UIDeviceOrientationPortraitUpsideDown
        result = AVCaptureVideoOrientationPortraitUpsideDown;
    } else {
        result = AVCaptureVideoOrientationPortrait;
    }
    return result;
}

@interface RCSightViewController () <RCSightRecorderDelegate, RCSightCapturerOutputDelegate,
                                     RCSightPlayerControllerDelegate, RCSightPreviewViewDelegate>
@property (nonatomic, strong) RCSightPreviewView *sightView;
@property (nonatomic, strong) RCSightCapturer *capturer;
@property (nonatomic, strong) RCBaseButton *switchCameraBtn;
@property (nonatomic, strong) RCBaseButton *dismissBtn;
@property (nonatomic, strong) RCBaseImageView *stillImageView;
@property (nonatomic, strong) RCBaseButton *playBtn;
@property (nonatomic, strong) RCSightActionButton *actionButton;
@property (nonatomic, strong) RCBaseButton *cancelBtn;
@property (nonatomic, strong) RCBaseButton *okBtn;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, strong) RCSightRecorder *recorder;
@property (nonatomic, strong) RCSightPlayerController *playerController;
@property (nonatomic, strong) NSURL *outputUrl;
@property (nonatomic, strong) UIImage *sightThumbnail;
@property (nonatomic, strong) UILabel *tipsLable;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) CTCallCenter *callCenter;
@property (nonatomic, assign) NSTimeInterval beginTime;
@property (nonatomic, assign) NSTimeInterval endTime;
@property (nonatomic, assign) RCSightViewControllerCameraCaptureMode captureMode;
@property (nonatomic, strong) CMMotionManager *motionManager;
@end

@implementation RCSightViewController {
    BOOL _statusBarHidden;
}

- (void)dealloc {
    [self.actionButton quit];
    
    [RCSightExtensionModule sharedInstance].isSightCameraHolding = NO;
    [self.motionManager stopAccelerometerUpdates];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidChangeStatusBarOrientationNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVCaptureSessionInterruptionEndedNotification
                                                  object:nil];
}
#pragma mark - Properties
- (RCSightPreviewView *)sightView {
    if (!_sightView) {
        _sightView = [[RCSightPreviewView alloc] initWithFrame:CGRectZero];
        _sightView.delegate = self;
    }
    return _sightView;
}

- (RCSightCapturer *)capturer {
    if (!_capturer) {
        _capturer = [[RCSightCapturer alloc] initWithVideoPreviewPlayer:self.sightView.previewLayer];
        _capturer.delegate = self;
    }
    return _capturer;
}

- (RCBaseImageView *)stillImageView {
    if (!_stillImageView) {
        _stillImageView = [[RCBaseImageView alloc] initWithFrame:CGRectZero];
        // TODO_yangyudong
        if ([[UIDevice currentDevice].model containsString:@"iPad"]) {
            _stillImageView.contentMode = UIViewContentModeScaleAspectFill;
        } else {
            _stillImageView.contentMode = UIViewContentModeScaleAspectFit;
        }
        _stillImageView.backgroundColor = [UIColor blackColor];
    }
    return _stillImageView;
}

- (RCBaseButton *)switchCameraBtn {
    if (!_switchCameraBtn) {
        _switchCameraBtn = [[RCBaseButton alloc] initWithFrame:CGRectMake(0, 0, CommonBtnSize, CommonBtnSize)];
        [_switchCameraBtn setImage:RCResourceImage(@"sight_camera_switch") forState:UIControlStateNormal];
        [_switchCameraBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _switchCameraBtn.backgroundColor = [UIColor clearColor];
        [_switchCameraBtn addTarget:self
                             action:@selector(switchCameraAction:)
                   forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchCameraBtn;
}

- (RCBaseButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [[RCBaseButton alloc] initWithFrame:CGRectMake(0, 0, OKBtnSize, OKBtnSize)];
        [_playBtn setImage:RCResourceImage(@"sight_play_btn") forState:UIControlStateNormal];
        [_playBtn setImage:RCResourceImage(@"sight_pause_btn") forState:UIControlStateSelected];
        [_playBtn addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
        _playBtn.enabled = NO;
    }
    return _playBtn;
}

- (RCSightActionButton *)actionButton {
    if (!_actionButton) {
        _actionButton = [[RCSightActionButton alloc] initWithFrame:CGRectMake(0, 0, ActionBtnSize, ActionBtnSize)];
        _actionButton.userInteractionEnabled = NO;
    }
    return _actionButton;
}

- (RCBaseButton *)dismissBtn {
    if (!_dismissBtn) {
        _dismissBtn = [[RCBaseButton alloc] initWithFrame:CGRectMake(0, 0, OKBtnSize, OKBtnSize)];
        [_dismissBtn setImage:RCResourceImage(@"sight_top_toolbar_close") forState:UIControlStateNormal];
        _dismissBtn.backgroundColor = [UIColor clearColor];
        [_dismissBtn addTarget:self action:@selector(dismissAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _dismissBtn;
}

- (RCBaseButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [[RCBaseButton alloc] initWithFrame:CGRectMake(0, 0, OKBtnSize, OKBtnSize)];
        [_cancelBtn setImage:RCResourceImage(@"sight_preview_cancel") forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
        _cancelBtn.enabled = NO;
    }
    return _cancelBtn;
}

- (RCBaseButton *)okBtn {
    if (!_okBtn) {
        _okBtn = [[RCBaseButton alloc] initWithFrame:CGRectMake(0, 0, OKBtnSize, OKBtnSize)];
        [_okBtn setImage:RCResourceImage(@"sight_preview_done") forState:UIControlStateNormal];
        [_okBtn addTarget:self action:@selector(okAction:) forControlEvents:UIControlEventTouchUpInside];
        _okBtn.enabled = NO;
    }
    return _okBtn;
}

- (RCSightRecorder *)recorder {
    if (!_recorder) {
        _recorder = [[RCSightRecorder alloc] initWithVideoSettings:self.capturer.recommendedVideoCompressionSettings
                                                     audioSettings:self.capturer.recommendedAudioCompressionSettings
                                                     dispatchQueue:self.capturer.sessionQueue];
        _recorder.delegate = self;
    }
    return _recorder;
}

- (UILabel *)tipsLable {
    if (!_tipsLable) {
        _tipsLable = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 21)];
        _tipsLable.font = [UIFont systemFontOfSize:14.0f];
        _tipsLable.textAlignment = NSTextAlignmentCenter;
        NSString *text = RCLocalizedString(@"TouchToTakeAPictureAndPressAndholdTheRecordingVideo");
        CGSize textSize = [text sizeWithAttributes:@{NSFontAttributeName : _tipsLable.font}];
        _tipsLable.frame = CGRectMake(0, 0, textSize.width, textSize.height);
        _tipsLable.text = text;
        _tipsLable.textColor = [UIColor whiteColor];
    }
    return _tipsLable;
}

- (RCSightPlayerController *)playerController {
    if (!_playerController) {
        _playerController = [[RCSightPlayerController alloc] init];
        _playerController.overlayHidden = YES;
        _playerController.delegate = self;
        _playerController.isLoopPlayback = YES;
        [_playerController.overlay.centerPlayBtn removeFromSuperview];
    }
    return _playerController;
}

- (CTCallCenter *)callCenter {
    if (!_callCenter) {
        _callCenter = [[CTCallCenter alloc] init];
    }
    return _callCenter;
}

- (CMMotionManager *)motionManager {
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    return _motionManager;
}

#pragma mark - Init
- (instancetype)initWithCaptureMode:(RCSightViewControllerCameraCaptureMode)mode {
    if (self = [super init]) {
        self.captureMode = mode;
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self
                          selector:@selector(appWillEnterBackground)
                              name:UIApplicationDidEnterBackgroundNotification
                            object:nil];
        [defaultCenter addObserver:self
                                selector:@selector(sessionInterruptionEnded:)
                                    name:AVCaptureSessionInterruptionEndedNotification
                                  object:nil];


    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        self.captureMode = RCSightViewControllerCameraCaptureModeSight;
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self
                          selector:@selector(appWillEnterBackground)
                              name:UIApplicationDidEnterBackgroundNotification
                            object:nil];
        [defaultCenter addObserver:self
                                selector:@selector(sessionInterruptionEnded:)
                                    name:AVCaptureSessionInterruptionEndedNotification
                                  object:nil];


    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [RCSightExtensionModule sharedInstance].isSightCameraHolding = YES;
    [self registerNotification];
    // Do any additional setup after loading the view.
    [self setAudioSessionCategory];
    [self.view addSubview:self.sightView];
    [self strechToSuperview:self.sightView];
#if !(TARGET_OS_SIMULATOR)
    [self.capturer startRunning];
    if (![self.capturer cameraSupportsTapToFocus]) {
        [self.sightView showFocusBoxAnimationAtPoint:CGPointMake(0.5, 0.5)];
    }
#endif
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    self.switchCameraBtn.frame =
        CGRectMake(screenSize.width - CommonBtnSize - Marging, YOffset, CommonBtnSize, CommonBtnSize);
    [self.view addSubview:self.switchCameraBtn];

    [self.view addSubview:self.playerController.view];
    [self strechToSuperview:self.playerController.view];
    self.playerController.view.hidden = YES;

    [self.view addSubview:self.stillImageView];
    [self strechToSuperview:self.stillImageView];
    self.stillImageView.hidden = YES;

    __weak typeof(self) weakSelf = self;
    [self.actionButton setAction:^(RCSightActionState state) {
        [weakSelf handleActionState:state];
    }];

    if (RCSightViewControllerCameraCaptureModePhoto == self.captureMode) {
        self.actionButton.supportLongPress = NO;
    }

    [self.view addSubview:self.dismissBtn];
    [self.view addSubview:self.cancelBtn];
    [self.view addSubview:self.okBtn];
    [self.view addSubview:self.playBtn];

    [self.view addSubview:self.actionButton];
    [self.view addSubview:self.tipsLable];

    self.actionButton.center = CGPointMake(screenSize.width / 2, screenSize.height - ActionBtnSize - BottomSpace);
    self.actionButton.accessibilityLabel = @"actionButton";
    
    self.cancelBtn.center = self.actionButton.center;
    self.cancelBtn.accessibilityLabel = @"cancelBtn";

    self.okBtn.center = self.actionButton.center;
    self.okBtn.accessibilityLabel = @"okBtn";

    self.playBtn.center = self.actionButton.center;
    self.playBtn.accessibilityLabel = @"playBtn";

    self.dismissBtn.frame = CGRectMake(Marging, YOffset, CommonBtnSize, CommonBtnSize);
    self.dismissBtn.accessibilityLabel = @"dismissBtn";

    self.tipsLable.center = CGPointMake(screenSize.width / 2, self.actionButton.frame.origin.y - 16);
    if (RCSightViewControllerCameraCaptureModeSight == self.captureMode) {
        [self performSelector:@selector(setStatusBarHidden:) withObject:@(YES) afterDelay:0.5];
    }

    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (AVAuthorizationStatusAuthorized != authorizationStatus) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                 completionHandler:^(BOOL granted) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         if (granted) {
                                             [self.sightView showFocusBoxAnimationAtPoint:CGPointMake(0.5, 0.5)];
                                         } else {
                                             self.actionButton.userInteractionEnabled = NO;
                                         }
                                     });
                                 }];
    }

    /// 设置来电时的事件处理
    [self.callCenter setCallEventHandler:^(CTCall *call) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (call.callState == CTCallStateIncoming) {
                [weakSelf dismissViewControllerAnimated:NO completion:nil];
            }
        });
    }];

    [self.motionManager startAccelerometerUpdates];
    [self setVideoOrientation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self hideTipsLabel];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
}

- (void)setStatusBarHidden:(NSNumber *)hidden {
    _statusBarHidden = [hidden boolValue];
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                     }];
}

#pragma mark - override

- (BOOL)prefersStatusBarHidden {
    return _statusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (BOOL)shouldAutorotate {
    return NO;
}

#pragma mark - Helpers
- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeDeviceOrientationNotification:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didCreateNewSession)
                                                 name:@"RCCallNewSessionCreation Notification"
                                               object:nil];
}

- (void)didChangeDeviceOrientationNotification:(NSNotification *)notification {
    [self updateSubViewsAutolayout];
    [self setVideoOrientation];
}

- (void)updateSubViewsAutolayout {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    self.switchCameraBtn.frame =
        CGRectMake(screenSize.width - CommonBtnSize - Marging, YOffset, CommonBtnSize, CommonBtnSize);
    self.actionButton.center = CGPointMake(screenSize.width / 2, screenSize.height - ActionBtnSize - BottomSpace);
    if (self.actionButton.hidden) {
        self.cancelBtn.center = CGPointMake(65.5, screenSize.height - ActionBtnSize - BottomSpace);
        self.okBtn.center = CGPointMake(screenSize.width - 65.5, screenSize.height - ActionBtnSize - BottomSpace);
    } else {
        self.cancelBtn.center = CGPointMake(screenSize.width / 2, screenSize.height - ActionBtnSize - BottomSpace);
        self.okBtn.center = CGPointMake(screenSize.width / 2, screenSize.height - ActionBtnSize - BottomSpace);
    }
    self.playBtn.center = self.actionButton.center;
    self.tipsLable.center = CGPointMake(screenSize.width / 2, self.actionButton.frame.origin.y - 16);
}

- (void)setVideoOrientation {
    if ([[UIDevice currentDevice].model containsString:@"iPad"]) {
        AVCaptureVideoOrientation orientation =
            (AVCaptureVideoOrientation)[UIApplication sharedApplication].statusBarOrientation;
        if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
            orientation = AVCaptureVideoOrientationLandscapeLeft;
        } else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
            orientation = AVCaptureVideoOrientationLandscapeRight;
        }
        self.sightView.previewLayer.connection.videoOrientation = orientation;
    }
}

- (void)didCreateNewSession {
#if !(TARGET_OS_SIMULATOR)
    [self.capturer stopRunning];
#endif
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)strechToSuperview:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *formats = @[ @"H:|[view]|", @"V:|[view]|" ];
    for (NSString *each in formats) {
        NSArray *constraints =
            [NSLayoutConstraint constraintsWithVisualFormat:each options:0 metrics:nil views:@{
                @"view" : view
            }];
        [self.view addConstraints:constraints];
    }
}

- (void)showStillImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.stillImageView.image = image;
        self.stillImageView.hidden = NO;
    });
}

- (void)handleActionState:(RCSightActionState)states {
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if (authorizationStatus == AVAuthorizationStatusRestricted || authorizationStatus == AVAuthorizationStatusDenied) {
        self.actionButton.userInteractionEnabled = NO;
        return;
    }
    switch (states) {
    case RCSightActionStateBegin:
        self.dismissBtn.hidden = YES;
        self.playBtn.hidden = YES;
        [self startRecording];
        break;
    case RCSightActionStateClick:
        self.dismissBtn.hidden = YES;
        self.playBtn.hidden = YES;
#if !(TARGET_OS_SIMULATOR)
        [self takeAPhoto];
#else
        [self showStillImage:nil];
#endif
        break;
    case RCSightActionStateDidCancel:
    case RCSightActionStateEnd:
        self.actionButton.hidden = YES;
        [self stopRecording];
        break;
    case RCSightActionStateWillCancel:
        break;
    case RCSightActionStateMoving:
        break;
    default:
        break;
    }
}

- (void)takeAPhoto {
    __weak typeof(self) weakSelf = self;
    CMAcceleration acceleration = self.motionManager.accelerometerData.acceleration;
    AVCaptureVideoOrientation orientation = orientationBaseOnAcceleration(acceleration);
    [self.capturer captureStillImage:orientation
                          completion:^(UIImage *image) {
                              [weakSelf showOkCancelBtnWithAnimation:NO];
                              [weakSelf showStillImage:image];
                          }];
}

- (void)startRecording {
    if (!self.isRecording) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(updateTimeLabel)
                                                    userInfo:nil
                                                     repeats:YES];
        self.isRecording = YES;
#if !(TARGET_OS_SIMULATOR)
        CMAcceleration acceleration = self.motionManager.accelerometerData.acceleration;
        AVCaptureVideoOrientation orientation = orientationBaseOnAcceleration(acceleration);
        [self.recorder prepareToRecord:orientation];
#endif
        self.tipsLable.hidden = NO;
        self.beginTime = [[NSDate date] timeIntervalSince1970];
        [self updateTimeLabel];
    }
}

- (void)stopRecording {
    if (self.isRecording) {
        self.isRecording = NO;
#if !(TARGET_OS_SIMULATOR)
        [self.recorder finishRecording];
#else
        [self sightRecorder:nil didWriteMovieAtURL:nil];
        self.endTime = [[NSDate date] timeIntervalSince1970];
        [self updateTimeLabel];
        [self hideTipsLabel];
#endif
        [self.timer invalidate];
    }
}

- (void)showOkCancelBtnWithAnimation:(BOOL)showPlayBtn {
    self.actionButton.hidden = YES;
    [UIView animateWithDuration:AnimateDuration
                     animations:^{
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        if ([RCKitUtility isRTL]) {
            self.okBtn.center = CGPointMake(65.5, screenSize.height - ActionBtnSize - BottomSpace);
            self.cancelBtn.center = CGPointMake(screenSize.width - 65.5, screenSize.height - ActionBtnSize - BottomSpace);
        } else {
            self.cancelBtn.center = CGPointMake(65.5, screenSize.height - ActionBtnSize - BottomSpace);
            self.okBtn.center = CGPointMake(screenSize.width - 65.5, screenSize.height - ActionBtnSize - BottomSpace);
        }
    }
        completion:^(BOOL finished) {
            self.playBtn.hidden = !showPlayBtn;
            self.cancelBtn.hidden = NO;
            self.okBtn.hidden = NO;
            self.playBtn.enabled = YES;
            self.okBtn.enabled = YES;
            self.cancelBtn.enabled = YES;
        }];
}

- (void)sightFailed {
    self.actionButton.hidden = YES;
    self.okBtn.hidden = YES;
    self.playBtn.hidden = YES;
    [UIView animateWithDuration:AnimateDuration
        animations:^{
            CGSize screenSize = [UIScreen mainScreen].bounds.size;
            self.cancelBtn.center = CGPointMake(65.5, screenSize.height - ActionBtnSize - BottomSpace);
            self.okBtn.center = CGPointMake(screenSize.width - 65.5, screenSize.height - ActionBtnSize - BottomSpace);
        }
        completion:^(BOOL finished) {
            // 录制失败 只显示取消按钮
            self.cancelBtn.hidden = NO;
            self.cancelBtn.enabled = YES;
        }];
    [self resetCapture];
    [RCToastView showToast:RCLocalizedString(@"SightCaptureFailed") rootView:self.view];
}

- (void)hideTipsLabel {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!weakSelf.isRecording) {
            weakSelf.tipsLable.text = @"";
            weakSelf.tipsLable.backgroundColor = [UIColor clearColor];
        }
    });
}

- (void)updateTimeLabel {
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
    [self updateTimeLabelWithEndTime:current];
}

- (void)updateTimeLabelWithEndTime:(NSTimeInterval)endTime {
    NSTimeInterval current = endTime;
    long seconds = round(current - self.beginTime);
    seconds = seconds > self.actionButton.canRecordMaxDuration ? self.actionButton.canRecordMaxDuration : seconds;
    NSString *tipsText = 0 == seconds ? @"" : [NSString stringWithFormat:@"%ld\"", (long)seconds];
    self.tipsLable.text = tipsText;
}

- (void)setAudioSessionCategory {
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    //保持后台音乐播放
    if (@available(iOS 10.0, *)) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                         withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                               error:nil];
    } else {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                         withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                               error:nil];
    }
}

- (void)resetCapture {
#if !(TARGET_OS_SIMULATOR)
    if (self.capturer) {
        [self.capturer stopRunning];
        self.capturer = nil;
        [self.capturer startRunning];
    }
#endif
}

#pragma mark - RCSightViewDelegate
- (void)cancelVideoPreview {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Target action
- (void)switchCameraAction:(UIButton *)sender {
    [self setAudioSessionCategory];
#if !(TARGET_OS_SIMULATOR)
    [self.capturer switchCamera];
#endif
}

- (void)dismissAction:(UIButton *)sender {
#if !(TARGET_OS_SIMULATOR)
    [self.capturer stopRunning];
#endif
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelAction:(UIButton *)sender {
    //[self.playerController reset];
    self.tipsLable.hidden = NO;
    [self hideTipsLabel];
    self.cancelBtn.hidden = YES;
    self.okBtn.hidden = YES;
    [UIView animateWithDuration:AnimateDuration
        animations:^{
            CGSize screenSize = [UIScreen mainScreen].bounds.size;
            self.cancelBtn.center = CGPointMake(screenSize.width / 2, screenSize.height - ActionBtnSize - BottomSpace);
            self.okBtn.center = CGPointMake(screenSize.width / 2, screenSize.height - ActionBtnSize - BottomSpace);
        }
        completion:^(BOOL finished) {
            self.playBtn.hidden = NO;
            self.actionButton.hidden = NO;
            self.dismissBtn.hidden = NO;
            self.stillImageView.hidden = YES;
            self.playBtn.selected = NO;
#if !(TARGET_OS_SIMULATOR)
            [self.playerController resetSightPlayer];
            [self.capturer resetAudioSession];
            [self.capturer resetSessionInput];
#endif
            [self setAudioSessionCategory];
            self.playerController.view.hidden = YES;
        }];
    
}

- (void)okAction:(UIButton *)sender {
    if (!self.stillImageView.hidden) {
        [self.capturer stopRunning];
        if ([self.delegate respondsToSelector:@selector(sightViewController:didFinishCapturingStillImage:)]) {
            self.stillImageView.hidden = YES;
            [self.delegate sightViewController:self didFinishCapturingStillImage:self.stillImageView.image];
        }
    } else {
        [self.capturer stopRunning];
        [self.playerController resetSightPlayer];
        [self.playerController.view removeFromSuperview];
        if ([self.delegate respondsToSelector:@selector(sightViewController:didWriteSightAtURL:thumbnail:duration:)]) {

            long seconds = round(self.endTime - self.beginTime);
            seconds =
                seconds > self.actionButton.canRecordMaxDuration ? self.actionButton.canRecordMaxDuration : seconds;
            [self.delegate sightViewController:self
                            didWriteSightAtURL:self.outputUrl
                                     thumbnail:self.sightThumbnail
                                      duration:seconds];
            //将小视频存入相册
            if (self.outputUrl) {
                PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
                [photoLibrary performChanges:^{
                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:self.outputUrl];
                }
                    completionHandler:^(BOOL success, NSError *_Nullable error) {
                        if (success) {
                            NSLog(@"RongIMKit small video saved to album");
                        } else {
                            NSLog(@"RongIMKit failed to save small video to album");
                        }
                    }];
            }
        }
    }
}

- (void)playAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self.playerController play];
    } else {
        [self.playerController pause];
    }
}

#pragma mark - RCSightRecorderDelegate
- (void)sightRecorder:(RCSightRecorder *)recorder didWriteMovieAtURL:(NSURL *)outputURL {
    NSDictionary *dic = @{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)};
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:outputURL options:dic];
    CMTime audioDuration = audioAsset.duration;
    Float64 audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    
    //录制成功，需要读取一下视频文件的总时长，保证精准
    self.endTime = self.beginTime + audioDurationSeconds;
    [self updateTimeLabelWithEndTime:self.endTime];
    [self hideTipsLabel];

    long duration = round(self.endTime - self.beginTime);
    if (0 == duration) {
        self.playBtn.hidden = YES;
        [self takeAPhoto];
        return;
    }
    [self showOkCancelBtnWithAnimation:YES];
#if TARGET_OS_SIMULATOR
    return;
#else
    self.outputUrl = outputURL;
    self.playerController.rcSightURL = self.outputUrl;
    self.sightThumbnail = [self.playerController firstFrameImage];
    [self.playerController setFirstFrameThumbnail:self.sightThumbnail];
    //[self.playerController play];
    self.playerController.view.hidden = NO;
#endif
}

- (void)sightRecorder:(RCSightRecorder *)recorder
     didFailWithError:(NSError *)error
               status:(NSInteger)status {
    self.endTime = [[NSDate date] timeIntervalSince1970];
    [self updateTimeLabel];
    [self hideTipsLabel];

    long duration = round(self.endTime - self.beginTime);
    if (0 == duration) {
        self.playBtn.hidden = YES;
        [self takeAPhoto];
    }else {
        // 录制失败 并且超过1s 给出失败提示
        [self sightFailed];
    }
    if ([self.delegate respondsToSelector:@selector(sightViewController:didWriteFailedWith:status:)]) {
        [self.delegate sightViewController:self
                        didWriteFailedWith:error
                                    status:status];
    }
}

#pragma mark - RCSightCapturerDelegate
- (void)didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self.recorder processSampleBuffer:sampleBuffer];
}

- (void)focusDidfinish:(CGPoint)point {
    CGPoint interestPoint = [self.sightView.previewLayer pointForCaptureDevicePointOfInterest:point];
    [self.sightView showFocusBoxAnimationAtPoint:interestPoint];
    self.actionButton.userInteractionEnabled = YES;
}

#pragma mark - RCSightPlayerControllerDelegate
- (void)playToEnd {
    self.playBtn.selected = NO;
}

#pragma mark - RCSightPreviewViewDelegate
- (void)tappedToFocusAtPoint:(CGPoint)point {
    [self.capturer focusAtPoint:point];
}

#pragma mark - Notification Selector
- (void)appWillEnterBackground {
    [self.playerController pause];
    self.playBtn.selected = NO;
}

- (void)sessionInterruptionEnded:(NSNotification*)notification
{
#if !(TARGET_OS_SIMULATOR)
    [self.capturer resetAudioSession];
    [self.capturer resetSessionInput];
#endif
}
@end
