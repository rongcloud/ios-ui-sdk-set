//
//  RCApplyNaviItemsViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/27.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCApplyNaviItemsViewModel.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCButton.h"
@interface RCApplyNaviItemsViewModel()
@property (nonatomic, strong) UIView *coverView;
@end

@implementation RCApplyNaviItemsViewModel
@dynamic delegate;

- (NSArray *)rightNavigationBarItems {
    RCButton *btn = [[RCButton alloc] init];
    [btn addTarget:self
            action:@selector(rightBarItemClicked:)
  forControlEvents:UIControlEventTouchUpInside];
    UIImage *image = RCDynamicImage(@"friend_apply_more_img", @"friend_apply_more");
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
    [NSLayoutConstraint activateConstraints:@[
        [self.coverView.leadingAnchor constraintEqualToAnchor:window.leadingAnchor],
        [self.coverView.trailingAnchor constraintEqualToAnchor:window.trailingAnchor],
        [self.coverView.topAnchor constraintEqualToAnchor:window.topAnchor],
        [self.coverView.bottomAnchor constraintEqualToAnchor:window.bottomAnchor]
    ]];
    [self.coverView setNeedsLayout];
    [self.coverView layoutIfNeeded];
}

- (void)removeCoverView {
    [self.coverView removeFromSuperview];
}

- (void)btnClick:(UIButton *)btn {
    if ([self.delegate respondsToSelector:@selector(userDidSelectCategory:)]) {
        [self.delegate userDidSelectCategory:(RCApplicationCategory)btn.tag];
    }
    [self removeCoverView];
    [btn setBackgroundColor:RCDynamicColor(@"clear_color", @"0x00000000", @"0x00000000")];
}

- (void)touchDown:(UIButton *)btn {
    [btn setBackgroundColor:RCDynamicColor(@"auxiliary_background_2_color", @"0x00000000", @"0x00000000")];
}

- (void)touchCancel:(UIButton *)btn {
    [btn setBackgroundColor:RCDynamicColor(@"clear_color", @"0x00000000", @"0x00000000")];
}
- (RCButton *)createButton:(NSString *)title category:(NSInteger)category {
    RCButton *btn = [RCButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    UIColor *color = RCDynamicColor(@"text_primary_color", @"0x111F2C", @"0xffffff");
    [btn setTitleColor:color forState:UIControlStateNormal];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.tag = category;
    [btn addTarget:self
            action:@selector(btnClick:)
  forControlEvents:UIControlEventTouchUpInside];
    
    [btn addTarget:self
            action:@selector(btnClick:)
  forControlEvents:UIControlEventTouchUpOutside];
    [btn addTarget:self
            action:@selector(touchDown:)
  forControlEvents:UIControlEventTouchDown];
    [btn addTarget:self
            action:@selector(touchCancel:)
  forControlEvents:UIControlEventTouchCancel];
    return btn;
}

- (void)configureSheetView:(UIView *)containerView {
    CGFloat width = 180;
    CGFloat height = 181;

    CGFloat yOffset = CGRectGetMaxY(self.responder.navigationController.navigationBar.frame);
    UIView *panel = [[UIView alloc] init];;
    panel.backgroundColor = RCDynamicColor(@"common_background_color", @"0xFAFAFA", @"0x2c2c2c");
    panel.layer.cornerRadius = 10;
    panel.layer.masksToBounds = YES;
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:panel];

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [panel addSubview:stackView];
    [NSLayoutConstraint activateConstraints:@[
        [panel.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-16],
        [panel.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:yOffset],
        [panel.widthAnchor constraintEqualToConstant:width],
        [panel.heightAnchor constraintEqualToConstant:height],

        [stackView.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor],
        [stackView.topAnchor constraintEqualToAnchor:panel.topAnchor constant:16],
        [stackView.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-16]
    ]];
    NSString *all = RCLocalizedString(@"FriendApplicationAll") ?:@"";
    NSString *received = RCLocalizedString(@"FriendApplicationRecieved") ?:@"";
    NSString *sent = RCLocalizedString(@"FriendApplicationSent") ?:@"";
    NSArray *titles = @[all, received, sent];
    for (int i = 0; i< titles.count; i++) {
        UIButton *btn = [self createButton:titles[i] category:i];
        [stackView addArrangedSubview:btn];
    }
}


- (UIView *)coverView {
    if (!_coverView) {
        UIWindow *window = [RCKitUtility getKeyWindow];
        UIView *view = [[UIView alloc] initWithFrame:window.bounds];
        view.backgroundColor = RCDynamicColor(@"mask_color", @"0x0000003f", @"0x0000003f");
        view.translatesAutoresizingMaskIntoConstraints = NO;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(removeCoverView)];
        [view addGestureRecognizer:tap];
        [self configureSheetView:view];
        _coverView = view;
    }
    return _coverView;
}

@end
