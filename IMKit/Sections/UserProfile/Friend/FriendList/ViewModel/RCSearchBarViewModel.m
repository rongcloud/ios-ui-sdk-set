//
//  RCUFriendListSearchBarViewModel.m
//  RongUserProfile
//
//  Created by RobinCui on 2024/8/16.
//


#import "RCSearchBarViewModel.h"
#import "RCSearchBar.h"
#import "RCKitCommonDefine.h"
@interface RCSearchBarViewModel()<UISearchBarDelegate,UISearchControllerDelegate> {

    BOOL _inSearching;
}
@property (nonatomic, weak) UIViewController *responder;
@property (nonatomic, assign) BOOL inSearching;
@property (nonatomic, copy) NSString *keyword;
@end


@implementation RCSearchBarViewModel
@dynamic delegate;

- (instancetype)initWithResponder:(UIViewController *)responder
{
    self = [super init];
    if (self) {
        self.responder = responder;
        self.searchBar = [self createSearchBar];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.searchBar = [self createSearchBar];
    }
    return self;
}

- (BOOL)isCurrentFirstResponder {
    return self.inSearching;
}

- (void)endEditingState {
    self.inSearching = NO;
    [self.searchBar resignFirstResponder];
    self.searchBar.text = nil;
    self.searchBar.showsCancelButton = NO;
    self.keyword = nil;
}

#pragma mark - UISearchBarDelegate
//  执行 delegate 搜索好友
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([self.keyword isEqualToString:searchText]) {
        return;
    }
    self.keyword = searchText;
    if ([self.delegate respondsToSelector:@selector(searchBar:textDidChange:)]) {
        return [self.delegate searchBar:searchBar textDidChange:searchText];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchBar.text = nil;
    self.inSearching = NO;
    self.searchBar.showsCancelButton = NO;
    [self.searchBar resignFirstResponder];
    self.keyword = nil;
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    BOOL shoudBegin = YES;
    if ([self.delegate respondsToSelector:@selector(searchBarShouldBeginEditing:)]) {
        shoudBegin = [self.delegate searchBarShouldBeginEditing:searchBar];;
    }
    if (!shoudBegin) {
        return NO;
    }
    self.inSearching = YES;
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
}


#pragma mark - Getter & Setter

- (void)setInSearching:(BOOL)inSearching {
    if (inSearching != _inSearching) {
        _inSearching = inSearching;
        if ([self.delegate respondsToSelector:@selector(searchBar:editingStateChanged:)]) {
            [self.delegate searchBar:self.searchBar editingStateChanged:inSearching];
        }
    }
}


- (UISearchBar *)createSearchBar {
    CGFloat height = 44;
    if (@available(iOS 11.0, *)) {
        height = 56;
    }
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    UISearchBar *bar = [[RCSearchBar alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    bar.delegate = self;
    bar.keyboardType = UIKeyboardTypeDefault;
    bar.placeholder = RCLocalizedString(@"ToSearch");
    return bar;
}
@end
