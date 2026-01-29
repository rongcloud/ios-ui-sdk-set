//
//  RCAddFriendView.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCUserSearchView.h"
#import "RCKitCommonDefine.h"

@implementation RCUserSearchView

- (void)setupView {
    [super setupView];
    self.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x111111);
    [self addSubview:self.labEmpty];
}

- (void)configureSearchBar:(UIView *)bar {
    [self addSubview:bar];
    self.searchBar = bar;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat searchBarHeight = self.searchBar.frame.size.height;
    if (self.searchBar) {
        self.searchBar.frame = CGRectMake(0, 0, self.bounds.size.width, searchBarHeight);
    }
    self.labEmpty.center = self.center;
}

- (UILabel *)labEmpty {
    if (!_labEmpty) {
        UILabel *lab = [[UILabel alloc] init];
        lab.text = RCLocalizedString(@"NoUsersWereFound");
        lab.textColor = RCDYCOLOR(0x939393, 0x666666);
        lab.font = [UIFont systemFontOfSize:17];
        lab.textAlignment = NSTextAlignmentCenter;
        lab.hidden = YES;
        [lab sizeToFit];
        _labEmpty = lab;
    }
    return _labEmpty;
}
@end

