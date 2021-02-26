//
//  RCStickerDownloadView.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/15.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerDownloadView.h"
#import "RCStickerUtility.h"
#import "RongIMKitHeader.h"
#define dispatch_main_async_safe(block)                                                                                \
    if ([NSThread isMainThread]) {                                                                                     \
        block();                                                                                                       \
    } else {                                                                                                           \
        dispatch_async(dispatch_get_main_queue(), block);                                                              \
    }

@interface RCStickerDownloadView ()

@property (nonatomic, assign) RCStickerDownloadViewStstus currentStatus;

@property (nonatomic, strong) UIButton *downloadBtn;

@property (nonatomic, strong) UIView *progressView;

@property (nonatomic, strong) UILabel *progressLabel;

@end

@implementation RCStickerDownloadView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 4.f;
        self.layer.masksToBounds = YES;
        self.layer.borderColor = HEXCOLOR(0x0099ff).CGColor;
        self.layer.borderWidth = 1.f;

        [self addSubview:self.progressView];
        [self addSubview:self.progressLabel];
        [self addSubview:self.downloadBtn];
    }
    return self;
}

- (void)setCurrentStstus:(RCStickerDownloadViewStstus)currentStatus progress:(float)progress {
    _currentStatus = currentStatus;
    dispatch_main_async_safe(^{
        self.progressLabel.text = ([NSString stringWithFormat:@"%d%%", (int)(progress)]);
        self.progressLabel.frame = self.bounds;
        self.downloadBtn.frame = self.bounds;

        switch (currentStatus) {
        case RCStickerDownloadViewStstusUnDownload:
            self.downloadBtn.hidden = NO;
            self.progressView.hidden = YES;
            self.progressLabel.hidden = YES;
            self.progressView.frame = CGRectZero;
            self.layer.borderColor = HEXCOLOR(0x0099ff).CGColor;
            break;
        case RCStickerDownloadViewStstusDownloading:
            self.downloadBtn.hidden = YES;
            self.progressView.hidden = NO;
            self.progressLabel.hidden = NO;
            self.progressView.frame =
                CGRectMake(0, 0, self.bounds.size.width * progress / 100.0, self.bounds.size.height);
            self.layer.borderColor = HEXCOLOR(0x6DC4FF).CGColor;

            break;
        default:
            break;
        }
    });
}

- (void)beginDownload {
    if (self.delegate && [self.delegate respondsToSelector:@selector(beginDownloadPackage)]) {
        [self.delegate beginDownloadPackage];
    }
}

- (UIButton *)downloadBtn {
    if (_downloadBtn == nil) {
        _downloadBtn = [[UIButton alloc] init];
        _downloadBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_downloadBtn setTitle:RongStickerString(@"begin_download") forState:UIControlStateNormal];
        _downloadBtn.backgroundColor = HEXCOLOR(0x0099FF);
        [_downloadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _downloadBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        [_downloadBtn addTarget:self action:@selector(beginDownload) forControlEvents:UIControlEventTouchUpInside];
    }
    return _downloadBtn;
}

- (UIView *)progressView {
    if (_progressView == nil) {
        _progressView = [[UIView alloc] init];
        _progressView.backgroundColor = HEXCOLOR(0x6DC4FF);
    }
    return _progressView;
}

- (UILabel *)progressLabel {
    if (_progressLabel == nil) {
        _progressLabel = [[UILabel alloc] init];
        _progressLabel.textAlignment = NSTextAlignmentCenter;
        _progressLabel.textColor = RCDYCOLOR(0x333333, 0x9f9f9f);
        _progressLabel.alpha = 0.33f;
        _progressLabel.font = [UIFont systemFontOfSize:15];
    }
    return _progressLabel;
}

@end
