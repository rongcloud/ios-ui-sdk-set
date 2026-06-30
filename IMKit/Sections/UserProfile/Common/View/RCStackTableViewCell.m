//
//  RCStackTableViewCell.m
//  RongIMKit
//
//  Created by RobinCui on 2025/12/10.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCStackTableViewCell.h"

@implementation RCStackTableViewCell

- (void)setupView {
    [super setupView];
    [self.paddingContainerView addSubview:self.contentStackView];
}

- (void)setupConstraints {
    [super setupConstraints];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentStackView.leadingAnchor constraintEqualToAnchor:self.paddingContainerView.leadingAnchor constant:RCUserManagementPadding],
        [self.contentStackView.trailingAnchor constraintEqualToAnchor:self.paddingContainerView.trailingAnchor constant:-RCUserManagementPadding],
        [self.contentStackView.topAnchor constraintEqualToAnchor:self.paddingContainerView.topAnchor],
        [self.contentStackView.bottomAnchor constraintEqualToAnchor:self.paddingContainerView.bottomAnchor]
    ]];
}

- (UIStackView *)contentStackView {
   if (!_contentStackView) {
       _contentStackView = [[UIStackView alloc] init];
       _contentStackView.axis = UILayoutConstraintAxisHorizontal;
       _contentStackView.alignment = UIStackViewAlignmentCenter;
       _contentStackView.distribution = UIStackViewDistributionFill;
       _contentStackView.spacing = 5;
       _contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
   }
   return _contentStackView;
}
@end
