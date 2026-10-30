//
//  RCNameEditView.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/20.
//

#import "RCNameEditView.h"
#import "RCKitCommonDefine.h"


#define RCNameEditViewPadding 16
#define RCNameEditViewTipFont 13.5
#define RCNameEditViewContentFont 17


@interface RCNameEditView ()

@property (nonatomic, strong) UIView *editView;

@end

@implementation RCNameEditView

#pragma mark -- private

- (void)setupView {
    [super setupView];
    self.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xf5f6f9", @"0x111111");
    [self addSubview:self.editView];
    [self addSubview:self.tipLabel];
    [self.editView addSubview:self.contentLabel];
    [self.editView addSubview:self.textField];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    // 设置点击次数（默认为1）
    tapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapGesture];
    self.userInteractionEnabled = YES;
    
    if ([RCKitUtility isRTL]) {
        self.textField.textAlignment = NSTextAlignmentRight;
    } else {
        self.textField.textAlignment = NSTextAlignmentLeft;
    }
}

- (void)setupConstraints {
    [super setupConstraints];
    [NSLayoutConstraint activateConstraints:@[
          [self.contentLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:RCNameEditViewPadding],
          [self.contentLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-RCNameEditViewPadding],
          [self.contentLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
          [self.contentLabel.bottomAnchor constraintEqualToAnchor:self.editView.topAnchor constant:-10],
          
          [self.editView.leadingAnchor constraintEqualToAnchor:self.contentLabel.leadingAnchor ],
          [self.editView.trailingAnchor constraintEqualToAnchor:self.contentLabel.trailingAnchor],
          [self.editView.heightAnchor constraintEqualToConstant:42],
          
          [self.textField.leadingAnchor constraintEqualToAnchor:self.editView.leadingAnchor constant:12],
          [self.textField.trailingAnchor constraintEqualToAnchor:self.editView.trailingAnchor constant:-12],
          [self.textField.centerYAnchor constraintEqualToAnchor:self.editView.centerYAnchor],
     
          [self.tipLabel.leadingAnchor constraintEqualToAnchor:self.editView.leadingAnchor],
          [self.tipLabel.trailingAnchor constraintEqualToAnchor:self.editView.trailingAnchor],
          [self.tipLabel.topAnchor constraintEqualToAnchor:self.editView.bottomAnchor constant:RCNameEditViewPadding]
      ]];
}


- (void)handleTap {
    if ([self.textField isFirstResponder]) {
        [self.textField resignFirstResponder];
    }
}

#pragma mark -- getter

- (UIView *)editView {
    if (!_editView) {
        _editView = [[UIView alloc] init];
        _editView.translatesAutoresizingMaskIntoConstraints = NO;
        _editView.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0x1c1c1e");
    }
    return _editView;
}

- (UITextField *)textField {
    if (!_textField) {
        _textField = [[UITextField alloc] init];
        [_textField setTextColor:RCDynamicColor(@"text_primary_color", @"0x000000", @"0xffffffcc")];
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _textField;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:RCNameEditViewContentFont];
        _contentLabel.accessibilityLabel = @"contentLabel";
        _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _contentLabel;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xA0A5Ab", @"0x9f9f9f");
        _tipLabel.font = [UIFont systemFontOfSize:RCNameEditViewTipFont];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.numberOfLines = 0;
        _tipLabel.accessibilityLabel = @"tipLabel";
        _tipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _tipLabel;
}
@end
