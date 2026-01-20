//
//  RCGroupNotificationNaviItemsViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2024/11/14.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupNotificationNaviItemsViewModel.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCButton.h"

@interface RCGroupNotificationNaviItemsViewModel()
@property (nonatomic, strong) UIView *coverView;
@end

@implementation RCGroupNotificationNaviItemsViewModel
@dynamic delegate;

- (NSArray *)rightNavigationBarItems {
    RCButton *btn = [[RCButton alloc] init];
    [btn addTarget:self
            action:@selector(rightBarItemClicked:)
  forControlEvents:UIControlEventTouchUpInside];
    UIImage *image = RCResourceImage(@"friend_apply_more");
    [btn setImage:image forState:UIControlStateNormal];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];
    return @[item];
}

- (void)rightBarItemClicked:(id)sender {
    if (self.responder) {
        UIView *btn = (UIView *)sender;
        [self showCoverViewBy:btn];
    }
}

- (void)showCoverViewBy:(UIView *)item {
    UIWindow *window = [RCKitUtility getKeyWindow];
    [window addSubview:self.coverView];
}

- (void)removeCoverView {
    [self.coverView removeFromSuperview];
}

- (void)btnClick:(UIButton *)btn {
    if ([self.delegate respondsToSelector:@selector(userDidSelectCategory:)]) {
        [self.delegate userDidSelectCategory:(RCGroupNotificationCategory)btn.tag];
    }
    self.responder.title = btn.titleLabel.text;
    [self removeCoverView];
}

- (RCButton *)createButton:(NSString *)title category:(NSInteger)category {
    RCButton *btn = [RCButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    UIColor *color = [RCKitUtility generateDynamicColor:HEXCOLOR(0x111F2C)
                                              darkColor:HEXCOLOR(0xffffff)];
    [btn setTitleColor:color forState:UIControlStateNormal];

    btn.tag = category;
    [btn addTarget:self
            action:@selector(btnClick:)
  forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)configureSheetView:(UIView *)containerView {
    CGFloat width = 160;
    CGFloat height = 201;
    CGFloat yOffset = CGRectGetMaxY(self.responder.navigationController.navigationBar.frame);
    CGFloat xOffset = CGRectGetWidth(containerView.frame) - 15 - width;
    CGRect rect = CGRectMake(xOffset, yOffset, width, height);
    UIView *panel = [[UIView alloc] initWithFrame:rect];;
    panel.backgroundColor = RCDYCOLOR(0xFAFAFA, 0x2c2c2c);
    panel.layer.cornerRadius = 6;
    panel.layer.masksToBounds = YES;
    
    NSString *all = RCLocalizedString(@"GroupNotificationAll") ?:@"";
    NSString *confirm = RCLocalizedString(@"GroupNotificationToBeConfirm") ?:@"";
    NSString *agree = RCLocalizedString(@"GroupNotificationAgreed") ?:@"";
    NSString *expired = RCLocalizedString(@"GroupNotificationExpired") ?:@"";
    NSArray *titles = @[all, confirm, agree, expired];
    CGFloat buttonHeight = (height - 24)/titles.count;
    for (int i = 0; i< titles.count; i++) {
        UIButton *btn = [self createButton:titles[i] category:i];
        btn.frame = CGRectMake(0, 12+i*buttonHeight, width, buttonHeight);
        [panel addSubview:btn];
    }
    [containerView addSubview:panel];
}


- (UIView *)coverView {
    if (!_coverView) {
        UIWindow *window = [RCKitUtility getKeyWindow];
        UIView *view = [[UIView alloc] initWithFrame:window.bounds];
        view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(removeCoverView)];
        [view addGestureRecognizer:tap];
        [self configureSheetView:view];
        _coverView = view;
    }
    return _coverView;
}
@end

