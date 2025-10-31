//
//  RCCombineMessagePreviewViewControllerm
//  RongIMKit
//
//  Created by liyan on 2019/8/9.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCCombineMessagePreviewViewController.h"
#import <WebKit/WebKit.h>
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCCombineMessageUtility.h"
#import "RCCombineMsgFilePreviewViewController.h"
#import "RCGIFPreviewViewController.h"
#import <objc/runtime.h>
#import "RCImageSlideController.h"
#import "RCSightSlideViewController.h"
#import "RCKitConfig.h"
#import "RCLocationViewController+imkit.h"
#import "RCSemanticContext.h"
#import "RCBaseImageView.h"
#import "RCBaseNavigationController.h"
#import "RCDownloadHelper.h"
#define FUNCTIONNAME @"buttonClick"
#define TIPVIEWWIDTH 140.0f

@interface RCCombineMessagePreviewViewController () <WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) RCMessageModel *messageModel;

@property (nonatomic, copy) NSString *remoteURL;

@property (nonatomic, assign) RCConversationType conversationType;

@property (nonatomic, copy) NSString *targetId;

@property (nonatomic, copy) NSString *navTitle;

@property (nonatomic, assign) BOOL ifWebViewPush; //标识是否是webview里边的跳转。

@property (nonatomic, strong) WKWebView *combineMsgWebView;

@property (nonatomic, strong) UIView *loadingTipView;

@property (nonatomic, strong) RCBaseImageView *loadingImageView;

@property (nonatomic, strong) UILabel *loadingLabel;

@property (nonatomic, strong) UIView *loadFailedTipView;

@property (nonatomic, strong) RCBaseImageView *loadFailedImageView;

@property (nonatomic, strong) UILabel *loadFailedLabel;
//显示撤回消息对话框
@property (nonatomic, assign) BOOL displayRecallDialog;

@end

@implementation RCCombineMessagePreviewViewController
#pragma mark - Life Cycle
- (instancetype)initWithRemoteURL:(NSString *)remoteURL
                 conversationType:(RCConversationType)conversationType
                         targetId:(NSString *)targetId
                         navTitle:(NSString *)navTitle {
    if (self = [super init]) {
        self.remoteURL = remoteURL;
        self.conversationType = conversationType;
        self.targetId = targetId;
        self.navTitle = navTitle;
        self.ifWebViewPush = YES;
    }
    return self;
}

- (instancetype)initWithMessageModel:(RCMessageModel *)messageModel navTitle:(NSString *)navTitle {
    if (self = [super init]) {
        self.messageModel = messageModel;
        self.conversationType = messageModel.conversationType;
        self.targetId = messageModel.targetId;
        self.navTitle = navTitle;
        self.ifWebViewPush = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0xffffff");
    [self setNav];
    [self addSubViews];
    if (self.ifWebViewPush) {
        [self showRemoteURL];
    } else {
        [self loadHtml];
    }
    [self registerNotificationCenter];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.combineMsgWebView.configuration.userContentController addScriptMessageHandler:self name:FUNCTIONNAME];
    [self registerObserver];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.displayRecallDialog) {
        self.displayRecallDialog = NO;
        [self showRecallDialog];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.combineMsgWebView.configuration.userContentController removeScriptMessageHandlerForName:FUNCTIONNAME];
}

#pragma mark - NSNotification
- (void)registerObserver {
    //监听UIWindow隐藏
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(endFullScreen)
                                                 name:UIWindowDidBecomeHiddenNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowDidBecomeKeyNotification)
                                                 name:UIWindowDidBecomeKeyNotification
                                               object:nil];
}

- (void)registerNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveRecallMessageNotification:)
                                                 name:RCKitDispatchRecallMessageNotification
                                               object:nil];
}

- (void)showRecallDialog {
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

- (void)didReceiveRecallMessageNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        long recalledMsgId = [notification.object longValue];
        //产品需求：当前正在查看的图片被撤回，dismiss 预览页面，否则不做处理
        if (recalledMsgId == self.messageModel.messageId) {
            if ([self isViewLoaded] && self.view.window != nil) {
                [self showRecallDialog];
            } else {
                self.displayRecallDialog = YES;
            }
        }
    });
}

- (void)windowDidBecomeKeyNotification {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

- (void)endFullScreen {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

#pragma mark - WKNavigationDelegate
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *name = message.name;
    NSDictionary *dict = message.body;
    if (name && [name isEqualToString:FUNCTIONNAME]) {
        NSString *templateType = @"";
        if (dict) {
            templateType = [dict objectForKey:@"type"];
        }
        if ([templateType isEqualToString:RCFileMessageTypeIdentifier]) {
            NSString *fileUrl = [dict objectForKey:@"fileUrl"];
            NSString *fileName = [dict objectForKey:@"fileName"];
            NSString *fileType = [dict objectForKey:@"fileType"];
            long long size = [[dict objectForKey:@"fileSize"] longLongValue];
            [self presentFilePreviewVC:fileUrl fileName:fileName fileSize:size fileType:fileType];
        } else if ([templateType isEqualToString:@"RC:LBSMsg"]) {
            NSString *locationName = [dict objectForKey:@"locationName"];
            NSString *latitude = [dict objectForKey:@"latitude"];
            NSString *longitude = [dict objectForKey:@"longitude"];
            [self presentLocationVC:locationName latitude:latitude longitude:longitude];
        } else if ([templateType isEqualToString:RCCombineMessageTypeIdentifier]) {
            NSString *fileUrl = [dict objectForKey:@"fileUrl"];
            NSString *navTitle = [dict objectForKey:@"title"];
            RCCombineMessagePreviewViewController *combinePreviewVC =
                [[RCCombineMessagePreviewViewController alloc] initWithRemoteURL:fileUrl
                                                                conversationType:self.conversationType
                                                                        targetId:self.targetId
                                                                        navTitle:navTitle];
            [self.navigationController pushViewController:combinePreviewVC animated:YES];
        } else if ([templateType isEqualToString:RCImageMessageTypeIdentifier]) {
            [self presentImagePreviewViewController:dict];
        } else if ([templateType isEqualToString:RCSightMessageTypeIdentifier]) {
            [self presentSightPreviewViewController:dict];
        } else if ([templateType isEqualToString:@"phone"]) {
            NSString *phoneNum = [dict objectForKey:@"phoneNum"];
            if (phoneNum) {
                NSString *phoneStr = [NSString stringWithFormat:@"tel://%@", phoneNum];
                if (@available(iOS 10.0, *)) {
                      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneStr]
                                                         options:@{}
                                               completionHandler:^(BOOL success) {
                      }];
                  } else {
                      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneStr]];
                  }
            }
        } else if ([templateType isEqualToString:@"link"]) {
            NSString *url = [dict objectForKey:@"link"];
            if (url) {
                if (@available(iOS 10.0, *)) {
                    [RCKitUtility openURLInSafariViewOrWebView:url base:self];
                    // 无法打开 a@126.com, 改为程序内加载
//                      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]
//                                                         options:@{}
//                                               completionHandler:^(BOOL success) {
//                      }];
                  } else {
                      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
                  }
            }
        } else if ([templateType isEqualToString:RCGIFMessageTypeIdentifier]) {
            [self presentGIFPreviewViewController:dict];
        }
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.combineMsgWebView evaluateJavaScript:@"document.documentElement.style.webkitUserSelect='none'"
                             completionHandler:nil];
    [self.combineMsgWebView evaluateJavaScript:@"document.documentElement.style.webkitTouchCallout='none'"
                             completionHandler:nil];
}

- (void)webView:(WKWebView *)webView
    didFailNavigation:(null_unspecified WKNavigation *)navigation
            withError:(NSError *)error {
    [self showLoadFailedTipView];
}

- (void)webView:(WKWebView *)webView
    didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation
                       withError:(NSError *)error {
    [self showLoadFailedTipView];
}

- (void)webView:(WKWebView *)webView
    didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
                    completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                                                NSURLCredential *_Nullable credential))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *card = [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, card);
    }
}

#pragma mark - Private Methods
- (void)setNav {
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    imgMirror = [RCSemanticContext imageflippedForRTL:imgMirror];
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:RCLocalizedString(@"Back") target:self action:@selector(clickBackBtn:)];
    self.navigationItem.title = self.navTitle;
}

- (void)loadHtml {
    if (!self.messageModel) {
        return;
    }
    RCCombineMessage *combineMsg = (RCCombineMessage *)self.messageModel.content;
    NSString *localPath = combineMsg.localPath;
    if (localPath.length > 0 &&
        [[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        [self showWebView:localPath];
    } else if (combineMsg.remoteUrl.length > 0) {
        if ([RCUtilities isRemoteUrl:combineMsg.remoteUrl]) {
            [self showLoadingTipView];
            __weak typeof(self) weakSelf = self;
            [[RCIM sharedRCIM] downloadMediaMessage:weakSelf.messageModel.messageId
                progress:^(int progress) {

                }
                success:^(NSString *mediaPath) {
                    dispatch_main_async_safe(^{
                        [weakSelf showWebView:mediaPath];
                    });
                }
                error:^(RCErrorCode errorCode) {
                    dispatch_main_async_safe(^{
                        [weakSelf showLoadFailedTipView];
                    });
                }
                cancel:^{
                    dispatch_main_async_safe(^{
                        [weakSelf showLoadFailedTipView];
                    });
                }];
        } else {
            [self showLoadFailedTipView];
        }
    } else {
        [self showLoadFailedTipView];
    }
}

- (void)showWebView:(NSString *)localPath {
    if (!localPath) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopAnimation];
        self.loadingTipView.hidden = YES;
        self.loadFailedTipView.hidden = YES;
        self.combineMsgWebView.hidden = NO;
        
        NSURL *url = [NSURL fileURLWithPath:localPath];
        NSString *html = [[NSString alloc] initWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:nil];
        
        if (html && url) {
            NSURL *targetUrl = url;
            // 获取私有云当前环境的域名，并将域名拼接在 url 参数上。目的是为了实现头像内外网域名的替换
            NSString *minioOSSAddr = [RCDownloadHelper getMinioOSSAddr];
            if (minioOSSAddr.length > 0) {
                NSString *target = [NSString stringWithFormat:@"%@?target=%@", url.absoluteURL, minioOSSAddr];
                targetUrl = [NSURL URLWithString:target];
            }
            
            [self.combineMsgWebView loadHTMLString:html baseURL:targetUrl];
        }
    });
}

- (void)showRemoteURL {
    if ([RCUtilities isRemoteUrl:self.remoteURL]) {
        __weak typeof(self) weakSelf = self;
        [self showLoadingTipView];
        [[RCCoreClient sharedCoreClient] downloadMediaFile:self.conversationType
            targetId:self.targetId
            mediaType:MediaType_HTML
            mediaUrl:self.remoteURL
            progress:^(int progress) {

            }
            success:^(NSString *mediaPath) {
                dispatch_main_async_safe(^{
                    [weakSelf showWebView:mediaPath];
                });
            }
            error:^(RCErrorCode errorCode) {
                dispatch_main_async_safe(^{
                    [weakSelf showLoadFailedTipView];
                });
            }
            cancel:^{

            }];
    } else {
        [self showLoadFailedTipView];
    }
}

- (void)showLoadingTipView {
    [self startAnimation];
    self.combineMsgWebView.hidden = YES;
    self.loadingTipView.hidden = NO;
    self.loadFailedTipView.hidden = YES;
}

- (void)showLoadFailedTipView {
    [self stopAnimation];
    self.combineMsgWebView.hidden = YES;
    self.loadingTipView.hidden = YES;
    self.loadFailedTipView.hidden = NO;
}

- (void)clickBackBtn:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)presentFilePreviewVC:(NSString *)remoteURL
                    fileName:(NSString *)fileName
                    fileSize:(long long)fileSize
                    fileType:(NSString *)fileType {
    RCCombineMsgFilePreviewViewController *fileViewController =
        [[RCCombineMsgFilePreviewViewController alloc] initWithRemoteURL:remoteURL
                                                        conversationType:self.conversationType
                                                                targetId:self.targetId
                                                                fileSize:fileSize
                                                                fileName:fileName
                                                                fileType:fileType];
    [self.navigationController pushViewController:fileViewController animated:YES];
}

- (void)presentImagePreviewViewController:(NSDictionary *)dict {
    NSString *imageUrl = [dict objectForKey:@"fileUrl"];
    NSString *thumbnailBase64Str = [dict objectForKey:@"imgUrl"];
    RCImageMessage *msgContent = [[RCImageMessage alloc] init];
    msgContent.localPath = imageUrl;
    msgContent.thumbnailImage = [self getThumbImage:thumbnailBase64Str];
    RCMessage *message = [[RCMessage alloc] initWithType:self.conversationType
                                                targetId:self.targetId
                                               direction:MessageDirection_SEND
                                                 content:msgContent];
    RCMessageModel *model = [RCMessageModel modelWithMessage:message];

    RCImageSlideController *imagePreviewVC = [[RCImageSlideController alloc] init];
    imagePreviewVC.messageModel = model;
    imagePreviewVC.onlyPreviewCurrentMessage = YES;
    RCBaseNavigationController *nav = [[RCBaseNavigationController alloc] initWithRootViewController:imagePreviewVC];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)presentSightPreviewViewController:(NSDictionary *)dict {
    NSString *sightUrl = [dict objectForKey:@"fileUrl"];
    NSString *thumbnailBase64Str = [dict objectForKey:@"imageBase64"];
    int duration = [[dict objectForKey:@"duration"] intValue];
    RCSightMessage *msgContent =
        [RCSightMessage messageWithLocalPath:@"" thumbnail:[self getThumbImage:thumbnailBase64Str] duration:duration];
    msgContent.remoteUrl = sightUrl;

    RCMessage *message = [[RCMessage alloc] initWithType:self.conversationType
                                                targetId:self.targetId
                                               direction:MessageDirection_SEND
                                                 content:msgContent];
    RCMessageModel *model = [RCMessageModel modelWithMessage:message];

    RCSightSlideViewController *svc = [[RCSightSlideViewController alloc] init];
    svc.messageModel = model;
    svc.topRightBtnHidden = YES;
    svc.onlyPreviewCurrentMessage = YES;
    RCBaseNavigationController *navc = [[RCBaseNavigationController alloc] initWithRootViewController:svc];
    navc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navc animated:YES completion:nil];
}

- (void)presentLocationVC:(NSString *)locationName latitude:(NSString *)latitude longitude:(NSString *)longitude {
    Class type = NSClassFromString(@"RCLocationViewController");
    if (type) {
        RCLocationViewController *locationViewController = [[type alloc] init];
        [locationViewController setLatitude:[latitude doubleValue] longitude:[longitude doubleValue] locationName:locationName];
        RCBaseNavigationController *navc = [[RCBaseNavigationController alloc] initWithRootViewController:locationViewController];
        if (self.navigationController) {
            //导航和原有的配色保持一直
            UIImage *image = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
            [navc.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
        }
        navc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:navc animated:YES completion:NULL];
    }
}

- (void)presentGIFPreviewViewController:(NSDictionary *)dict {
    NSString *imageUrl = [dict objectForKey:@"fileUrl"];
    RCGIFMessage *msgContent = [[RCGIFMessage alloc] init];
    msgContent.remoteUrl = imageUrl;
    RCMessage *message = [[RCMessage alloc] initWithType:self.conversationType
                                                targetId:self.targetId
                                               direction:MessageDirection_SEND
                                                 content:msgContent];
    RCMessageModel *model = [RCMessageModel modelWithMessage:message];
    
    RCGIFPreviewViewController *gifPreviewVC = [[RCGIFPreviewViewController alloc] init];
    gifPreviewVC.messageModel = model;
    [self.navigationController pushViewController:gifPreviewVC animated:NO];
}

- (void)startAnimation {
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI * 2.0];
    rotationAnimation.duration = 1.5;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = MAXFLOAT;
    [self.loadingImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)stopAnimation {
    if (self.loadingImageView) {
        [self.loadingImageView.layer removeAnimationForKey:@"rotationAnimation"];
    }
}

- (UIImage *)getThumbImage:(NSString *)thumbnailBase64String {
    // thumbnailBase64String 去掉前缀 "data:image/png;base64,"
    NSArray *array = [thumbnailBase64String componentsSeparatedByString:@","];
    if (array && array.count > 0) {
        thumbnailBase64String = array.lastObject;
    }
    UIImage *thumbnailImage = nil;
    if (thumbnailBase64String) {
        NSData *imageData = nil;
        if (class_getInstanceMethod([NSData class], @selector(initWithBase64EncodedString:options:))) {
            imageData = [[NSData alloc] initWithBase64EncodedString:thumbnailBase64String
                                                            options:NSDataBase64DecodingIgnoreUnknownCharacters];
        } else {
            imageData = [RCUtilities dataWithBase64EncodedString:thumbnailBase64String];
        }
        thumbnailImage = [UIImage imageWithData:imageData];
    }
    return thumbnailImage;
}

- (void)addSubViews {
    [self.view addSubview:self.combineMsgWebView];
    [self.view addSubview:self.loadingTipView];
    [self.loadingTipView addSubview:self.loadingImageView];
    [self.loadingTipView addSubview:self.loadingLabel];
    [self.view addSubview:self.loadFailedTipView];
    [self.loadFailedTipView addSubview:self.loadFailedImageView];
    [self.loadFailedTipView addSubview:self.loadFailedLabel];
}

#pragma mark subViews
- (WKWebView *)combineMsgWebView {
    if (!_combineMsgWebView) {
        CGFloat navBarHeight = 64;
        CGFloat homeBarHeight = [RCKitUtility getWindowSafeAreaInsets].bottom;
        if (homeBarHeight > 0) {
            navBarHeight = 88;
        }
        _combineMsgWebView =
            [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width,
                                                        self.view.bounds.size.height - navBarHeight - homeBarHeight)];
        _combineMsgWebView.UIDelegate = self;
        _combineMsgWebView.navigationDelegate = self;
        _combineMsgWebView.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0xffffff");
    }
    return _combineMsgWebView;
}

- (UIView *)loadingTipView {
    if (!_loadingTipView) {
        _loadingTipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TIPVIEWWIDTH, 62)];
        _loadingTipView.center = CGPointMake(self.combineMsgWebView.center.x, self.combineMsgWebView.center.y);
    }
    return _loadingTipView;
}

- (RCBaseImageView *)loadingImageView {
    if (!_loadingImageView) {
        _loadingImageView = [[RCBaseImageView alloc] initWithFrame:CGRectMake((TIPVIEWWIDTH - 27) / 2, 0, 27, 27)];
        _loadingImageView.image = RCDynamicImage(@"conversation_msg_combine_loading_img", @"combine_loading");
    }
    return _loadingImageView;
}

- (UILabel *)loadingLabel {
    if (!_loadingLabel) {
        _loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 42, TIPVIEWWIDTH, 21)];
        _loadingLabel.font = [[RCKitConfig defaultConfig].font fontOfThirdLevel];
        _loadingLabel.numberOfLines = 1;
        _loadingLabel.textAlignment = NSTextAlignmentCenter;
        _loadingLabel.backgroundColor = [UIColor clearColor];
        _loadingLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0x666666", @"0x666666");
        _loadingLabel.text = RCLocalizedString(@"CombineMessageLoading");
    }
    return _loadingLabel;
}

- (UIView *)loadFailedTipView {
    if (!_loadFailedTipView) {
        _loadFailedTipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TIPVIEWWIDTH, 62)];
        _loadFailedTipView.center = CGPointMake(self.combineMsgWebView.center.x, self.combineMsgWebView.center.y);
    }
    return _loadFailedTipView;
}

- (RCBaseImageView *)loadFailedImageView {
    if (!_loadFailedImageView) {
        _loadFailedImageView = [[RCBaseImageView alloc] initWithFrame:CGRectMake((TIPVIEWWIDTH - 45) / 2, 0, 45, 54)];
        _loadFailedImageView.image = RCDynamicImage(@"combine_msg_preview_failed_img", @"combine_failed");
        _loadFailedImageView.userInteractionEnabled = NO;
    }
    return _loadFailedImageView;
}

- (UILabel *)loadFailedLabel {
    if (!_loadFailedLabel) {
        _loadFailedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 54 + 15, TIPVIEWWIDTH, 21)];
        _loadFailedLabel.font = [[RCKitConfig defaultConfig].font fontOfThirdLevel];
        _loadFailedLabel.numberOfLines = 1;
        _loadFailedLabel.textAlignment = NSTextAlignmentCenter;
        _loadFailedLabel.backgroundColor = [UIColor clearColor];
        _loadFailedLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0x666666", @"0x666666");
        _loadFailedLabel.text = RCLocalizedString(@"CombineMessageLoadFailed");
    }
    return _loadFailedLabel;
}

@end
