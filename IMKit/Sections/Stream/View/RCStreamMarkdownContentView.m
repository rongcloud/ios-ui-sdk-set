//
//  RCStreamMarkdownContentView.m
//  RongIMKit
//
//  Created by zgh on 2025/3/5.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "RCStreamMarkdownContentView.h"
#import "RCStreamMarkdownContentViewModel.h"
#import "RCKitConfig.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"

extern NSString *const RCConversationViewScrollNotification;

@interface WeakScriptMessageHandler : NSObject <WKScriptMessageHandler>
@property (nonatomic, weak) id<WKScriptMessageHandler> delegate;
- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate;
@end

@implementation WeakScriptMessageHandler
- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.delegate userContentController:userContentController didReceiveScriptMessage:message];
}
@end

@interface RCStreamMarkdownContentView ()<WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, weak) RCStreamMarkdownContentViewModel *viewModel;

@end

@implementation RCStreamMarkdownContentView

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.webView.frame = self.bounds;
}

- (void)configViewModel:(RCStreamContentViewModel *)contentViewModel {
    [super configViewModel:contentViewModel];
    if (![contentViewModel isKindOfClass:RCStreamMarkdownContentViewModel.class]) {
        return;
    }
    RCStreamMarkdownContentViewModel *viewModel = (RCStreamMarkdownContentViewModel *)contentViewModel;
    self.viewModel = viewModel;
    [self loadWebView];
}

- (void)cleanView {
    [super cleanView];
    [self.webView removeFromSuperview];
    self.webView = nil;
}

- (void)dealloc {
    DebugLog(@"dealloc");
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"longpress"];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"heightChanged"];
    [self.webView.configuration.userContentController removeAllUserScripts];
    
    self.webView.navigationDelegate = nil;
    self.webView.UIDelegate = nil;
    [self.webView stopLoading];
    self.webView = nil;
}

#pragma mark -- private

- (void)loadWebView {
    if (!self.webView) {
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        [config.userContentController addScriptMessageHandler:[[WeakScriptMessageHandler alloc] initWithDelegate:self] name:@"heightChanged"];
        
        //  设置正确的视口大小[多次调用loadHTMLString, 会导致web视图计算出错]
        NSString *viewportScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'); document.getElementsByTagName('head')[0].appendChild(meta);";
        WKUserScript *script = [[WKUserScript alloc] initWithSource:viewportScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [config.userContentController addUserScript:script];
        
        self.webView = [[WKWebView alloc] initWithFrame:self.bounds configuration:config];
        self.webView.backgroundColor = [UIColor clearColor];
        self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.webView setOpaque:NO];
        self.webView.scrollView.scrollEnabled = NO;
        self.webView.navigationDelegate = self;
        self.webView.UIDelegate = self;
        [self addSubview:self.webView];
    }
    NSString *bundlePath = [RCKitUtility bundlePathWithName:@"RongCloud"];
    
    [self.webView loadHTMLString:self.viewModel.htmlContent baseURL:[NSURL fileURLWithPath:bundlePath]];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    // 检查是否为链接点击（主框架外的导航动作通常是链接点击）
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSURL *url = navigationAction.request.URL;
        if ([self.delegate respondsToSelector:@selector(streamContentViewDidClickUrl:)]){
            [self.delegate streamContentViewDidClickUrl:url.absoluteString];
        }
        // 允许其他链接在WKWebView中加载
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    // 其他类型的导航动作，允许默认行为
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSString *js = [self.viewModel javascriptStringForHeight];
    [webView evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        // 处理结果同上
        CGFloat height = [result floatValue];
        [self.viewModel reloadContentHeight:height];
    }];
}

#pragma mark -- WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"heightChanged"]) {
        NSNumber *height = message.body;
        if (height.floatValue > 0) {
            [self.viewModel reloadContentHeight:height.floatValue];
        }
    }
}
@end
