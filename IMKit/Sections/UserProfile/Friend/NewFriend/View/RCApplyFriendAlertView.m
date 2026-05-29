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
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.35];
    self.containerView = [self configureContainerView];
    [self addSubview:self.containerView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.containerView.center = CGPointMake(self.center.x, self.center.y-self.containerView.frame.size.height/2);
}

#pragma mark - Private

- (UIView *)configureContainerView {
    CGFloat width = 280;
    CGFloat height = 199;
    UIView *view = [UIView new];
    view.accessibilityLabel = @"container";
    view.layer.cornerRadius = 7;
    view.backgroundColor = RCDYCOLOR(0xFAFAFA, 0x2c2c2c);
    view.layer.masksToBounds = YES;
    view.bounds = CGRectMake(0, 0, width, height);
    
    self.labTitle.frame = CGRectMake(15, 10, 250, 24);
    [view addSubview:self.labTitle];
    
    self.txtView.frame = CGRectMake(8, CGRectGetMaxY(self.labTitle.frame)+10, 264, 85);
    [view addSubview:self.txtView];
    
 
    CGFloat buttonHeight = 55;
    UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(0, height-buttonHeight-1, width, 1)];
    line1.backgroundColor = RCDYCOLOR(0xe5e6e7, 0x323232);
    [view addSubview:line1];

    self.cancelButton.frame = CGRectMake(0, height-buttonHeight, (width-1)/2, buttonHeight);
    [view addSubview:self.cancelButton];
    
    UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake((width+1)/2, CGRectGetMinY(self.cancelButton.frame), 1, CGRectGetHeight(self.cancelButton.frame))];
    line2.backgroundColor =  RCDYCOLOR(0xe5e6e7, 0x323232);
    [view addSubview:line2];

    self.confirmButton.frame = CGRectMake((width+1)/2+1,CGRectGetMinY(self.cancelButton.frame), CGRectGetWidth(self.cancelButton.frame), CGRectGetHeight(self.cancelButton.frame));
    [view addSubview:self.confirmButton];
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
        lab.textColor =  [RCKitUtility generateDynamicColor:HEXCOLOR(0x111f2c)
                                                  darkColor:[HEXCOLOR(0xffffff) colorWithAlphaComponent:0.8]];
        lab.textAlignment = NSTextAlignmentCenter;
        _labTitle = lab;
    }
    return _labTitle;
}

- (RCPlaceholderTextView *)txtView {
    if (!_txtView) {
        RCPlaceholderTextView *txt = [[RCPlaceholderTextView alloc] init];
        txt.backgroundColor = RCDYCOLOR(0xe5e5e5, 0x1a1a1a);
        [txt setTextColor:RCDYCOLOR(0x333333, 0x9f9f9f)];
        txt.layer.cornerRadius = 7;
        txt.delegate = self;
        txt.font = [UIFont systemFontOfSize:14];
        txt.contentInset = UIEdgeInsetsMake(6, 6, 6, 6);
        txt.delegate = self;
        _txtView = txt;
    }
    return _txtView;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[RCBaseButton alloc] initWithFrame:CGRectMake(0, 0, 99, 40)];
        [_confirmButton setTitle:RCLocalizedString(@"Confirm") forState:UIControlStateNormal];
        [_confirmButton setTitleColor:RCDYCOLOR(0x0099ff, 0x007acc) forState:(UIControlStateNormal)];
        [_confirmButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        [_confirmButton addTarget:self
                           action:@selector(confirmButtonClick)
                 forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [[RCBaseButton alloc] initWithFrame:CGRectMake(0, 0, 99, 40)];
        [_cancelButton setTitle:RCLocalizedString(@"Cancel") forState:UIControlStateNormal];
        [_cancelButton setTitleColor:RCDYCOLOR(0x111f2c, 0xAAAAAA)
                            forState:(UIControlStateNormal)];
        [_cancelButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        [_cancelButton addTarget:self
                           action:@selector(cancelButtonClick)
                 forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}


@end
