//
//  RCSearchUserProfileViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCSearchUserProfileViewModel.h"
#import "RCSearchBar.h"
#import "RCKitCommonDefine.h"

@interface RCSearchUserProfileViewModel()<UISearchBarDelegate,UISearchControllerDelegate> {
}
@end

@implementation RCSearchUserProfileViewModel
@dynamic delegate;

- (instancetype)initWithPlaceholder:(NSString *)placeholder
{
    self = [super init];
    if (self) {
        self.searchBar = [self createSearchBar:placeholder];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.searchBar = [self createSearchBar:RCLocalizedString(@"UserSearchApplicationNumber")];
    }
    return self;
}

- (void)endEditingState {
    [self.searchBar resignFirstResponder];
    self.searchBar.showsCancelButton = NO;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchBar.text = nil;
    self.searchBar.showsCancelButton = NO;
    [self.searchBar resignFirstResponder];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = YES;
    for (UIView *view in [[[self.searchBar subviews] objectAtIndex:0] subviews]) {
        if ([view isKindOfClass:[NSClassFromString(@"UINavigationButton") class]]) {
            UIButton *cancel = (UIButton *)view;
            [cancel setTitle:RCLocalizedString(@"Cancel") forState:UIControlStateNormal];
            break;
        }
    }
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    if ([self.delegate respondsToSelector:@selector(searchUserProfileWithText:)]) {
        [self.delegate searchUserProfileWithText:searchBar.text];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([self.delegate respondsToSelector:@selector(searchBar:textDidChange:)]) {
        [self.delegate searchBar:searchBar textDidChange:searchText];
    }
}
- (UISearchBar *)createSearchBar:(NSString *)placeholder {
    CGFloat height = 44;
    if (@available(iOS 11.0, *)) {
        height = 56;
    }
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    UISearchBar *bar = [[RCSearchBar alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    bar.delegate = self;
    bar.keyboardType = UIKeyboardTypeDefault;
    bar.placeholder = placeholder;
    return bar;
}
@end

