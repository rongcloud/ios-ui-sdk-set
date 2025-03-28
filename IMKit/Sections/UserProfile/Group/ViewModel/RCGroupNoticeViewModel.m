//
//  RCGroupNoticeViewModel.m
//  RongIMKit
//
//  Created by zgh on 2024/8/28.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCGroupNoticeViewModel.h"
#import "RCKitCommonDefine.h"
#import "RCAlertView.h"
#import "RCIM.h"
@interface RCGroupNoticeViewModel ()

@property (nonatomic, strong) RCGroupInfo *group;

@property (nonatomic, assign) BOOL canEdit;

@property (nonatomic, assign) NSInteger limit;

@end

@implementation RCGroupNoticeViewModel
@dynamic delegate;

- (instancetype)initWithGroup:(RCGroupInfo *)group {
    self = [super init];
    if (self) {
        self.group = group;
        self.canEdit = [self canEditProfile];
        self.limit = 1024;
    }
    return self;
}

- (void)updateNotice:(NSString *)notice inViewController:(nonnull UIViewController *)viewController{
    RCGroupInfo *group = [[RCGroupInfo alloc] init];
    group.groupId = self.group.groupId;
    group.notice = notice;
    if ([self.delegate respondsToSelector:@selector(groupNoticeWillUpdate:viewModel:inViewController:)]) {
        BOOL intercept = [self.delegate groupNoticeWillUpdate:group viewModel:self inViewController:viewController];
        if (intercept) {
            return;
        }
    }
    [RCAlertView showAlertController:nil message:RCLocalizedString(@"GroupNoticeUpdateAlert") actionTitles:nil cancelTitle:RCLocalizedString(@"Cancel") confirmTitle:RCLocalizedString(@"Confirm") preferredStyle:(UIAlertControllerStyleAlert) actionsBlock:nil cancelBlock:nil confirmBlock:^{
        [self updateGroup:group inViewController:viewController];
    } inViewController:viewController];
    
}

- (NSString *)tip {
    if (self.canEdit) {
        return nil;
    }
    if (self.group.groupInfoEditPermission == RCGroupOperationPermissionOwner) {
        return RCLocalizedString(@"GroupOperationOnlyOwner");
    }
    if (self.group.groupInfoEditPermission == RCGroupOperationPermissionOwnerOrManager) {
        return RCLocalizedString(@"GroupOperationOwnerAndManager");
    }
    return nil;
}

#pragma mark -- private

- (BOOL)canEditProfile {
    if (self.group.groupInfoEditPermission == RCGroupOperationPermissionOwner && self.group.role == RCGroupMemberRoleOwner) {
        return YES;
    }
    if (self.group.groupInfoEditPermission == RCGroupOperationPermissionOwnerOrManager && (self.group.role == RCGroupMemberRoleOwner || self.group.role == RCGroupMemberRoleManager)) {
        return YES;
    }
    if (self.group.groupInfoEditPermission == RCGroupOperationPermissionEveryone) {
        return YES;
    }
    return NO;
}

- (void)updateGroup:(RCGroupInfo *)group inViewController:(nonnull UIViewController *)viewController {
    [self loadingWithTip:RCLocalizedString(@"Saving")];
    [[RCIM sharedRCIM] updateGroupInfo:group
                          successBlock:^{
        [self stopLoading];
        if ([self.delegate respondsToSelector:@selector(groupNoticeDidUpdate:viewModel:inViewController:)]) {
            BOOL intercept = [self.delegate groupNoticeDidUpdate:group viewModel:self inViewController:viewController];
            if (intercept) {
                return;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [viewController.navigationController popViewControllerAnimated:YES];
            [RCAlertView showAlertController:nil message:RCLocalizedString(@"GroupNoticeSuccess") hiddenAfterDelay:2];
        });
    } errorBlock:^(RCErrorCode errorCode, NSArray<NSString *> * _Nullable errorKeys) {
        [self stopLoading];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *tips = RCLocalizedString(@"SetFailed");
            if (errorCode == RC_SERVICE_INFORMATION_AUDIT_FAILED) {
                tips = RCLocalizedString(@"Content_Contains_Sensitive");
            }

            [RCAlertView showAlertController:nil message:tips hiddenAfterDelay:2];
        });
    }];
}
@end
