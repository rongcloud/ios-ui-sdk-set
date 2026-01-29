//
//  RCGroupNoticeView.m
//  RongIMKit
//
//  Created by zgh on 2024/8/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupNoticeView.h"
#import "RCKitCommonDefine.h"
#define RCGroupNoticeViewTipFont 13.5
#define RCGroupNoticeViewTipBottom 30
#define RCGroupNoticeViewTextTop 15
#define RCGroupNoticeViewEmptyTop 25
#define RCGroupNoticeViewLeading 13.5
#define RCGroupNoticeViewTextHeight 150

@implementation RCGroupNoticeView

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat yInset = 8;
    self.tipLabel.frame = CGRectMake(RCGroupNoticeViewLeading, CGRectGetMaxY(self.frame) - self.tipLabel.frame.size.height - RCGroupNoticeViewTipBottom, self.frame.size.width - RCGroupNoticeViewLeading * 2, self.tipLabel.frame.size.height);
    [self.tipLabel sizeToFit];
    self.tipLabel.center = CGPointMake(self.center.x, CGRectGetMaxY(self.frame) - self.tipLabel.frame.size.height/2 - RCGroupNoticeViewTipBottom + yInset/2);
    if (self.textView.userInteractionEnabled) {
        self.textView.backgroundColor = RCDYCOLOR(0xffffff, 0x1a1a1a);
        self.textView.frame = CGRectMake(0, RCGroupNoticeViewTextTop, self.frame.size.width, RCGroupNoticeViewTextHeight);
        self.textView.textContainerInset = UIEdgeInsetsMake(yInset, 18, yInset, 18);
        self.textView.showsVerticalScrollIndicator = NO;
    } else {
        self.textView.backgroundColor = self.backgroundColor;
        self.textView.frame = CGRectMake(18, RCGroupNoticeViewTextTop, self.frame.size.width-36, self.tipLabel.frame.origin.y - RCGroupNoticeViewTextTop * 2);
    }
    self.emptyLabel.frame = CGRectMake(RCGroupNoticeViewLeading, RCGroupNoticeViewEmptyTop, self.frame.size.width - RCGroupNoticeViewLeading * 2, self.emptyLabel.frame.size.height);
    [self.emptyLabel sizeToFit];
    self.emptyLabel.center = CGPointMake(self.center.x, self.emptyLabel.frame.size.height/2 + RCGroupNoticeViewEmptyTop);

}

- (void)showEmptylabel:(BOOL)show {
    self.textView.hidden = show;
    self.emptyLabel.hidden = !show;
}
- (void)updateTextViewHeight:(BOOL)canEdit {
    self.textView.userInteractionEnabled = canEdit;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark -- private

- (void)setupView {
    [super setupView];
    self.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x111111);

    [self addSubview:self.textView];
    [self addSubview:self.tipLabel];
    [self addSubview:self.emptyLabel];
}

#pragma mark -- getter

- (RCPlaceholderTextView *)textView {
    if (!_textView) {
        _textView = [RCPlaceholderTextView new];
        _textView.font = [UIFont systemFontOfSize:17];
        _textView.placeholder = RCLocalizedString(@"GroupNoticeEditPlaceholder");
        _textView.placeholderColor = HEXCOLOR(0xa0a5ab);
        [_textView setTextColor:RCDYCOLOR(0x333333, 0x9f9f9f)];
    }
    return _textView;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.textColor = RCDYCOLOR(0xA0A5Ab, 0x878787);
        _tipLabel.font = [UIFont systemFontOfSize:RCGroupNoticeViewTipFont];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.numberOfLines = 0;
    }
    return _tipLabel;
}

- (UILabel *)emptyLabel {
    if (!_emptyLabel) {
        _emptyLabel = [[UILabel alloc] init];
        _emptyLabel.textColor = RCDYCOLOR(0xA0A5Ab, 0x878787);
        _emptyLabel.font = [UIFont systemFontOfSize:17];
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.numberOfLines = 0;
        _emptyLabel.text = RCLocalizedString(@"GroupNoticeIsEmpty");
    }
    return _emptyLabel;
}

@end
