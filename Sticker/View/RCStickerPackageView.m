//
//  RCStickerPackageView.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/15.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerPackageView.h"
#import "RCStickerDownloadView.h"
#import "RCStickerDataManager.h"
#import "RCStickerUtility.h"
#import "RongStickerAdaptiveHeader.h"
#define ScreenWidth [UIScreen mainScreen].bounds.size.width

@interface RCStickerPackageView () <RCStickerDownloadViewDelegate>

@property (nonatomic, strong) RCStickerPackageConfig *packageConfig;

@property (nonatomic, strong) UIImageView *coverView;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) RCStickerDownloadView *downloadView;

@end

@implementation RCStickerPackageView

- (instancetype)initWithPackageConfig:(RCStickerPackageConfig *)packageConfig {
    self = [super initWithFrame:CGRectMake(0, 0, ScreenWidth, 186)];
    if (self) {
        self.packageConfig = packageConfig;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x1c1c1c);
    [self addSubview:self.coverView];
    [self addSubview:self.nameLabel];
    [self addSubview:self.downloadView];
    self.coverView.frame = CGRectMake(34, 23, 164, 140);
    CGFloat originX = self.frame.size.width - 150;
    if (self.frame.size.width < 375) {
        originX = originX + 25;
        self.coverView.frame = CGRectMake(17, 23, 164, 140);
    }
    self.nameLabel.frame = CGRectMake(originX, 48, 100, 34);
    self.downloadView.frame = CGRectMake(originX, CGRectGetMaxY(self.nameLabel.frame) + 28, 100, 32);

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(packageDownloading:)
                                                 name:RCStickersDownloadingNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(packageDownloadFailed:)
                                                 name:RCStickersDownloadFiledNotification
                                               object:nil];

    [self configSubView];
}

- (void)configSubView {

    NSNumber *progress = [[RCStickerDataManager sharedManager] getDownloadProgress:self.packageConfig.packageId];
    if (!progress) {
        [self.downloadView setCurrentStstus:RCStickerDownloadViewStstusUnDownload progress:0];
    } else {
        [self.downloadView setCurrentStstus:RCStickerDownloadViewStstusDownloading progress:[progress floatValue]];
    }
    NSData *coverData = [[RCStickerDataManager sharedManager] packageCoverById:self.packageConfig.packageId];
    if (coverData) {
        self.coverView.image = [UIImage imageWithData:coverData];
    } else {
        self.coverView.image = RongStickerImage(@"cover_failed");
    }
    self.nameLabel.text = self.packageConfig.name;
    if ([RCKitUtility isRTL]) {
        [self.nameLabel setTransform:CGAffineTransformMakeScale(-1, 1)];
        [self.downloadView setTransform:CGAffineTransformMakeScale(-1, 1)];
    }
}

#pragma mark - Notification

- (void)packageDownloading:(NSNotification *)notification {
    NSString *packageId = [notification.userInfo objectForKey:@"packageId"];
    float progress = [[notification.userInfo objectForKey:@"progress"] floatValue];
    if (![packageId isEqualToString:self.packageConfig.packageId]) {
        return;
    }
    [self.downloadView setCurrentStstus:RCStickerDownloadViewStstusDownloading progress:progress];
}

- (void)packageDownloadFailed:(NSNotification *)notification {
    NSString *packageId = [notification.userInfo objectForKey:@"packageId"];
    int errorCode = [[notification.userInfo objectForKey:@"errorCode"] intValue];
    NSLog(@"packageDownloadFailed errorCode is %d", errorCode);
    if (![packageId isEqualToString:self.packageConfig.packageId]) {
        return;
    }
    [self.downloadView setCurrentStstus:RCStickerDownloadViewStstusUnDownload progress:0];
}

#pragma mark - RCStickerDownloadViewDelegate

- (void)beginDownloadPackage {
    [self.downloadView setCurrentStstus:RCStickerDownloadViewStstusDownloading progress:0];
    [[RCStickerDataManager sharedManager] downloadPackagesZip:self.packageConfig.packageId
        progress:^(int progress) {

        }
        success:^(NSArray<RCStickerSingle *> *stickers) {

        }
        error:^(int errorCode) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                UIViewController *rootVC = [RCKitUtility getKeyWindow].rootViewController;
                UIAlertController *alertVC = [UIAlertController
                    alertControllerWithTitle:[NSString stringWithFormat:RongStickerString(@"download_failed_alert"),
                                                                        weakSelf.packageConfig.name]
                                     message:@""
                              preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:RongStickerString(@"confirm")
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction *_Nonnull action){

                                                                      }];
                [alertVC addAction:confirmAction];
                [rootVC presentViewController:alertVC animated:YES completion:nil];
            });
        }];
}

- (UIImageView *)coverView {
    if (_coverView == nil) {
        _coverView = [[UIImageView alloc] init];
        _coverView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _coverView;
}

- (UILabel *)nameLabel {
    if (_nameLabel == nil) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = RCDYCOLOR(0x333333, 0x9f9f9f);
        _nameLabel.font = [UIFont systemFontOfSize:22];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _nameLabel;
}

- (RCStickerDownloadView *)downloadView {
    if (_downloadView == nil) {
        _downloadView = [[RCStickerDownloadView alloc] init];
        _downloadView.delegate = self;
    }
    return _downloadView;
}

@end
