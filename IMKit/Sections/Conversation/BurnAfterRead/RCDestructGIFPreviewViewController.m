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
#import <AssetsLibrary/AssetsLibrary.h>
#import "RCGIFUtility.h"
#import "RCDestructCountDownButton.h"
#import "RCIMClient+Destructing.h"
@interface RCDestructGIFPreviewViewController ()

@property (nonatomic, strong) NSData *gifData;

// 展示GIF的view
@property (nonatomic, strong) RCGIFImageView *gifView;

@property (nonatomic, strong) RCDestructCountDownButton *rightTopButton;

@end

@implementation RCDestructGIFPreviewViewController
#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = RCDYCOLOR(0xf0f0f6, 0x000000);
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
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:RCResourceImage(@"navigator_btn_back") title:RCLocalizedString(@"Back") target:self action:@selector(clickBackBtn:)];
}

- (void)addSubViews {
    [self.view addSubview:self.gifView];
    [self.view addSubview:self.rightTopButton];
    NSNumber *duration = [[RCIMClient sharedRCIMClient] getDestructMessageRemainDuration:self.messageModel.messageUId];
    if (duration != nil && [duration integerValue] < 30) {
        [self.rightTopButton setDestructCountDownButtonHighlighted];
    }
    [self.rightTopButton messageDestructing:[duration integerValue]];
}

- (void)configModel {
    if (!self.messageModel) {
        return;
    }
    RCMessage *msg = [[RCIMClient sharedRCIMClient] getMessage:self.messageModel.messageId];
    RCGIFMessage *gifMessage = (RCGIFMessage *)msg.content;
    [[RCIMClient sharedRCIMClient] messageBeginDestruct:msg];
    if (gifMessage && gifMessage.localPath.length > 0) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            weakSelf.gifData = [NSData dataWithContentsOfFile:[RCUtilities getCorrectedFilePath:gifMessage.localPath]];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.gifData) {
                    weakSelf.gifView.animatedImage = [RCGIFImage animatedImageWithGIFData:weakSelf.gifData];
                }
            });
        });
    }
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
        _rightTopButton = [[RCDestructCountDownButton alloc] initWithFrame:CGRectMake(12, [RCKitUtility getWindowSafeAreaInsets].top + 12, 20, 20)];
    }
    return _rightTopButton;
}

@end
