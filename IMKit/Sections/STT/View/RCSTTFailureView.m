//
//  RCSTTFailureView.m
//  RongIMKit
//
//  Created by RobinCui on 2025/5/27.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCSTTFailureView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"

@interface RCSTTFailureView()
@property (nonatomic, strong) UILabel *labContent;
@property (nonatomic, strong) UIImageView *imgView;
@end
@implementation RCSTTFailureView

- (void)setupView {
    [super setupView];
    [self.imgView sizeToFit];
    [self.labContent sizeToFit];
    [self addSubview:self.imgView];
    [self addSubview:self.labContent];
    self.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                    darkColor:HEXCOLOR(0x1c1c1e)];
    self.bounds = CGRectMake(0, 0, 24+CGRectGetWidth(self.imgView.bounds) +8+
                             CGRectGetWidth(self.labContent.bounds), 40);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imgView.center = CGPointMake(12 + CGRectGetMidX(self.imgView.bounds), CGRectGetMidY(self.bounds));
    self.labContent.center = CGPointMake(CGRectGetMaxX(self.imgView.frame) +8+
                                         CGRectGetMidX(self.labContent.bounds)
                                         , CGRectGetMidY(self.bounds));
}

- (void)showText:(NSString *)text {
    self.labContent.text = text;
}

- (UILabel *)labContent {
    if (!_labContent) {
        UILabel *lab  = [UILabel new];
        lab.textColor = RCDYCOLOR(0xA0A5Ab, 0x878787);
        lab.font = [UIFont systemFontOfSize:16];
        lab.text = RCLocalizedString(@"STTOperationFailed");
        _labContent = lab;
    }
    return _labContent;
}

- (UIImageView *)imgView {
    if (!_imgView) {
        UIImageView *view = [UIImageView new];
        view.image = RCResourceImage(@"sendMsg_failed_tip");
        _imgView = view;
    }
    return _imgView;;
}
@end
