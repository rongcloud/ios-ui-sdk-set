//
//  RCDestructGIFPreviewViewController.m
//  RongIMKit
//
//  Created by Zhaoqianyu on 2019/9/3.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCDestructGIFPreviewViewController.h"
#import "RCGIFImage.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCDestructCountDownButton.h"
#import "RCCoreClient+Destructing.h"
#import "RCImageMessageProgressView.h"
#import "RCSemanticContext.h"

@interface RCDestructGIFPreviewViewController ()

@property (nonatomic, strong) NSData *gifData;

// 展示GIF的view
@property (nonatomic, strong) RCGIFImageView *gifView;

@property (nonatomic, strong) RCDestructCountDownButton *rightTopButton;

@property (nonatomic, strong) RCImageMessageProgressView *progressView;


@end

@implementation RCDestructGIFPreviewViewController
#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xf0f0f6", @"0x000000");
    [self setNav];
    [self addSubViews];
    [self configModel];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMessageDestructing:)
                                                 name:RCKitMessageDestructingNotification
                                               object:nil];
}

#pragma mark - Private Methods

- (void)setNav {
    //设置左键
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    imgMirror = [RCSemanticContext imageflippedForRTL:imgMirror];
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:RCLocalizedString(@"Back") target:self action:@selector(clickBackBtn:)];
}

- (void)addSubViews {
    [self.view addSubview:self.gifView];
    [self.view addSubview:self.rightTopButton];
    NSNumber *duration = [[RCCoreClient sharedCoreClient] getDestructMessageRemainDuration:self.messageModel.messageUId];
    if (duration != nil && [duration integerValue] < 30) {
        [self.rightTopButton setDestructCountDownButtonHighlighted];
    }
    [self.rightTopButton messageDestructing:[duration integerValue]];
}

- (void)configModel {
    if (!self.messageModel) {
        return;
    }
    RCMessage *msg = [[RCCoreClient sharedCoreClient] getMessage:self.messageModel.messageId];
    RCGIFMessage *gifMessage = (RCGIFMessage *)msg.content;
    if (gifMessage && gifMessage.localPath.length > 0) {
        [[RCCoreClient sharedCoreClient] messageBeginDestruct:msg];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.gifData = [NSData dataWithContentsOfFile:gifMessage.localPath];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.gifData) {
                    self.gifView.animatedImage = [RCGIFImage animatedImageWithGIFData:self.gifData];
                }
            });
        });
    }else{
        [self downLoadGif];
    }
}

- (void)downLoadGif {
    [self showProgressView];
    [[RCIM sharedRCIM] downloadMediaMessage:self.messageModel.messageId  progress:^(int progress) {
        dispatch_main_async_safe(^{
            [self.progressView updateProgress:progress];
        });
    } success:^(NSString *mediaPath) {
        dispatch_main_async_safe(^{
            [self hiddenProgressView];
            [self configModel];
        });
    } error:^(RCErrorCode errorCode) {
        dispatch_main_async_safe(^{
            [self hiddenProgressView];
            [self showFailedView];
        });
    } cancel:^{
        
    }];
}

- (void)showFailedView{
    RCBaseImageView *failedImageView = [[RCBaseImageView alloc] init];
    failedImageView.image = RCDynamicImage(@"conversation_msg_cell_image_broken_img", @"broken");
    failedImageView.frame = CGRectMake(0, 0, 81, 60);
    failedImageView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2-60);
    UILabel *failLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - 75, self.view.frame.size.height / 2 - 26, 150, 30)];
    failLabel.text = RCLocalizedString(@"ImageLoadFailed");
    failLabel.textAlignment = NSTextAlignmentCenter;
    failLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0x999999", @"0x999999");
    [self.view addSubview:failedImageView];
    [self.view addSubview:failLabel];
}

- (void)showProgressView{
    [self.view addSubview:self.progressView];
    [self.progressView setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2-60)];
    [self.progressView startAnimating];
}

- (void)hiddenProgressView{
    [self.progressView stopAnimating];
    [self.progressView removeFromSuperview];
}

- (void)clickBackBtn:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle {
    [RCAlertView showAlertController:title message:message cancelTitle:cancelTitle inViewController:self];
}

- (void)onMessageDestructing:(NSNotification *)notification {
    NSDictionary *dataDict = notification.userInfo;
    RCMessage *message = dataDict[@"message"];
    NSInteger duration = [dataDict[@"remainDuration"] integerValue];
    if (![message.messageUId isEqualToString:self.messageModel.messageUId]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (duration >= 0 && duration <= 30) {
            if (self.rightTopButton.isDestructCountDownButtonHighlighted == NO) {
                [self.rightTopButton setDestructCountDownButtonHighlighted];
            }
            [self.rightTopButton messageDestructing:duration];
            if (duration == 0) {
                [self onMessageDestructDestory:message];
            }
        }
    });
}

- (void)onMessageDestructDestory:(RCMessage *)message {
    if (![message.messageUId isEqualToString:self.messageModel.messageUId]) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

#pragma mark - Getters and Setters

- (RCGIFImageView *)gifView {
    if (!_gifView) {
        CGRect viewFrame = self.view.bounds;
        CGFloat homeBarHeight = [self getSafeAreaExtraBottomHeight];
        CGFloat NavBarHeight = [self getDeviceNavBarHeight];
        _gifView = [[RCGIFImageView alloc]
            initWithFrame:CGRectMake(0, 0, viewFrame.size.width, viewFrame.size.height - NavBarHeight - homeBarHeight)];
        _gifView.userInteractionEnabled = YES;
        _gifView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _gifView;
}

- (CGFloat)getSafeAreaExtraBottomHeight {
    return [RCKitUtility getWindowSafeAreaInsets].bottom;
}

- (CGFloat)getDeviceNavBarHeight {
    return [RCKitUtility getWindowSafeAreaInsets].top;
}

- (UIButton *)rightTopButton {
    if (!_rightTopButton) {
        _rightTopButton = [[RCDestructCountDownButton alloc] initWithFrame:CGRectMake(12, 12, 20, 20)];
    }
    return _rightTopButton;
}

- (RCImageMessageProgressView *)progressView{
    if (!_progressView) {
        _progressView =
            [[RCImageMessageProgressView alloc] initWithFrame:CGRectMake(0, 0, 135, 135)];
        _progressView.label.hidden = YES;
        _progressView.indicatorView.color = RCDynamicColor(@"text_secondary_color", @"0x999999", @"0x999999");
        _progressView.backgroundColor = [UIColor clearColor];
    }
    return _progressView;
}
@end
