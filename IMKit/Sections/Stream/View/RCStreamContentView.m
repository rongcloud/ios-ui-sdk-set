//
//  RCStreamContentView.m
//  RongIMKit
//
//  Created by zgh on 2025/2/27.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCStreamContentView.h"
#import "RCKitConfig.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCMessageCellTool.h"
#import "RCMessageModel+StreamCellVM.h"
#import "RCStreamMarkdownContentViewModel.h"

@interface RCStreamContentView ()

@property (nonatomic, strong) RCMessageModel *model;

@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSInteger dotCount;

@property (nonatomic, weak) RCStreamContentViewModel *contentViewModel;

@end

@implementation RCStreamContentView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.statusLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.statusLabel.hidden) {
        self.statusLabel.frame = self.bounds;
    }
}

- (void)dealloc {
    [self invalidTimer];
}

- (void)configViewModel:(RCStreamContentViewModel *)contentViewModel {
    self.statusLabel.hidden = YES;
    [self invalidTimer];
    self.contentViewModel = contentViewModel;
}

- (void)cleanView {
    self.statusLabel.frame = CGRectZero;
    self.statusLabel.text = nil;
}

- (void)showLoading {
    [self bringSubviewToFront:self.statusLabel];
    self.statusLabel.hidden = NO;
    if (self.timer) {
        return;
    }
    // 初始化计数器和定时器
    self.dotCount = 1;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updateLoadingText) userInfo:nil repeats:YES];
}

- (void)showFailed {
    [self invalidTimer];
    self.statusLabel.hidden = NO;
    [self bringSubviewToFront:self.statusLabel];
    self.statusLabel.text = [RCStreamContentViewModel failedInfo];
}

#pragma mark -- private

- (void)invalidTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)updateLoadingText {
    // 更新省略号数量
    NSString *dots = @"";
    for (int i = 0; i < self.dotCount; i++) {
        dots = [dots stringByAppendingString:@"."];
    }
    NSString *loading = [NSString stringWithFormat:@"%@%@", RCLocalizedString(@"StreamMessageTyping"), dots];
    self.statusLabel.text = loading;
    // 循环控制省略号数量
    if (self.dotCount == 3) {
        self.dotCount = 1;
    } else {
        self.dotCount++;
    }
}

#pragma mark - getter

- (UILabel *)statusLabel {
    if (!_statusLabel) {
        _statusLabel = [[UILabel alloc] init];
        _statusLabel.numberOfLines = 0;
        [_statusLabel setFont:[[RCKitConfig defaultConfig].font fontOfSecondLevel]];
    }
    return _statusLabel;
}
@end
