//
//  RCGIFPreviewViewController.m
//  RongIMKit
//
//  Created by liyan on 2018/12/24.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCGIFPreviewViewController.h"
#import "RCGIFImage.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCAssetHelper.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCIM.h"
#import "RCAlertView.h"
#import "RCActionSheetView.h"
#import "RCSemanticContext.h"
#import "RCMBProgressHUD.h"

@interface RCGIFPreviewViewController ()

@property (nonatomic, strong) NSData *gifData;

// 展示GIF的view
@property (nonatomic, strong) RCGIFImageView *gifView;

@property (nonatomic, strong) RCMBProgressHUD *progressHUD;

@end

@implementation RCGIFPreviewViewController
#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = RCDynamicColor(@"common_background_color", @"0xf0f0f6", @"0x000000");
    [self setNav];
    [self addSubViews];
    [self configModel];
    [self registerNotificationCenter];
}

#pragma mark - 数据处理
- (void)configModel {
    if (!self.messageModel && !self.messageModel.content) {
        return;
    }
    RCGIFMessage *gifMessage = (RCGIFMessage *)self.messageModel.content;
    if (gifMessage.localPath.length > 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.gifData = [NSData dataWithContentsOfFile:gifMessage.localPath];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.gifData) {
                    self.gifView.animatedImage = [RCGIFImage animatedImageWithGIFData:self.gifData];
                }
            });
        });
    } else if (gifMessage.remoteUrl.length > 0) {
        self.progressHUD =
            [RCMBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.progressHUD.label.text = RCLocalizedString(@"FileIsDownloading");
        self.progressHUD.bezelView.style = RCMBProgressHUDBackgroundStyleSolidColor;
        self.progressHUD.bezelView.color = [UIColor clearColor];
        
        __weak typeof(self) weakSelf = self;
        [[RCCoreClient sharedCoreClient] downloadMediaFile:[self getFileNameFromRemoteUrl]
                                                  mediaUrl:gifMessage.remoteUrl
                                                  progress:nil
                                                   success:^(NSString * _Nonnull mediaPath) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            // 保存下载后的路径
            gifMessage.localPath = mediaPath;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                strongSelf.gifData = [NSData dataWithContentsOfFile:mediaPath];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf.progressHUD hideAnimated:YES];
                    strongSelf.progressHUD = nil;
                    if (strongSelf.gifData) {
                        strongSelf.gifView.animatedImage = [RCGIFImage animatedImageWithGIFData:strongSelf.gifData];
                    }
                });
            });
        } error:^(RCErrorCode errorCode) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.progressHUD.label.text = RCLocalizedString(@"FileDownloadFailed");
                [strongSelf.progressHUD hideAnimated:YES afterDelay:1];
                strongSelf.progressHUD = nil;
            });
        } cancel:nil];
    }
}


- (void)saveGIF {
    RCGIFMessage *gifMessage =
        (RCGIFMessage *)self.messageModel.content;
    if (gifMessage.localPath.length > 0) {
        [RCAssetHelper savePhotosAlbumWithPath:gifMessage.localPath authorizationStatusBlock:^{
            [self showAlertController:RCLocalizedString(@"AccessRightTitle")
                              message:RCLocalizedString(@"photoAccessRight")
                          cancelTitle:RCLocalizedString(@"OK")];
        } resultBlock:^(BOOL success) {
            [self showAlertWithSuccess:success];
        }];

    }
}

- (void)showAlertWithSuccess:(BOOL)success {
    if (success) {
        DebugLog(@"save image suceed");
        [self showAlertController:nil
                          message:RCLocalizedString(@"SavePhotoSuccess")
                      cancelTitle:RCLocalizedString(@"OK")];
    } else {
        DebugLog(@" save image fail");
        [self showAlertController:nil
                          message:RCLocalizedString(@"SavePhotoFailed")
                      cancelTitle:RCLocalizedString(@"OK")];
    }
}

- (NSString *)getFileNameFromRemoteUrl {
    RCGIFMessage *gifMessage =
        (RCGIFMessage *)self.messageModel.content;
    NSString *name = [NSString stringWithFormat:@"%@.gif", [RCFileUtility getFileKey:gifMessage.remoteUrl]];
    
    NSString *fileName = [RCFileUtility getFileName:name
                                   conversationType:self.messageModel.conversationType
                                          mediaType:MediaType_FILE
                                           targetId:self.messageModel.targetId];
    return fileName;
}

#pragma mark - Notification
- (void)registerNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveRecallMessageNotification:)
                                                 name:RCKitDispatchRecallMessageNotification
                                               object:nil];
}

- (void)didReceiveRecallMessageNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        long recalledMsgId = [notification.object longValue];
        //产品需求：当前正在查看的图片被撤回，dismiss 预览页面，否则不做处理
        if (recalledMsgId == self.messageModel.messageId) {
            UIAlertController *alertController = [UIAlertController
                alertControllerWithTitle:nil
                                 message:RCLocalizedString(@"MessageRecallAlert")
                          preferredStyle:UIAlertControllerStyleAlert];
            [alertController
                addAction:[UIAlertAction actionWithTitle:RCLocalizedString(@"Confirm")
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *_Nonnull action) {
                                                     [self.navigationController popViewControllerAnimated:YES];
                                                 }]];
            [self.navigationController presentViewController:alertController animated:YES completion:nil];
        }
    });
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
    //长按可选择是否保存图片
    UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    [self.view addGestureRecognizer:longPress];
}


- (void)clickBackBtn:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)longPressed:(id)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        [RCActionSheetView showActionSheetView:nil cellArray:@[RCLocalizedString(@"Save")] cancelTitle:RCLocalizedString(@"Cancel") selectedBlock:^(NSInteger index) {
            [self saveGIF];
        } cancelBlock:^{
                
        }];
    }
}

- (void)showAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle {
    [RCAlertView showAlertController:title message:message cancelTitle:cancelTitle inViewController:self];
}

- (CGFloat)getSafeAreaExtraBottomHeight {
    return [RCKitUtility getWindowSafeAreaInsets].bottom;
}

- (CGFloat)getDeviceNavBarHeight {
    return [RCKitUtility getWindowSafeAreaInsets].top;
}

#pragma mark - Getter & Setter
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
@end
