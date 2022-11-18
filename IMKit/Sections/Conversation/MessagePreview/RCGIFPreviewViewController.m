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
#import "RCGIFUtility.h"
#import "RCAssetHelper.h"
#import <RongIMLib/RongIMLib.h>
#import "RCIM.h"
#import "RCKitConfig.h"
#import "RCAlertView.h"
#import "RCActionSheetView.h"
#import "RCSemanticContext.h"

@interface RCGIFPreviewViewController ()

@property (nonatomic, strong) NSData *gifData;

// 展示GIF的view
@property (nonatomic, strong) RCGIFImageView *gifView;

@end

@implementation RCGIFPreviewViewController
#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = RCDYCOLOR(0xf0f0f6, 0x000000);
    [self setNav];
    [self addSubViews];
    [self configModel];
    [self registerNotificationCenter];
}

#pragma mark - 数据处理
- (void)configModel {
    if (!self.messageModel) {
        return;
    }
    RCGIFMessage *gifMessage =
        (RCGIFMessage *)[[RCIMClient sharedRCIMClient] getMessage:self.messageModel.messageId].content;
    if (gifMessage && gifMessage.localPath.length > 0) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            weakSelf.gifData = [NSData dataWithContentsOfFile:gifMessage.localPath];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.gifData) {
                    weakSelf.gifView.animatedImage = [RCGIFImage animatedImageWithGIFData:weakSelf.gifData];
                }
            });
        });
    }
}


- (void)saveGIF {
    if (self.gifData) {
        [RCAssetHelper savePhotosAlbumWithImage:[UIImage imageWithData:self.gifData] authorizationStatusBlock:^{
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
    UIImage *imgMirror = RCResourceImage(@"navigator_btn_back");
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
