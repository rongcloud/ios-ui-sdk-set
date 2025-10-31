//
//  RCPlaceholderTextView.m
//  RongIMKit
//
//  Created by zgh on 2024/10/17.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCPlaceholderTextView.h"
#import "RCKitCommonDefine.h"

@interface RCPlaceholderTextView ()

@property (nonatomic, strong) UILabel *placeholderLabel;

@end

@implementation RCPlaceholderTextView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.placeholderLabel];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePlaceholder) name:UITextViewTextDidChangeNotification object:self];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self updatePlaceholder];
}

- (void)setFont:(UIFont *)font {
    [super setFont:font];
    self.placeholderLabel.font = font;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.placeholderLabel.hidden && self.placeholderLabel.text.length > 0) {
        CGRect caretRect = [self caretRectForPosition:self.selectedTextRange.start];
        CGPoint cursorPosition = [self convertPoint:caretRect.origin toView:self];
        CGFloat newX = cursorPosition.x; // 设置placeholder标签的x位置
        CGFloat newWidth = self.frame.size.width - newX * 2;
        CGRect rect = CGRectMake(newX, 8, newWidth, 0);
        self.placeholderLabel.frame = rect;
        [self.placeholderLabel sizeToFit];
    }
}

- (void)setPlaceholder:(NSString *)placeholder {
    self.placeholderLabel.text = placeholder;
    [self.placeholderLabel sizeToFit];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (NSString *)placeholder {
    return self.placeholderLabel.text;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    self.placeholderLabel.textColor = placeholderColor;
}

- (UIColor *)placeholderColor {
    return self.placeholderLabel.textColor;
}

- (UILabel *)placeholderLabel {
    if (!_placeholderLabel) {
        _placeholderLabel = [[UILabel alloc] init];
        _placeholderLabel.numberOfLines = 0;
        _placeholderLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xD3D3D3", @"0xD3D3D3");
    }
    return _placeholderLabel;
}

- (void)updatePlaceholder {
    self.placeholderLabel.hidden = self.text.length > 0;
    if (!self.placeholderLabel.hidden) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}


@end
