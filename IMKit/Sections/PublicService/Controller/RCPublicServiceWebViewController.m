//
//  RCPublicServiceWebViewController.m
//  RongIMLib
//
//  Created by litao on 15/4/11.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import "RCPublicServiceWebViewController.h"
#import <WebKit/WebKit.h>
#import "RCKitCommonDefine.h"
@interface RCPublicServiceWebViewController () <WKNavigationDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIView *defaultContainer;
@property (nonatomic, strong) UIProgressView *progress;
@property (nonatomic, copy) NSString *url;
//与上个url的区别，上个是页面起始url，这个是跳转的url。
@property (nonatomic, copy) NSString *currentUrl;
@property (nonatomic, assign) BOOL isHideNavigationBar;

@end

#define SUCCESS_STATUS_PAIR @"status" : @"success"
#define ERROR_STATUS_PAIR @"status" : @"error"
#define COMPLETE_STATUS_PAIR @"status" : @"complete"
#define CANCEL_STATUS_PAIR @"status" : @"cancel"
#define TRIGGER_STATUS_PAIR @"status" : @"trigger"

@implementation RCPublicServiceWebViewController
- (instancetype)initWithURLString:(NSString *)URLString {
    self = [super init];

    if (self) {
        self.url = URLString;
        self.backButtonTextColor =  RCDynamicColor(@"common_background_color", @"0xffffff", @"0xffffff");
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:RCDynamicImage(@"conversation_setting_img",@"rc_setting")
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(onOptionButtonPressed)];
    [self.webView sizeToFit];

    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:(NSKeyValueObservingOptionNew) context:nil];
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];

    self.navigationItem.rightBarButtonItem = item;
    if (self.url && self.url.length) {
        NSURL *loadUrl = [NSURL URLWithString:self.url];
        [self.progress setProgress:0];
        [self.webView loadRequest:[NSURLRequest requestWithURL:loadUrl]];
    }

    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:RCLocalizedString(@"Back") target:self action:@selector(leftBarButtonItemPressed:)];
}

- (void)leftBarButtonItemPressed:(id)sender {
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)onOptionButtonPressed {

    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController
        addAction:[UIAlertAction actionWithTitle:RCLocalizedString(@"Cancel")
                                           style:UIAlertActionStyleCancel
                                         handler:nil]];
    [alertController
        addAction:[UIAlertAction actionWithTitle:RCLocalizedString(@"OpenURLInBrowser")
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *_Nonnull action) {
                                             NSURL *openUrl = [NSURL URLWithString:self.currentUrl];
                                             if ([[UIApplication sharedApplication] canOpenURL:openUrl]) {
                                                 if (@available(iOS 10.0, *)) {
                                                       [[UIApplication sharedApplication] openURL:openUrl
                                                                                          options:@{}
                                                                                completionHandler:^(BOOL success) {
                                                       }];
                                                   } else {
                                                       [[UIApplication sharedApplication] openURL:openUrl];
                                                   }
                                             }
                                         }]];
    [alertController
        addAction:[UIAlertAction actionWithTitle:RCLocalizedString(@"CopyURL")
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *_Nonnull action) {
                                             UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                             pasteboard.string = self.currentUrl;
                                         }]];
    if ([[UIDevice currentDevice].model containsString:@"iPad"]) {
        UIPopoverPresentationController *popPresenter = [alertController popoverPresentationController];
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        popPresenter.sourceView = window;
        popPresenter.sourceRect = CGRectMake(window.frame.size.width / 2, window.frame.size.height / 2, 0, 0);
        popPresenter.permittedArrowDirections = 0;
    }

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.navigationController.navigationBarHidden == YES) {
        self.isHideNavigationBar = YES;
        self.navigationController.navigationBarHidden = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isHideNavigationBar) {
        self.navigationController.navigationBarHidden = YES;
    }
}

- (void)loadView {

    CGRect navFrame = self.navigationController.navigationBar.frame;
    CGRect clientRect = CGRectMake(0, 0, navFrame.size.width, 2);

    CGRect bounds = [[UIScreen mainScreen] bounds];
    bounds.size.height = bounds.size.height - CGRectGetMaxY(navFrame);
    self.view = [[UIView alloc] initWithFrame:bounds];
    [self.view setBackgroundColor:RCDynamicColor(@"common_background_color", @"0xFFFFFF", @"0xFFFFFF")];

    self.webView = [[WKWebView alloc] initWithFrame:bounds];
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];

    self.progress = [[UIProgressView alloc] initWithFrame:clientRect];
    [self.view addSubview:self.progress];
}

- (void)hideProgress {
    [self.progress setHidden:YES];
}

#pragma mark KVO的监听代理
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    //网页进度
    if ([keyPath isEqualToString:@"estimatedProgress"] && object == self.webView) {
        CGFloat progress = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
        if (progress == 1) {
            [self.progress setProgress:1 animated:YES];
            [self performSelector:@selector(hideProgress) withObject:nil afterDelay:0.3];
        } else {
            [self.progress setProgress:progress animated:YES];
            self.progress.hidden = NO;
        }
    } else if ([keyPath isEqualToString:@"title"]) {
        //网页title
        if (object == self.webView) {
            self.title = self.webView.title;
        }
    }
}

#pragma mark 移除观察者
- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:@"title"];
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}
#pragma mark - WKNavigationDelegate
//页面开始加载
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self.progress setProgress:0 animated:YES];
}
//开始获取到网页内容时返回
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
}
//页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.progress setProgress:1 animated:YES];
    [self performSelector:@selector(hideProgress) withObject:nil afterDelay:0.3];
}
//页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation {
    [self hideProgress];
}

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
                      decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    self.currentUrl = [webView.URL absoluteString];
    //"webViewWillLoadData"
    decisionHandler(WKNavigationResponsePolicyAllow);
}

@end
