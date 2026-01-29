//
//  RCGroupNoticeView.m
//  RongIMKit
//
//  Created by zgh on 2024/8/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupNoticeView.h"
#import "RCKitCommonDefine.h"
#define RCGroupNoticeViewTipFont 17
#define RCGroupNoticeViewTipBottom 30
#define RCGroupNoticeViewTextTop 10
#define RCGroupNoticeViewTextHeight 200
@interface RCGroupNoticeView()
@property (nonatomic, strong) NSLayoutConstraint *textViewHeightConstraint;
@end

@implementation RCGroupNoticeView
- (void)setupConstraints {
    [super setupConstraints];
    self.textViewHeightConstraint = [self.textView.heightAnchor constraintEqualToConstant:RCGroupNoticeViewTextHeight];
    [NSLayoutConstraint activateConstraints:@[
          [self.textView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:RCUserManagementViewPadding],
          [self.textView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-RCUserManagementViewPadding],
          [self.textView.topAnchor constraintEqualToAnchor:self.topAnchor constant:RCGroupNoticeViewTextTop],
          self.textViewHeightConstraint,
          [self.emptyLabel.leadingAnchor constraintEqualToAnchor:self.textView.leadingAnchor],
          [self.emptyLabel.trailingAnchor constraintEqualToAnchor:self.textView.trailingAnchor],
          [self.emptyLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

          [self.emptyImageView.bottomAnchor constraintEqualToAnchor:self.emptyLabel.topAnchor constant:-RCGroupNoticeViewTextTop],
          [self.emptyImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
          
          [self.tipLabel.leadingAnchor constraintEqualToAnchor:self.textView.leadingAnchor],
          [self.tipLabel.trailingAnchor constraintEqualToAnchor:self.textView.trailingAnchor],
          [self.tipLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-RCGroupNoticeViewTipBottom],
        ]];
}

- (void)showEmptylabel:(BOOL)show {
    self.textView.hidden = show;
    self.emptyLabel.hidden = !show;
    self.emptyImageView.hidden = !show;
}

- (void)updateTextViewHeight:(BOOL)canEdit {
    self.textView.editable = canEdit;
    if (!canEdit) {
        self.textView.backgroundColor = [UIColor clearColor];
        self.textViewHeightConstraint.active = NO;
        [NSLayoutConstraint activateConstraints:@[
            [self.textView.bottomAnchor constraintEqualToAnchor:self.tipLabel.topAnchor constant:-19]
        ]];
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark -- private

- (void)setupView {
    [super setupView];
    self.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xf5f6f9", @"0x111111");
    [self addSubview:self.textView];
    [self addSubview:self.tipLabel];
    [self addSubview:self.emptyImageView];
    [self addSubview:self.emptyLabel];
}

#pragma mark -- getter

- (RCPlaceholderTextView *)textView {
    if (!_textView) {
        _textView = [RCPlaceholderTextView new];
        _textView.font = [UIFont systemFontOfSize:RCGroupNoticeViewTipFont];
        _textView.placeholder = RCLocalizedString(@"GroupNoticeEditPlaceholder");
        _textView.placeholderColor = RCDynamicColor(@"disabled_color",@"0xa0a5ab", @"0xa0a5ab");
        [_textView setTextColor:RCDynamicColor(@"text_primary_color", @"0x333333", @"0x9f9f9f")];
        _textView.backgroundColor = RCDynamicColor(@"common_background_color",@"0xFFFFFF", @"0x2D2D32");
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _textView;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xA0A5Ab", @"0x878787");
        _tipLabel.font = [UIFont systemFontOfSize:12];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.numberOfLines = 0;
        _tipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _tipLabel;
}

- (UILabel *)emptyLabel {
    if (!_emptyLabel) {
        _emptyLabel = [[UILabel alloc] init];
        _emptyLabel.textColor = RCDynamicColor(@"text_primary_color", @"0xA0A5Ab", @"0x878787");
        _emptyLabel.font = [UIFont systemFontOfSize:RCGroupNoticeViewTipFont];
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.numberOfLines = 0;
        _emptyLabel.text = RCLocalizedString(@"GroupNoticeIsEmpty");
        _emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _emptyLabel;
}

- (UIImageView *)emptyImageView {
    if (!_emptyImageView) {
        _emptyImageView = [UIImageView new];
        _emptyImageView.image = RCDynamicImage(@"conversation-list_no_message_img", @"no_message_img");
        _emptyImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_emptyImageView sizeToFit];
        _emptyImageView.hidden = YES;
    }
    return _emptyImageView;
}
@end
