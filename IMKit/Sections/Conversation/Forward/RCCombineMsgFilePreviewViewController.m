//
//  RCCombineMsgFilePreviewViewController.m
//  RongIMKit
//
//  Created by Jue on 16/7/29.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCCombineMsgFilePreviewViewController.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import <WebKit/WebKit.h>
#import "RCKitConfig.h"
#import "RCActionSheetView.h"
#import "RCSemanticContext.h"
#import "RCButton.h"
#import "RCBaseImageView.h"
#import "RCAlertView.h"

extern NSString *const RCKitDispatchDownloadMediaNotification;

@interface RCCombineMsgFilePreviewViewController ()

@property (nonatomic, copy) NSString *remoteURL;
@property (nonatomic, copy) NSString *localPath;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *fileType;
@property (nonatomic, assign) RCConversationType conversationType;
@property (nonatomic, copy) NSString *targetId;
@property (nonatomic, assign) long long fileSize;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *sizeLabel;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) RCBaseImageView *typeIconView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) RCBaseButton *downloadButton;
@property (nonatomic, strong) RCBaseButton *openInOtherAppButton;
@property (nonatomic, strong) RCBaseButton *cancelButton;

@property (nonatomic, assign) int extentLayoutForY;

@end

@implementation RCCombineMsgFilePreviewViewController
#pragma mark - Life Cycle
- (instancetype)initWithRemoteURL:(NSString *)remoteURL
                 conversationType:(RCConversationType)conversationType
                         targetId:(NSString *)targetId
                         fileSize:(long long)fileSize
                         fileName:(NSString *)fileName
                         fileType:(NSString *)fileType {
    if (self = [super init]) {
        self.remoteURL = remoteURL;
        self.conversationType = conversationType;
        self.targetId = targetId;
        self.fileSize = fileSize;
        self.fileName = fileName;
        self.fileType = fileType;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xf0f0f6", @"0x000000");
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.title = RCLocalizedString(@"PreviewFile");

    //根据导航栏透明度来设置布局
    if (self.navigationController.navigationBar.translucent) {
        self.extentLayoutForY = 64;
    } else {
        self.extentLayoutForY = 0;
    }
    //设置右键
    RCButton *rightBtn = [RCButton buttonWithType:UIButtonTypeCustom];
    rightBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *rightImage = RCDynamicImage(@"file_preview_forward_img", @"forwardIcon");
    [rightBtn setImage:rightImage forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(moreAction) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];

    //设置左键
    UIImage *imgMirror = RCDynamicImage(@"navigation_bar_btn_back_img", @"navigator_btn_back");
    imgMirror = [RCSemanticContext imageflippedForRTL:imgMirror];
    self.navigationItem.leftBarButtonItems = [RCKitUtility getLeftNavigationItems:imgMirror title:RCLocalizedString(@"Back") target:self action:@selector(clickBackBtn:)];

    [self registerNotificationCenter];
    [self setupSubviews];
    
    if ([self isFileDownloaded] && [self isFileSupported]) {
        [self layoutAndPreviewFile];
    } else {
        [self layoutForShowFileInfo];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Methods

- (void)registerNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadMediaStatus:)
                                                 name:RCKitDispatchDownloadMediaNotification
                                               object:nil];
}

- (void)updateDownloadMediaStatus:(NSNotification *)notify {
    NSDictionary *statusDic = notify.userInfo;
    if (![self.remoteURL isEqualToString:statusDic[@"mediaUrl"]]) {
        return;
    }
    NSString *type = statusDic[@"type"];
    dispatch_main_async_safe(^{
        if ([type isEqualToString:@"progress"]) {
            [self layoutForDownloading];
            float progress = (float)[statusDic[@"progress"] intValue] / 100.0f;
            [self downloading:progress];
        } else if ([type isEqualToString:@"success"]) {
            self.localPath = statusDic[@"mediaPath"];
            if ([self isFileSupported]) {
                [self layoutAndPreviewFile];
            } else {
                [self layoutForShowFileInfo];
            }
        } else if ([type isEqualToString:@"error"]) {
            [self layoutForShowFileInfo];
            if ([statusDic[@"errorCode"] intValue] == RC_NETWORK_UNAVAILABLE) {
                [self showAlertController:RCLocalizedString(@"ConnectionIsNotReachable")];
            } else {
                [self showAlertController:RCLocalizedString(@"FileDownloadFailed")];
            }
        } else if ([type isEqualToString:@"cancel"]) {
            [self layoutForShowFileInfo];
            [self showAlertController:RCLocalizedString(@"FileDownloadCanceled")];
        }
    });
}


- (void)setupSubviews {
    [self.view addSubview:self.webView];
    [self.view addSubview:self.typeIconView];
    [self.view addSubview:self.nameLabel];
    [self.view addSubview:self.sizeLabel];
    [self.view addSubview:self.progressLabel];
    [self.view addSubview:self.progressView];
    [self.view addSubview:self.downloadButton];
    [self.view addSubview:self.openInOtherAppButton];
    [self.view addSubview:self.cancelButton];
    [self.view bringSubviewToFront:self.cancelButton];
}

- (void)startFileDownLoad {
    [self layoutForDownloading];
    [[RCIM sharedRCIM] downloadMediaFile:self.fileName mediaUrl:self.remoteURL progress:^(int progress) {
        
    } success:^(NSString *mediaPath) {
        
    } error:^(RCErrorCode errorCode) {
        
    } cancel:^{
        
    }];
}

- (void)showAlertController:(NSString *)message {
    [RCAlertView showAlertController:nil message:message cancelTitle:RCLocalizedString(@"OK") inViewController:self];
}

- (void)downloading:(float)progress {
    [self.progressView setProgress:progress animated:YES];
    self.progressLabel.text =
        [NSString stringWithFormat:@"%@(%@/%@)", RCLocalizedString(@"FileIsDownloading"),
                                   [RCKitUtility getReadableStringForFileSize:progress * self.fileSize],
                                   [RCKitUtility getReadableStringForFileSize:self.fileSize]];
}

- (BOOL)isFileDownloaded {
    NSString *fileLocalPath;
    if (self.localPath) {
        fileLocalPath = self.localPath;
    } else {
        fileLocalPath = [RCFileUtility getFileLocalPath:self.remoteURL];
    }
    /// fileLocalPath 为绝对路径，重新运行路径改变，需要矫正
    if (fileLocalPath) {
        fileLocalPath = [RCUtilities getCorrectedFilePath:fileLocalPath];
    }
    if ([RCFileUtility isFileExist:fileLocalPath]) {
        self.localPath = fileLocalPath;
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isFileSupported {
    if (![[RCKitUtility getFileTypeIcon:self.fileType] isEqualToString:@"OtherFile"]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)layoutForShowFileInfo {
    self.webView.hidden = YES;
    self.navigationItem.rightBarButtonItem.enabled = NO;

    self.typeIconView.hidden = NO;
    self.nameLabel.hidden = NO;
    self.sizeLabel.hidden = NO;
    self.progressView.hidden = YES;
    self.progressLabel.hidden = YES;
    self.cancelButton.hidden = YES;
    if ([self isFileDownloaded]) {
        self.downloadButton.hidden = YES;
        self.openInOtherAppButton.hidden = NO;
    } else {
        self.downloadButton.hidden = NO;
        self.openInOtherAppButton.hidden = YES;
    }
}

- (void)layoutForDownloading {
    self.webView.hidden = YES;
    self.navigationItem.rightBarButtonItem.enabled = NO;

    self.typeIconView.hidden = NO;
    self.nameLabel.hidden = NO;
    self.sizeLabel.hidden = YES;
    self.downloadButton.hidden = YES;
    self.openInOtherAppButton.hidden = YES;
    self.progressView.hidden = NO;
    self.progressLabel.hidden = NO;
    self.cancelButton.hidden = NO;
}

- (void)layoutAndPreviewFile {
    self.webView.hidden = NO;
    self.navigationItem.rightBarButtonItem.enabled = YES;

    self.typeIconView.hidden = YES;
    self.nameLabel.hidden = YES;
    self.sizeLabel.hidden = YES;
    self.downloadButton.hidden = YES;
    self.openInOtherAppButton.hidden = YES;
    self.progressView.hidden = YES;
    self.progressLabel.hidden = YES;
    self.cancelButton.hidden = YES;

    [self transformEncodingFromFilePath:self.localPath];
    if (self.localPath) {
        NSURL *fileURL = [NSURL fileURLWithPath:self.localPath];
        [self.webView loadFileURL:fileURL allowingReadAccessToURL:fileURL];
    }
}

- (void)moreAction {
    [RCActionSheetView showActionSheetView:nil cellArray:@[RCLocalizedString(@"OpenFileInOtherApp")] cancelTitle:RCLocalizedString(@"Cancel") selectedBlock:^(NSInteger index) {
        [self openInOtherApp:self.localPath];
    } cancelBlock:^{
            
    }];
}

- (void)clickBackBtn:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)openInOtherApp:(NSString *)localPath {
    if (!localPath) {
        return;
    }
    UIActivityViewController *activityVC =
        [[UIActivityViewController alloc] initWithActivityItems:@[ [NSURL fileURLWithPath:localPath] ]
                                          applicationActivities:nil];
    if ([RCKitUtility currentDeviceIsIPad]) {
        UIPopoverPresentationController *popPresenter = [activityVC popoverPresentationController];
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        popPresenter.sourceView = window;
        popPresenter.sourceRect = CGRectMake(window.frame.size.width / 2, window.frame.size.height / 2, 0, 0);
        popPresenter.permittedArrowDirections = 0;
    }
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)cancelFileDownload {
    [[RCCoreClient sharedCoreClient] cancelDownloadMediaUrl:self.remoteURL successBlock:^{
        
    } errorBlock:^(RCErrorCode errorCode) {
        
    }];
}

- (void)openCurrentFileInOtherApp {
    [self openInOtherApp:self.localPath];
}

// txt格式乱码问题解决方法
- (NSString *)examineTheFilePathStr:(NSString *)str {
    NSStringEncoding *useEncodeing = nil; //带编码头的如utf-8等，这里会识别出来
    NSString *body = [NSString
        stringWithContentsOfFile:str
                    usedEncoding:useEncodeing
                           error:
                               nil]; //识别不到，按GBK编码再解码一次.这里不能先按GB18030解码，否则会出现整个文档无换行bug
    if (!body) {
        body = [NSString stringWithContentsOfFile:str encoding:0x80000632 error:nil];

    } //还是识别不到，按GB18030编码再解码一次.
    if (!body) {
        body = [NSString stringWithContentsOfFile:str encoding:0x80000631 error:nil];
    } //有值代表需要转换  为空表示不需要转换
    return body;
}

- (void)transformEncodingFromFilePath:(NSString *)filePath {       //调用上述转码方法获取正常字符串
    NSString *body = [self examineTheFilePathStr:filePath];        //转换为二进制
    NSData *data = [body dataUsingEncoding:NSUTF16StringEncoding]; //覆盖原来的文件
    [data writeToFile:filePath atomically:YES];                    //此时在读取该文件，就是正常格式啦
}

#pragma mark - Getters and Setters
- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc]
            initWithFrame:CGRectMake(0, self.extentLayoutForY, [UIScreen mainScreen].bounds.size.width,
                                     [UIScreen mainScreen].bounds.size.height - self.extentLayoutForY)];
        _webView.scrollView.contentInset = (UIEdgeInsets){8, 8, 8, 8};
        _webView.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xf2f2f3", @"0xf2f2f3");
        
    }
    return _webView;
}

- (RCBaseImageView *)typeIconView {
    if (!_typeIconView) {
        _typeIconView = [[RCBaseImageView alloc]
            initWithFrame:CGRectMake((self.view.bounds.size.width - 75) / 2, 30 + self.extentLayoutForY, 75, 75)];
        _typeIconView.image = [RCKitUtility imageWithFileSuffix:self.fileType];
    }

    return _typeIconView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc]
            initWithFrame:CGRectMake(10, 122 + self.extentLayoutForY, self.view.bounds.size.width - 10 * 2, 21)];
        _nameLabel.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
        _nameLabel.text = self.fileName;
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x343434", @"0x9f9f9f");
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _nameLabel;
}

- (UILabel *)sizeLabel {
    if (!_sizeLabel) {
        _sizeLabel =
            [[UILabel alloc] initWithFrame:CGRectMake(0, 151 + self.extentLayoutForY, self.view.bounds.size.width, 12)];
        _sizeLabel.font = [[RCKitConfig defaultConfig].font fontOfGuideLevel];
        _sizeLabel.text = [RCKitUtility getReadableStringForFileSize:self.fileSize];
        _sizeLabel.textAlignment = NSTextAlignmentCenter;
        _sizeLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xa8a8a8", @"0x666666");
    }
    return _sizeLabel;
}

- (UILabel *)progressLabel {
    if (!_progressLabel) {
        _progressLabel = [[UILabel alloc]
            initWithFrame:CGRectMake(10, 151 + self.extentLayoutForY, self.view.bounds.size.width - 10 * 2, 21)];
        _progressLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xa8a8a8", @"0xa8a8a8");
        _progressLabel.textAlignment = NSTextAlignmentCenter;
        _progressLabel.font = [[RCKitConfig defaultConfig].font fontOfGuideLevel];
    }
    return _progressLabel;
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc]
            initWithFrame:CGRectMake(10, 184 + self.extentLayoutForY, self.view.bounds.size.width - 10 * 3, 8)];
        _progressView.transform = CGAffineTransformMakeScale(1.0f, 4.0f);
        _progressView.progressViewStyle = UIProgressViewStyleDefault;
        _progressView.progressTintColor = RCDynamicColor(@"primary_color", @"0x0099ff", @"0x0099ff");
    }
    return _progressView;
}

- (RCBaseButton *)downloadButton {
    if (!_downloadButton) {
        _downloadButton = [[RCBaseButton alloc]
            initWithFrame:CGRectMake(10, 197 + self.extentLayoutForY, self.view.bounds.size.width - 10 * 2, 40)];
        _downloadButton.backgroundColor = RCDynamicColor(@"primary_color", @"0x0099ff", @"0x0099ff");
        _downloadButton.layer.cornerRadius = 5.0f;
//        _downloadButton.layer.borderWidth = 0.5f;
//        _downloadButton.layer.borderColor = [HEXCOLOR(0x0181dd) CGColor];
        [_downloadButton setTitle:RCLocalizedString(@"StartDownloadFile")
                         forState:UIControlStateNormal];
        [_downloadButton addTarget:self
                            action:@selector(startFileDownLoad)
                  forControlEvents:UIControlEventTouchUpInside];
    }
    return _downloadButton;
}

- (RCBaseButton *)openInOtherAppButton {
    if (!_openInOtherAppButton) {
        _openInOtherAppButton = [[RCBaseButton alloc]
            initWithFrame:CGRectMake(10, 197 + self.extentLayoutForY, self.view.bounds.size.width - 10 * 2, 40)];
        _openInOtherAppButton.backgroundColor = RCDynamicColor(@"primary_color", @"0x0099ff", @"0x0099ff");
        _openInOtherAppButton.layer.cornerRadius = 5.0f;
//        _openInOtherAppButton.layer.borderWidth = 0.5f;
//        _openInOtherAppButton.layer.borderColor = [HEXCOLOR(0x0181dd) CGColor];
        [_openInOtherAppButton setTitle:RCLocalizedString(@"OpenFileInOtherApp")
                               forState:UIControlStateNormal];
        [_openInOtherAppButton addTarget:self
                                  action:@selector(openCurrentFileInOtherApp)
                        forControlEvents:UIControlEventTouchUpInside];
    }
    return _openInOtherAppButton;
}

- (RCBaseButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [[RCBaseButton alloc] initWithFrame:self.downloadButton.frame];
        [_cancelButton setTitle:RCLocalizedString(@"Close") forState:(UIControlStateNormal)];
        [_cancelButton addTarget:self
                          action:@selector(cancelFileDownload)
                forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.backgroundColor = RCDynamicColor(@"primary_color", @"0x0089E5", @"0x0089E5");
        _cancelButton.layer.cornerRadius = 5.0f;
//        _cancelButton.layer.borderWidth = 0.5f;
//        _cancelButton.layer.borderColor = [HEXCOLOR(0x0181dd) CGColor];
    }
    return _cancelButton;
}
@end
