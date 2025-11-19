//
//  CCSightPlayerOverlayView.m
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/4/28.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightPlayerOverlayView.h"
#import "RongSightAdaptiveHeader.h"
#define RCBottomViewAlignBottom ([RCKitUtility getWindowSafeAreaInsets].bottom + 54)
#define RCTopViewAlignHeight ([RCKitUtility getWindowSafeAreaInsets].top + 66)
#define RCCloseButtonAlignTop [RCKitUtility getWindowSafeAreaInsets].top+30
@interface RCSightPlayerOverlayView ()

@property (nonatomic, strong) RCBaseButton *playBtn;
@property (nonatomic, strong) RCBaseButton *closeBtn;
@property (nonatomic, strong) UILabel *currentTimeLab;
@property (nonatomic, strong) UILabel *durationTimeLabel;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) RCBaseButton *centerPlayBtn;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) RCBaseView *topView;
@property (nonatomic, strong) RCBaseImageView *thumbnailView;

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) NSLayoutConstraint *topYConstraint;
@property (nonatomic, strong) NSLayoutConstraint *topHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *closeYConstraint;

@property (nonatomic, assign) BOOL scrubbing;
@property (nonatomic, assign) BOOL controlsHidden;
@property (nonatomic, assign) BOOL hideCenterBtn;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) RCBaseButton *extraButton;
@end

@implementation RCSightPlayerOverlayView

#pragma mark - properties

- (RCBaseButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [[RCBaseButton alloc] init];
        [_playBtn setImage:RCResourceImage(@"player_start_button") forState:UIControlStateNormal];
        [_playBtn setImage:RCResourceImage(@"player_suspend_button") forState:UIControlStateSelected];
        [_playBtn addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (RCBaseButton *)centerPlayBtn {
    if (!_centerPlayBtn) {
        _centerPlayBtn = [[RCBaseButton alloc] initWithFrame:CGRectMake(0, 0, 63, 63)];
        [_centerPlayBtn setImage:RCResourceImage(@"play_btn_normal") forState:UIControlStateNormal];
        [_centerPlayBtn addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _centerPlayBtn;
}

- (RCBaseButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [[RCBaseButton alloc] init];
        [_closeBtn setImage:RCResourceImage(@"sight_top_toolbar_close") forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(closeAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

- (UISlider *)slider {
    if (!_slider) {
        _slider = [[UISlider alloc] init];
        [_slider setThumbImage:RCResourceImage(@"player_slider_pan") forState:UIControlStateNormal];
        [_slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_slider addTarget:self
                      action:@selector(sliderUpInside)
            forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        [_slider addTarget:self action:@selector(sliderTouchDown) forControlEvents:UIControlEventTouchDown];
        if([RCKitUtility isRTL]){
            _slider.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        }else{
            _slider.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
    }
    return _slider;
}

- (UILabel *)currentTimeLab {
    if (!_currentTimeLab) {
        _currentTimeLab = [[UILabel alloc] init];
        _currentTimeLab.textColor = [UIColor whiteColor];
        _currentTimeLab.text = @"00:00";
        _currentTimeLab.accessibilityLabel = @"currentTimeLab";
    }
    return _currentTimeLab;
}

- (RCBaseButton *)extraButton {
    if (!_extraButton) {
        _extraButton = [[RCBaseButton alloc] init];
    }
    return _extraButton;
}

- (UILabel *)durationTimeLabel {
    if (!_durationTimeLabel) {
        _durationTimeLabel = [[UILabel alloc] init];
        _durationTimeLabel.textColor = [UIColor whiteColor];
        _durationTimeLabel.text = @"--:--";
    }
    return _durationTimeLabel;
}

- (RCBaseView *)topView {
    if (!_topView) {
        _topView = [[RCBaseView alloc] init];
        RCBaseImageView *backgroudView = [[RCBaseImageView alloc] init];
        backgroudView.image = RCResourceImage(@"player_shadow_top");
        [_topView addSubview:backgroudView];
        self.topHeightConstraint = [self constrainView:_topView toSize:RCTopViewAlignHeight direction:CCSightLayoutDirectionVertical];
        [self strechToSuperview:backgroudView];
        [_topView addSubview:self.closeBtn];
        [_topView addSubview:self.extraButton];
        [self constrainView:self.closeBtn toSize:44 direction:CCSightLayoutDirectionHorizontal];
        [self constrainView:self.closeBtn toSize:44 direction:CCSightLayoutDirectionVertical];
        [self constraintAlignSuperView:self.closeBtn alignSpace:20
                             AlignMent:CCSightLayoutAlignLeading];
        self.closeYConstraint = [self constraintAlignSuperView:self.closeBtn alignSpace:RCCloseButtonAlignTop AlignMent:CCSightLayoutAlignTop];

        [self constrainView:self.extraButton toSize:44 direction:CCSightLayoutDirectionHorizontal];
        [self constrainView:self.extraButton toSize:44 direction:CCSightLayoutDirectionVertical];
        [self constraintAlignSuperView:self.extraButton alignSpace:ISX ? 31 : 9 AlignMent:CCSightLayoutAlignTop];
        [self constraintAlignSuperView:self.extraButton alignSpace:ISX ? 8 : 0 AlignMent:CCSightLayoutAlignTrailing];
    }
    return _topView;
}

- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];

        RCBaseView *contentView = [[RCBaseView alloc] init];
        contentView.backgroundColor = [UIColor clearColor];
        [_bottomView addSubview:contentView];
        [self constraintAlignSuperView:contentView alignSpace:0 AlignMent:CCSightLayoutAlignLeading];
        [self constraintAlignSuperView:contentView alignSpace:0 AlignMent:CCSightLayoutAlignTrailing];
        [self constraintAlignSuperView:contentView alignSpace:0 AlignMent:CCSightLayoutAlignTop];
        [self constraintAlignSuperView:contentView alignSpace:ISX ? 24 : 0 AlignMent:CCSightLayoutAlignBottom];

        RCBaseImageView *backgroudView = [[RCBaseImageView alloc] init];
        backgroudView.image = RCResourceImage(@"player_shadow_bottom");
        [contentView addSubview:backgroudView];
        [self strechToSuperview:backgroudView];
        [self constrainView:_bottomView toSize:RCBottomViewAlignBottom direction:CCSightLayoutDirectionVertical];

        [self constrainView:self.playBtn toSize:44 direction:CCSightLayoutDirectionHorizontal];
        [contentView addSubview:self.playBtn];

        [self constraintAlignSuperView:self.playBtn alignSpace:0 AlignMent:CCSightLayoutAlignTop];
        [self constraintAlignSuperView:self.playBtn alignSpace:0 AlignMent:CCSightLayoutAlignLeading];
        [self constraintAlignSuperView:self.playBtn alignSpace:0 AlignMent:CCSightLayoutAlignBottom];

        [self constrainView:self.currentTimeLab toSize:50 direction:CCSightLayoutDirectionHorizontal];
        [contentView addSubview:self.currentTimeLab];

        [self constraintCenterYInSuperview:self.currentTimeLab];
        [self constraintView:self.playBtn toView:self.currentTimeLab horizontalSpace:8];

        [self constrainView:self.durationTimeLabel toSize:50 direction:CCSightLayoutDirectionHorizontal];
        [contentView addSubview:self.durationTimeLabel];
        [self constraintCenterYInSuperview:self.durationTimeLabel];
        [self constraintAlignSuperView:self.durationTimeLabel alignSpace:0 AlignMent:CCSightLayoutAlignTrailing];

        [contentView addSubview:self.slider];
        [self constraintCenterYInSuperview:self.slider];
        [self constraintView:self.currentTimeLab toView:self.slider horizontalSpace:8];
        [self constraintView:self.slider toView:self.durationTimeLabel horizontalSpace:8];
        [self constraintAlignSuperView:self.slider alignSpace:0 AlignMent:CCSightLayoutAlignTop];
        [self constraintAlignSuperView:self.slider alignSpace:0 AlignMent:CCSightLayoutAlignBottom];
    }
    return _bottomView;
}

#pragma mark - init
- (instancetype)init {
    if (self = [super init]) {
        [self registerNotificationCenter];
        [self setUp];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
    }
    return self;
}

- (void)setUp {
    self.backgroundColor = [UIColor clearColor];
    self.thumbnailView = [[RCBaseImageView alloc] init];
    self.thumbnailView.backgroundColor = [UIColor blackColor];
    self.thumbnailView.userInteractionEnabled = YES;
    self.thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.thumbnailView];
    [self strechToSuperview:self.thumbnailView];

    [self addSubview:self.topView];
    [self addSubview:self.bottomView];

    [self installHorizontalFlexibleConstraintsForView:self.topView];
    self.topYConstraint =
        [self constraintAlignSuperView:self.topView alignSpace:-RCTopViewAlignHeight AlignMent:CCSightLayoutAlignTop];

    [self installHorizontalFlexibleConstraintsForView:self.bottomView];
    self.bottomConstraint =
        [self constraintAlignSuperView:self.bottomView alignSpace:-RCBottomViewAlignBottom AlignMent:CCSightLayoutAlignBottom];
    self.bottomView.hidden = YES;

    self.indicatorView =
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self addSubview:self.indicatorView];
    [self constraintCenterInSuperview:self.indicatorView];
    self.indicatorView.hidden = YES;

    [self constrainView:self.centerPlayBtn toSize:CGSizeMake(63, 63)];
    [self addSubview:self.centerPlayBtn];
    [self constraintCenterInSuperview:self.centerPlayBtn];
    self.controlsHidden = YES;

    UITapGestureRecognizer *tapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
    [self addGestureRecognizer:tapGesture];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark - Notification
- (void)registerNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarFrameNotification
                                               object:nil];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    UIDeviceOrientation interfaceOrientation = [UIDevice currentDevice].orientation;
    if (interfaceOrientation == UIDeviceOrientationLandscapeLeft || interfaceOrientation == UIDeviceOrientationLandscapeRight || interfaceOrientation == UIDeviceOrientationPortrait){
        //屏幕旋转后视图变化
        [UIView animateWithDuration:0.3 animations:^{
            self.closeYConstraint.constant = RCCloseButtonAlignTop;
            self.topHeightConstraint.constant = RCTopViewAlignHeight;
            if (self.controlsHidden) {
                self.topYConstraint.constant = -RCTopViewAlignHeight;
                self.bottomConstraint.constant = -RCBottomViewAlignBottom;
            } else {
                self.topYConstraint.constant = 0;
                if (![self.delegate prefersBottomBarHidden]) {
                    self.bottomConstraint.constant = 0;
                }
            }
            [self layoutIfNeeded];
        }];
    }
}

#pragma mark - target action
- (void)playAction:(UIButton *)sender {
    BOOL selected = !sender.selected;
    self.centerPlayBtn.selected = selected;
    self.playBtn.selected = selected;
    if (sender.selected) {
        self.centerPlayBtn.hidden = YES;
        [self.delegate play];
    } else {
        [self.delegate pause];
        self.centerPlayBtn.hidden = NO;
    }
}

- (void)closeAction:(UIButton *)sender {
    [self.delegate cancel];
}

- (void)sliderValueChanged:(UISlider *)slider {
    [self setScrubbingTime:slider.value];
    [self.delegate scrubbedToTime:slider.value];
}

- (void)sliderUpInside {
    self.scrubbing = NO;
    [self.delegate scrubbingDidEnd];
}

- (void)sliderTouchDown {
    self.scrubbing = YES;
    self.thumbnailView.hidden = YES;
    [self.delegate scrubbingDidStart];
}

#pragma mark - gesture selector
- (void)tapHandler:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGRect rect = CGRectMake(0, screenSize.height - 54, self.frame.size.width, 54);
    if (CGRectContainsPoint(rect, point)) {
        return;
    }
    [self toggleControls];
}

#pragma mark - helper

- (NSString *)formatSeconds:(NSInteger)value {
    NSInteger seconds = value % 60;
    NSInteger minutes = value / 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext(); //据说该方法返回的对象是autorelease的
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - autolayout
- (void)installHorizontalFlexibleConstraintsForView:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSString *horizontalFromat = @"H:|[view]|";
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:horizontalFromat
                                                                             options:0
                                                                             metrics:nil
                                                                               views:@{
                                                                                   @"view" : view
                                                                               }];
    [self addConstraints:horizontalConstraints];
}

typedef NS_ENUM(NSInteger, CCSightLayoutDirection) {
    CCSightLayoutDirectionHorizontal = 0,
    CCSightLayoutDirectionVertical,
};

- (NSLayoutConstraint *)constrainView:(UIView *)view toSize:(CGFloat)size direction:(CCSightLayoutDirection)direction {
    NSString *axisString = direction == CCSightLayoutDirectionHorizontal ? @"H:" : @"V:";
    NSString *formatString = [NSString stringWithFormat:@"%@[view(==size)]", axisString];
    NSDictionary *bindings = NSDictionaryOfVariableBindings(view);
    NSDictionary *metrics = @{ @"size" : @(size) };
    NSArray *constraints =
        [NSLayoutConstraint constraintsWithVisualFormat:formatString options:0 metrics:metrics views:bindings];
    [view addConstraints:constraints];
    return constraints.firstObject;
}

- (void)constraintView:(UIView *)leftview toView:(UIView *)rightView horizontalSpace:(CGFloat)space {
    leftview.translatesAutoresizingMaskIntoConstraints = NO;
    rightView.translatesAutoresizingMaskIntoConstraints = NO;
    NSString *formatString = @"H:[left]-space-[right]";
    NSDictionary *bindings = @{ @"left" : leftview, @"right" : rightView };
    NSDictionary *metrics = @{ @"space" : @(space) };
    NSArray<NSLayoutConstraint *> *constraints =
        [NSLayoutConstraint constraintsWithVisualFormat:formatString options:0 metrics:metrics views:bindings];
    constraints.firstObject.priority = UILayoutPriorityDefaultHigh;
    [leftview.superview addConstraints:constraints];
}

- (void)constraintCenterInSuperview:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *constraintY = [NSLayoutConstraint constraintWithItem:view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:view.superview
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0f
                                                                    constant:0];
    [view.superview addConstraint:constraintY];

    NSLayoutConstraint *constraintX = [NSLayoutConstraint constraintWithItem:view
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:view.superview
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0f
                                                                    constant:0];

    [view.superview addConstraint:constraintX];
}

- (void)constrainView:(UIView *)view toSize:(CGSize)size {

    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *formats = @[ @"H:[view(==width)]", @"V:[view(==height)]" ];

    for (NSString *each in formats) {
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:each
                                                                       options:0
                                                                       metrics:@{
                                                                           @"width" : @(size.width),
                                                                           @"height" : @(size.height)
                                                                       }
                                                                         views:@{
                                                                             @"view" : view
                                                                         }];
        [view addConstraints:constraints];
    }
}

- (void)constraintCenterYInSuperview:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:view
                                                                  attribute:NSLayoutAttributeCenterY
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:view.superview
                                                                  attribute:NSLayoutAttributeCenterY
                                                                 multiplier:1.0f
                                                                   constant:0];
    [view.superview addConstraint:constraint];
}

- (void)strechToSuperview:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *formats = @[ @"H:|[view]|", @"V:|[view]|" ];
    for (NSString *each in formats) {
        NSArray *constraints =
            [NSLayoutConstraint constraintsWithVisualFormat:each options:0 metrics:nil views:@{
                @"view" : view
            }];
        [view.superview addConstraints:constraints];
    }
}

- (void)animatedHideControls {
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.topYConstraint.constant = -RCTopViewAlignHeight;
                         self.bottomConstraint.constant = -RCBottomViewAlignBottom;
                         [self layoutIfNeeded];
                     }];
}

typedef NS_ENUM(NSInteger, CCSightLayoutAlignMent) {
    CCSightLayoutAlignLeading = 0,
    CCSightLayoutAlignTrailing,
    CCSightLayoutAlignTop,
    CCSightLayoutAlignBottom,
};

- (NSLayoutConstraint *)constraintAlignSuperView:(UIView *)view
                                      alignSpace:(CGFloat)space
                                       AlignMent:(CCSightLayoutAlignMent)align {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSString *formatString = nil;
    if (CCSightLayoutAlignLeading == align) {
        formatString = @"H:|-space-[view]";
    } else if (CCSightLayoutAlignTrailing == align) {
        formatString = @"H:[view]-space-|";
    } else if (CCSightLayoutAlignTop == align) {
        formatString = @"V:|-space-[view]";
    } else if (CCSightLayoutAlignBottom == align) {
        formatString = @"V:[view]-space-|";
    }
    NSDictionary *bindings = @{ @"view" : view };
    NSDictionary *metrics = @{ @"space" : @(space) };
    if (formatString.length <= 0) {
        return nil;
    }
    NSArray *constraints =
        [NSLayoutConstraint constraintsWithVisualFormat:formatString options:0 metrics:metrics views:bindings];
    [view.superview addConstraints:constraints];
    return constraints.firstObject;
}

#pragma mark - CCSightTransport

- (void)setControlBarHidden:(BOOL)hidden {
    if ([self.delegate respondsToSelector:@selector(prefersControlBardHidden)] && [self.delegate prefersControlBardHidden]) {
        return;
    }
    if (hidden) {
        self.topYConstraint.constant = -RCTopViewAlignHeight;
        self.bottomConstraint.constant = -RCBottomViewAlignBottom;
        self.controlsHidden = YES;
    } else {
        self.topYConstraint.constant = 0;
        if (self.centerPlayBtn.hidden) {
            self.bottomConstraint.constant = 0;
        }
        self.controlsHidden = NO;
    }
    [self updateConstraintsIfNeeded];
}

- (void)toggleControls {
    if ([self.delegate respondsToSelector:@selector(prefersControlBardHidden)] && [self.delegate prefersControlBardHidden]) {
        return;
    }
    if (self.bottomView.hidden) {
        self.bottomView.hidden = NO;
    }
    [UIView animateWithDuration:0.3
        animations:^{
            if (!self.controlsHidden) {
                self.topYConstraint.constant = -RCTopViewAlignHeight;
                self.bottomConstraint.constant = -RCBottomViewAlignBottom;
            } else {
                self.topYConstraint.constant = 0;
                self.closeYConstraint.constant = RCCloseButtonAlignTop;
                if (![self.delegate prefersBottomBarHidden]) {
                    self.bottomConstraint.constant = 0;
                }
            }
            [self layoutIfNeeded];
            self.controlsHidden = !self.controlsHidden;
        }
        completion:^(BOOL finished) {
            if (self.bottomConstraint.constant < 0) {
                self.bottomView.hidden = YES;
            }
        }];
}

- (void)setThumbnailImage:(UIImage *)img {
    self.thumbnailView.image = img;
}

- (void)setCurrentTime:(NSTimeInterval)time duration:(NSTimeInterval)duration {
    if (isnan(time)) {
        time = 0;
    }
    if (isnan(duration)) {
        duration = 0;
    }
    NSInteger currentSeconds = round(time);
    NSInteger durationSeconds = round(duration);
    self.durationTimeLabel.text = [self formatSeconds:durationSeconds];
    self.currentTimeLab.text = [self formatSeconds:currentSeconds];
    self.slider.minimumValue = 0.0f;
    self.slider.maximumValue = duration;
    self.slider.value = time;
}

- (void)setScrubbingTime:(NSTimeInterval)time {
    self.currentTimeLab.text = [self formatSeconds:time];
}

- (void)playbackComplete {
    self.thumbnailView.hidden = NO;
    self.playBtn.selected = NO;
    self.centerPlayBtn.selected = NO;

    if (self.hideCenterBtn) {
        return;
    }

    self.centerPlayBtn.hidden = NO;
}

- (void)hideCenterPlayBtn {
    self.hideCenterBtn = YES;
    self.centerPlayBtn.hidden = YES;
}

- (void)readyToPlay {
    self.thumbnailView.hidden = YES;
}

- (void)willPlay {
    self.playBtn.selected = YES;
}

- (void)startIndicatorViewAnimating {
    self.indicatorView.hidden = NO;
    [self.indicatorView startAnimating];
}

- (void)stopIndicatorViewAnimating {
    [self.indicatorView stopAnimating];
    self.indicatorView.hidden = YES;
}

@end
