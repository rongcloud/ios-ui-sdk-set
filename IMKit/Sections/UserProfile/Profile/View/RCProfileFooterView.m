//
//  RCProfileFooterView.m
//  RongIMKit
//
//  Created by zgh on 2024/8/22.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCProfileFooterView.h"
#import "RCConversationViewController.h"
#import "RCKitCommonDefine.h"
#define RCProfileFooterViewButtonHeight 42
#define RCProfileFooterViewButtonLeadingOrTrailing 25

@interface RCProfileFooterView ()
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) UIStackView *buttonsStackView;
@property (nonatomic, strong) UIStackView *containerStackView;

@end

@implementation RCProfileFooterView

- (instancetype)initWithTopSpace:(CGFloat)topSpace buttonSpace:(CGFloat)buttonSpace items:(nonnull NSArray<RCButtonItem *> *)items {
    self = [super init];
    if (self) {
        self.items = items;
        self.frame = CGRectMake(0, 0, SCREEN_WIDTH, (topSpace + RCProfileFooterViewButtonHeight + buttonSpace) * items.count);
        [self setupButtonItems:topSpace buttonSpace:buttonSpace items:items];
    }
    return self;
}

- (void)setupView
{
    [super setupView];
    [self addSubview:self.buttonsStackView];
}


- (void)buttonDidClick:(UIButton *)sender {
    RCButtonItem *item = self.items[sender.tag];
    item.clickBlock();
}

- (UIButton *)buttonWithItem:(RCButtonItem *)item {
    UIButton *button = [[UIButton alloc] init];
    [button setTitle:item.title forState:(UIControlStateNormal)];
    [button setTitleColor:item.titleColor forState:(UIControlStateNormal)];
    button.backgroundColor = item.backgroundColor;
    button.layer.cornerRadius = 5;
    button.layer.masksToBounds = YES;
    if (item.buttonIcon) {
        [button setImage:item.buttonIcon forState:UIControlStateNormal];
        [button setImage:item.buttonIcon forState:UIControlStateHighlighted];
        NSInteger spacing = 3;
        if ([RCKitUtility isRTL]) {
            button.titleEdgeInsets = UIEdgeInsetsMake(0.0,
                                                      -spacing,
                                                      0,
                                                      0);
            button.imageEdgeInsets = UIEdgeInsetsMake(0,
                                                      0,
                                                      0.0,
                                                      -spacing);
        }
        else
        {
            button.titleEdgeInsets = UIEdgeInsetsMake(0.0,
                                                      0,
                                                      0,
                                                      -spacing);
            button.imageEdgeInsets = UIEdgeInsetsMake(0,
                                                      -spacing,
                                                      0.0,
                                                      0);
        }
    }
    if (item.borderColor) {
        button.layer.borderWidth = 0.5;
        button.layer.borderColor = item.borderColor.CGColor;
    }
    return button;
}

- (void)setupButtonItems:(CGFloat)topSpace
             buttonSpace:(CGFloat)buttonSpace
                   items:(nonnull NSArray<RCButtonItem *> *)items {
    if (items.count == 0) {
        return;
    }
    self.buttonsStackView.spacing = buttonSpace;
    for (int i = 0; i < items.count; i++) {
        UIButton *button = [self buttonWithItem:items[i]];
        [button addTarget:self action:@selector(buttonDidClick:) forControlEvents:(UIControlEventTouchUpInside)];
        button.tag = i;
        [self addSubview:button];
        [self.buttonsStackView addArrangedSubview:button];
    }
    
    NSInteger count = items.count;
    CGFloat height = RCProfileFooterViewButtonHeight*count + buttonSpace*(count -1);
    [NSLayoutConstraint activateConstraints:@[
          [self.buttonsStackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
          [self.buttonsStackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
          [self.buttonsStackView.heightAnchor constraintEqualToConstant:height],
          [self.buttonsStackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:topSpace]
      ]];
}

- (UIStackView *)buttonsStackView {
    if (!_buttonsStackView) {
        _buttonsStackView = [[UIStackView alloc] init];
        _buttonsStackView.translatesAutoresizingMaskIntoConstraints = NO;
        _buttonsStackView.axis = UILayoutConstraintAxisVertical;
        _buttonsStackView.alignment = UIStackViewAlignmentFill;
        _buttonsStackView.spacing = 10;
        _buttonsStackView.distribution = UIStackViewDistributionFillEqually;
    }
    return _buttonsStackView;
}

@end
