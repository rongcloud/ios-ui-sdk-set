//
//  RCFriendApplyAlertView.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/30.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCApplyFriendAlertView.h"
#import "RCKitCommonDefine.h"
#import "RCBaseButton.h"
#import "RCKitUtility.h"
#import "RCPlaceholderTextView.h"

@interface RCApplyFriendAlertView()<UITextViewDelegate>
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) RCPlaceholderTextView *txtView;
@property (nonatomic, strong) UILabel *labTitle;
@property (nonatomic, copy) RCApplyFriendAlertBlock block;
@property (nonatomic, assign) NSInteger limit;
@end

@implementation RCApplyFriendAlertView
+ (void)showAlert:(NSString *)title
      placeholder:(NSString *)placeholder
       completion:(void(^)(NSString *))completion {
    [self showAlert:title
        placeholder:placeholder
        lengthLimit:INT32_MAX
         completion:completion];
}

+ (void)showAlert:(NSString *)title
      placeholder:(NSString *)placeholder
      lengthLimit:(NSInteger)limit
       completion:(RCApplyFriendAlertBlock)completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        RCApplyFriendAlertView *alert = [RCApplyFriendAlertView new];
        alert.labTitle.text = title;
        alert.txtView.placeholder = placeholder;
        alert.block = completion;
        alert.limit = limit;
        UIWindow *window = [RCKitUtility getKeyWindow];
        alert.frame = [window bounds];
        [window addSubview:alert];
    });
}

- (void)setupView {
    [super setupView];
    self.backgroundColor =RCDynamicColor(@"mask_color", @"0x00000059", @"0x00000059");
    self.containerView = [self configureContainerView];
    [self addSubview:self.containerView];
}

- (void)setupConstraints {
    [super setupConstraints];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.containerView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.containerView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-100],
        [self.containerView.widthAnchor constraintEqualToConstant:288]
    ]];
}

#pragma mark - Private

- (UIView *)configureContainerView {
    UIView *view = [UIView new];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    
    view.accessibilityLabel = @"container";
    view.layer.cornerRadius = 10;
    view.backgroundColor = RCDynamicColor(@"common_background_color", @"0xFAFAFA", @"0x2c2c2c");
    view.layer.masksToBounds = YES;
    
    UIStackView *contentStackView = [[UIStackView alloc] init];
    contentStackView.axis = UILayoutConstraintAxisVertical;
    contentStackView.alignment = UIStackViewAlignmentFill;
    contentStackView.distribution = UIStackViewDistributionFill;
    contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:contentStackView];
    
    UIView *titleContainer = [UIView new];
    titleContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [titleContainer addSubview:self.labTitle];
    [NSLayoutConstraint activateConstraints:@[
        [self.labTitle.centerXAnchor constraintEqualToAnchor:titleContainer.centerXAnchor],
        [self.labTitle.topAnchor constraintEqualToAnchor:titleContainer.topAnchor constant:24],
        [self.labTitle.bottomAnchor constraintEqualToAnchor:titleContainer.bottomAnchor constant:-20]
    ]];
    [contentStackView addArrangedSubview:titleContainer];
    
    UIView *txtContainer = [UIView new];
    txtContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [txtContainer addSubview:self.txtView];
    [NSLayoutConstraint activateConstraints:@[
        [self.txtView.leadingAnchor constraintEqualToAnchor:txtContainer.leadingAnchor constant:16],
        [self.txtView.trailingAnchor constraintEqualToAnchor:txtContainer.trailingAnchor constant:-16],
        [self.txtView.topAnchor constraintEqualToAnchor:txtContainer.topAnchor],
        [self.txtView.bottomAnchor constraintEqualToAnchor:txtContainer.bottomAnchor constant:-28],
        [self.txtView.heightAnchor constraintEqualToConstant:110]
    ]];
    [contentStackView addArrangedSubview:txtContainer];
    
    UIView *line1 = [[UIView alloc] init];
    line1.backgroundColor = RCDynamicColor(@"line_background_color", @"0xe5e6e7", @"0x323232");
    line1.translatesAutoresizingMaskIntoConstraints = NO;
    [contentStackView addArrangedSubview:line1];
    [NSLayoutConstraint activateConstraints:@[
        [line1.heightAnchor constraintEqualToConstant:1]
    ]];
    
    UIView *line2 = [[UIView alloc] init];
    line2.translatesAutoresizingMaskIntoConstraints = NO;
    line2.backgroundColor =  RCDynamicColor(@"line_background_color", @"0xe5e6e7", @"0x323232");
    
    UIStackView *bottomStackView = [[UIStackView alloc] init];
    [contentStackView addArrangedSubview:bottomStackView];

    bottomStackView.axis = UILayoutConstraintAxisHorizontal;
    bottomStackView.alignment = UIStackViewAlignmentFill;
    bottomStackView.distribution = UIStackViewDistributionFill;
    bottomStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomStackView addArrangedSubview:self.cancelButton];
    [bottomStackView addArrangedSubview:line2];
    [bottomStackView addArrangedSubview:self.confirmButton];
    CGFloat buttonHeight = 55;

    [NSLayoutConstraint activateConstraints:@[
        [line2.widthAnchor constraintEqualToConstant:1],
        [line2.heightAnchor constraintEqualToConstant:buttonHeight],
        [self.cancelButton.widthAnchor constraintEqualToAnchor:self.confirmButton.widthAnchor],

        [contentStackView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [contentStackView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [contentStackView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [contentStackView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
    ]];
    
    return view;
}

- (void)confirmButtonClick {
    NSString *text = self.txtView.text;
    if (self.block) {
        self.block(text);
    }
    [self removeFromSuperview];
}

- (void)cancelButtonClick {
    [self removeFromSuperview];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if (newText.length > self.limit) {
        return NO;
    }
    return YES;
}

#pragma mark - Property
- (UILabel *)labTitle {
    if (!_labTitle) {
        UILabel *lab = [UILabel new];
        lab.font = [UIFont systemFontOfSize:17];
        lab.textColor = RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc");
        lab.textAlignment = NSTextAlignmentCenter;
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        _labTitle = lab;
    }
    return _labTitle;
}

- (RCPlaceholderTextView *)txtView {
    if (!_txtView) {
        RCPlaceholderTextView *txt = [[RCPlaceholderTextView alloc] init];
        txt.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xe5e5e5", @"0x1a1a1a");
        [txt setTextColor:RCDynamicColor(@"text_primary_color", @"0x333333", @"0x9f9f9f")];
        txt.layer.cornerRadius = 4;
        txt.delegate = self;
        txt.font = [UIFont systemFontOfSize:14];
        txt.contentInset = UIEdgeInsetsMake(6, 6, 6, 6);
        txt.delegate = self;
        txt.translatesAutoresizingMaskIntoConstraints = NO;
        [txt setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        _txtView = txt;
    }
    return _txtView;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[RCBaseButton alloc] initWithFrame:CGRectMake(0, 0, 99, 40)];
        [_confirmButton setTitle:RCLocalizedString(@"Confirm") forState:UIControlStateNormal];
        [_confirmButton setTitleColor:RCDynamicColor(@"primary_color",@"0x0099ff", @"0x007acc") forState:(UIControlStateNormal)];
        [_confirmButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        [_confirmButton addTarget:self
                           action:@selector(confirmButtonClick)
                 forControlEvents:UIControlEventTouchUpInside];
        _confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _confirmButton;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [[RCBaseButton alloc] initWithFrame:CGRectMake(0, 0, 99, 40)];
        [_cancelButton setTitle:RCLocalizedString(@"Cancel") forState:UIControlStateNormal];
        [_cancelButton setTitleColor:RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xAAAAAA")
                            forState:(UIControlStateNormal)];
        [_cancelButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        [_cancelButton addTarget:self
                           action:@selector(cancelButtonClick)
                 forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _cancelButton;
}


@end
