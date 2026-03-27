//
//  RCUserProfileViewModel.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/16.
//

#import "RCProfileViewModel.h"

@interface RCProfileViewModel ()

@property (nonatomic, strong) RCProfileFooterViewModel *footerViewModel;

@property (nonatomic, strong) NSArray <NSArray <RCProfileCellViewModel*> *> *profileList;

@end

@implementation RCProfileViewModel
@dynamic delegate;

- (void)updateProfile {
    
}

- (void)configFooterViewModel:(RCProfileFooterViewModel *)viewModel {
    if ([self.delegate respondsToSelector:@selector(profileViewModel:willLoadProfileFooterViewModel:)]) {
        self.footerViewModel = [self.delegate profileViewModel:self willLoadProfileFooterViewModel:viewModel];
    } else {
        self.footerViewModel = viewModel;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.responder reloadFooterView];
    });
}

- (UIView *)loadFooterView {
    return [self.footerViewModel loadView];
}

- (void)setProfileList:(NSArray<NSArray<RCProfileCellViewModel *> *> *)profileList {
    if ([self.delegate respondsToSelector:@selector(profileViewModel:willLoadProfileCellViewModel:)]) {
        _profileList = [self.delegate profileViewModel:self willLoadProfileCellViewModel:profileList];
    } else {
        _profileList = profileList;
    }
}

@end
