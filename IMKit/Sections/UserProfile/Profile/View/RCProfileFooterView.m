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
#define RCProfileFooterViewButtonHeight 40
#define RCProfileFooterViewButtonLeadingOrTrailing 25

@interface RCProfileFooterView ()
@property (nonatomic, strong) NSArray *items;
@end

@implementation RCProfileFooterView

- (instancetype)initWithTopSpace:(CGFloat)topSpace buttonSpace:(CGFloat)buttonSpace items:(nonnull NSArray<RCButtonItem *> *)items {
    self = [super init];
    if (self) {
        self.items = items;
        self.frame = CGRectMake(0, 0, SCREEN_WIDTH, (topSpace + RCProfileFooterViewButtonHeight + buttonSpace) * items.count);
        if (items.count > 0) {
            for (int i = 0; i < items.count; i++) {
                UIButton *button = [self buttonWithItem:items[i]];
                button.frame = CGRectMake(RCProfileFooterViewButtonLeadingOrTrailing, topSpace + i * (RCProfileFooterViewButtonHeight + buttonSpace), SCREEN_WIDTH - RCProfileFooterViewButtonLeadingOrTrailing * 2, RCProfileFooterViewButtonHeight);
                [button addTarget:self action:@selector(buttonDidClick:) forControlEvents:(UIControlEventTouchUpInside)];
                button.tag = i;
                [self addSubview:button];
            }
        }
    }
    return self;
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
    if (item.borderColor) {
        button.layer.borderWidth = 0.5;
        button.layer.borderColor = item.borderColor.CGColor;
    }
    return button;
}
@end
