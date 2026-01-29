//
//  RCAddFriendView.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCUserSearchView.h"
#import "RCKitCommonDefine.h"

@interface RCUserSearchView()
@property (nonatomic, strong) UIStackView *contentStackView;
@property (nonatomic, strong) UIView *barContainerView;

@end

@implementation RCUserSearchView

- (void)setupView {
    [super setupView];
    self.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xf5f6f9", @"0x111111");
    [self addSubview:self.contentStackView];
    
    UIImageView *imgEmpty = [[UIImageView alloc] init];
    [imgEmpty setImage:RCDynamicImage(@"friend_search_not_exist_img", @"friend_not_exist")];
    imgEmpty.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentStackView addArrangedSubview:imgEmpty];
    [self.contentStackView addArrangedSubview:self.labEmpty];
}

- (void)setupConstraints {
    [super setupConstraints];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentStackView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.contentStackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor]
    ]];
}


- (UIView *)containerViewFor:(UIView *)bar {
    bar.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView *outer = [UIView new];
    outer.translatesAutoresizingMaskIntoConstraints = NO;
    
    CGFloat barHeight = 40;
    UIView *inner = [UIView new];
    inner.translatesAutoresizingMaskIntoConstraints = NO;
    inner.layer.cornerRadius = barHeight/2;
    inner.layer.masksToBounds = YES;
    inner.backgroundColor = RCDynamicColor(@"common_background_color", @"0xFFFFFF", @"0x000000");
    
    [outer addSubview:inner];
    [inner addSubview:bar];
    [NSLayoutConstraint activateConstraints:@[
        [inner.leadingAnchor constraintEqualToAnchor:outer.leadingAnchor constant:16],
        [inner.trailingAnchor constraintEqualToAnchor:outer.trailingAnchor constant:-16],
        [inner.topAnchor constraintEqualToAnchor:outer.topAnchor constant:8],
        [inner.bottomAnchor constraintEqualToAnchor:outer.bottomAnchor],
        [inner.heightAnchor constraintEqualToConstant:barHeight],
        
        [bar.centerYAnchor constraintEqualToAnchor:inner.centerYAnchor],
        [bar.leadingAnchor constraintEqualToAnchor:inner.leadingAnchor constant:5],
        [bar.trailingAnchor constraintEqualToAnchor:inner.trailingAnchor constant:-5],
    ]];
    return outer;
}

- (void)configureSearchBar:(UIView *)bar {
    if (self.barContainerView) {
        [self.barContainerView removeFromSuperview];
    }
    UIView *view = [self containerViewFor:bar];
    [self addSubview:view];
    self.searchBar = bar;
    self.barContainerView = view;
    NSLayoutAnchor *topAnchor;
    if (@available(iOS 11.0, *)) {
        topAnchor = self.safeAreaLayoutGuide.topAnchor;
    } else {
        topAnchor = self.topAnchor;
    }
    [NSLayoutConstraint activateConstraints:@[
          [view.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
          [view.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
          [view.topAnchor constraintEqualToAnchor:topAnchor],
      ]];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}


- (void)displayEmptyView:(BOOL)display {
    self.contentStackView.hidden = !display;
}

- (UILabel *)labEmpty {
    if (!_labEmpty) {
        UILabel *lab = [[UILabel alloc] init];
        lab.text = RCLocalizedString(@"NoUsersWereFound");
        lab.textColor = RCDynamicColor(@"text_primary_color", @"0x939393", @"0x666666");
        lab.font = [UIFont systemFontOfSize:17];
        lab.textAlignment = NSTextAlignmentCenter;
        lab.translatesAutoresizingMaskIntoConstraints = NO;
        [lab sizeToFit];
        _labEmpty = lab;
    }
    return _labEmpty;
}

- (UIStackView *)contentStackView {
    if (!_contentStackView) {
        _contentStackView = [[UIStackView alloc] init];
        _contentStackView.axis = UILayoutConstraintAxisVertical;
        _contentStackView.alignment = UIStackViewAlignmentCenter;
        _contentStackView.distribution = UIStackViewDistributionEqualCentering;
        _contentStackView.spacing = 13;
        _contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentStackView.hidden = YES;
        
    }
    return _contentStackView;
}
@end

