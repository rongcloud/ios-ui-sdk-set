//
//  RCAddFriendViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCUserSearchViewModel.h"
#import "RCSearchUserProfileViewModel.h"
#import "RCUserProfileViewModel.h"
#import "RCProfileViewController.h"
#import "RCKitCommonDefine.h"

@interface RCUserSearchViewModel()<RCSearchUserProfileViewModelDelegate>
@property (nonatomic, strong) RCSearchUserProfileViewModel *searchBarVM;
@property (nonatomic, strong) RCNavigationItemsViewModel *naviItemsVM;
@property (nonatomic, weak) UIViewController <RCListViewModelResponder> *responder;

@end

@implementation RCUserSearchViewModel
@dynamic delegate;

#pragma mark - Public

- (UISearchBar *)configureSearchBarForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureSearchBarViewModelForUserSearchViewModel:)]) {
        self.searchBarVM = [self.delegate willConfigureSearchBarViewModelForUserSearchViewModel:self];
    } else if(!self.searchBarVM) {
        RCSearchUserProfileViewModel *vm = [[RCSearchUserProfileViewModel alloc] initWithPlaceholder:RCLocalizedString(@"UserSearchApplicationNumber")];
        vm.delegate = self;
        self.searchBarVM = vm;
    }
    return self.searchBarVM.searchBar;
}

- (NSArray *)configureRightNaviItemsForViewController:(UIViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(willConfigureRightNavigationItemsForUserSearchViewModel:)]) {
        self.naviItemsVM = [self.delegate willConfigureRightNavigationItemsForUserSearchViewModel:self];
    } else if(!self.naviItemsVM) {
        RCNavigationItemsViewModel *vm = [[RCNavigationItemsViewModel alloc] initWithResponder:viewController];
        self.naviItemsVM = vm;
    }
    return [self.naviItemsVM rightNavigationBarItems];
}

- (void)endEditingState {
    [self.searchBarVM endEditingState];
}

- (void)bindResponder:(UIViewController <RCListViewModelResponder>*)responder {
    self.responder = responder;
}


#pragma mark - RCSearchUserProfileViewModelDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reloadData:NO];
}

- (void)searchUserProfileWithText:(NSString *)text {
    if ([self.delegate respondsToSelector:@selector(userSearchViewModel:searchUserProfileWithText:)]) {
        BOOL ret = [self.delegate userSearchViewModel:self
                            searchUserProfileWithText:text];
        if (ret) {
            return;
        }
    }
    [self startLoading];
    [[RCCoreClient sharedCoreClient] searchUserProfileByUniqueId:text
                                                         success:^(RCUserProfile * _Nonnull userProfile) {
        [self reloadData:userProfile == nil];
        if (userProfile) {
            [self showUserProfile:userProfile];
        }
        [self endLoading];
    }
                                                           error:^(RCErrorCode errorCode) {
        [self showTipsWithCode:errorCode];
        if (errorCode == RC_USER_PROFILE_USER_NOT_EXIST) {
            [self reloadData:YES];
            
        }
        [self endLoading];
    }];
}
#pragma mark -- Private
- (void)startLoading {
    if ([self.responder respondsToSelector:@selector(startLoading)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder startLoading];
        });
    }
}

- (void)endLoading {
    if ([self.responder respondsToSelector:@selector(endLoading)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder endLoading];
        });
    }
}

- (void)showUserProfile:(RCUserProfile *)profile {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(userSearchViewModel:showUserProfile:)]) {
            BOOL ret = [self.delegate userSearchViewModel:self
                                          showUserProfile:profile];
            if (ret) {
                return;
            }
        }
        RCProfileViewModel *viewModel = [RCUserProfileViewModel viewModelWithUserId:profile.userId];
        RCProfileViewController *vc = [[RCProfileViewController alloc] initWithViewModel:viewModel];
        [self.responder.navigationController pushViewController:vc
                                                       animated:YES];
    });
}
- (void)showTipsWithCode:(RCErrorCode)errorCode {
    if ([self.responder respondsToSelector:@selector(showTips:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder showTips:RCLocalizedString(@"UserSearchFailed")];
        });
    }
}

- (void)reloadData:(BOOL)ret {
    if ([self.responder respondsToSelector:@selector(reloadData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.responder reloadData:ret];
        });
    }
}

@end
